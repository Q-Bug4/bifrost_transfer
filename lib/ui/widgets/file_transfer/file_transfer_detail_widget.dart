import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../application/states/file_transfer_state_notifier.dart';
import '../../../application/models/file_transfer_model.dart';

/// 文件传输详情组件
class FileTransferDetailWidget extends StatelessWidget {
  /// 构造函数
  const FileTransferDetailWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FileTransferStateNotifier>(
      builder: (context, fileTransferState, child) {
        final selectedTransfer = fileTransferState.selectedFileTransfer;

        if (selectedTransfer == null) {
          return const Center(
            child: Text('请选择一个文件传输'),
          );
        }

        return _buildDetailContent(
            context, selectedTransfer, fileTransferState);
      },
    );
  }

  /// 构建详情内容
  Widget _buildDetailContent(
    BuildContext context,
    FileTransferModel transfer,
    FileTransferStateNotifier fileTransferState,
  ) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    // 获取状态文本和颜色
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (transfer.status) {
      case FileTransferStatus.waiting:
        statusText = '等待中';
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case FileTransferStatus.transferring:
        statusText = '传输中';
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        break;
      case FileTransferStatus.completed:
        statusText = '已完成';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case FileTransferStatus.failed:
        statusText = '失败';
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case FileTransferStatus.cancelled:
        statusText = '已取消';
        statusColor = Colors.grey;
        statusIcon = Icons.cancel;
        break;
    }

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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDetailItem(
            context,
            '文件名',
            transfer.fileName,
            Icons.insert_drive_file,
          ),
          _buildDetailItem(
            context,
            '文件大小',
            getFileSizeText(transfer.fileSize),
            Icons.data_usage,
          ),
          _buildDetailItem(
            context,
            '文件路径',
            transfer.filePath,
            Icons.folder,
          ),
          _buildDetailItem(
            context,
            '传输方向',
            transfer.direction == FileTransferDirection.sending ? '发送' : '接收',
            Icons.swap_horiz,
          ),
          _buildDetailItem(
            context,
            '开始时间',
            dateFormat.format(transfer.startTime),
            Icons.access_time,
          ),
          if (transfer.endTime != null)
            _buildDetailItem(
              context,
              '结束时间',
              dateFormat.format(transfer.endTime!),
              Icons.access_time_filled,
            ),
          if (transfer.errorMessage != null)
            _buildDetailItem(
              context,
              '错误信息',
              transfer.errorMessage!,
              Icons.error_outline,
            ),
          if (transfer.isTransferring) ...[
            const SizedBox(height: 16),
            Text(
              '传输进度',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: transfer.progress / 100,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${transfer.progress.toStringAsFixed(1)}%',
                  style: theme.textTheme.bodyMedium,
                ),
                if (transfer.transferSpeed != null)
                  Text(
                    '${(transfer.transferSpeed! / 1024 / 1024).toStringAsFixed(2)} MB/s',
                    style: theme.textTheme.bodyMedium,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (transfer.isTransferring)
                ElevatedButton.icon(
                  onPressed: () =>
                      fileTransferState.cancelFileTransfer(transfer.transferId),
                  icon: const Icon(Icons.cancel),
                  label: const Text('取消传输'),
                ),
              if (!transfer.isCompleted && !transfer.isTransferring)
                ElevatedButton.icon(
                  onPressed: () =>
                      fileTransferState.resumeFileTransfer(transfer.transferId),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('继续传输'),
                ),
              OutlinedButton.icon(
                onPressed: () => fileTransferState.clearSelectedFileTransfer(),
                icon: const Icon(Icons.close),
                label: const Text('关闭详情'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建详情项
  Widget _buildDetailItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
