import 'dart:async';
import 'package:mockito/annotations.dart';
import 'package:bifrost_transfer/application/services/text_transfer_service.dart';
import 'package:bifrost_transfer/application/models/text_transfer_model.dart';

@GenerateMocks([TextTransferService])
void main() {}

/// 测试用的文本传输服务实现
class TestTextTransferService implements TextTransferService {
  /// 文本传输流控制器
  final StreamController<TextTransferModel> _textTransferController =
      StreamController<TextTransferModel>.broadcast();

  /// 活跃的文本传输
  final Map<String, TextTransferModel> _activeTextTransfers = {};

  /// 下一个传输ID
  int _nextTransferId = 1;

  @override
  Stream<TextTransferModel> get textTransferStream =>
      _textTransferController.stream;

  @override
  Future<String> sendText(String text) async {
    final transferId = 'text_${_nextTransferId++}';
    final lineCount = text.isEmpty ? 0 : '\n'.allMatches(text).length + 1;

    final transfer = TextTransferModel(
      transferId: transferId,
      text: text,
      textLength: text.length,
      lineCount: lineCount,
      direction: TextTransferDirection.sending,
      status: TextTransferStatus.waiting,
    );

    _activeTextTransfers[transferId] = transfer;
    _textTransferController.add(transfer);

    // 模拟传输过程
    await Future.delayed(const Duration(milliseconds: 100));

    // 更新为传输中
    final transferring = transfer.copyWith(
      status: TextTransferStatus.transferring,
      processedLength: (transfer.textLength * 0.5).round(),
    );
    _activeTextTransfers[transferId] = transferring;
    _textTransferController.add(transferring);

    // 模拟传输完成
    await Future.delayed(const Duration(milliseconds: 100));

    // 更新为已完成
    final completed = transferring.copyWith(
      status: TextTransferStatus.completed,
      processedLength: transfer.textLength,
      endTime: DateTime.now(),
    );
    _activeTextTransfers[transferId] = completed;
    _textTransferController.add(completed);

    return transferId;
  }

  @override
  Future<void> cancelTextTransfer(String transferId) async {
    final transfer = _activeTextTransfers[transferId];
    if (transfer == null) return;

    if (transfer.status == TextTransferStatus.waiting ||
        transfer.status == TextTransferStatus.transferring) {
      final cancelled = transfer.copyWith(
        status: TextTransferStatus.cancelled,
        endTime: DateTime.now(),
      );
      _activeTextTransfers[transferId] = cancelled;
      _textTransferController.add(cancelled);
    }
  }

  @override
  List<TextTransferModel> getActiveTextTransfers() {
    return _activeTextTransfers.values.toList();
  }

  @override
  TextTransferModel? getTextTransfer(String transferId) {
    return _activeTextTransfers[transferId];
  }

  /// 添加一个接收的文本传输
  void addReceivedTextTransfer(String text) {
    final transferId = 'text_${_nextTransferId++}';
    final lineCount = text.isEmpty ? 0 : '\n'.allMatches(text).length + 1;

    final transfer = TextTransferModel(
      transferId: transferId,
      text: text,
      textLength: text.length,
      lineCount: lineCount,
      direction: TextTransferDirection.receiving,
      status: TextTransferStatus.waiting,
    );

    _activeTextTransfers[transferId] = transfer;
    _textTransferController.add(transfer);

    // 更新为传输中
    Future.delayed(const Duration(milliseconds: 50)).then((_) {
      final transferring = transfer.copyWith(
        status: TextTransferStatus.transferring,
        processedLength: (transfer.textLength * 0.5).round(),
      );
      _activeTextTransfers[transferId] = transferring;
      _textTransferController.add(transferring);

      // 更新为已完成
      Future.delayed(const Duration(milliseconds: 50)).then((_) {
        final completed = transferring.copyWith(
          status: TextTransferStatus.completed,
          processedLength: transfer.textLength,
          endTime: DateTime.now(),
        );
        _activeTextTransfers[transferId] = completed;
        _textTransferController.add(completed);
      });
    });
  }

  /// 清理资源
  void dispose() {
    _textTransferController.close();
  }
}
