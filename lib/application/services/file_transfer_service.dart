import 'dart:async';
import '../models/file_transfer_model.dart';

/// 文件传输服务接口
abstract class FileTransferService {
  /// 发送文件
  ///
  /// [filePath] 要发送的文件路径
  /// 返回传输ID
  Future<String> sendFile(String filePath);

  /// 发送文件夹
  ///
  /// [directoryPath] 要发送的文件夹路径
  /// 返回传输ID列表
  Future<List<String>> sendDirectory(String directoryPath);

  /// 取消文件传输
  ///
  /// [transferId] 传输ID
  Future<void> cancelFileTransfer(String transferId);

  /// 暂停文件传输
  ///
  /// [transferId] 传输ID
  Future<void> pauseFileTransfer(String transferId);

  /// 恢复文件传输
  ///
  /// [transferId] 传输ID
  Future<void> resumeFileTransfer(String transferId);

  /// 获取文件传输状态流
  ///
  /// 返回文件传输状态流
  Stream<FileTransferModel> get fileTransferStream;

  /// 获取当前活跃的文件传输
  ///
  /// 返回当前活跃的文件传输列表
  List<FileTransferModel> getActiveFileTransfers();

  /// 获取指定ID的文件传输
  ///
  /// [transferId] 传输ID
  /// 返回指定ID的文件传输，如果不存在则返回null
  FileTransferModel? getFileTransfer(String transferId);

  /// 设置文件接收目录
  ///
  /// [directory] 接收目录路径
  Future<void> setReceiveDirectory(String directory);

  /// 获取文件接收目录
  ///
  /// 返回当前的文件接收目录路径
  String getReceiveDirectory();
}
