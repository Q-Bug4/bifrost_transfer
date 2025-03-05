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
  String? _receiveDirectory;

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
    _initReceiveDirectory();
  }

  /// 初始化接收目录
  Future<void> _initReceiveDirectory() async {
    if (_receiveDirectory == null || _receiveDirectory!.isEmpty) {
      final defaultDir = await _getDefaultReceiveDirectory();
      await setReceiveDirectory(defaultDir);
    }

    // 确保目录存在
    final dir = Directory(_receiveDirectory!);
    if (!dir.existsSync()) {
      _logger.info('创建接收目录: $_receiveDirectory');
      await dir.create(recursive: true);
      _logger.info('成功创建接收目录');
    }
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = bytes.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return '${size.toStringAsFixed(2)} ${units[unitIndex]}';
  }

  /// 格式化传输速度
  String _formatTransferSpeed(double bytesPerSecond) {
    if (bytesPerSecond < 0.1) return '0 B/s';
    return '${_formatFileSize(bytesPerSecond.toInt())}/s';
  }

  /// 格式化剩余时间
  String _formatRemainingTime(double seconds) {
    if (seconds < 0.1) return '0秒';
    if (seconds < 60) return '${seconds.toStringAsFixed(0)}秒';
    if (seconds < 3600) {
      final minutes = (seconds / 60).floor();
      final remainingSeconds = (seconds % 60).floor();
      return '$minutes分${remainingSeconds}秒';
    }
    final hours = (seconds / 3600).floor();
    final minutes = ((seconds % 3600) / 60).floor();
    return '$hours小时$minutes分';
  }

  @override
  Future<String> sendFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      const error = '文件不存在';
      _logger.severe('$error: $filePath');
      throw FileSystemException(error, filePath);
    }

    final fileName = path.basename(filePath);
    final fileSize = await file.length();
    final fileHash = await _calculateFileHash(file);
    final transferId = DateTime.now().millisecondsSinceEpoch.toString();

    _logger.info('准备发送文件: $fileName');
    _logger.info('- 文件大小: ${_formatFileSize(fileSize)}');
    _logger.info('- 文件路径: $filePath');
    _logger.info('- 文件哈希: $fileHash');
    _logger.info('- 传输ID: $transferId');

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
      _logger.fine('已发送文件传输请求: $transferId');

      return transferId;
    } catch (e) {
      _logger.severe('发送文件传输请求失败: $e');
      _logger.severe('- 文件名: ${fileTransfer.fileName}');
      _logger.severe('- 错误详情: ${e.toString()}');

      // 更新状态为失败
      final failedTransfer = fileTransfer.copyWith(
        status: FileTransferStatus.failed,
        errorMessage: e.toString(),
        endTime: DateTime.now(),
      );
      _activeTransfers[transferId] = failedTransfer;
      _notifyFileTransferUpdate(failedTransfer);

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
    final transfer = _activeTransfers[transferId];
    if (transfer == null) {
      throw Exception('传输不存在');
    }

    if (!_socketService.isConnected) {
      throw Exception('未连接到设备');
    }

    if (transfer.isCompleted || transfer.isCancelled) {
      throw Exception('传输已完成或已取消，无法恢复');
    }

    // 创建恢复传输消息
    final message = SocketMessageModel.createFileTransferResumeMessage(
      transferId: transferId,
      fileName: transfer.fileName,
      filePath: transfer.filePath,
      fileSize: transfer.fileSize,
      fileHash: transfer.fileHash,
      bytesTransferred: transfer.bytesTransferred,
    );

    try {
      await _socketService.sendMessage(message);

      // 更新传输状态
      final updatedTransfer = transfer.copyWith(
        status: FileTransferStatus.transferring,
      );
      _activeTransfers[transferId] = updatedTransfer;
      _notifyFileTransferUpdate(updatedTransfer);

      _logger.info('恢复文件传输: $transferId');
    } catch (e) {
      _logger.severe('恢复文件传输失败: $e');
      throw Exception('恢复文件传输失败: $e');
    }
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
    _logger.info('初始化接收目录: $directory');
    _receiveDirectory = directory;

    // 确保目录存在
    final dir = Directory(directory);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
      _logger.info('成功创建接收目录');
    }
  }

  @override
  String getReceiveDirectory() {
    return _receiveDirectory ?? '';
  }

  /// 处理接收到的消息
  void _handleMessage(SocketMessageModel message) {
    switch (message.type) {
      case SocketMessageType.FILE_TRANSFER_REQUEST:
        _handleFileTransferRequest(message);
        break;
      case SocketMessageType.FILE_TRANSFER_RESPONSE:
        _handleFileTransferResponse(message.data);
        break;
      case SocketMessageType.FILE_TRANSFER_DATA:
        _handleFileTransferData(message);
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
  Future<void> _handleFileTransferRequest(SocketMessageModel message) async {
    final fileName = message.data['fileName'] as String;
    final fileSize = message.data['fileSize'] as int;
    final fileHash = message.data['fileHash'] as String;
    final transferId = message.data['transferId'] as String;

    // 确保接收目录已初始化
    await _initReceiveDirectory();

    final filePath = '$_receiveDirectory/$fileName';
    _logger.info('收到文件传输请求:');
    _logger.info('- 文件名: $fileName');
    _logger.info('- 文件大小: ${_formatFileSize(fileSize)}');
    _logger.info('- 保存路径: $filePath');

    final transfer = FileTransferModel(
      transferId: transferId,
      fileName: fileName,
      filePath: filePath,
      fileSize: fileSize,
      fileHash: fileHash,
      direction: FileTransferDirection.receiving,
    );

    _activeTransfers[transferId] = transfer;
    _transferController.add(transfer);

    // 发送接受响应
    final response = SocketMessageModel.createFileTransferResponse(
      fileName: fileName,
      fileSize: fileSize,
      fileHash: fileHash,
      accepted: true,
    );
    final success = await _socketService.sendMessage(response);
    if (!success) {
      throw Exception('发送文件传输响应消息失败');
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

  /// 处理文件传输数据
  void _handleFileTransferData(SocketMessageModel message) {
    final transferId = message.data['transferId']?.toString();
    if (transferId == null) {
      _logger.warning('收到的文件数据中没有transferId');
      return;
    }
    final transfer = _activeTransfers[transferId];
    if (transfer == null) {
      _logger.warning('收到未知传输ID的文件数据: $transferId');
      return;
    }

    try {
      if (transfer.isReceiving) {
        final filePath = transfer.filePath;
        final file = File(filePath);
        final data = message.data['data'] as List<int>;

        // 确保目录存在
        final dir = file.parent;
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }

        // 写入文件数据
        file.writeAsBytesSync(data, mode: FileMode.write);

        _logger.info('接收文件数据: ${transfer.fileName}');
        _logger.info('保存到: ${transfer.filePath}');
      }

      // 更新传输进度
      final newBytesTransferred = transfer.bytesTransferred +
          (message.data['data'] as List<int>).length;
      final now = DateTime.now();
      final duration = now.difference(transfer.startTime).inSeconds;
      final speed = duration > 0 ? newBytesTransferred / duration : 0;

      final updatedTransfer = transfer.copyWith(
        bytesTransferred: newBytesTransferred,
        status: newBytesTransferred >= transfer.fileSize
            ? FileTransferStatus.completed
            : FileTransferStatus.transferring,
        transferSpeed: speed.toDouble(),
      );

      _activeTransfers[transferId] = updatedTransfer;
      _transferController.add(updatedTransfer);

      // 如果传输完成，发送完成消息
      if (updatedTransfer.isCompleted) {
        _handleFileTransferComplete({
          'transferId': transferId,
          'fileName': updatedTransfer.fileName,
        });
      }
    } catch (e) {
      _logger.severe('处理文件数据失败: $e');
      _handleTransferError(transferId, '文件写入失败: $e');
    }
  }

  /// 开始文件传输
  Future<void> _startFileTransfer(String transferId) async {
    final fileTransfer = _activeTransfers[transferId];
    if (fileTransfer == null) return;

    try {
      _logger.info('开始传输文件: ${fileTransfer.fileName}');
      _logger.info('- 文件大小: ${_formatFileSize(fileTransfer.fileSize)}');
      _logger.info(
          '- 传输方向: ${fileTransfer.direction == FileTransferDirection.sending ? '发送' : '接收'}');

      final file = File(fileTransfer.filePath);
      final fileStream = file.openRead();
      final chunkSize = 512 * 1024; // 512KB
      var bytesTransferred = 0;
      var startTime = DateTime.now();
      var lastProgressLogTime = startTime;

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
        final chunkMessage = SocketMessageModel.createFileTransferChunk(
          data: chunk,
        );
        await _socketService.sendMessage(chunkMessage);

        // 更新传输进度
        bytesTransferred += chunk.length;
        final now = DateTime.now();
        final duration = now.difference(startTime).inSeconds;
        final speed =
            duration > 0 ? (bytesTransferred / duration).toDouble() : 0.0;

        final updatedTransfer = fileTransfer.copyWith(
          bytesTransferred: bytesTransferred,
          transferSpeed: speed.toDouble(),
          status: FileTransferStatus.transferring,
        );
        _activeTransfers[transferId] = updatedTransfer;
        _notifyFileTransferUpdate(updatedTransfer);

        // 每秒最多记录一次进度日志
        if (now.difference(lastProgressLogTime).inSeconds >= 1) {
          final progress = (bytesTransferred / fileTransfer.fileSize * 100)
              .toStringAsFixed(1);
          final remainingBytes =
              (fileTransfer.fileSize - bytesTransferred).toDouble();
          final speedDouble = speed.toDouble();
          final remainingTime =
              speedDouble > 0 ? remainingBytes / speedDouble : 0.0;

          _logger.fine('文件传输进度:');
          _logger.fine('- 文件名: ${fileTransfer.fileName}');
          _logger.fine(
              '- 已传输: ${_formatFileSize(bytesTransferred)} / ${_formatFileSize(fileTransfer.fileSize)} ($progress%)');
          _logger.fine('- 传输速度: ${_formatTransferSpeed(speed)}');
          _logger.fine('- 预计剩余时间: ${_formatRemainingTime(remainingTime)}');

          lastProgressLogTime = now;
        }

        // 发送进度消息
        final progressMessage = SocketMessageModel.createFileTransferProgress(
          fileName: fileTransfer.fileName,
          bytesTransferred: bytesTransferred,
          totalBytes: fileTransfer.fileSize,
          progress: updatedTransfer.progress,
        );
        final success = await _socketService.sendMessage(progressMessage);
        if (!success) {
          throw Exception('发送文件传输进度消息失败');
        }
      }

      // 发送传输完成消息
      final completeMessage = SocketMessageModel.createFileTransferComplete(
        fileName: fileTransfer.fileName,
        filePath: fileTransfer.filePath,
        fileSize: fileTransfer.fileSize,
        fileHash: fileTransfer.fileHash,
      );
      final success = await _socketService.sendMessage(completeMessage);
      if (!success) {
        throw Exception('发送文件传输完成消息失败');
      }

      // 更新状态为已完成
      final completedTransfer = fileTransfer.copyWith(
        status: FileTransferStatus.completed,
        bytesTransferred: fileTransfer.fileSize,
        endTime: DateTime.now(),
      );
      _activeTransfers[transferId] = completedTransfer;
      _notifyFileTransferUpdate(completedTransfer);

      final duration =
          completedTransfer.endTime!.difference(startTime).inSeconds;
      final averageSpeed =
          duration > 0 ? (fileTransfer.fileSize / duration).toDouble() : 0.0;

      _logger.info('文件传输完成:');
      _logger.info('- 文件名: ${fileTransfer.fileName}');
      _logger.info('- 总大小: ${_formatFileSize(fileTransfer.fileSize)}');
      _logger.info('- 总用时: ${_formatRemainingTime(duration.toDouble())}');
      _logger.info('- 平均速度: ${_formatTransferSpeed(averageSpeed)}');
    } catch (e) {
      _logger.severe('文件传输失败:');
      _logger.severe('- 文件名: ${fileTransfer.fileName}');
      _logger.severe('- 错误信息: $e');

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
    final fileSize = data['fileSize'] as int;
    final fileHash = data['fileHash'] as String;

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

  /// 获取默认接收目录
  Future<String> _getDefaultReceiveDirectory() async {
    final homeDir =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    return '$homeDir/Downloads/Bifrost';
  }

  /// 处理文件传输错误
  void _handleTransferError(String transferId, String errorMessage) {
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
}
