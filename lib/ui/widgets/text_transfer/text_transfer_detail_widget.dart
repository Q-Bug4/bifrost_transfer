import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../application/models/text_transfer_model.dart';
import '../../../application/states/text_transfer_state_notifier.dart';

/// 文本传输详情组件
class TextTransferDetailWidget extends StatelessWidget {
  /// 构造函数
  const TextTransferDetailWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTransferState = Provider.of<TextTransferStateNotifier>(context);
    final selectedTransfer = textTransferState.selectedTextTransfer;

    if (selectedTransfer == null) {
      return const Center(
        child: Text('请选择一个文本传输记录查看详情'),
      );
    }

    return _buildDetailContent(context, selectedTransfer, textTransferState);
  }

  /// 构建详情内容
  Widget _buildDetailContent(
    BuildContext context,
    TextTransferModel transfer,
    TextTransferStateNotifier textTransferState,
  ) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    // 获取状态文本和颜色
    String statusText;
    Color statusColor;

    switch (transfer.status) {
      case TextTransferStatus.waiting:
        statusText = '等待中';
        statusColor = Colors.orange;
        break;
      case TextTransferStatus.transferring:
        statusText = '传输中 (${transfer.progress.toStringAsFixed(1)}%)';
        statusColor = Colors.blue;
        break;
      case TextTransferStatus.completed:
        statusText = '已完成';
        statusColor = Colors.green;
        break;
      case TextTransferStatus.failed:
        statusText = '失败: ${transfer.errorMessage ?? "未知错误"}';
        statusColor = Colors.red;
        break;
      case TextTransferStatus.cancelled:
        statusText = '已取消';
        statusColor = Colors.grey;
        break;
    }

    // 获取方向文本
    final directionText =
        transfer.direction == TextTransferDirection.sending ? '发送' : '接收';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 标题栏
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8.0),
              topRight: Radius.circular(8.0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '文本传输详情',
                style: theme.textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  textTransferState.clearSelectedTextTransfer();
                },
                tooltip: '关闭',
              ),
            ],
          ),
        ),

        // 信息区域 - 使用Expanded和SingleChildScrollView
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 状态信息
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('状态: ', style: theme.textTheme.bodyLarge),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),

                // 方向信息
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('方向: ', style: theme.textTheme.bodyLarge),
                    Text(directionText),
                  ],
                ),
                const SizedBox(height: 8.0),

                // 大小信息
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('大小: ', style: theme.textTheme.bodyLarge),
                    Text('${transfer.textLength} 字节 (${transfer.lineCount} 行)'),
                  ],
                ),
                const SizedBox(height: 8.0),

                // 时间信息
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('开始时间: ', style: theme.textTheme.bodyLarge),
                    Text(dateFormat.format(transfer.startTime)),
                  ],
                ),
                if (transfer.endTime != null) ...[
                  const SizedBox(height: 8.0),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('结束时间: ', style: theme.textTheme.bodyLarge),
                      Text(dateFormat.format(transfer.endTime!)),
                    ],
                  ),
                ],
                const SizedBox(height: 16.0),

                // 文本内容
                Text('文本内容:', style: theme.textTheme.bodyLarge),
                const SizedBox(height: 8.0),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 使用LimitedBox限制文本高度，并使用SingleChildScrollView使其可滚动
                      LimitedBox(
                        maxHeight: 100, // 限制最大高度
                        child: SingleChildScrollView(
                          child: Text(
                            transfer.text,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.copy, size: 16.0),
                          label: const Text('复制文本'),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: transfer.text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('文本已复制到剪贴板')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // 操作按钮
                if (transfer.status == TextTransferStatus.waiting ||
                    transfer.status == TextTransferStatus.transferring)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.cancel),
                      label: const Text('取消传输'),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
