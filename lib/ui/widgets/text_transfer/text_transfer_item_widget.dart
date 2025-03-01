import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../application/models/text_transfer_model.dart';
import '../../../application/states/text_transfer_state_notifier.dart';

/// 文本传输项组件
class TextTransferItemWidget extends StatelessWidget {
  /// 文本传输模型
  final TextTransferModel transfer;

  /// 点击回调
  final VoidCallback onTap;

  /// 构造函数
  const TextTransferItemWidget({
    Key? key,
    required this.transfer,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTransferState = Provider.of<TextTransferStateNotifier>(context);

    // 格式化时间
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final startTimeStr = dateFormat.format(transfer.startTime);

    // 获取状态颜色和图标
    Color statusColor;
    IconData statusIcon;

    switch (transfer.status) {
      case TextTransferStatus.waiting:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case TextTransferStatus.transferring:
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        break;
      case TextTransferStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case TextTransferStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case TextTransferStatus.cancelled:
        statusColor = Colors.grey;
        statusIcon = Icons.cancel;
        break;
    }

    // 获取方向图标
    IconData directionIcon = transfer.direction == TextTransferDirection.sending
        ? Icons.upload
        : Icons.download;

    return ListTile(
      onTap: onTap,
      leading: Stack(
        alignment: Alignment.center,
        children: [
          Icon(directionIcon, color: theme.primaryColor),
          if (transfer.status == TextTransferStatus.transferring)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                value: transfer.progress,
                strokeWidth: 2,
                backgroundColor: Colors.grey.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
            ),
        ],
      ),
      title: Text(
        _getDisplayText(transfer.text),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${transfer.textLength} 字节 | $startTimeStr',
        style: theme.textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 8),
          if (transfer.status == TextTransferStatus.waiting ||
              transfer.status == TextTransferStatus.transferring)
            IconButton(
              icon: const Icon(Icons.cancel, size: 20),
              onPressed: () async {
                try {
                  await textTransferState
                      .cancelTextTransfer(transfer.transferId);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('取消传输失败: $e')),
                    );
                  }
                }
              },
              tooltip: '取消',
            ),
        ],
      ),
    );
  }

  /// 获取显示文本
  String _getDisplayText(String text) {
    // 移除换行符，限制长度
    return text.replaceAll('\n', ' ').trim();
  }
}
