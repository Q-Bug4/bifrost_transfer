import 'package:bifrost_transfer/ui/widgets/connection_request_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('连接请求对话框关闭测试', () {
    testWidgets('点击接受按钮应关闭对话框并调用回调', (WidgetTester tester) async {
      bool acceptCalled = false;
      bool dialogClosed = false;

      // 构建一个简单的测试应用，只包含对话框
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => ConnectionRequestDialog(
                          initiatorIp: '192.168.1.100',
                          initiatorName: '测试设备',
                          pairingCode: '123456',
                          testMode: true, // 使用测试模式避免延迟
                          onAccept: () {
                            // 关闭对话框
                            Navigator.of(context).pop();
                            acceptCalled = true;
                          },
                          onReject: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ).then((_) {
                        dialogClosed = true;
                      });
                    },
                    child: const Text('显示对话框'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      // 点击按钮显示对话框
      await tester.tap(find.text('显示对话框'));
      await tester.pumpAndSettle();

      // 验证对话框显示
      expect(find.text('收到连接请求'), findsOneWidget);
      expect(find.text('设备 "测试设备" (192.168.1.100) 请求连接到您的设备。'), findsOneWidget);
      expect(find.text('请确认对方设备上显示的配对码与下方一致：'), findsOneWidget);
      expect(find.text('123456'), findsOneWidget);

      // 点击接受按钮
      await tester.tap(find.text('接受'));
      await tester.pumpAndSettle();

      // 验证对话框关闭
      expect(find.text('收到连接请求'), findsNothing);
      expect(acceptCalled, true);
      expect(dialogClosed, true);
    });

    testWidgets('点击拒绝按钮应关闭对话框并调用回调', (WidgetTester tester) async {
      bool rejectCalled = false;
      bool dialogClosed = false;

      // 构建一个简单的测试应用，只包含对话框
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => ConnectionRequestDialog(
                          initiatorIp: '192.168.1.100',
                          initiatorName: '测试设备',
                          pairingCode: '123456',
                          testMode: true, // 使用测试模式避免延迟
                          onAccept: () {
                            Navigator.of(context).pop();
                          },
                          onReject: () {
                            // 关闭对话框
                            Navigator.of(context).pop();
                            rejectCalled = true;
                          },
                        ),
                      ).then((_) {
                        dialogClosed = true;
                      });
                    },
                    child: const Text('显示对话框'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      // 点击按钮显示对话框
      await tester.tap(find.text('显示对话框'));
      await tester.pumpAndSettle();

      // 验证对话框显示
      expect(find.text('收到连接请求'), findsOneWidget);
      expect(find.text('设备 "测试设备" (192.168.1.100) 请求连接到您的设备。'), findsOneWidget);

      // 点击拒绝按钮
      await tester.tap(find.text('拒绝'));
      await tester.pumpAndSettle();

      // 验证对话框关闭
      expect(find.text('收到连接请求'), findsNothing);
      expect(rejectCalled, true);
      expect(dialogClosed, true);
    });
  });
}
