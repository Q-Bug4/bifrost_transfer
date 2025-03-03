import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../application/states/file_transfer_state_notifier.dart';
import '../../../application/models/file_transfer_model.dart';

/// 文件传输列表组件
class FileTransferListWidget extends StatelessWidget {
  /// 构造函数
  const FileTransferListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FileTransferStateNotifier>(
      builder: (context, fileTransferState, child) {
        final transfers = fileTransferState.activeFileTransfers;

        if (transfers.isEmpty) {
          return const Center(
            child: Text('暂无文件传输'),
          );
        }

        return ListView.builder(
          itemCount: transfers.length,
          itemBuilder: (context, index) {
            final transfer = transfers[index];
            return _buildTransferItem(context, transfer, fileTransferState);
          },
        );
      },
    );
  }

  /// 构建传输项
  Widget _buildTransferItem(
    BuildContext context,
    FileTransferModel transfer,
    FileTransferStateNotifier fileTransferState,
  ) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    // 获取状态文本和颜色
    String statusText;
    Color statusColor;

    switch (transfer.status) {
      case FileTransferStatus.waiting:
        statusText = '等待中';
        statusColor = Colors.orange;
        break;
      case FileTransferStatus.transferring:
        statusText = '传输中 (${transfer.progress.toStringAsFixed(1)}%)';
        statusColor = Colors.blue;
        break;
      case FileTransferStatus.completed:
        statusText = '已完成';
        statusColor = Colors.green;
        break;
      case FileTransferStatus.failed:
        statusText = '失败: ${transfer.errorMessage ?? "未知错误"}';
        statusColor = Colors.red;
        break;
      case FileTransferStatus.cancelled:
        statusText = '已取消';
        statusColor = Colors.grey;
        break;
    }

    // 获取方向文本
    final directionText =
        transfer.direction == FileTransferDirection.sending ? '发送' : '接收';

    // 获取文件大小文本
    String getFileSizeText(int bytes) {
      const units = ['B', 'KB', 'MB', 'GB', 'TB'];
      var size = bytes.toDouble();
      var unitIndex = 0;
      while (size >= 1024 && unitIndex < units.length - 1) {
        size /= 1024;
        unitIndex++;
      }
      return '${size.toStringAsFixed(2)} ${units[unitIndex]}';
    }

    final fileSizeText = getFileSizeText(transfer.fileSize);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => fileTransferState.selectFileTransfer(transfer.transferId),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.file_copy,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      transfer.fileName,
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    directionText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    fileSizeText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(transfer.startTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (transfer.isTransferring) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: transfer.progress / 100,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${transfer.progress.toStringAsFixed(1)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (transfer.transferSpeed != null)
                      Text(
                        '${(transfer.transferSpeed! / 1024 / 1024).toStringAsFixed(2)} MB/s',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
