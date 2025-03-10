import 'dart:convert';
import '../../infrastructure/constants/network_constants.dart';

/// Socket消息类型枚举
enum SocketMessageType {
  /// 连接请求
  CONNECTION_REQUEST,

  /// 连接响应
  CONNECTION_RESPONSE,

  /// 配对确认
  PAIRING_CONFIRMATION,

  /// 心跳检测请求
  PING,

  /// 心跳检测响应
  PONG,

  /// 文件传输请求
  FILE_TRANSFER_REQUEST,

  /// 文件传输响应
  FILE_TRANSFER_RESPONSE,

  /// 文件传输数据
  FILE_TRANSFER_DATA,

  /// 文件传输进度
  FILE_TRANSFER_PROGRESS,

  /// 文件传输完成
  FILE_TRANSFER_COMPLETE,

  /// 文件传输取消
  FILE_TRANSFER_CANCEL,

  /// 文件传输错误
  FILE_TRANSFER_ERROR,

  /// 文件传输恢复
  FILE_TRANSFER_RESUME,

  /// 文本传输请求
  TEXT_TRANSFER_REQUEST,

  /// 文本传输响应
  TEXT_TRANSFER_RESPONSE,

  /// 文本传输进度
  TEXT_TRANSFER_PROGRESS,

  /// 文本传输完成
  TEXT_TRANSFER_COMPLETE,

  /// 文本传输取消
  TEXT_TRANSFER_CANCEL,

  /// 文本传输错误
  TEXT_TRANSFER_ERROR,

  /// 断开连接
  DISCONNECT,

  /// 连接丢失
  CONNECTION_LOST,

  /// 错误消息
  ERROR,
}

/// Socket消息模型类
class SocketMessageModel {
  /// 消息类型
  final SocketMessageType type;

  /// 消息数据
  final Map<String, dynamic> data;

  /// 消息时间戳
  final int timestamp;

  /// 协议版本
  final String protocolVersion;

  /// 构造函数
  SocketMessageModel({
    required this.type,
    required this.data,
    int? timestamp,
    String? protocolVersion,
  })  : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch,
        protocolVersion = protocolVersion ?? NetworkConstants.PROTOCOL_VERSION;

  /// 从JSON字符串创建消息对象
  factory SocketMessageModel.fromJson(String jsonStr) {
    final Map<String, dynamic> json = jsonDecode(jsonStr);

    return SocketMessageModel(
      type: _stringToMessageType(json['type']),
      data: json['data'] ?? {},
      timestamp: json['timestamp'],
      protocolVersion: json['protocolVersion'],
    );
  }

  /// 将消息对象转换为JSON字符串
  String toJson() {
    return jsonEncode({
      'type': type.toString().split('.').last,
      'data': data,
      'timestamp': timestamp,
      'protocolVersion': protocolVersion,
    });
  }

  /// 字符串转消息类型
  static SocketMessageType _stringToMessageType(String typeStr) {
    return SocketMessageType.values.firstWhere(
      (type) => type.toString().split('.').last == typeStr,
      orElse: () => SocketMessageType.ERROR,
    );
  }

  /// 创建连接请求消息
  static SocketMessageModel createConnectionRequest({
    required String deviceName,
    required String deviceIp,
    required String pairingCode,
  }) {
    return SocketMessageModel(
      type: SocketMessageType.CONNECTION_REQUEST,
      data: {
        'deviceName': deviceName,
        'deviceIp': deviceIp,
        'pairingCode': pairingCode,
      },
    );
  }

  /// 创建连接响应消息
  static SocketMessageModel createConnectionResponse({
    required bool accepted,
    required String deviceName,
    required String deviceIp,
    String? rejectReason,
  }) {
    return SocketMessageModel(
      type: SocketMessageType.CONNECTION_RESPONSE,
      data: {
        'accepted': accepted,
        'deviceName': deviceName,
        'deviceIp': deviceIp,
        if (rejectReason != null) 'rejectReason': rejectReason,
      },
    );
  }

  /// 创建配对确认消息
  static SocketMessageModel createPairingConfirmation({
    required bool confirmed,
    String? rejectReason,
  }) {
    return SocketMessageModel(
      type: SocketMessageType.PAIRING_CONFIRMATION,
      data: {
        'confirmed': confirmed,
        if (rejectReason != null) 'rejectReason': rejectReason,
      },
    );
  }

  /// 创建心跳检测请求消息
  static SocketMessageModel createPing() {
    return SocketMessageModel(
      type: SocketMessageType.PING,
      data: {},
    );
  }

  /// 创建心跳检测响应消息
  static SocketMessageModel createPong() {
    return SocketMessageModel(
      type: SocketMessageType.PONG,
      data: {},
    );
  }

  /// 创建文件传输请求消息
  static SocketMessageModel createFileTransferRequest({
    required String fileName,
    required int fileSize,
    required String fileHash,
    required String filePath,
  }) {
    return SocketMessageModel(
      type: SocketMessageType.FILE_TRANSFER_REQUEST,
      data: {
        'fileName': fileName,
        'fileSize': fileSize,
        'fileHash': fileHash,
        'filePath': filePath,
      },
    );
  }

  /// 创建文件传输响应消息
  static SocketMessageModel createFileTransferResponse({
    required bool accepted,
    required String fileName,
    String? rejectReason,
  }) {
    return SocketMessageModel(
      type: SocketMessageType.FILE_TRANSFER_RESPONSE,
      data: {
        'accepted': accepted,
        'fileName': fileName,
        if (rejectReason != null) 'rejectReason': rejectReason,
      },
    );
  }

