import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/file_transfer/file_transfer_list_widget.dart';
import '../widgets/file_transfer/file_transfer_detail_widget.dart';
import '../../application/states/file_transfer_state_notifier.dart';
import '../../application/services/file_picker_service.dart';

/// 文件传输屏幕
class FileTransferScreen extends StatelessWidget {
  /// 构造函数
  const FileTransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FileTransferStateNotifier>(
      builder: (context, fileTransferState, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('文件传输'),
            actions: [
              IconButton(
                icon: const Icon(Icons.folder),
                onPressed: () => _selectReceiveDirectory(context),
                tooltip: '选择接收文件夹',
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _selectFilesToSend(context),
                tooltip: '选择要发送的文件',
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              // 根据屏幕宽度决定布局方式
              if (constraints.maxWidth >= 800) {
                // 宽屏布局：左侧列表，右侧详情
                return Row(
                  children: [
                    SizedBox(
                      width: 320,
                      child: Card(
                        margin: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(Icons.swap_horiz),
                                  const SizedBox(width: 8),
                                  Text(
                                    '传输列表',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            const Expanded(
                              child: FileTransferListWidget(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    const Expanded(
                      child: Card(
                        margin: EdgeInsets.all(8),
                        child: FileTransferDetailWidget(),
                      ),
                    ),
                  ],
                );
              } else {
                // 窄屏布局：根据是否选中切换列表和详情
                return fileTransferState.selectedFileTransfer == null
                    ? const FileTransferListWidget()
                    : const FileTransferDetailWidget();
              }
            },
          ),
        );
      },
    );
  }

  /// 选择接收文件夹
  Future<void> _selectReceiveDirectory(BuildContext context) async {
    final filePickerService =
        Provider.of<FilePickerService>(context, listen: false);
    final fileTransferState =
        Provider.of<FileTransferStateNotifier>(context, listen: false);

    final directory = await filePickerService.pickDirectory();
    if (directory != null) {
      await fileTransferState.setReceiveDirectory(directory);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已设置接收文件夹：$directory'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 选择要发送的文件
  Future<void> _selectFilesToSend(BuildContext context) async {
    final filePickerService =
        Provider.of<FilePickerService>(context, listen: false);
    final fileTransferState =
        Provider.of<FileTransferStateNotifier>(context, listen: false);

    final files = await filePickerService.pickFiles();
    if (files.isNotEmpty) {
      for (final file in files) {
        await fileTransferState.sendFile(file);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已添加 ${files.length} 个文件到传输队列'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
