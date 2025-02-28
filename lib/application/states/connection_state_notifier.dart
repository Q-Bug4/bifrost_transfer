import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../models/connection_model.dart';
import '../models/device_info_model.dart';
import '../services/connection_service.dart';

/// 连接状态管理类，使用ChangeNotifier进行状态管理
class ConnectionStateNotifier extends ChangeNotifier {
  /// 日志记录器
  final _logger = Logger('ConnectionStateNotifier');
  
  /// 连接服务
  final ConnectionService _connectionService;
  
  /// 本地设备信息
  DeviceInfoModel? _localDeviceInfo;
  
  /// 当前连接状态
  ConnectionModel _connectionState = ConnectionModel();
  
  /// 连接请求信息
  Map<String, dynamic>? _pendingConnectionRequest;
  
  /// 连接状态流订阅
  StreamSubscription<ConnectionModel>? _connectionStateSubscription;
  
  /// 连接请求流订阅
  StreamSubscription<Map<String, dynamic>>? _connectionRequestSubscription;

  /// 构造函数
  ConnectionStateNotifier(this._connectionService) {
    _init();
  }

  /// 获取本地设备信息
  DeviceInfoModel? get localDeviceInfo => _localDeviceInfo;
  
  /// 获取当前连接状态
  ConnectionModel get connectionState => _connectionState;
  
  /// 获取待处理的连接请求
  Map<String, dynamic>? get pendingConnectionRequest => _pendingConnectionRequest;
  
  /// 初始化
  Future<void> _init() async {
    try {
      // 获取本地设备信息
      _localDeviceInfo = await _connectionService.getLocalDeviceInfo();
      
      // 订阅连接状态流
      _connectionStateSubscription = _connectionService.connectionStateStream.listen(_handleConnectionStateChange);
      
      // 订阅连接请求流
      _connectionRequestSubscription = _connectionService.connectionRequestStream.listen(_handleConnectionRequest);
      
      notifyListeners();
    } catch (e) {
      _logger.severe('初始化失败: $e');
    }
  }

  /// 处理连接状态变化
  void _handleConnectionStateChange(ConnectionModel state) {
    _connectionState = state;
    
    // 如果连接成功或失败，清除待处理的连接请求
    if (state.status == ConnectionStatus.connected || state.status == ConnectionStatus.failed) {
      _pendingConnectionRequest = null;
    }
    
    notifyListeners();
  }

  /// 处理连接请求
  void _handleConnectionRequest(Map<String, dynamic> request) {
    _logger.info('收到连接请求: $request');
    _pendingConnectionRequest = request;
    _logger.info('设置待处理连接请求: $_pendingConnectionRequest');
    notifyListeners();
    _logger.info('通知监听器更新');
  }

  /// 发起连接
  Future<void> initiateConnection(String targetIp) async {
    try {
      await _connectionService.initiateConnection(targetIp);
    } catch (e) {
      _logger.severe('发起连接失败: $e');
      rethrow;
    }
  }

  /// 接受连接请求
  Future<void> acceptConnectionRequest() async {
    if (_pendingConnectionRequest == null) {
      _logger.warning('没有待处理的连接请求');
      return;
    }
    
    final initiatorIp = _pendingConnectionRequest!['deviceIp'] as String;
    final pairingCode = _pendingConnectionRequest!['pairingCode'] as String;
    
    try {
      final success = await _connectionService.acceptConnection(initiatorIp, pairingCode);
      
      if (!success) {
        _logger.warning('接受连接请求失败');
      }
    } catch (e) {
      _logger.severe('接受连接请求失败: $e');
      rethrow;
    }
  }

  /// 拒绝连接请求
  Future<void> rejectConnectionRequest() async {
    if (_pendingConnectionRequest == null) {
      _logger.warning('没有待处理的连接请求');
      return;
    }
    
    final initiatorIp = _pendingConnectionRequest!['deviceIp'] as String;
    
    try {
      await _connectionService.rejectConnection(initiatorIp);
      _pendingConnectionRequest = null;
      notifyListeners();
    } catch (e) {
      _logger.severe('拒绝连接请求失败: $e');
      rethrow;
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    try {
      await _connectionService.disconnect();
    } catch (e) {
      _logger.severe('断开连接失败: $e');
      rethrow;
    }
  }

  /// 取消连接请求
  Future<void> cancelConnection() async {
    try {
      await _connectionService.cancelConnection();
    } catch (e) {
      _logger.severe('取消连接请求失败: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _connectionStateSubscription?.cancel();
    _connectionRequestSubscription?.cancel();
    super.dispose();
  }
} 