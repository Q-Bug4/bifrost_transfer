import 'dart:async';
import '../models/connection_model.dart';
import '../models/device_info_model.dart';

/// 连接服务接口，定义连接相关的方法
abstract class ConnectionService {
  /// 获取本地设备信息
  Future<DeviceInfoModel> getLocalDeviceInfo();
  
  /// 发起连接请求
  /// 
  /// [targetIp] 目标设备IP地址
  /// 返回生成的配对码
  Future<String> initiateConnection(String targetIp);
  
  /// 接受连接请求
  /// 
  /// [initiatorIp] 发起方IP地址
  /// [pairingCode] 配对码
  Future<bool> acceptConnection(String initiatorIp, String pairingCode);
  
  /// 拒绝连接请求
  /// 
  /// [initiatorIp] 发起方IP地址
  Future<void> rejectConnection(String initiatorIp);
  
  /// 断开当前连接
  Future<void> disconnect();
  
  /// 取消连接请求
  Future<void> cancelConnection();
  
  /// 连接状态流，用于监听连接状态变化
  Stream<ConnectionModel> get connectionStateStream;
  
  /// 连接请求流，用于监听接收到的连接请求
  Stream<Map<String, dynamic>> get connectionRequestStream;
  
  /// 模拟接收连接请求（仅用于测试）
  /// 
  /// [deviceIp] 模拟设备的IP地址
  /// [deviceName] 模拟设备的名称
  /// [pairingCode] 模拟的配对码
  Future<void> simulateIncomingConnectionRequest(
    String deviceIp,
    String deviceName,
    String pairingCode,
  );
} 