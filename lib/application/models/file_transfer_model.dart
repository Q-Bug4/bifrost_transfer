/// 文件传输状态枚举
enum FileTransferStatus {
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

/// 文件传输方向枚举
enum FileTransferDirection {
  /// 发送
  sending,

  /// 接收
  receiving,
}

/// 文件传输模型类
class FileTransferModel {
  /// 传输ID
  final String transferId;

  /// 文件名
  final String fileName;

  /// 文件路径
  final String filePath;

  /// 文件大小（字节）
  final int fileSize;

  /// 文件哈希值
  final String fileHash;

  /// 已传输字节数
  final int bytesTransferred;

  /// 传输状态
  final FileTransferStatus status;

  /// 传输方向
  final FileTransferDirection direction;

  /// 错误信息
  final String? errorMessage;

  /// 开始时间
  final DateTime startTime;

  /// 结束时间
  final DateTime? endTime;

  /// 传输速度（字节/秒）
  final double? transferSpeed;

  /// 构造函数
  FileTransferModel({
    required this.transferId,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.fileHash,
    this.bytesTransferred = 0,
    this.status = FileTransferStatus.waiting,
    required this.direction,
    this.errorMessage,
    DateTime? startTime,
    this.endTime,
    this.transferSpeed,
  }) : startTime = startTime ?? DateTime.now();

  /// 创建副本
  FileTransferModel copyWith({
    String? transferId,
    String? fileName,
    String? filePath,
    int? fileSize,
    String? fileHash,
    int? bytesTransferred,
    FileTransferStatus? status,
    FileTransferDirection? direction,
    String? errorMessage,
    DateTime? startTime,
    DateTime? endTime,
    double? transferSpeed,
  }) {
    return FileTransferModel(
      transferId: transferId ?? this.transferId,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      fileHash: fileHash ?? this.fileHash,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      status: status ?? this.status,
      direction: direction ?? this.direction,
      errorMessage: errorMessage ?? this.errorMessage,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      transferSpeed: transferSpeed ?? this.transferSpeed,
    );
  }

  /// 计算传输进度（0-100）
  double get progress {
    if (fileSize == 0) return 0;
    return (bytesTransferred / fileSize * 100).clamp(0, 100);
  }

  /// 计算剩余时间（秒）
  double? get remainingTime {
    if (transferSpeed == null || transferSpeed == 0) return null;
    final remainingBytes = fileSize - bytesTransferred;
    return remainingBytes / transferSpeed!;
  }

  /// 是否完成
  bool get isCompleted => status == FileTransferStatus.completed;

  /// 是否失败
  bool get isFailed => status == FileTransferStatus.failed;

  /// 是否取消
  bool get isCancelled => status == FileTransferStatus.cancelled;

  /// 是否正在传输
  bool get isTransferring => status == FileTransferStatus.transferring;

  /// 是否等待中
  bool get isWaiting => status == FileTransferStatus.waiting;

  /// 是否发送
  bool get isSending => direction == FileTransferDirection.sending;

  /// 是否接收
  bool get isReceiving => direction == FileTransferDirection.receiving;
}
