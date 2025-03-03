import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:logging/logging.dart';
import '../models/connection_model.dart';
import '../models/device_info_model.dart';
import '../models/socket_message_model.dart';
import '../models/connection_status.dart';
import '../../infrastructure/constants/network_constants.dart';
import '../../infrastructure/utils/network_utils.dart';
import 'connection_service.dart';
import 'socket_communication_service.dart';

/// 连接服务实现类
class ConnectionServiceImpl implements ConnectionService {
  /// 日志记录器
  final _logger = Logger('ConnectionServiceImpl');

  /// 连接状态控制器
  final _connectionStateController =
      StreamController<ConnectionModel>.broadcast();

  /// 连接请求控制器
  final _connectionRequestController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// 当前连接状态
  ConnectionModel _currentConnectionState =
      ConnectionModel(status: ConnectionStatus.disconnected);

  /// 本地设备信息
  DeviceInfoModel _localDevice;

  /// 随机数生成器，用于生成配对码
  final _random = Random();

  /// 连接超时计时器
  Timer? _connectionTimer;

  /// 配对确认超时计时器
  Timer? _pairingTimer;

  /// Socket通信服务
  final SocketCommunicationService _socketService;

  /// 消息订阅
  StreamSubscription<SocketMessageModel>? _messageSubscription;

  /// 连接状态订阅
  StreamSubscription<ConnectionStatus>? _connectionStatusSubscription;

  /// 当前连接的设备信息
  DeviceInfoModel? _connectedDevice;

  /// 构造函数
  ConnectionServiceImpl(SocketCommunicationService socketService)
      : _socketService = socketService,
        _localDevice = DeviceInfoModel(
          deviceName: 'Unknown',
          ipAddress: '127.0.0.1',
        ) {
    init();
  }

  /// 初始化服务
  @override
  Future<void> init() async {
    _messageSubscription = _socketService.messageStream.listen(_handleMessage);
    _connectionStatusSubscription = _socketService.connectionStatusStream
        .listen(_handleSocketConnectionStatus);
    await _startSocketServer();
  }

  @override
  Future<bool> connectToDevice(String ip,
      {int port = NetworkConstants.LISTEN_PORT}) async {
    try {
      final connected = await _socketService.connectToDevice(ip, port: port);
      if (connected) {
        _updateConnectionState(
          _currentConnectionState.copyWith(
            status: ConnectionStatus.connected,
            remoteIpAddress: ip,
          ),
        );
        return true;
      } else {
        _updateConnectionState(
          _currentConnectionState.copyWith(
            status: ConnectionStatus.failed,
            failureReason: '连接失败',
          ),
        );
        return false;
      }
    } catch (e) {
      _updateConnectionState(
        _currentConnectionState.copyWith(
          status: ConnectionStatus.failed,
          failureReason: e.toString(),
        ),
      );
      return false;
    }
  }

  @override
  Future<void> disconnectFromDevice() async {
    await _socketService.disconnectFromDevice();
  }

  @override
  Stream<ConnectionStatus> get connectionStatusStream =>
      _connectionStateController.stream.map((state) => state.status);

  @override
  ConnectionStatus get currentStatus => _currentConnectionState.status;

  @override
  DeviceInfoModel? get connectedDevice => _connectedDevice;

  @override
  DeviceInfoModel get localDevice => _localDevice;

  @override
  Future<void> simulateIncomingConnectionRequest(
      DeviceInfoModel remoteDevice) async {
    final pairingCode = _generatePairingCode();
    final connectionRequestMessage = SocketMessageModel.createConnectionRequest(
      deviceName: remoteDevice.deviceName,
      deviceIp: remoteDevice.ipAddress,
      pairingCode: pairingCode,
    );
    _handleMessage(connectionRequestMessage);
  }

  /// 发送连接响应消息
  Future<void> _sendConnectionResponse(
      SocketMessageModel connectionResponseMessage) async {
    try {
      await _socketService.sendMessage(connectionResponseMessage);
      _logger.info('发送连接响应消息成功');
    } catch (e) {
      _logger.severe('发送连接响应消息失败: $e');
      throw Exception('发送连接响应消息失败');
    }
  }

