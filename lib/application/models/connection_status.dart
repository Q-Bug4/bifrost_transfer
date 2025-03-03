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

  /// 已取消
  cancelled,
}
