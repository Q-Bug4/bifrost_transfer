import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:bifrost_transfer/ui/widgets/text_transfer/text_input_widget.dart';
import 'package:bifrost_transfer/application/states/text_transfer_state_notifier.dart';
import 'package:bifrost_transfer/application/models/text_transfer_model.dart';
import '../../../mocks/mock_text_transfer_service.mocks.dart';

void main() {
  group('TextInputWidget', () {
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
    });

    tearDown(() {
      textTransferStreamController.close();
    });

    testWidgets('应正确显示初始UI', (WidgetTester tester) async {
      // 构建组件
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TextTransferStateNotifier>.value(
            value: textTransferStateNotifier,
            child: const Scaffold(
              body: TextInputWidget(),
            ),
          ),
        ),
      );

      // 验证UI
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('请输入要发送的文本...'), findsOneWidget);
      expect(find.text('0 字节 | 0 行'), findsOneWidget);
      expect(find.text('发送'), findsOneWidget);

      // 验证发送按钮初始状态（应该被禁用，因为文本为空）
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('输入文本应更新状态', (WidgetTester tester) async {
      // 构建组件
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TextTransferStateNotifier>.value(
            value: textTransferStateNotifier,
            child: const Scaffold(
              body: TextInputWidget(),
            ),
          ),
        ),
      );

      // 输入文本
      await tester.enterText(find.byType(TextField), 'Hello, World!');
      await tester.pump();

      // 验证状态更新
      expect(textTransferStateNotifier.currentText, equals('Hello, World!'));
      expect(find.text('13 字节 | 1 行'), findsOneWidget);

      // 验证发送按钮状态（应该被启用）
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('输入超大文本应显示错误提示', (WidgetTester tester) async {
      // 构建组件
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TextTransferStateNotifier>.value(
            value: textTransferStateNotifier,
            child: const Scaffold(
              body: TextInputWidget(),
            ),
          ),
        ),
      );

      // 输入超大文本
      final largeText = 'A' * (32 * 1024 + 1);
      await tester.enterText(find.byType(TextField), largeText);
      await tester.pump();

      // 验证错误提示
      expect(find.text('文本超过32KB限制，请减少文本内容'), findsOneWidget);

      // 验证发送按钮状态（应该被禁用）
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('点击发送按钮应调用sendText', (WidgetTester tester) async {
      // 设置模拟返回值
      when(mockTextTransferService.sendText(any))
          .thenAnswer((_) async => 'test_id');

      // 构建组件
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TextTransferStateNotifier>.value(
            value: textTransferStateNotifier,
            child: const Scaffold(
              body: TextInputWidget(),
            ),
          ),
        ),
      );

      // 输入文本
      await tester.enterText(find.byType(TextField), 'Test Message');
      await tester.pump();

      // 点击发送按钮
      await tester.tap(find.text('发送'));
      await tester.pump();

      // 验证调用
      verify(mockTextTransferService.sendText('Test Message')).called(1);
    });

    testWidgets('发送成功应显示成功提示', (WidgetTester tester) async {
      // 设置模拟返回值
      when(mockTextTransferService.sendText(any))
          .thenAnswer((_) async => 'test_id');

      // 构建组件
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TextTransferStateNotifier>.value(
            value: textTransferStateNotifier,
            child: const Scaffold(
              body: TextInputWidget(),
            ),
          ),
        ),
      );

      // 输入文本
      await tester.enterText(find.byType(TextField), 'Test Message');
      await tester.pump();

      // 点击发送按钮
      await tester.tap(find.text('发送'));
      await tester.pumpAndSettle();

      // 验证成功提示
      expect(find.text('文本发送成功'), findsOneWidget);
    });

    testWidgets('发送失败应显示错误提示', (WidgetTester tester) async {
      // 设置模拟返回值
      when(mockTextTransferService.sendText(any)).thenThrow(Exception('测试错误'));

      // 构建组件
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TextTransferStateNotifier>.value(
            value: textTransferStateNotifier,
            child: const Scaffold(
              body: TextInputWidget(),
            ),
          ),
        ),
      );

      // 输入文本
      await tester.enterText(find.byType(TextField), 'Test Message');
      await tester.pump();

      // 点击发送按钮
      await tester.tap(find.text('发送'));
      await tester.pumpAndSettle();

      // 验证错误提示
      expect(find.text('文本发送失败: Exception: 测试错误'), findsOneWidget);
    });
  });
}