  /// 发送连接请求消息
  Future<void> _sendConnectionRequest(
      SocketMessageModel connectionRequestMessage) async {
    try {
      await _socketService.sendMessage(connectionRequestMessage);
      _logger.info('发送连接请求消息成功');
    } catch (e) {
      _logger.severe('发送连接请求消息失败: $e');
      throw Exception('发送连接请求消息失败');
    }
  }

  /// 启动Socket服务器
  Future<void> _startSocketServer() async {
    try {
      await _socketService.startServer();
      _logger.info('Socket服务器启动成功');
    } catch (e) {
      _logger.severe('Socket服务器启动失败: $e');
    }
  }

  @override
  Future<DeviceInfoModel> getLocalDeviceInfo() async {
    try {
      final deviceName = await NetworkUtils.getDeviceName();
      final ipAddress = await NetworkUtils.getLocalIpAddress();

      _localDevice = DeviceInfoModel(
        deviceName: deviceName,
        ipAddress: ipAddress,
      );

      _logger.info('获取本地设备信息: 设备名称=$deviceName, IP地址=$ipAddress');
      return _localDevice;
    } catch (e) {
      _logger.severe('获取本地设备信息失败: $e');
      return _localDevice;
    }
  }

  @override
  Future<String> initiateConnection(String targetIp) async {
    try {
      _updateConnectionState(
        _currentConnectionState.copyWith(
          status: ConnectionStatus.connecting,
          remoteIpAddress: targetIp,
          isInitiator: true,
        ),
      );

      final pairingCode = _generatePairingCode();
      final localDeviceInfo = await getLocalDeviceInfo();

      final connected = await connectToDevice(targetIp);
      if (!connected) {
        throw Exception('连接失败');
      }

      final connectionRequestMessage =
          SocketMessageModel.createConnectionRequest(
        deviceName: localDeviceInfo.deviceName,
        deviceIp: localDeviceInfo.ipAddress,
        pairingCode: pairingCode,
      );

      await _sendConnectionRequest(connectionRequestMessage);

      _updateConnectionState(
        _currentConnectionState.copyWith(
          status: ConnectionStatus.awaitingConfirmation,
          pairingCode: pairingCode,
        ),
      );

      return pairingCode;
    } catch (e) {
      _updateConnectionState(
        _currentConnectionState.copyWith(
          status: ConnectionStatus.failed,
          failureReason: e.toString(),
        ),
      );
      rethrow;
    }
  }

  @override
  Future<bool> acceptConnection(String initiatorIp, String pairingCode) async {
    try {
      if (_currentConnectionState.pairingCode != pairingCode) {
        throw Exception('配对码不匹配');
      }

      final localDeviceInfo = await getLocalDeviceInfo();
      final connectionResponseMessage =
          SocketMessageModel.createConnectionResponse(
        accepted: true,
        deviceName: localDeviceInfo.deviceName,
        deviceIp: localDeviceInfo.ipAddress,
      );

      await _sendConnectionResponse(connectionResponseMessage);

      _updateConnectionState(
        _currentConnectionState.copyWith(
          status: ConnectionStatus.connected,
        ),
      );

      return true;
    } catch (e) {
      _logger.severe('接受连接失败: $e');
      return false;
    }
  }

  @override
  Future<void> rejectConnection(String initiatorIp) async {
    try {
      final localDeviceInfo = await getLocalDeviceInfo();
      final connectionResponseMessage =
          SocketMessageModel.createConnectionResponse(
        accepted: false,
        deviceName: localDeviceInfo.deviceName,
        deviceIp: localDeviceInfo.ipAddress,
        rejectReason: '用户拒绝连接',
      );

      await _sendConnectionResponse(connectionResponseMessage);
      await disconnectFromDevice();

      _updateConnectionState(
        _currentConnectionState.copyWith(
          status: ConnectionStatus.failed,
        ),
      );
    } catch (e) {
      _logger.severe('拒绝连接失败: $e');
      throw Exception('拒绝连接失败: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      final disconnectMessage = SocketMessageModel(
        type: SocketMessageType.DISCONNECT,
        data: {'reason': '用户主动断开连接'},
      );

      await _socketService.sendMessage(disconnectMessage);
      await disconnectFromDevice();

      _updateConnectionState(
        _currentConnectionState.copyWith(
          status: ConnectionStatus.disconnected,
        ),
      );
    } catch (e) {
      _logger.severe('断开连接失败: $e');
      throw Exception('断开连接失败: $e');
    }
  }

