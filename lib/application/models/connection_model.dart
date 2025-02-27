/// 连接模型类，用于表示设备连接状态和信息
class ConnectionModel {
  /// 连接状态枚举
  final ConnectionStatus status;
  
  /// 远程设备名称
  final String? remoteDeviceName;
  
  /// 远程设备IP地址
  final String? remoteIpAddress;
  
  /// 配对码，用于连接确认
  final String? pairingCode;
  
  /// 是否为发起方
  final bool isInitiator;

  /// 构造函数
  ConnectionModel({
    this.status = ConnectionStatus.disconnected,
    this.remoteDeviceName,
    this.remoteIpAddress,
    this.pairingCode,
    this.isInitiator = false,
  });

  /// 创建一个新的连接模型实例，用于状态更新
  ConnectionModel copyWith({
    ConnectionStatus? status,
    String? remoteDeviceName,
    String? remoteIpAddress,
    String? pairingCode,
    bool? isInitiator,
  }) {
    return ConnectionModel(
      status: status ?? this.status,
      remoteDeviceName: remoteDeviceName ?? this.remoteDeviceName,
      remoteIpAddress: remoteIpAddress ?? this.remoteIpAddress,
      pairingCode: pairingCode ?? this.pairingCode,
      isInitiator: isInitiator ?? this.isInitiator,
    );
  }
}

/// 连接状态枚举
enum ConnectionStatus {
  /// 未连接
  disconnected,
  
  /// 连接中
  connecting,
  
  /// 等待确认
  awaitingConfirmation,
  
  /// 已连接
  connected,
  
  /// 连接失败
  failed,
} 