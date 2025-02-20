import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import '../../application/di/service_locator.dart';
import '../../application/services/file_transfer_service.dart';
import '../../application/services/network_service.dart';

class FileTransferWidget extends StatefulWidget {
  const FileTransferWidget({super.key});

  @override
  State<FileTransferWidget> createState() => _FileTransferWidgetState();
}

class _FileTransferWidgetState extends State<FileTransferWidget> {
  final _fileTransferService = getIt<FileTransferService>();
  final _networkService = getIt<NetworkService>();
  final List<FileTransfer> _transfers = [];

  @override
  void initState() {
    super.initState();
    _setupTransferListener();
  }

  void _setupTransferListener() {
    _fileTransferService.incomingTransfers.listen((transfer) {
      setState(() {
        _transfers.add(transfer);
      });
    });
  }

  Future<void> _pickAndSendFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || !mounted) return;

    final path = result.files.single.path;
    if (path == null || !mounted) return;

    try {
      final stream = _fileTransferService.sendFile(path);
      stream.listen(
        (transfer) {
          if (!mounted) return;
          setState(() {
            final index = _transfers.indexWhere((t) => t.fileName == transfer.fileName);
            if (index >= 0) {
              _transfers[index] = transfer;
            } else {
              _transfers.add(transfer);
            }
          });
        },
        onError: (error) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sending file: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleDroppedFile(String filePath) {
    if (!mounted) return;
    try {
      final stream = _fileTransferService.sendFile(filePath);
      stream.listen(
        (transfer) {
          if (!mounted) return;
          setState(() {
            final index = _transfers.indexWhere((t) => t.fileName == transfer.fileName);
            if (index >= 0) {
              _transfers[index] = transfer;
            } else {
              _transfers.add(transfer);
            }
          });
        },
        onError: (error) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sending file: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('传输设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('默认保存路径'),
              subtitle: Text(_fileTransferService.getSavePath() ?? '未设置'),
              onTap: () async {
                // TODO: Implement save path selection
              },
            ),
            ListTile(
              title: const Text('传输速度限制'),
              subtitle: const Text('不限制'),
              onTap: () {
                // TODO: Implement speed limit settings
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _pauseTransfer(String fileName) {
    try {
      _fileTransferService.pauseTransfer(fileName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pause transfer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectionStatus>(
      stream: _networkService.connectionStatus,
      builder: (context, snapshot) {
        final isConnected = snapshot.data == ConnectionStatus.connected;

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Connected Device Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D), // dark-200
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.computer,
                      color: Color(0xFF6366F1), // primary
                    ),
                    const SizedBox(width: 12),
                    const Text('王总的工作站'),
                    const SizedBox(width: 12),
                    Text(
                      isConnected ? '已连接' : '未连接',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: _showSettings,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Drag Drop Zone
              Expanded(
                child: DragTarget<String>(
                  onWillAccept: (data) => isConnected,
                  onAccept: _handleDroppedFile,
                  builder: (context, candidateData, rejectedData) {
                    return DottedBorder(
                      color: const Color(0xFF3D3D3D), // dark-300
                      strokeWidth: 2,
                      borderType: BorderType.RRect,
                      radius: const Radius.circular(8),
                      padding: EdgeInsets.zero,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload,
                              size: 48,
                              color: isConnected
                                  ? const Color(0xFF6366F1)
                                  : Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isConnected
                                  ? '拖拽文件到此处，或点击选择文件'
                                  : '请先连接设备',
                              style: TextStyle(
                                color: isConnected ? null : Colors.grey,
                              ),
                            ),
                            if (isConnected) ...[
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _pickAndSendFile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('选择文件'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Transfer List
              ..._transfers.map((transfer) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D3D3D), // dark-300
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getFileIcon(transfer.fileName),
                            color: _getFileIconColor(transfer.fileName),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  transfer.fileName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _formatFileSize(transfer.fileSize),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (transfer.status == 'transferring') ...[
                            Text(
                              '${_formatFileSize(_fileTransferService.getCurrentSpeed())}/s',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.pause),
                              onPressed: () => _pauseTransfer(transfer.fileName),
                              color: Colors.grey,
                            ),
                          ],
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => _fileTransferService.cancelTransfer(transfer.fileName),
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: transfer.progress,
                          backgroundColor: const Color(0xFF1E1E1E), // dark-100
                          valueColor: AlwaysStoppedAnimation<Color>(
                            transfer.status == 'transferring'
                                ? const Color(0xFF6366F1)
                                : Colors.grey,
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              )).toList(),
            ],
          ),
        );
      },
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileIconColor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.blue;
      case 'doc':
      case 'docx':
        return Colors.lightBlue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatFileSize(num bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
} 