import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../models/connection_model.dart';
import '../models/device_info_model.dart';
import 'connection_service.dart';

/// 连接服务实现类
class ConnectionServiceImpl implements ConnectionService {
  /// 日志记录器
  final _logger = Logger('ConnectionServiceImpl');
  
  /// 连接状态控制器
  final _connectionStateController = StreamController<ConnectionModel>.broadcast();
  
  /// 连接请求控制器
  final _connectionRequestController = StreamController<Map<String, dynamic>>.broadcast();
  
  /// 当前连接状态
  ConnectionModel _currentConnectionState = ConnectionModel();
  
  /// 本地设备信息
  DeviceInfoModel? _localDeviceInfo;
  
  /// 随机数生成器，用于生成配对码
  final _random = Random();
  
  /// 连接超时计时器
  Timer? _connectionTimer;
  
  /// 配对确认超时计时器
  Timer? _pairingTimer;

  @override
  Future<DeviceInfoModel> getLocalDeviceInfo() async {
    // 如果已经获取过本地设备信息，直接返回
    if (_localDeviceInfo != null) {
      return _localDeviceInfo!;
    }
    
    // 模拟获取本地设备信息
    // 在实际应用中，这里应该调用平台特定的API获取设备名称和IP地址
    _localDeviceInfo = DeviceInfoModel(
      deviceName: '开发者工作站', // 实际应用中应该获取真实设备名称
      ipAddress: '192.168.1.100', // 实际应用中应该获取真实IP地址
    );
    
    return _localDeviceInfo!;
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
      
      // 设置连接请求超时（10秒）
      _connectionTimer = Timer(const Duration(seconds: 10), () {
        if (_currentConnectionState.status == ConnectionStatus.connecting) {
          _updateConnectionState(
            _currentConnectionState.copyWith(
              status: ConnectionStatus.failed,
            ),
          );
          _logger.warning('连接请求超时');
        }
      });
      
      // 模拟网络请求，检查设备是否可达
      // 在实际应用中，这里应该发送真实的网络请求
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
      
      // 设备可达，生成6位数字配对码
      final pairingCode = _generatePairingCode();
      
      // 更新连接状态，包含配对码
      _updateConnectionState(
        _currentConnectionState.copyWith(
          status: ConnectionStatus.awaitingConfirmation,
          pairingCode: pairingCode,
        ),
      );
      
      // 设置配对确认超时（30秒）
      _pairingTimer = Timer(const Duration(seconds: 30), () {
        if (_currentConnectionState.status == ConnectionStatus.awaitingConfirmation) {
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
  /// 在实际应用中，这里应该发送ping请求或尝试建立TCP连接
  Future<bool> _checkDeviceReachable(String ip) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(seconds: 2));
    
    // 模拟设备可达性检查
    // 在实际应用中，这里应该根据实际网络请求结果返回
    // 这里简单地假设所有IP地址都是可达的
    return true;
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
      
      // 模拟网络请求，发送接受连接的响应
      // 在实际应用中，这里应该发送真实的网络请求
      await Future.delayed(const Duration(seconds: 1));
      
      // 模拟连接成功
      _updateConnectionState(
        _currentConnectionState.copyWith(
          status: ConnectionStatus.connected,
          remoteDeviceName: '远程设备', // 实际应用中应该获取真实设备名称
        ),
      );
      
      _logger.info('接受来自 $initiatorIp 的连接请求');
      
      return true;
    } catch (e) {
      // 连接失败，更新状态
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
  Future<void> rejectConnection(String initiatorIp) async {
    try {
      // 模拟网络请求，发送拒绝连接的响应
      // 在实际应用中，这里应该发送真实的网络请求
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 更新连接状态为未连接
      _updateConnectionState(
        ConnectionModel(),
      );
      
      _logger.info('拒绝来自 $initiatorIp 的连接请求');
    } catch (e) {
      _logger.severe('拒绝连接失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      // 如果当前没有连接，直接返回
      if (_currentConnectionState.status != ConnectionStatus.connected) {
        return;
      }
      
      // 模拟网络请求，发送断开连接的请求
      // 在实际应用中，这里应该发送真实的网络请求
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 更新连接状态为未连接
      _updateConnectionState(
        ConnectionModel(),
      );
      
      _logger.info('断开连接');
    } catch (e) {
      _logger.severe('断开连接失败: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> cancelConnection() async {
    try {
      // 只有在连接中或等待确认状态才能取消
      if (_currentConnectionState.status != ConnectionStatus.connecting && 
          _currentConnectionState.status != ConnectionStatus.awaitingConfirmation) {
        return;
      }
      
      // 取消超时计时器
      _connectionTimer?.cancel();
      _pairingTimer?.cancel();
      
      // 模拟网络请求，发送取消连接的请求
      // 在实际应用中，这里应该发送真实的网络请求
      await Future.delayed(const Duration(milliseconds: 300));
      
      // 更新连接状态为未连接
      _updateConnectionState(
        ConnectionModel(),
      );
      
      _logger.info('取消连接请求');
    } catch (e) {
      _logger.severe('取消连接失败: $e');
      rethrow;
    }
  }

  @override
  Stream<ConnectionModel> get connectionStateStream => _connectionStateController.stream;

  @override
  Stream<Map<String, dynamic>> get connectionRequestStream => _connectionRequestController.stream;

  /// 更新连接状态
  void _updateConnectionState(ConnectionModel newState) {
    _currentConnectionState = newState;
    _connectionStateController.add(newState);
  }

  /// 生成6位数字配对码
  String _generatePairingCode() {
    return (_random.nextInt(900000) + 100000).toString();
  }
  
  /// 模拟接收连接请求，用于测试
  /// 
  /// 在实际应用中，这个方法应该由网络监听器调用
  void simulateIncomingConnectionRequest(String initiatorIp, String initiatorName, String pairingCode) {
    _connectionRequestController.add({
      'initiatorIp': initiatorIp,
      'initiatorName': initiatorName,
      'pairingCode': pairingCode,
    });
    
    _logger.info('收到来自 $initiatorIp ($initiatorName) 的连接请求，配对码: $pairingCode');
  }
  
  @override
  void dispose() {
    _connectionTimer?.cancel();
    _pairingTimer?.cancel();
    _connectionStateController.close();
    _connectionRequestController.close();
  }
} 