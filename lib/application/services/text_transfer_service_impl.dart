import 'dart:async';
import 'package:logging/logging.dart';
import '../models/text_transfer_model.dart';
import '../models/socket_message_model.dart';
import 'socket_communication_service.dart';
import 'text_transfer_service.dart';

/// 文本传输服务实现类
class TextTransferServiceImpl implements TextTransferService {
  /// 日志记录器
  final _logger = Logger('TextTransferServiceImpl');

  /// Socket通信服务
  final SocketCommunicationService _socketService;

  /// 文本传输状态控制器
  final _textTransferController =
      StreamController<TextTransferModel>.broadcast();

  /// 活跃的文本传输
  final Map<String, TextTransferModel> _activeTextTransfers = {};

  /// 消息订阅
  StreamSubscription<SocketMessageModel>? _messageSubscription;

  /// 构造函数
  TextTransferServiceImpl(this._socketService) {
    _subscribeToMessages();
  }

  @override
  Future<String> sendText(String text) async {
    if (text.isEmpty) {
      throw Exception('文本内容不能为空');
    }

    if (text.length > 32 * 1024) {
      throw Exception('文本内容过大，超过32KB限制');
    }

    final lineCount = '\n'.allMatches(text).length + 1;
    final textLength = text.length;

    // 创建文本传输请求消息
    final message = SocketMessageModel.createTextTransferRequestMessage(
      text: text,
      textLength: textLength,
      lineCount: lineCount,
    );

    final transferId = message.data['transferId'] as String;

    // 创建文本传输模型
    final textTransfer = TextTransferModel(
      transferId: transferId,
      text: text,
      textLength: textLength,
      lineCount: lineCount,
      status: TextTransferStatus.waiting,
      direction: TextTransferDirection.sending,
    );

    // 添加到活跃传输列表
    _activeTextTransfers[transferId] = textTransfer;
    _notifyTextTransferUpdate(textTransfer);

    try {
      // 发送请求
      await _socketService.sendMessage(message);

      // 更新状态为传输中
      final updatedTransfer = textTransfer.copyWith(
        status: TextTransferStatus.transferring,
      );
      _activeTextTransfers[transferId] = updatedTransfer;
      _notifyTextTransferUpdate(updatedTransfer);

      return transferId;
    } catch (e) {
      // 更新状态为失败
      final failedTransfer = textTransfer.copyWith(
        status: TextTransferStatus.failed,
        errorMessage: e.toString(),
        endTime: DateTime.now(),
      );
      _activeTextTransfers[transferId] = failedTransfer;
      _notifyTextTransferUpdate(failedTransfer);

      _logger.severe('发送文本失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> cancelTextTransfer(String transferId) async {
    final textTransfer = _activeTextTransfers[transferId];
    if (textTransfer == null) {
      _logger.warning('尝试取消不存在的文本传输: $transferId');
      return;
    }

    try {
      // 发送取消消息
      final message = SocketMessageModel.createTextTransferCancelMessage(
        transferId: transferId,
      );
      await _socketService.sendMessage(message);

      // 更新状态为已取消
      final cancelledTransfer = textTransfer.copyWith(
        status: TextTransferStatus.cancelled,
        endTime: DateTime.now(),
      );
      _activeTextTransfers[transferId] = cancelledTransfer;
      _notifyTextTransferUpdate(cancelledTransfer);
    } catch (e) {
      _logger.severe('取消文本传输失败: $e');
      rethrow;
    }
  }

  @override
  Stream<TextTransferModel> get textTransferStream =>
      _textTransferController.stream;

  @override
  List<TextTransferModel> getActiveTextTransfers() {
    return _activeTextTransfers.values.toList();
  }

  @override
  TextTransferModel? getTextTransfer(String transferId) {
    return _activeTextTransfers[transferId];
  }

  /// 订阅Socket消息
  void _subscribeToMessages() {
    _messageSubscription = _socketService.messageStream.listen(_handleMessage);
  }

  /// 处理Socket消息
  void _handleMessage(SocketMessageModel message) {
    switch (message.type) {
      case SocketMessageType.TEXT_TRANSFER_REQUEST:
        _handleTextTransferRequest(message);
        break;
      case SocketMessageType.TEXT_TRANSFER_RESPONSE:
        _handleTextTransferResponse(message);
        break;
      case SocketMessageType.TEXT_TRANSFER_PROGRESS:
        _handleTextTransferProgress(message);
        break;
      case SocketMessageType.TEXT_TRANSFER_COMPLETE:
        _handleTextTransferComplete(message);
        break;
      case SocketMessageType.TEXT_TRANSFER_CANCEL:
        _handleTextTransferCancel(message);
        break;
      case SocketMessageType.TEXT_TRANSFER_ERROR:
        _handleTextTransferError(message);
        break;
      default:
        // 忽略其他类型的消息
        break;
    }
  }

  /// 处理文本传输请求
  void _handleTextTransferRequest(SocketMessageModel message) {
    final transferId = message.data['transferId'] as String;
    final text = message.data['text'] as String;
    final textLength = message.data['textLength'] as int;
    final lineCount = message.data['lineCount'] as int;

    // 创建文本传输模型
    final textTransfer = TextTransferModel(
      transferId: transferId,
      text: text,
      textLength: textLength,
      lineCount: lineCount,
      status: TextTransferStatus.transferring,
      direction: TextTransferDirection.receiving,
    );

    // 添加到活跃传输列表
    _activeTextTransfers[transferId] = textTransfer;
    _notifyTextTransferUpdate(textTransfer);

    // 自动接受文本传输请求
    _acceptTextTransfer(transferId);
  }

  /// 接受文本传输请求
  Future<void> _acceptTextTransfer(String transferId) async {
    try {
      // 发送接受响应
      final responseMessage =
          SocketMessageModel.createTextTransferResponseMessage(
        transferId: transferId,
        accepted: true,
      );
      await _socketService.sendMessage(responseMessage);

      // 更新状态为已完成
      final textTransfer = _activeTextTransfers[transferId];
      if (textTransfer != null) {
        final completedTransfer = textTransfer.copyWith(
          status: TextTransferStatus.completed,
          processedLength: textTransfer.textLength,
          endTime: DateTime.now(),
        );
        _activeTextTransfers[transferId] = completedTransfer;
        _notifyTextTransferUpdate(completedTransfer);
      }

      // 发送完成消息
      final completeMessage =
          SocketMessageModel.createTextTransferCompleteMessage(
        transferId: transferId,
        text: textTransfer?.text ?? '',
      );
      await _socketService.sendMessage(completeMessage);
    } catch (e) {
      _logger.severe('接受文本传输失败: $e');

      // 更新状态为失败
      final textTransfer = _activeTextTransfers[transferId];
      if (textTransfer != null) {
        final failedTransfer = textTransfer.copyWith(
          status: TextTransferStatus.failed,
          errorMessage: e.toString(),
          endTime: DateTime.now(),
        );
        _activeTextTransfers[transferId] = failedTransfer;
        _notifyTextTransferUpdate(failedTransfer);
      }
    }
  }

  /// 处理文本传输响应
  void _handleTextTransferResponse(SocketMessageModel message) {
    final transferId = message.data['transferId'] as String;
    final accepted = message.data['accepted'] as bool;
    final rejectReason = message.data['rejectReason'] as String?;

    final textTransfer = _activeTextTransfers[transferId];
    if (textTransfer == null) {
      _logger.warning('收到未知文本传输的响应: $transferId');
      return;
    }

    if (accepted) {
      // 更新状态为传输中
      final updatedTransfer = textTransfer.copyWith(
        status: TextTransferStatus.transferring,
      );
      _activeTextTransfers[transferId] = updatedTransfer;
      _notifyTextTransferUpdate(updatedTransfer);

      // 发送完成消息
      _completeTextTransfer(transferId);
    } else {
      // 更新状态为失败
      final failedTransfer = textTransfer.copyWith(
        status: TextTransferStatus.failed,
        errorMessage: rejectReason ?? '接收方拒绝接收文本',
        endTime: DateTime.now(),
      );
      _activeTextTransfers[transferId] = failedTransfer;
      _notifyTextTransferUpdate(failedTransfer);
    }
  }

  /// 完成文本传输
  Future<void> _completeTextTransfer(String transferId) async {
    try {
      final textTransfer = _activeTextTransfers[transferId];
      if (textTransfer == null) return;

      // 发送完成消息
      final completeMessage =
          SocketMessageModel.createTextTransferCompleteMessage(
        transferId: transferId,
        text: textTransfer.text,
      );
      await _socketService.sendMessage(completeMessage);

      // 更新状态为已完成
      final completedTransfer = textTransfer.copyWith(
        status: TextTransferStatus.completed,
        processedLength: textTransfer.textLength,
        endTime: DateTime.now(),
      );
      _activeTextTransfers[transferId] = completedTransfer;
      _notifyTextTransferUpdate(completedTransfer);
    } catch (e) {
      _logger.severe('完成文本传输失败: $e');

      // 更新状态为失败
      final textTransfer = _activeTextTransfers[transferId];
      if (textTransfer != null) {
        final failedTransfer = textTransfer.copyWith(
          status: TextTransferStatus.failed,
          errorMessage: e.toString(),
          endTime: DateTime.now(),
        );
        _activeTextTransfers[transferId] = failedTransfer;
        _notifyTextTransferUpdate(failedTransfer);
      }
    }
  }

  /// 处理文本传输进度
  void _handleTextTransferProgress(SocketMessageModel message) {
    final transferId = message.data['transferId'] as String;
    final processedLength = message.data['processedLength'] as int;
    final totalLength = message.data['totalLength'] as int;

    final textTransfer = _activeTextTransfers[transferId];
    if (textTransfer == null) {
      _logger.warning('收到未知文本传输的进度: $transferId');
      return;
    }

    // 更新进度
    final updatedTransfer = textTransfer.copyWith(
      processedLength: processedLength,
      textLength: totalLength,
    );
    _activeTextTransfers[transferId] = updatedTransfer;
    _notifyTextTransferUpdate(updatedTransfer);
  }

  /// 处理文本传输完成
  void _handleTextTransferComplete(SocketMessageModel message) {
    final transferId = message.data['transferId'] as String;
    final text = message.data['text'] as String?;

    _logger.info('收到文本传输完成消息: $transferId');

    final transfer = _activeTextTransfers[transferId];
    if (transfer != null) {
      final updatedTransfer = transfer.copyWith(
        status: TextTransferStatus.completed,
        processedLength: transfer.textLength,
        text: text ?? transfer.text,
        endTime: DateTime.now(),
      );

      _activeTextTransfers[transferId] = updatedTransfer;
      _notifyTextTransferUpdate(updatedTransfer);
      _logger.info('文本传输完成: $transferId');
    } else {
      _logger.warning('未找到对应的文本传输: $transferId');
    }
  }

  /// 处理文本传输取消
  void _handleTextTransferCancel(SocketMessageModel message) {
    final transferId = message.data['transferId'] as String;

    final textTransfer = _activeTextTransfers[transferId];
    if (textTransfer == null) {
      _logger.warning('收到未知文本传输的取消消息: $transferId');
      return;
    }

    // 更新状态为已取消
    final cancelledTransfer = textTransfer.copyWith(
      status: TextTransferStatus.cancelled,
      endTime: DateTime.now(),
    );
    _activeTextTransfers[transferId] = cancelledTransfer;
    _notifyTextTransferUpdate(cancelledTransfer);
  }

  /// 处理文本传输错误
  void _handleTextTransferError(SocketMessageModel message) {
    final transferId = message.data['transferId'] as String;
    final errorMessage = message.data['errorMessage'] as String;

    final textTransfer = _activeTextTransfers[transferId];
    if (textTransfer == null) {
      _logger.warning('收到未知文本传输的错误消息: $transferId');
      return;
    }

    // 更新状态为失败
    final failedTransfer = textTransfer.copyWith(
      status: TextTransferStatus.failed,
      errorMessage: errorMessage,
      endTime: DateTime.now(),
    );
    _activeTextTransfers[transferId] = failedTransfer;
    _notifyTextTransferUpdate(failedTransfer);
  }

  /// 通知文本传输状态更新
  void _notifyTextTransferUpdate(TextTransferModel textTransfer) {
    _textTransferController.add(textTransfer);
  }

  /// 释放资源
  void dispose() {
    _messageSubscription?.cancel();
    _textTransferController.close();
  }
}
