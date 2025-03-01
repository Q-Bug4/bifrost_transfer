import 'dart:async';
import '../models/text_transfer_model.dart';

/// 文本传输服务接口
abstract class TextTransferService {
  /// 发送文本
  ///
  /// [text] 要发送的文本内容
  /// 返回传输ID
  Future<String> sendText(String text);

  /// 取消文本传输
  ///
  /// [transferId] 传输ID
  Future<void> cancelTextTransfer(String transferId);

  /// 获取文本传输状态流
  ///
  /// 返回文本传输状态流
  Stream<TextTransferModel> get textTransferStream;

  /// 获取当前活跃的文本传输
  ///
  /// 返回当前活跃的文本传输列表
  List<TextTransferModel> getActiveTextTransfers();

  /// 获取指定ID的文本传输
  ///
  /// [transferId] 传输ID
  /// 返回指定ID的文本传输，如果不存在则返回null
  TextTransferModel? getTextTransfer(String transferId);
}