  /// 创建文件传输数据消息
  static SocketMessageModel createFileTransferDataMessage({
    required String transferId,
    required String fileName,
    required String data,
    required int offset,
  }) {
    return SocketMessageModel(
      type: SocketMessageType.FILE_TRANSFER_DATA,
      data: {
        'transferId': transferId,
        'fileName': fileName,
        'data': data,
        'offset': offset,
      },
    );
  }

  /// 创建文件传输进度消息
  static SocketMessageModel createFileTransferProgress({
    required String fileName,
    required int bytesTransferred,
    required int totalBytes,
    required double progress,
  }) {
    return SocketMessageModel(
      type: SocketMessageType.FILE_TRANSFER_PROGRESS,
      data: {
        'fileName': fileName,
        'bytesTransferred': bytesTransferred,
        'totalBytes': totalBytes,
        'progress': progress,
      },
    );
  }

  /// 创建文件传输完成消息
  static SocketMessageModel createFileTransferComplete({
    required String fileName,
    required String filePath,
  }) {
    return SocketMessageModel(
      type: SocketMessageType.FILE_TRANSFER_COMPLETE,
      data: {
        'fileName': fileName,
        'filePath': filePath,
      },
    );
  }

  /// 创建文件传输取消消息
  static SocketMessageModel createFileTransferCancel({
    required String fileName,
    required String reason,
  }) {
    return SocketMessageModel(
      type: SocketMessageType.FILE_TRANSFER_CANCEL,
      data: {
        'fileName': fileName,
        'reason': reason,
      },
    );
  }

  /// 创建文件传输错误消息
  static SocketMessageModel createFileTransferErrorMessage({
    required String transferId,
    required String errorMessage,
  }) {
    return SocketMessageModel(
      type: SocketMessageType.FILE_TRANSFER_ERROR,
      data: {
        'transferId': transferId,
        'errorMessage': errorMessage,
      },
    );
  }

  /// 创建文件传输恢复消息
  static SocketMessageModel createFileTransferResumeMessage({
    required String transferId,
    required String fileName,
    required String filePath,
    required int fileSize,
    required String fileHash,
    required int bytesTransferred,
  }) {
    return SocketMessageModel(
      type: SocketMessageType.FILE_TRANSFER_RESUME,
      data: {
        'transferId': transferId,
        'fileName': fileName,
        'filePath': filePath,
        'fileSize': fileSize,
        'fileHash': fileHash,
        'bytesTransferred': bytesTransferred,
      },
    );
  }

  /// 创建文本传输请求消息
  static SocketMessageModel createTextTransferRequestMessage({
    required String text,
    required int textLength,
    required int lineCount,
  }) {
    return SocketMessageModel(
      type: SocketMessageType.TEXT_TRANSFER_REQUEST,
      data: {
        'transferId': DateTime.now().millisecondsSinceEpoch.toString(),
        'textLength': textLength,
        'lineCount': lineCount,
        'text': text,
      },
    );
  }

  /// 创建文本传输响应消息
  static SocketMessageModel createTextTransferResponseMessage({
    required String transferId,
    required bool accepted,
    String? rejectReason,
  }) {
    return SocketMessageModel(
      type: SocketMessageType.TEXT_TRANSFER_RESPONSE,
      data: {
        'transferId': transferId,
        'accepted': accepted,
        if (rejectReason != null) 'rejectReason': rejectReason,
      },
    );
  }

  /// 创建文本传输进度消息
  static SocketMessageModel createTextTransferProgressMessage({
    required String transferId,
    required int processedLength,
    required int totalLength,
  }) {
    return SocketMessageModel(
      type: SocketMessageType.TEXT_TRANSFER_PROGRESS,
      data: {
        'transferId': transferId,
        'processedLength': processedLength,
        'totalLength': totalLength,
      },
    );
  }

  /// 创建文本传输完成消息
  static SocketMessageModel createTextTransferCompleteMessage({
    required String transferId,
    required String text,
  }) {
    return SocketMessageModel(
      type: SocketMessageType.TEXT_TRANSFER_COMPLETE,
      data: {
        'transferId': transferId,
        'text': text,
      },
    );
  }

  /// 创建文本传输取消消息
  static SocketMessageModel createTextTransferCancelMessage({
    required String transferId,
  }) {
    return SocketMessageModel(
      type: SocketMessageType.TEXT_TRANSFER_CANCEL,
      data: {
        'transferId': transferId,
      },
    );
  }

  /// 创建文本传输错误消息
  static SocketMessageModel createTextTransferErrorMessage({
    required String transferId,
    required String errorMessage,
  }) {
    return SocketMessageModel(
      type: SocketMessageType.TEXT_TRANSFER_ERROR,
      data: {
        'transferId': transferId,
        'errorMessage': errorMessage,
      },
    );
  }

  /// 创建断开连接消息
  static SocketMessageModel createDisconnect({
    String? reason,
  }) {
    return SocketMessageModel(
      type: SocketMessageType.DISCONNECT,
      data: {
        if (reason != null) 'reason': reason,
      },
    );
  }

  /// 创建连接丢失消息
  static SocketMessageModel createConnectionLost({
    required String reason,
  }) {
    return SocketMessageModel(
      type: SocketMessageType.CONNECTION_LOST,
      data: {
        'reason': reason,
      },
    );
  }

  /// 创建错误消息
  static SocketMessageModel createError({
    required String errorCode,
    required String errorMessage,
  }) {
    return SocketMessageModel(
      type: SocketMessageType.ERROR,
      data: {
        'errorCode': errorCode,
        'errorMessage': errorMessage,
      },
    );
  }
}
