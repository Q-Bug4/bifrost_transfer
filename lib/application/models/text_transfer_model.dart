/// 文本传输状态枚举
enum TextTransferStatus {
  /// 等待中
  waiting,

  /// 传输中
  transferring,

  /// 已完成
  completed,

  /// 失败
  failed,

  /// 已取消
  cancelled,
}

/// 文本传输方向枚举
enum TextTransferDirection {
  /// 发送
  sending,

  /// 接收
  receiving,
}

/// 文本传输模型类
class TextTransferModel {
  /// 传输ID
  final String transferId;

  /// 文本内容
  final String text;

  /// 文本长度
  final int textLength;

  /// 行数
  final int lineCount;

  /// 已处理长度
  final int processedLength;

  /// 传输状态
  final TextTransferStatus status;

  /// 传输方向
  final TextTransferDirection direction;

  /// 错误信息
  final String? errorMessage;

  /// 开始时间
  final DateTime startTime;

  /// 结束时间
  final DateTime? endTime;

  /// 构造函数
  TextTransferModel({
    required this.transferId,
    required this.text,
    required this.textLength,
    required this.lineCount,
    this.processedLength = 0,
    this.status = TextTransferStatus.waiting,
    required this.direction,
    this.errorMessage,
    DateTime? startTime,
    this.endTime,
  }) : startTime = startTime ?? DateTime.now();

  /// 创建副本
  TextTransferModel copyWith({
    String? transferId,
    String? text,
    int? textLength,
    int? lineCount,
    int? processedLength,
    TextTransferStatus? status,
    TextTransferDirection? direction,
    String? errorMessage,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return TextTransferModel(
      transferId: transferId ?? this.transferId,
      text: text ?? this.text,
      textLength: textLength ?? this.textLength,
      lineCount: lineCount ?? this.lineCount,
      processedLength: processedLength ?? this.processedLength,
      status: status ?? this.status,
      direction: direction ?? this.direction,
      errorMessage: errorMessage ?? this.errorMessage,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  /// 计算传输进度（0-100）
  double get progress {
    if (textLength == 0) return 0;
    return (processedLength / textLength * 100).clamp(0, 100);
  }

  /// 是否完成
  bool get isCompleted => status == TextTransferStatus.completed;

  /// 是否失败
  bool get isFailed => status == TextTransferStatus.failed;

  /// 是否取消
  bool get isCancelled => status == TextTransferStatus.cancelled;

  /// 是否正在传输
  bool get isTransferring => status == TextTransferStatus.transferring;

  /// 是否等待中
  bool get isWaiting => status == TextTransferStatus.waiting;

  /// 是否发送
  bool get isSending => direction == TextTransferDirection.sending;

  /// 是否接收
  bool get isReceiving => direction == TextTransferDirection.receiving;
}
