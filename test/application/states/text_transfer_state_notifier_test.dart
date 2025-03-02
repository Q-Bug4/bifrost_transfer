import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:bifrost_transfer/application/states/text_transfer_state_notifier.dart';
import 'package:bifrost_transfer/application/models/text_transfer_model.dart';
import '../../mocks/mock_text_transfer_service.mocks.dart';

void main() {
  group('TextTransferStateNotifier', () {
    late MockTextTransferService mockTextTransferService;
    late TextTransferStateNotifier notifier;
    late StreamController<TextTransferModel> textTransferStreamController;

    setUp(() {
      mockTextTransferService = MockTextTransferService();
      textTransferStreamController =
          StreamController<TextTransferModel>.broadcast();

      // 设置模拟返回值
      when(mockTextTransferService.getActiveTextTransfers()).thenReturn([]);
      when(mockTextTransferService.textTransferStream)
          .thenAnswer((_) => textTransferStreamController.stream);

      notifier = TextTransferStateNotifier(
        textTransferService: mockTextTransferService,
      );
    });

    tearDown(() {
      textTransferStreamController.close();
    });

    test('初始状态应正确', () {
      // 验证初始状态
      expect(notifier.activeTextTransfers, isEmpty);
      expect(notifier.selectedTextTransfer, isNull);
      expect(notifier.currentText, isEmpty);
      expect(notifier.currentTextSize, equals(0));
      expect(notifier.currentTextLineCount, equals(0));
      expect(notifier.isTextSizeExceeded, isFalse);
    });

    test('设置currentText应正确更新状态', () {
      // 设置文本
      notifier.currentText = 'Hello, World!';

      // 验证状态
      expect(notifier.currentText, equals('Hello, World!'));
      expect(notifier.currentTextSize, equals(13));
      expect(notifier.currentTextLineCount, equals(1));
      expect(notifier.isTextSizeExceeded, isFalse);

      // 设置超大文本
      final largeText = 'A' * (32 * 1024 + 1);
      notifier.currentText = largeText;

      // 验证状态
      expect(notifier.currentText, equals(largeText));
      expect(notifier.currentTextSize, equals(32 * 1024 + 1));
      expect(notifier.isTextSizeExceeded, isTrue);
    });

    test('sendText应调用textTransferService.sendText', () async {
      // 设置模拟返回值
      when(mockTextTransferService.sendText(any))
          .thenAnswer((_) async => 'test_id');

      // 设置文本
      notifier.currentText = 'Test Message';

      // 调用sendText
      await notifier.sendText();

      // 验证调用
      verify(mockTextTransferService.sendText('Test Message')).called(1);

      // 验证文本被清空
      expect(notifier.currentText, isEmpty);
    });

    test('sendText应在文本为空时抛出异常', () async {
      // 设置空文本
      notifier.currentText = '';

      // 调用sendText应抛出异常
      expect(() => notifier.sendText(), throwsException);

      // 验证未调用服务
      verifyNever(mockTextTransferService.sendText(any));
    });

    test('sendText应在文本超过大小限制时抛出异常', () async {
      // 设置超大文本
      notifier.currentText = 'A' * (32 * 1024 + 1);

      // 调用sendText应抛出异常
      expect(() => notifier.sendText(), throwsException);

      // 验证未调用服务
      verifyNever(mockTextTransferService.sendText(any));
    });

    test('cancelTextTransfer应调用textTransferService.cancelTextTransfer',
        () async {
      // 设置模拟返回值
      when(mockTextTransferService.cancelTextTransfer(any))
          .thenAnswer((_) async => {});

      // 调用cancelTextTransfer
      await notifier.cancelTextTransfer('test_id');

      // 验证调用
      verify(mockTextTransferService.cancelTextTransfer('test_id')).called(1);
    });

    test('selectTextTransfer应正确更新selectedTextTransfer', () {
      // 创建测试数据
      final testTransfer = TextTransferModel(
        transferId: 'test_id',
        text: 'Test Message',
        textLength: 12,
        lineCount: 1,
        direction: TextTransferDirection.sending,
      );

      // 设置模拟返回值
      when(mockTextTransferService.getTextTransfer('test_id'))
          .thenReturn(testTransfer);

      // 调用selectTextTransfer
      notifier.selectTextTransfer('test_id');

      // 验证状态
      expect(notifier.selectedTextTransfer, equals(testTransfer));
    });

    test('clearSelectedTextTransfer应正确清除selectedTextTransfer', () {
      // 创建测试数据
      final testTransfer = TextTransferModel(
        transferId: 'test_id',
        text: 'Test Message',
        textLength: 12,
        lineCount: 1,
        direction: TextTransferDirection.sending,
      );

      // 设置模拟返回值
      when(mockTextTransferService.getTextTransfer('test_id'))
          .thenReturn(testTransfer);

      // 先选择一个传输
      notifier.selectTextTransfer('test_id');
      expect(notifier.selectedTextTransfer, isNotNull);

      // 清除选择
      notifier.clearSelectedTextTransfer();

      // 验证状态
      expect(notifier.selectedTextTransfer, isNull);
    });

    test('_handleTextTransferUpdate应正确更新activeTextTransfers', () async {
      // 创建测试数据
      final testTransfer = TextTransferModel(
        transferId: 'test_id',
        text: 'Test Message',
        textLength: 12,
        lineCount: 1,
        direction: TextTransferDirection.sending,
        status: TextTransferStatus.waiting,
        startTime: DateTime.now(),
      );

      // 模拟getActiveTextTransfers返回包含新传输的列表
      when(mockTextTransferService.getActiveTextTransfers())
          .thenReturn([testTransfer]);

      // 通过流发送更新
      textTransferStreamController.add(testTransfer);

      // 等待异步操作完成
      await Future.delayed(Duration.zero);

      // 验证状态
      expect(notifier.activeTextTransfers, contains(testTransfer));
    });
  });
}
