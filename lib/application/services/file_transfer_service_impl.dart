import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import '../models/file_transfer_model.dart';
import '../models/socket_message_model.dart';
import '../models/connection_status.dart';
import 'file_transfer_service.dart';
import 'socket_communication_service.dart';

/// 文件传输服务实现类
class FileTransferServiceImpl implements FileTransferService {
  /// 日志记录器
  final _logger = Logger('FileTransferServiceImpl');

  /// Socket通信服务
  final SocketCommunicationService _socketService;

  /// 活动的文件传输
  final Map<String, FileTransferModel> _activeTransfers = {};

  /// 文件传输流控制器
  final _transferController = StreamController<FileTransferModel>.broadcast();

  /// 接收文件的目录
  String _receiveDirectory = '${Platform.environment['HOME']}/Downloads';

  /// 消息订阅
  late final StreamSubscription<SocketMessageModel> _messageSubscription;

  /// 连接状态订阅
  late final StreamSubscription<ConnectionStatus> _connectionStatusSubscription;

  /// 构造函数
  FileTransferServiceImpl(SocketCommunicationService socketService)
      : _socketService = socketService {
    _messageSubscription = _socketService.messageStream.listen(_handleMessage);
    _connectionStatusSubscription = _socketService.connectionStatusStream
        .listen(_handleConnectionStatusChange);
  }

  /// 初始化接收目录
  void _initReceiveDirectory() {
    final homeDir =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    _receiveDirectory = path.join(homeDir ?? '', 'Downloads', 'Bifrost');
    Directory(_receiveDirectory).createSync(recursive: true);
  }

