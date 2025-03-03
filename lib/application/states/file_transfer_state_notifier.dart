import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../models/file_transfer_model.dart';
import '../services/file_transfer_service.dart';

/// 文件传输状态管理类
class FileTransferStateNotifier extends ChangeNotifier {
  /// 日志记录器
  final _logger = Logger('FileTransferStateNotifier');

  /// 文件传输服务
  final FileTransferService _fileTransferService;

  /// 当前活跃的文件传输
  List<FileTransferModel> _activeFileTransfers = [];

  /// 当前选中的文件传输
  FileTransferModel? _selectedFileTransfer;

  /// 文件传输流订阅
  StreamSubscription<FileTransferModel>? _fileTransferSubscription;

  /// 构造函数
  FileTransferStateNotifier({
    required FileTransferService fileTransferService,
  }) : _fileTransferService = fileTransferService {
    _init();
  }

  /// 获取当前活跃的文件传输
  List<FileTransferModel> get activeFileTransfers => _activeFileTransfers;

  /// 获取当前选中的文件传输
  FileTransferModel? get selectedFileTransfer => _selectedFileTransfer;

  /// 获取文件接收目录
  String get receiveDirectory => _fileTransferService.getReceiveDirectory();

  /// 初始化
  void _init() {
    // 获取当前活跃的文件传输
    _activeFileTransfers = _fileTransferService.getActiveFileTransfers();

    // 订阅文件传输状态变化
    _fileTransferSubscription = _fileTransferService.fileTransferStream
        .listen(_handleFileTransferUpdate);
  }

  /// 处理文件传输状态更新
  void _handleFileTransferUpdate(FileTransferModel fileTransfer) {
    // 更新活跃文件传输列表
    final index = _activeFileTransfers
        .indexWhere((t) => t.transferId == fileTransfer.transferId);
    if (index >= 0) {
      _activeFileTransfers[index] = fileTransfer;
    } else {
      _activeFileTransfers.add(fileTransfer);
    }

    // 如果当前选中的文件传输被更新，也更新选中的文件传输
    if (_selectedFileTransfer?.transferId == fileTransfer.transferId) {
      _selectedFileTransfer = fileTransfer;
    }

    notifyListeners();
  }

  /// 发送文件
  Future<void> sendFile(String filePath) async {
    try {
      await _fileTransferService.sendFile(filePath);
    } catch (e) {
      _logger.severe('发送文件失败: $e');
      rethrow;
    }
  }

  /// 发送文件夹
  Future<void> sendDirectory(String directoryPath) async {
    try {
      await _fileTransferService.sendDirectory(directoryPath);
    } catch (e) {
      _logger.severe('发送文件夹失败: $e');
      rethrow;
    }
  }

  /// 取消文件传输
  Future<void> cancelFileTransfer(String transferId) async {
    try {
      await _fileTransferService.cancelFileTransfer(transferId);
    } catch (e) {
      _logger.severe('取消文件传输失败: $e');
      rethrow;
    }
  }

  /// 暂停文件传输
  Future<void> pauseFileTransfer(String transferId) async {
    try {
      await _fileTransferService.pauseFileTransfer(transferId);
    } catch (e) {
      _logger.severe('暂停文件传输失败: $e');
      rethrow;
    }
  }

  /// 恢复文件传输
  Future<void> resumeFileTransfer(String transferId) async {
    try {
      await _fileTransferService.resumeFileTransfer(transferId);
    } catch (e) {
      _logger.severe('恢复文件传输失败: $e');
      rethrow;
    }
  }

  /// 选择文件传输
  void selectFileTransfer(String transferId) {
    _selectedFileTransfer = _fileTransferService.getFileTransfer(transferId);
    notifyListeners();
  }

  /// 清除选中的文件传输
  void clearSelectedFileTransfer() {
    _selectedFileTransfer = null;
    notifyListeners();
  }

  /// 设置文件接收目录
  Future<void> setReceiveDirectory(String directory) async {
    try {
      await _fileTransferService.setReceiveDirectory(directory);
      notifyListeners();
    } catch (e) {
      _logger.severe('设置文件接收目录失败: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _fileTransferSubscription?.cancel();
    super.dispose();
  }
}
