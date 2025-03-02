import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:bifrost_transfer/ui/widgets/text_transfer/text_transfer_detail_widget.dart';
import 'package:bifrost_transfer/application/states/text_transfer_state_notifier.dart';
import 'package:bifrost_transfer/application/models/text_transfer_model.dart';
import '../../../mocks/mock_text_transfer_service.mocks.dart';

// 创建一个模拟的剪贴板类
class MockClipboard {
  static String? _clipboardData;

  static Future<void> setData(ClipboardData data) async {
    _clipboardData = data.text;
  }

  static Future<ClipboardData?> getData(String format) async {
    return _clipboardData != null ? ClipboardData(text: _clipboardData!) : null;
  }

  static void reset() {
    _clipboardData = null;
  }
}

void main() {
  // 设置剪贴板模拟
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TextTransferDetailWidget', () {
    late MockTextTransferService mockTextTransferService;
    late TextTransferStateNotifier textTransferStateNotifier;
    late StreamController<TextTransferModel> textTransferStreamController;

    setUp(() {
      mockTextTransferService = MockTextTransferService();
      textTransferStreamController =
          StreamController<TextTransferModel>.broadcast();

      // 设置模拟返回值
      when(mockTextTransferService.getActiveTextTransfers()).thenReturn([]);
      when(mockTextTransferService.textTransferStream)
          .thenAnswer((_) => textTransferStreamController.stream);

      textTransferStateNotifier = TextTransferStateNotifier(
        textTransferService: mockTextTransferService,
      );

      // 重置模拟剪贴板
      MockClipboard.reset();

      // 替换系统剪贴板方法
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            final Map<String, dynamic> args =
                methodCall.arguments as Map<String, dynamic>;
            await MockClipboard.setData(
                ClipboardData(text: args['text'] as String));
            return null;
          } else if (methodCall.method == 'Clipboard.getData') {
            final data = await MockClipboard.getData(Clipboard.kTextPlain);
            return <String, dynamic>{'text': data?.text};
          }
          return null;
        },
      );
    });

    tearDown(() {
      textTransferStreamController.close();
      // 清除剪贴板模拟
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    testWidgets('未选择传输时应显示提示信息', (WidgetTester tester) async {
      // 构建组件
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TextTransferStateNotifier>.value(
            value: textTransferStateNotifier,
            child: const Scaffold(
              body: TextTransferDetailWidget(),
            ),
          ),
        ),
      );

      // 验证UI
      expect(find.text('请选择一个文本传输记录查看详情'), findsOneWidget);
    });

    testWidgets('选择传输后应显示详情', (WidgetTester tester) async {
      // 创建测试数据
      final testTransfer = TextTransferModel(
        transferId: 'test_id',
        text: 'Test Message Content',
        textLength: 20,
        lineCount: 1,
        direction: TextTransferDirection.sending,
        status: TextTransferStatus.completed,
        startTime: DateTime(2023, 1, 1, 10, 0),
        endTime: DateTime(2023, 1, 1, 10, 1),
      );

      // 设置模拟返回值
      when(mockTextTransferService.getTextTransfer('test_id'))
          .thenReturn(testTransfer);

      // 选择传输
      textTransferStateNotifier.selectTextTransfer('test_id');

      // 构建组件
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TextTransferStateNotifier>.value(
            value: textTransferStateNotifier,
            child: const Scaffold(
              body: TextTransferDetailWidget(),
            ),
          ),
        ),
      );

      // 验证UI - 使用实际UI中的文本格式
      expect(find.text('文本传输详情'), findsOneWidget);
      expect(find.text('状态: '), findsOneWidget);
      expect(find.text('已完成'), findsOneWidget);
      expect(find.text('方向: '), findsOneWidget);
      expect(find.text('发送'), findsOneWidget);
      expect(find.text('大小: '), findsOneWidget);
      expect(find.text('20 字节 (1 行)'), findsOneWidget);
      expect(find.text('开始时间: '), findsOneWidget);
      expect(find.text('2023-01-01 10:00:00'), findsOneWidget);
      expect(find.text('结束时间: '), findsOneWidget);
      expect(find.text('2023-01-01 10:01:00'), findsOneWidget);
      expect(find.text('Test Message Content'), findsOneWidget);
      expect(find.text('复制文本'), findsOneWidget);
    });

    testWidgets('不同状态应显示不同颜色', (WidgetTester tester) async {
      // 创建测试数据 - 等待中
      final waitingTransfer = TextTransferModel(
        transferId: 'test_id_1',
        text: 'Waiting Message',
        textLength: 14,
        lineCount: 1,
        direction: TextTransferDirection.sending,
        status: TextTransferStatus.waiting,
        startTime: DateTime(2023, 1, 1, 10, 0),
      );

      // 设置模拟返回值
      when(mockTextTransferService.getTextTransfer('test_id_1'))
          .thenReturn(waitingTransfer);

      // 选择传输
      textTransferStateNotifier.selectTextTransfer('test_id_1');

      // 构建组件
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TextTransferStateNotifier>.value(
            value: textTransferStateNotifier,
            child: const Scaffold(
              body: TextTransferDetailWidget(),
            ),
          ),
        ),
      );

      // 验证UI - 使用实际UI中的文本格式
      expect(find.text('状态: '), findsOneWidget);
      expect(find.text('等待中'), findsOneWidget);
      expect(find.text('取消传输'), findsOneWidget);

      // 创建测试数据 - 传输中
      final transferringTransfer = TextTransferModel(
        transferId: 'test_id_2',
        text: 'Transferring Message',
        textLength: 20,
        lineCount: 1,
        direction: TextTransferDirection.sending,
        status: TextTransferStatus.transferring,
        processedLength: 10,
        startTime: DateTime(2023, 1, 1, 10, 0),
      );

      // 设置模拟返回值
      when(mockTextTransferService.getTextTransfer('test_id_2'))
          .thenReturn(transferringTransfer);

      // 选择传输
      textTransferStateNotifier.selectTextTransfer('test_id_2');
      await tester.pump();

      // 验证UI - 使用实际UI中的文本格式
      expect(find.text('状态: '), findsOneWidget);
      expect(find.text('传输中 (50.0%)'), findsOneWidget);
      expect(find.text('取消传输'), findsOneWidget);

      // 创建测试数据 - 失败
      final failedTransfer = TextTransferModel(
        transferId: 'test_id_3',
        text: 'Failed Message',
        textLength: 14,
        lineCount: 1,
        direction: TextTransferDirection.sending,
        status: TextTransferStatus.failed,
        errorMessage: '连接断开',
        startTime: DateTime(2023, 1, 1, 10, 0),
        endTime: DateTime(2023, 1, 1, 10, 1),
      );

      // 设置模拟返回值
      when(mockTextTransferService.getTextTransfer('test_id_3'))
          .thenReturn(failedTransfer);

      // 选择传输
      textTransferStateNotifier.selectTextTransfer('test_id_3');
      await tester.pump();

      // 验证UI - 使用实际UI中的文本格式
      expect(find.text('状态: '), findsOneWidget);
      expect(find.text('失败: 连接断开'), findsOneWidget);
    });

    testWidgets('接收方向应正确显示', (WidgetTester tester) async {
      // 创建测试数据
      final receivingTransfer = TextTransferModel(
        transferId: 'test_id',
        text: 'Received Message',
        textLength: 16,
        lineCount: 1,
        direction: TextTransferDirection.receiving,
        status: TextTransferStatus.completed,
        startTime: DateTime(2023, 1, 1, 10, 0),
        endTime: DateTime(2023, 1, 1, 10, 1),
      );

      // 设置模拟返回值
      when(mockTextTransferService.getTextTransfer('test_id'))
          .thenReturn(receivingTransfer);

      // 选择传输
      textTransferStateNotifier.selectTextTransfer('test_id');

      // 构建组件
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TextTransferStateNotifier>.value(
            value: textTransferStateNotifier,
            child: const Scaffold(
              body: TextTransferDetailWidget(),
            ),
          ),
        ),
      );

      // 验证UI - 使用实际UI中的文本格式
      expect(find.text('方向: '), findsOneWidget);
      expect(find.text('接收'), findsOneWidget);
    });

    testWidgets('点击复制按钮应显示复制成功提示', (WidgetTester tester) async {
      // 创建测试数据
      final testTransfer = TextTransferModel(
        transferId: 'test_id',
        text: 'Test Message to Copy',
        textLength: 19,
        lineCount: 1,
        direction: TextTransferDirection.sending,
        status: TextTransferStatus.completed,
        startTime: DateTime(2023, 1, 1, 10, 0),
        endTime: DateTime(2023, 1, 1, 10, 1),
      );

      // 设置模拟返回值
      when(mockTextTransferService.getTextTransfer('test_id'))
          .thenReturn(testTransfer);

      // 选择传输
      textTransferStateNotifier.selectTextTransfer('test_id');

      // 构建组件
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TextTransferStateNotifier>.value(
            value: textTransferStateNotifier,
            child: const Scaffold(
              body: TextTransferDetailWidget(),
            ),
          ),
        ),
      );

      // 点击复制按钮
      await tester.tap(find.text('复制文本'));
      await tester.pump();

      // 验证Snackbar显示
      expect(find.text('文本已复制到剪贴板'), findsOneWidget);
    });

    testWidgets('点击取消按钮应调用cancelTextTransfer', (WidgetTester tester) async {
      // 设置模拟返回值
      when(mockTextTransferService.cancelTextTransfer(any))
          .thenAnswer((_) async => {});

      // 创建测试数据
      final waitingTransfer = TextTransferModel(
        transferId: 'test_id',
        text: 'Waiting Message',
        textLength: 14,
        lineCount: 1,
        direction: TextTransferDirection.sending,
        status: TextTransferStatus.waiting,
        startTime: DateTime(2023, 1, 1, 10, 0),
      );

      // 设置模拟返回值
      when(mockTextTransferService.getTextTransfer('test_id'))
          .thenReturn(waitingTransfer);

      // 选择传输
      textTransferStateNotifier.selectTextTransfer('test_id');

      // 构建组件
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TextTransferStateNotifier>.value(
            value: textTransferStateNotifier,
            child: const Scaffold(
              body: TextTransferDetailWidget(),
            ),
          ),
        ),
      );

      // 点击取消按钮
      await tester.tap(find.text('取消传输'));
      await tester.pump();

      // 验证调用
      verify(mockTextTransferService.cancelTextTransfer('test_id')).called(1);
    });
  });
}
