/// 连接模型类，用于表示设备连接状态和信息
class ConnectionModel {
  /// 连接状态
  final ConnectionStatus status;

  /// 远程设备名称
  final String? remoteDeviceName;

  /// 远程设备IP地址
  final String? remoteIpAddress;

  /// 配对码
  final String? pairingCode;

  /// 失败原因
  final String? failureReason;

  /// 是否为发起方
  final bool isInitiator;

  /// 构造函数
  const ConnectionModel({
    required this.status,
    this.remoteDeviceName,
    this.remoteIpAddress,
    this.pairingCode,
    this.failureReason,
    this.isInitiator = false,
  });

  /// 创建副本
  ConnectionModel copyWith({
    ConnectionStatus? status,
    String? remoteDeviceName,
    String? remoteIpAddress,
    String? pairingCode,
    String? failureReason,
    bool? isInitiator,
  }) {
    return ConnectionModel(
      status: status ?? this.status,
      remoteDeviceName: remoteDeviceName ?? this.remoteDeviceName,
      remoteIpAddress: remoteIpAddress ?? this.remoteIpAddress,
      pairingCode: pairingCode ?? this.pairingCode,
      failureReason: failureReason ?? this.failureReason,
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
