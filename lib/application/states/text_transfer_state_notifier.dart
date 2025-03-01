import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../models/text_transfer_model.dart';
import '../services/text_transfer_service.dart';

/// 文本传输状态管理类
class TextTransferStateNotifier extends ChangeNotifier {
  /// 日志记录器
  final _logger = Logger('TextTransferStateNotifier');

  /// 文本传输服务
  final TextTransferService _textTransferService;

  /// 当前活跃的文本传输
  List<TextTransferModel> _activeTextTransfers = [];

  /// 当前选中的文本传输
  TextTransferModel? _selectedTextTransfer;

  /// 文本传输流订阅
  StreamSubscription<TextTransferModel>? _textTransferSubscription;

  /// 构造函数
  TextTransferStateNotifier({
    required TextTransferService textTransferService,
  }) : _textTransferService = textTransferService {
    _init();
  }

  /// 获取当前活跃的文本传输
  List<TextTransferModel> get activeTextTransfers => _activeTextTransfers;

  /// 获取当前选中的文本传输
  TextTransferModel? get selectedTextTransfer => _selectedTextTransfer;

  /// 获取当前输入的文本
  String _currentText = '';
  String get currentText => _currentText;

  /// 设置当前输入的文本
  set currentText(String value) {
    _currentText = value;
    notifyListeners();
  }

  /// 获取当前文本的字节大小
  int get currentTextSize => _currentText.length;

  /// 获取当前文本的行数
  int get currentTextLineCount =>
      _currentText.isEmpty ? 0 : '\n'.allMatches(_currentText).length + 1;

  /// 是否超过大小限制（32KB）
  bool get isTextSizeExceeded => currentTextSize > 32 * 1024;

  /// 初始化
  void _init() {
    // 获取当前活跃的文本传输
    _activeTextTransfers = _textTransferService.getActiveTextTransfers();

    // 订阅文本传输状态变化
    _textTransferSubscription = _textTransferService.textTransferStream
        .listen(_handleTextTransferUpdate);
  }

  /// 处理文本传输状态更新
  void _handleTextTransferUpdate(TextTransferModel textTransfer) {
    // 更新活跃文本传输列表
    final index = _activeTextTransfers
        .indexWhere((t) => t.transferId == textTransfer.transferId);
    if (index >= 0) {
      _activeTextTransfers[index] = textTransfer;
    } else {
      _activeTextTransfers.add(textTransfer);
    }

    // 如果当前选中的文本传输被更新，也更新选中的文本传输
    if (_selectedTextTransfer?.transferId == textTransfer.transferId) {
      _selectedTextTransfer = textTransfer;
    }

    notifyListeners();
  }

  /// 发送文本
  Future<void> sendText() async {
    if (_currentText.isEmpty) {
      throw Exception('文本内容不能为空');
    }

    if (isTextSizeExceeded) {
      throw Exception('文本内容过大，超过32KB限制');
    }

    try {
      await _textTransferService.sendText(_currentText);
      // 发送成功后清空当前文本
      _currentText = '';
      notifyListeners();
    } catch (e) {
      _logger.severe('发送文本失败: $e');
      rethrow;
    }
  }

  /// 取消文本传输
  Future<void> cancelTextTransfer(String transferId) async {
    try {
      await _textTransferService.cancelTextTransfer(transferId);
    } catch (e) {
      _logger.severe('取消文本传输失败: $e');
      rethrow;
    }
  }

  /// 选择文本传输
  void selectTextTransfer(String transferId) {
    _selectedTextTransfer = _textTransferService.getTextTransfer(transferId);
    notifyListeners();
  }

  /// 清除选中的文本传输
  void clearSelectedTextTransfer() {
    _selectedTextTransfer = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _textTransferSubscription?.cancel();
    super.dispose();
  }
}
