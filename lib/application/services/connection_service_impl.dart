import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:logging/logging.dart';
import '../models/connection_model.dart';
import '../models/device_info_model.dart';
import '../models/socket_message_model.dart';
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
  DeviceInfoModel? _localDeviceInfo;

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
  StreamSubscription<bool>? _connectionStatusSubscription;

  /// 构造函数
  ConnectionServiceImpl(this._socketService) {
    // 订阅Socket消息
    _messageSubscription = _socketService.messageStream.listen(_handleMessage);

    // 订阅Socket连接状态
    _connectionStatusSubscription = _socketService.connectionStatusStream
        .listen(_handleSocketConnectionStatus);

    // 启动Socket服务器
    _startSocketServer();
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
    // 如果已经获取过本地设备信息，直接返回
    if (_localDeviceInfo != null) {
      return _localDeviceInfo!;
    }

    try {
      // 使用NetworkUtils获取真实的设备名称和IP地址
      final deviceName = await NetworkUtils.getDeviceName();
      final ipAddress = await NetworkUtils.getLocalIpAddress();

      _localDeviceInfo = DeviceInfoModel(
        deviceName: deviceName,
        ipAddress: ipAddress,
      );

      _logger.info('获取本地设备信息: 设备名称=$deviceName, IP地址=$ipAddress');
      return _localDeviceInfo!;
    } catch (e) {
      _logger.severe('获取本地设备信息失败: $e');

      // 获取失败时使用默认值
      _localDeviceInfo = DeviceInfoModel(
        deviceName: '未知设备',
        ipAddress: '127.0.0.1',
      );

      return _localDeviceInfo!;
    }
  }

  @override
  Future<String> initiateConnection(String targetIp) async {
    try {
      // 更新连接状态为连接中
      _updateConnectionState(
        _currentConnectionState.copyWith(
          status: ConnectionStatus.connecting,
          remoteIpAddress: targetIp,
          isInitiator: true,
        ),
      );

      // 设置连接请求超时
      _connectionTimer = Timer(
          Duration(
              milliseconds: NetworkConstants.CONNECTION_REQUEST_TIMEOUT_MS),
          () {
        if (_currentConnectionState.status == ConnectionStatus.connecting) {
          _updateConnectionState(
            _currentConnectionState.copyWith(
              status: ConnectionStatus.failed,
            ),
          );
          _logger.warning('连接请求超时');
        }
      });

      // 检查设备是否可达
      bool isReachable = await _checkDeviceReachable(targetIp);

      // 取消连接超时计时器
      _connectionTimer?.cancel();

      if (!isReachable) {
        // 设备不可达，更新状态为失败
        _updateConnectionState(
          _currentConnectionState.copyWith(
            status: ConnectionStatus.failed,
          ),
        );
        throw Exception('无法连接到目标设备，请检查IP地址是否正确');
      }

      // 获取本地设备信息
      final localDeviceInfo = await getLocalDeviceInfo();

      // 设备可达，生成6位数字配对码
      final pairingCode = _generatePairingCode();

      // 更新连接状态，包含配对码
      _updateConnectionState(
        _currentConnectionState.copyWith(
          status: ConnectionStatus.awaitingConfirmation,
          pairingCode: pairingCode,
        ),
      );

      // 连接到远程设备
      bool connected = await _socketService.connectToDevice(targetIp);

      if (!connected) {
        _updateConnectionState(
          _currentConnectionState.copyWith(
            status: ConnectionStatus.failed,
          ),
        );
        throw Exception('连接到目标设备失败');
      }

      // 发送连接请求消息
      final connectionRequestMessage =
          SocketMessageModel.createConnectionRequest(
        deviceName: localDeviceInfo.deviceName,
        deviceIp: localDeviceInfo.ipAddress,
        pairingCode: pairingCode,
      );

      bool sent = await _socketService.sendMessage(connectionRequestMessage);

      if (!sent) {
        await _socketService.disconnectFromDevice();
        _updateConnectionState(
          _currentConnectionState.copyWith(
            status: ConnectionStatus.failed,
          ),
        );
        throw Exception('发送连接请求失败');
      }

      // 设置配对确认超时
      _pairingTimer = Timer(
          Duration(
              milliseconds: NetworkConstants.PAIRING_CONFIRMATION_TIMEOUT_MS),
          () {
        if (_currentConnectionState.status ==
            ConnectionStatus.awaitingConfirmation) {
          _socketService.disconnectFromDevice();
          _updateConnectionState(
            _currentConnectionState.copyWith(
              status: ConnectionStatus.failed,
            ),
          );
          _logger.warning('配对确认超时');
        }
      });

      _logger.info('发起连接请求到 $targetIp，配对码: $pairingCode');

      return pairingCode;
    } catch (e) {
      // 连接失败，更新状态
      _updateConnectionState(
        _currentConnectionState.copyWith(
          status: ConnectionStatus.failed,
        ),
      );

      _logger.severe('发起连接失败: $e');
      rethrow;
    }
  }

  /// 检查设备是否可达
  ///
  /// 尝试建立TCP连接到目标设备的指定端口，检查设备是否可达
  Future<bool> _checkDeviceReachable(String ip) async {
    _logger.info('检查设备可达性: $ip');

    try {
      // 尝试连接到目标设备的指定端口
      final socket = await Socket.connect(ip, NetworkConstants.LISTEN_PORT,
          timeout: const Duration(seconds: 3));

      // 连接成功，关闭socket
      await socket.close();
      _logger.info('设备可达: $ip:${NetworkConstants.LISTEN_PORT}');
      return true;
    } catch (e) {
      _logger.warning('设备不可达: $ip, 错误: $e');
      return false;
    }
  }

  @override
  Future<bool> acceptConnection(String initiatorIp, String pairingCode) async {
    try {
      // 更新连接状态为连接中
      _updateConnectionState(
        _currentConnectionState.copyWith(
          status: ConnectionStatus.connecting,
          remoteIpAddress: initiatorIp,
          isInitiator: false,
        ),
      );

      // 获取本地设备信息
      final localDeviceInfo = await getLocalDeviceInfo();

      // 发送接受连接响应
      final connectionResponseMessage =
          SocketMessageModel.createConnectionResponse(
        accepted: true,
        deviceName: localDeviceInfo.deviceName,
        deviceIp: localDeviceInfo.ipAddress,
      );

      bool sent = await _socketService.sendMessage(connectionResponseMessage);

      if (!sent) {
        _updateConnectionState(
          _currentConnectionState.copyWith(
            status: ConnectionStatus.failed,
          ),
        );
        throw Exception('发送接受连接响应失败');
      }

      // 更新连接状态为已连接
      _updateConnectionState(
        _currentConnectionState.copyWith(
          status: ConnectionStatus.connected,
        ),
      );

      _logger.info('接受来自 $initiatorIp 的连接请求');

      return true;
    } catch (e) {
      _updateConnectionState(
        _currentConnectionState.copyWith(
          status: ConnectionStatus.failed,
        ),
      );

      _logger.severe('接受连接失败: $e');
      return false;
    }
  }

  @override
  Future<bool> rejectConnection(String initiatorIp, [String? reason]) async {
    try {
      // 获取本地设备信息
      final localDeviceInfo = await getLocalDeviceInfo();

      // 发送拒绝连接响应
      final connectionResponseMessage =
          SocketMessageModel.createConnectionResponse(
        accepted: false,
        deviceName: localDeviceInfo.deviceName,
        deviceIp: localDeviceInfo.ipAddress,
        rejectReason: reason,
      );

      await _socketService.sendMessage(connectionResponseMessage);

      // 断开连接
      await _socketService.disconnectFromDevice();

      // 更新连接状态为已拒绝
      _updateConnectionState(
        _currentConnectionState.copyWith(
          status: ConnectionStatus.disconnected,
        ),
      );

      _logger.info(
          '拒绝来自 $initiatorIp 的连接请求${reason != null ? '，原因: $reason' : ''}');

      return true;
    } catch (e) {
      _logger.severe('拒绝连接失败: $e');
      return false;
    }
  }

  @override
  Future<bool> disconnect() async {
    try {
      // 发送断开连接消息
      final disconnectMessage = SocketMessageModel.createDisconnect(
        reason: '用户主动断开连接',
      );

      await _socketService.sendMessage(disconnectMessage);

      // 断开Socket连接
      await _socketService.disconnectFromDevice();

      // 更新连接状态为已断开
      _updateConnectionState(
        _currentConnectionState.copyWith(
          status: ConnectionStatus.disconnected,
        ),
      );

      _logger.info('断开连接');

      return true;
    } catch (e) {
      _logger.severe('断开连接失败: $e');
      return false;
    }
  }

  @override
  Future<bool> cancelConnection() async {
    try {
      // 断开Socket连接
      await _socketService.disconnectFromDevice();

      // 取消计时器
      _connectionTimer?.cancel();
      _pairingTimer?.cancel();

      // 更新连接状态为已断开
      _updateConnectionState(
        _currentConnectionState.copyWith(
          status: ConnectionStatus.disconnected,
        ),
      );

      _logger.info('取消连接');

      return true;
    } catch (e) {
      _logger.severe('取消连接失败: $e');
      return false;
    }
  }

  /// 处理Socket消息
  void _handleMessage(SocketMessageModel message) {
    _logger.info('收到Socket消息: ${message.type}');

    switch (message.type) {
      case SocketMessageType.CONNECTION_REQUEST:
        _handleConnectionRequest(message);
        break;
      case SocketMessageType.CONNECTION_RESPONSE:
        _handleConnectionResponse(message);
        break;
      case SocketMessageType.PAIRING_CONFIRMATION:
        _handlePairingConfirmation(message);
        break;
      case SocketMessageType.DISCONNECT:
        _handleDisconnect(message);
        break;
      case SocketMessageType.TEXT_TRANSFER_REQUEST:
      case SocketMessageType.TEXT_TRANSFER_RESPONSE:
      case SocketMessageType.TEXT_TRANSFER_PROGRESS:
      case SocketMessageType.TEXT_TRANSFER_COMPLETE:
      case SocketMessageType.TEXT_TRANSFER_CANCEL:
      case SocketMessageType.TEXT_TRANSFER_ERROR:
      case SocketMessageType.FILE_TRANSFER_REQUEST:
      case SocketMessageType.FILE_TRANSFER_RESPONSE:
      case SocketMessageType.FILE_TRANSFER_PROGRESS:
      case SocketMessageType.FILE_TRANSFER_COMPLETE:
      case SocketMessageType.FILE_TRANSFER_CANCEL:
      case SocketMessageType.FILE_TRANSFER_ERROR:
        // 忽略文件和文本传输相关的消息，这些消息由其他服务处理
        break;
      default:
        _logger.warning('未处理的消息类型: ${message.type}');
    }
  }

  /// 处理连接请求消息
  void _handleConnectionRequest(SocketMessageModel message) {
    try {
      // 如果当前已经连接，拒绝新的连接请求
      if (_currentConnectionState.status == ConnectionStatus.connected) {
        _logger.warning('已有连接，拒绝新的连接请求');

        // 发送拒绝连接响应
        _rejectConnection(message.data['deviceIp'], '已有连接');
        return;
      }

      // 解析连接请求数据
      final deviceName = message.data['deviceName'] as String;
      final deviceIp = message.data['deviceIp'] as String;
      final pairingCode = message.data['pairingCode'] as String;

      // 更新连接状态为等待确认
      _updateConnectionState(
        _currentConnectionState.copyWith(
          status: ConnectionStatus.awaitingConfirmation,
          remoteDeviceName: deviceName,
          remoteIpAddress: deviceIp,
          pairingCode: pairingCode,
          isInitiator: false,
        ),
      );

      // 触发连接请求事件
      _connectionRequestController.add({
        'deviceName': deviceName,
        'deviceIp': deviceIp,
        'pairingCode': pairingCode,
      });

      _logger.info('收到来自 $deviceName ($deviceIp) 的连接请求，配对码: $pairingCode');
    } catch (e) {
      _logger.severe('处理连接请求失败: $e');
    }
  }

  /// 处理连接响应消息
  void _handleConnectionResponse(SocketMessageModel message) {
    try {
      // 取消配对确认超时计时器
      _pairingTimer?.cancel();

      // 解析连接响应数据
      final accepted = message.data['accepted'] as bool;
      final deviceName = message.data['deviceName'] as String;
      final deviceIp = message.data['deviceIp'] as String;

      if (accepted) {
        // 如果接受连接，更新连接状态为已连接
        _updateConnectionState(
          _currentConnectionState.copyWith(
            status: ConnectionStatus.connected,
            remoteDeviceName: deviceName,
            remoteIpAddress: deviceIp,
          ),
        );

        _logger.info('连接请求已被接受，已连接到: $deviceName ($deviceIp)');
      } else {
        // 如果拒绝连接，更新连接状态为已拒绝
        final rejectReason = message.data['rejectReason'] as String?;

        _updateConnectionState(
          _currentConnectionState.copyWith(
            status: ConnectionStatus.failed,
          ),
        );

        _logger.warning('连接请求被拒绝: ${rejectReason ?? '无原因'}');

        // 断开Socket连接
        _socketService.disconnectFromDevice();
      }
    } catch (e) {
      _logger.severe('处理连接响应失败: $e');
    }
  }

  /// 处理配对确认消息
  void _handlePairingConfirmation(SocketMessageModel message) {
    try {
      // 解析配对确认数据
      final confirmed = message.data['confirmed'] as bool;

      if (confirmed) {
        // 如果确认配对，更新连接状态为已连接
        _updateConnectionState(
          _currentConnectionState.copyWith(
            status: ConnectionStatus.connected,
          ),
        );

        _logger.info('配对已确认，连接已建立');
      } else {
        // 如果拒绝配对，更新连接状态为已拒绝
        final rejectReason = message.data['rejectReason'] as String?;

        _updateConnectionState(
          _currentConnectionState.copyWith(
            status: ConnectionStatus.failed,
          ),
        );

        _logger.warning('配对被拒绝: ${rejectReason ?? '无原因'}');

        // 断开Socket连接
        _socketService.disconnectFromDevice();
      }
    } catch (e) {
      _logger.severe('处理配对确认失败: $e');
    }
  }

  /// 处理断开连接消息
  void _handleDisconnect(SocketMessageModel message) {
    try {
      final reason = message.data['reason'] as String?;

      // 更新连接状态为已断开
      _updateConnectionState(
        _currentConnectionState.copyWith(
          status: ConnectionStatus.disconnected,
        ),
      );

      _logger.info('远程设备断开连接${reason != null ? '，原因: $reason' : ''}');
    } catch (e) {
      _logger.severe('处理断开连接消息失败: $e');
    }
  }

  /// 处理Socket连接状态变化
  void _handleSocketConnectionStatus(bool connected) {
    _logger.info('Socket连接状态变化: $connected');

    if (!connected &&
        _currentConnectionState.status == ConnectionStatus.connected) {
      // 如果Socket连接断开，但当前状态是已连接，则更新状态为断开连接
      _updateConnectionState(
        _currentConnectionState.copyWith(
          status: ConnectionStatus.disconnected,
        ),
      );
    }
  }

  /// 拒绝连接请求
  Future<void> _rejectConnection(String deviceIp, String reason) async {
    try {
      // 获取本地设备信息
      final localDeviceInfo = await getLocalDeviceInfo();

      // 发送拒绝连接响应
      final connectionResponseMessage =
          SocketMessageModel.createConnectionResponse(
        accepted: false,
        deviceName: localDeviceInfo.deviceName,
        deviceIp: localDeviceInfo.ipAddress,
        rejectReason: reason,
      );

      await _socketService.sendMessage(connectionResponseMessage);
    } catch (e) {
      _logger.severe('发送拒绝连接响应失败: $e');
    }
  }

  /// 生成随机配对码
  String _generatePairingCode() {
    return List.generate(6, (_) => _random.nextInt(10)).join();
  }

  /// 更新连接状态
  void _updateConnectionState(ConnectionModel newState) {
    _currentConnectionState = newState;
    _connectionStateController.add(newState);
    _logger.info('连接状态更新: ${newState.status}');
  }

  @override
  ConnectionModel getConnectionState() {
    return _currentConnectionState;
  }

  @override
  Stream<ConnectionModel> get connectionStateStream =>
      _connectionStateController.stream;

  @override
  Stream<Map<String, dynamic>> get connectionRequestStream =>
      _connectionRequestController.stream;

  /// 模拟接收连接请求（仅用于测试）
  Future<void> simulateIncomingConnectionRequest(
    String deviceIp,
    String deviceName,
    String pairingCode,
  ) async {
    _logger.info('模拟接收连接请求: 设备=$deviceName, IP=$deviceIp, 配对码=$pairingCode');

    // 更新连接状态为等待确认
    _updateConnectionState(
      _currentConnectionState.copyWith(
        status: ConnectionStatus.awaitingConfirmation,
        remoteDeviceName: deviceName,
        remoteIpAddress: deviceIp,
        pairingCode: pairingCode,
        isInitiator: false,
      ),
    );

    // 触发连接请求事件
    _connectionRequestController.add({
      'deviceName': deviceName,
      'deviceIp': deviceIp,
      'pairingCode': pairingCode,
    });
  }

  @override
  void dispose() {
    // 取消订阅
    _messageSubscription?.cancel();
    _connectionStatusSubscription?.cancel();

    // 取消计时器
    _connectionTimer?.cancel();
    _pairingTimer?.cancel();

    // 关闭控制器
    _connectionStateController.close();
    _connectionRequestController.close();

    _logger.info('连接服务已释放资源');
  }
}