  @override
  Future<void> cancelConnection() async {
    try {
      await disconnectFromDevice();
      _connectionTimer?.cancel();
      _pairingTimer?.cancel();

      _updateConnectionState(
        _currentConnectionState.copyWith(
          status: ConnectionStatus.cancelled,
        ),
      );
    } catch (e) {
      _logger.severe('取消连接失败: $e');
      throw Exception('取消连接失败: $e');
    }
  }

  /// 生成6位数字配对码
  String _generatePairingCode() {
    return (_random.nextInt(900000) + 100000).toString();
  }

  /// 检查设备是否可达
  Future<bool> _checkDeviceReachable(String ip) async {
    try {
      final result = await InternetAddress(ip).reverse();
      return result != null;
    } catch (e) {
      return false;
    }
  }

  /// 更新连接状态
  void _updateConnectionState(ConnectionModel newState) {
    _currentConnectionState = newState;
    _connectionStateController.add(newState);
  }

  /// 处理Socket连接状态变化
  void _handleSocketConnectionStatus(ConnectionStatus status) {
    if (status == ConnectionStatus.disconnected) {
      _connectedDevice = null;
    }
    _updateConnectionState(_currentConnectionState.copyWith(status: status));
  }

  /// 处理收到的消息
  void _handleMessage(SocketMessageModel message) {
    switch (message.type) {
      case SocketMessageType.CONNECTION_REQUEST:
        _handleConnectionRequest(message);
        break;
      case SocketMessageType.CONNECTION_RESPONSE:
        _handleConnectionResponse(message);
        break;
      case SocketMessageType.DISCONNECT:
        _handleDisconnect(message);
        break;
      default:
        _logger.warning('收到未知类型的消息: ${message.type}');
    }
  }

  /// 处理连接请求
  void _handleConnectionRequest(SocketMessageModel message) {
    if (_currentConnectionState.status != ConnectionStatus.disconnected) {
      _logger.warning('当前状态不是断开连接，无法处理连接请求');
      return;
    }

    final remoteDeviceName = message.data['deviceName'] as String;
    final remoteIpAddress = message.data['deviceIp'] as String;
    final pairingCode = message.data['pairingCode'] as String;

    _connectedDevice = DeviceInfoModel(
      deviceName: remoteDeviceName,
      ipAddress: remoteIpAddress,
    );

    _updateConnectionState(
      _currentConnectionState.copyWith(
        status: ConnectionStatus.awaitingConfirmation,
        remoteDeviceName: remoteDeviceName,
        remoteIpAddress: remoteIpAddress,
        pairingCode: pairingCode,
        isInitiator: false,
      ),
    );

    _connectionRequestController.add({
      'deviceName': remoteDeviceName,
      'deviceIp': remoteIpAddress,
      'pairingCode': pairingCode,
    });
  }

  /// 处理连接响应
  void _handleConnectionResponse(SocketMessageModel message) {
    if (_currentConnectionState.status !=
        ConnectionStatus.awaitingConfirmation) {
      _logger.warning('当前状态不是等待确认，无法处理连接响应');
      return;
    }

    final accepted = message.data['accepted'] as bool;
    if (accepted) {
      _updateConnectionState(
        _currentConnectionState.copyWith(
          status: ConnectionStatus.connected,
        ),
      );
    } else {
      _updateConnectionState(
        _currentConnectionState.copyWith(
          status: ConnectionStatus.failed,
        ),
      );
    }
  }

  /// 处理断开连接
  void _handleDisconnect(SocketMessageModel message) {
    _connectedDevice = null;
    _updateConnectionState(
      _currentConnectionState.copyWith(
        status: ConnectionStatus.disconnected,
      ),
    );
  }

  @override
  Stream<ConnectionModel> get connectionStateStream =>
      _connectionStateController.stream;

  @override
  Stream<Map<String, dynamic>> get connectionRequestStream =>
      _connectionRequestController.stream;

  /// 释放资源
  @override
  Future<void> dispose() async {
    await _messageSubscription?.cancel();
    await _connectionStatusSubscription?.cancel();
    await _connectionStateController.close();
    await _connectionRequestController.close();
    _connectionTimer?.cancel();
    _pairingTimer?.cancel();
  }
}
