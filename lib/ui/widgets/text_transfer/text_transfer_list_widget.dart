import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../application/models/text_transfer_model.dart';
import '../../../application/states/text_transfer_state_notifier.dart';
import 'text_transfer_item_widget.dart';

/// 文本传输列表组件
class TextTransferListWidget extends StatelessWidget {
  /// 构造函数
  const TextTransferListWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTransferState = Provider.of<TextTransferStateNotifier>(context);
    final activeTransfers = textTransferState.activeTextTransfers;

    if (activeTransfers.isEmpty) {
      return const Center(
        child: Text('暂无文本传输记录'),
      );
    }

    // 按照开始时间排序，最新的在前面
    final sortedTransfers = List<TextTransferModel>.from(activeTransfers)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    return ListView.separated(
      itemCount: sortedTransfers.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final transfer = sortedTransfers[index];
        return TextTransferItemWidget(
          transfer: transfer,
          onTap: () {
            textTransferState.selectTextTransfer(transfer.transferId);
          },
        );
      },
    );
  }
}
