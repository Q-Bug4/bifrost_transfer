import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../models/connection_model.dart';
import '../models/device_info_model.dart';
import '../services/connection_service.dart';
import '../services/device_info_service.dart';

/// 连接状态管理类，使用ChangeNotifier进行状态管理
class ConnectionStateNotifier extends ChangeNotifier {
  /// 日志记录器
  final _logger = Logger('ConnectionStateNotifier');

  /// 连接服务
  final ConnectionService _connectionService;

  /// 设备信息服务
  final DeviceInfoService _deviceInfoService;

  /// 本地设备信息
  DeviceInfoModel? _localDeviceInfo;

  /// 当前连接状态
  ConnectionModel _connectionState =
      ConnectionModel(status: ConnectionStatus.disconnected);

  /// 连接请求信息
  Map<String, dynamic>? _pendingConnectionRequest;

  /// 连接状态流订阅
  StreamSubscription<ConnectionModel>? _connectionStateSubscription;

  /// 连接请求流订阅
  StreamSubscription<Map<String, dynamic>>? _connectionRequestSubscription;

  /// 构造函数
  ConnectionStateNotifier({
    required ConnectionService connectionService,
    required DeviceInfoService deviceInfoService,
  })  : _connectionService = connectionService,
        _deviceInfoService = deviceInfoService {
    _init();
  }

  /// 获取本地设备信息
  DeviceInfoModel? get localDeviceInfo => _localDeviceInfo;

  /// 获取当前连接状态
  ConnectionModel get connectionState => _connectionState;

  /// 获取待处理的连接请求
  Map<String, dynamic>? get pendingConnectionRequest =>
      _pendingConnectionRequest;

  /// 初始化
  Future<void> _init() async {
    try {
      // 获取本地设备信息
      _localDeviceInfo = await _deviceInfoService.getDeviceInfo();

      // 订阅连接状态变化
      _connectionStateSubscription = _connectionService.connectionStateStream
          .listen(_handleConnectionStateChange);

      // 订阅连接请求
      _connectionRequestSubscription = _connectionService
          .connectionRequestStream
          .listen(_handleConnectionRequest);

      notifyListeners();
    } catch (e) {
      _logger.severe('初始化失败: $e');
    }
  }

  /// 处理连接状态变化
  void _handleConnectionStateChange(ConnectionModel newState) {
    _connectionState = newState;

    // 如果连接成功，清除待处理的连接请求
    if (newState.status == ConnectionStatus.connected) {
      _pendingConnectionRequest = null;
    }

    notifyListeners();
  }

  /// 处理连接请求
  void _handleConnectionRequest(Map<String, dynamic> request) {
    _pendingConnectionRequest = request;
    notifyListeners();
  }

  /// 更新连接状态
  void updateConnectionState(ConnectionModel newState) {
    _connectionState = newState;
    notifyListeners();
  }

  /// 发起连接
  Future<void> initiateConnection(String targetIp) async {
    try {
      // 更新状态为连接中
      _connectionState = ConnectionModel(
        status: ConnectionStatus.connecting,
        remoteIpAddress: targetIp,
        isInitiator: true,
      );
      notifyListeners();

      // 发起连接请求
      await _connectionService.initiateConnection(targetIp);
    } catch (e) {
      // 连接失败
      _connectionState = ConnectionModel(
        status: ConnectionStatus.failed,
        failureReason: e.toString(),
      );
      notifyListeners();
      rethrow;
    }
  }

  /// 接受连接请求
  Future<void> acceptConnectionRequest() async {
    if (_pendingConnectionRequest == null) {
      return;
    }

    final initiatorIp = _pendingConnectionRequest!['deviceIp'] as String;
    final pairingCode = _pendingConnectionRequest!['pairingCode'] as String;

    try {
      // 更新状态为连接中
      _connectionState = ConnectionModel(
        status: ConnectionStatus.connecting,
        remoteIpAddress: initiatorIp,
        isInitiator: false,
      );

      // 清除待处理的连接请求
      _pendingConnectionRequest = null;
      notifyListeners();

      // 接受连接请求
      await _connectionService.acceptConnection(initiatorIp, pairingCode);
    } catch (e) {
      // 连接失败
      _connectionState = ConnectionModel(
        status: ConnectionStatus.failed,
        failureReason: e.toString(),
      );
      notifyListeners();
      rethrow;
    }
  }

  /// 拒绝连接请求
  Future<void> rejectConnectionRequest() async {
    if (_pendingConnectionRequest == null) {
      return;
    }

    final initiatorIp = _pendingConnectionRequest!['deviceIp'] as String;

    try {
      // 清除待处理的连接请求
      _pendingConnectionRequest = null;
      notifyListeners();

      // 拒绝连接请求
      await _connectionService.rejectConnection(initiatorIp);
    } catch (e) {
      _logger.severe('拒绝连接请求失败: $e');
      rethrow;
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    try {
      await _connectionService.disconnect();

      // 更新状态为断开连接
      _connectionState = ConnectionModel(status: ConnectionStatus.disconnected);
      notifyListeners();
    } catch (e) {
      _logger.severe('断开连接失败: $e');
      rethrow;
    }
  }

  /// 取消连接请求
  Future<void> cancelConnection() async {
    try {
      await _connectionService.cancelConnection();

      // 更新状态为断开连接
      _connectionState = ConnectionModel(status: ConnectionStatus.disconnected);
      notifyListeners();
    } catch (e) {
      _logger.severe('取消连接请求失败: $e');
      rethrow;
    }
  }

  /// 连接成功回调
  void onConnectionEstablished({
    required String remoteDeviceName,
    required String remoteIpAddress,
  }) {
    _connectionState = ConnectionModel(
      status: ConnectionStatus.connected,
      remoteDeviceName: remoteDeviceName,
      remoteIpAddress: remoteIpAddress,
      isInitiator: _connectionState.isInitiator,
    );
    notifyListeners();
  }

  /// 连接失败回调
  void onConnectionFailed({
    required String reason,
  }) {
    _connectionState = ConnectionModel(
      status: ConnectionStatus.failed,
      failureReason: reason,
    );
    notifyListeners();
  }

  /// 接收连接请求回调
  void onConnectionRequested({
    required String initiatorName,
    required String initiatorIp,
    required String pairingCode,
  }) {
    _pendingConnectionRequest = {
      'deviceName': initiatorName,
      'deviceIp': initiatorIp,
      'pairingCode': pairingCode,
    };
    notifyListeners();
  }

  @override
  void dispose() {
    _connectionStateSubscription?.cancel();
    _connectionRequestSubscription?.cancel();
    super.dispose();
  }
}