  @override
  Future<String> sendFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw FileSystemException('文件不存在', filePath);
    }

    final fileName = path.basename(filePath);
    final fileSize = await file.length();
    final fileHash = await _calculateFileHash(file);
    final transferId = DateTime.now().millisecondsSinceEpoch.toString();

    // 创建文件传输请求消息
    final message = SocketMessageModel.createFileTransferRequest(
      fileName: fileName,
      fileSize: fileSize,
      fileHash: fileHash,
      filePath: filePath,
    );

    // 创建文件传输模型
    final fileTransfer = FileTransferModel(
      transferId: transferId,
      fileName: fileName,
      filePath: filePath,
      fileSize: fileSize,
      fileHash: fileHash,
      status: FileTransferStatus.waiting,
      direction: FileTransferDirection.sending,
    );

    // 添加到活跃传输列表
    _activeTransfers[transferId] = fileTransfer;
    _notifyFileTransferUpdate(fileTransfer);

    try {
      // 发送请求
      await _socketService.sendMessage(message);

      return transferId;
    } catch (e) {
      // 更新状态为失败
      final failedTransfer = fileTransfer.copyWith(
        status: FileTransferStatus.failed,
        errorMessage: e.toString(),
        endTime: DateTime.now(),
      );
      _activeTransfers[transferId] = failedTransfer;
      _notifyFileTransferUpdate(failedTransfer);

      _logger.severe('发送文件失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> sendDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!directory.existsSync()) {
      throw FileSystemException('目录不存在', directoryPath);
    }

    final transferIds = <String>[];
    await for (final file in directory.list(recursive: true)) {
      if (file is File) {
        final transferId = await sendFile(file.path);
        transferIds.add(transferId);
      }
    }

    return transferIds;
  }

  @override
  Future<void> cancelFileTransfer(String transferId) async {
    final fileTransfer = _activeTransfers[transferId];
    if (fileTransfer == null) {
      _logger.warning('尝试取消不存在的文件传输: $transferId');
      return;
    }

    try {
      // 发送取消消息
      final message = SocketMessageModel.createFileTransferCancel(
        fileName: fileTransfer.fileName,
        reason: '用户取消',
      );
      await _socketService.sendMessage(message);

      // 更新状态为已取消
      final cancelledTransfer = fileTransfer.copyWith(
        status: FileTransferStatus.cancelled,
        endTime: DateTime.now(),
      );
      _activeTransfers[transferId] = cancelledTransfer;
      _notifyFileTransferUpdate(cancelledTransfer);
    } catch (e) {
      _logger.severe('取消文件传输失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> pauseFileTransfer(String transferId) async {
    // TODO: 实现文件传输暂停功能
    throw UnimplementedError('暂停文件传输功能尚未实现');
  }

  @override
  Future<void> resumeFileTransfer(String transferId) async {
    // TODO: 实现文件传输恢复功能
    throw UnimplementedError('恢复文件传输功能尚未实现');
  }

  @override
  Stream<FileTransferModel> get fileTransferStream =>
      _transferController.stream;

  @override
  List<FileTransferModel> getActiveFileTransfers() {
    return _activeTransfers.values.toList();
  }

  @override
  FileTransferModel? getFileTransfer(String transferId) {
    return _activeTransfers[transferId];
  }

  @override
  Future<void> setReceiveDirectory(String directory) async {
    final dir = Directory(directory);
    if (!dir.existsSync()) {
      throw FileSystemException('目录不存在', directory);
    }
    _receiveDirectory = directory;
  }

  @override
  String getReceiveDirectory() {
    return _receiveDirectory;
  }

  /// 处理接收到的消息
  void _handleMessage(SocketMessageModel message) {
    switch (message.type) {
      case SocketMessageType.FILE_TRANSFER_REQUEST:
        _handleFileTransferRequest(message.data);
        break;
      case SocketMessageType.FILE_TRANSFER_RESPONSE:
        _handleFileTransferResponse(message.data);
        break;
      case SocketMessageType.FILE_TRANSFER_PROGRESS:
        _handleFileTransferProgress(message.data);
        break;
      case SocketMessageType.FILE_TRANSFER_COMPLETE:
        _handleFileTransferComplete(message.data);
        break;
      case SocketMessageType.FILE_TRANSFER_CANCEL:
        _handleFileTransferCancel(message.data);
        break;
      case SocketMessageType.FILE_TRANSFER_ERROR:
        _handleFileTransferError(message.data);
        break;
      default:
        // 忽略其他类型的消息
        break;
    }
  }

  /// 处理文件传输请求
  void _handleFileTransferRequest(Map<String, dynamic> data) async {
    final fileName = data['fileName'] as String;
    final fileSize = data['fileSize'] as int;
    final fileHash = data['fileHash'] as String;
    final filePath = path.join(_receiveDirectory, fileName);
    final transferId = DateTime.now().millisecondsSinceEpoch.toString();

    // 创建文件传输模型
    final fileTransfer = FileTransferModel(
      transferId: transferId,
      fileName: fileName,
      filePath: filePath,
      fileSize: fileSize,
      fileHash: fileHash,
      status: FileTransferStatus.waiting,
      direction: FileTransferDirection.receiving,
    );

    // 添加到活跃传输列表
    _activeTransfers[transferId] = fileTransfer;
    _notifyFileTransferUpdate(fileTransfer);

    // 自动接受文件传输请求
    _acceptFileTransfer(transferId);
  }

  /// 接受文件传输请求
  Future<void> _acceptFileTransfer(String transferId) async {
    final fileTransfer = _activeTransfers[transferId];
    if (fileTransfer == null) return;

    try {
      // 发送接受响应
      final responseMessage = SocketMessageModel.createFileTransferResponse(
        accepted: true,
        fileName: fileTransfer.fileName,
      );
      await _socketService.sendMessage(responseMessage);

      // 更新状态为传输中
      final updatedTransfer = fileTransfer.copyWith(
        status: FileTransferStatus.transferring,
      );
      _activeTransfers[transferId] = updatedTransfer;
      _notifyFileTransferUpdate(updatedTransfer);
    } catch (e) {
      _logger.severe('接受文件传输失败: $e');

      // 更新状态为失败
      final failedTransfer = fileTransfer.copyWith(
        status: FileTransferStatus.failed,
        errorMessage: e.toString(),
        endTime: DateTime.now(),
      );
      _activeTransfers[transferId] = failedTransfer;
      _notifyFileTransferUpdate(failedTransfer);
    }
  }

  /// 处理文件传输响应
  void _handleFileTransferResponse(Map<String, dynamic> data) {
    final fileName = data['fileName'] as String;
    final accepted = data['accepted'] as bool;
    final rejectReason = data['rejectReason'] as String?;

    final fileTransfer = _activeTransfers.values.firstWhere(
      (transfer) => transfer.fileName == fileName,
      orElse: () => throw Exception('未找到对应的文件传输：$fileName'),
    );

    if (accepted) {
      // 开始传输文件数据
      _startFileTransfer(fileTransfer.transferId);
    } else {
      // 更新状态为失败
      final failedTransfer = fileTransfer.copyWith(
        status: FileTransferStatus.failed,
        errorMessage: rejectReason ?? '接收方拒绝接收文件',
        endTime: DateTime.now(),
      );
      _activeTransfers[fileTransfer.transferId] = failedTransfer;
      _notifyFileTransferUpdate(failedTransfer);
    }
  }

  /// 开始文件传输
  Future<void> _startFileTransfer(String transferId) async {
    final fileTransfer = _activeTransfers[transferId];
    if (fileTransfer == null) return;

    try {
      final file = File(fileTransfer.filePath);
      final fileStream = file.openRead();
      final chunkSize = 1024 * 1024; // 1MB
      var bytesTransferred = 0;
      var startTime = DateTime.now();

      await for (final chunk in fileStream.transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (data, sink) {
            if (data.length > chunkSize) {
              var offset = 0;
              while (offset < data.length) {
                final end = (offset + chunkSize) < data.length
                    ? offset + chunkSize
                    : data.length;
                sink.add(data.sublist(offset, end));
                offset = end;
              }
            } else {
              sink.add(data);
            }
          },
        ),
      )) {
        // 发送文件数据块
        // TODO: 实现文件数据传输

        // 更新传输进度
        bytesTransferred += chunk.length;
        final now = DateTime.now();
        final duration = now.difference(startTime).inSeconds;
        final speed =
            duration > 0 ? (bytesTransferred / duration).toDouble() : 0.0;

        final updatedTransfer = fileTransfer.copyWith(
          bytesTransferred: bytesTransferred,
          transferSpeed: speed,
        );
        _activeTransfers[transferId] = updatedTransfer;
        _notifyFileTransferUpdate(updatedTransfer);

        // 发送进度消息
        final progressMessage = SocketMessageModel.createFileTransferProgress(
          fileName: fileTransfer.fileName,
          bytesTransferred: bytesTransferred,
          totalBytes: fileTransfer.fileSize,
          progress: updatedTransfer.progress,
        );
        await _socketService.sendMessage(progressMessage);
      }

      // 发送传输完成消息
      final completeMessage = SocketMessageModel.createFileTransferComplete(
        fileName: fileTransfer.fileName,
        filePath: fileTransfer.filePath,
      );
      await _socketService.sendMessage(completeMessage);

      // 更新状态为已完成
      final completedTransfer = fileTransfer.copyWith(
        status: FileTransferStatus.completed,
        bytesTransferred: fileTransfer.fileSize,
        endTime: DateTime.now(),
      );
      _activeTransfers[transferId] = completedTransfer;
      _notifyFileTransferUpdate(completedTransfer);
    } catch (e) {
      _logger.severe('文件传输失败: $e');

      // 更新状态为失败
      final failedTransfer = fileTransfer.copyWith(
        status: FileTransferStatus.failed,
        errorMessage: e.toString(),
        endTime: DateTime.now(),
      );
      _activeTransfers[transferId] = failedTransfer;
      _notifyFileTransferUpdate(failedTransfer);

      // 发送错误消息
      final errorMessage = SocketMessageModel.createFileTransferErrorMessage(
        transferId: transferId,
        errorMessage: e.toString(),
      );
      await _socketService.sendMessage(errorMessage);
    }
  }

  /// 处理文件传输进度
  void _handleFileTransferProgress(Map<String, dynamic> data) {
    final fileName = data['fileName'] as String;
    final bytesTransferred = data['bytesTransferred'] as int;
    final totalBytes = data['totalBytes'] as int;
    final progress = data['progress'] as double;

    final fileTransfer = _activeTransfers.values.firstWhere(
      (transfer) => transfer.fileName == fileName,
      orElse: () => throw Exception('未找到对应的文件传输：$fileName'),
    );

    // 更新进度
    final now = DateTime.now();
    final duration = now.difference(fileTransfer.startTime).inSeconds;
    final speed = duration > 0 ? (bytesTransferred / duration).toDouble() : 0.0;

    final updatedTransfer = fileTransfer.copyWith(
      bytesTransferred: bytesTransferred,
      fileSize: totalBytes,
      transferSpeed: speed,
    );
    _activeTransfers[fileTransfer.transferId] = updatedTransfer;
    _notifyFileTransferUpdate(updatedTransfer);
  }

  /// 处理文件传输完成
  void _handleFileTransferComplete(Map<String, dynamic> data) {
    final fileName = data['fileName'] as String;
    final filePath = data['filePath'] as String;

    final fileTransfer = _activeTransfers.values.firstWhere(
      (transfer) => transfer.fileName == fileName,
      orElse: () => throw Exception('未找到对应的文件传输：$fileName'),
    );

    // 更新状态为已完成
    final completedTransfer = fileTransfer.copyWith(
      status: FileTransferStatus.completed,
      bytesTransferred: fileTransfer.fileSize,
      endTime: DateTime.now(),
    );
    _activeTransfers[fileTransfer.transferId] = completedTransfer;
    _notifyFileTransferUpdate(completedTransfer);
  }

  /// 处理文件传输取消
  void _handleFileTransferCancel(Map<String, dynamic> data) {
    final fileName = data['fileName'] as String;
    final reason = data['reason'] as String;

    final fileTransfer = _activeTransfers.values.firstWhere(
      (transfer) => transfer.fileName == fileName,
      orElse: () => throw Exception('未找到对应的文件传输：$fileName'),
    );

    // 更新状态为已取消
    final cancelledTransfer = fileTransfer.copyWith(
      status: FileTransferStatus.cancelled,
      errorMessage: reason,
      endTime: DateTime.now(),
    );
    _activeTransfers[fileTransfer.transferId] = cancelledTransfer;
    _notifyFileTransferUpdate(cancelledTransfer);
  }

  /// 处理文件传输错误
  void _handleFileTransferError(Map<String, dynamic> data) {
    final transferId = data['transferId'] as String;
    final errorMessage = data['errorMessage'] as String;

    final fileTransfer = _activeTransfers[transferId];
    if (fileTransfer == null) {
      _logger.warning('收到未知文件传输的错误消息: $transferId');
      return;
    }

    // 更新状态为失败
    final failedTransfer = fileTransfer.copyWith(
      status: FileTransferStatus.failed,
      errorMessage: errorMessage,
      endTime: DateTime.now(),
    );
    _activeTransfers[transferId] = failedTransfer;
    _notifyFileTransferUpdate(failedTransfer);
  }

  /// 处理连接状态变化
  void _handleConnectionStatusChange(ConnectionStatus status) {
    if (status == ConnectionStatus.disconnected) {
      // 当连接断开时，更新所有活跃传输的状态
      for (final transfer in _activeTransfers.values) {
        if (transfer.status == FileTransferStatus.transferring ||
            transfer.status == FileTransferStatus.waiting) {
          final updatedTransfer = transfer.copyWith(
            status: FileTransferStatus.failed,
            errorMessage: '连接断开',
            endTime: DateTime.now(),
          );
          _activeTransfers[transfer.transferId] = updatedTransfer;
          _notifyFileTransferUpdate(updatedTransfer);
        }
      }
    }
  }

  /// 计算文件哈希值
  Future<String> _calculateFileHash(File file) async {
    final digest = await file.openRead().transform(sha256).single;
    return base64.encode(digest.bytes);
  }

  /// 通知文件传输状态更新
  void _notifyFileTransferUpdate(FileTransferModel fileTransfer) {
    _transferController.add(fileTransfer);
  }

  /// 释放资源
  void dispose() {
    _messageSubscription.cancel();
    _transferController.close();
  }
}
