import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bifrost_transfer/ui/widgets/connection_request_dialog.dart';

void main() {
  // 测试连接请求对话框
  group('ConnectionRequestDialog', () {
    testWidgets('应正确显示发起方信息和配对码', (WidgetTester tester) async {
      // 安排测试数据
      const initiatorIp = '192.168.1.101';
      const initiatorName = 'Test Device';
      const pairingCode = '123456';
      bool acceptCalled = false;
      bool rejectCalled = false;
      
      // 构建对话框
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionRequestDialog(
              initiatorIp: initiatorIp,
              initiatorName: initiatorName,
              pairingCode: pairingCode,
              onAccept: () {
                acceptCalled = true;
              },
              onReject: () {
                rejectCalled = true;
              },
            ),
          ),
        ),
      );
      
      // 验证对话框标题
      expect(find.text('收到连接请求'), findsOneWidget);
      
      // 验证发起方信息
      expect(find.text('设备 "Test Device" (192.168.1.101) 请求连接到您的设备。'), findsOneWidget);
      
      // 验证配对码
      expect(find.text('配对码'), findsOneWidget);
      expect(find.text('123456'), findsOneWidget);
      
      // 验证按钮
      expect(find.text('接受'), findsOneWidget);
      expect(find.text('拒绝'), findsOneWidget);
    });
    
    testWidgets('点击接受按钮应调用onAccept回调', (WidgetTester tester) async {
      // 安排测试数据
      const initiatorIp = '192.168.1.101';
      const initiatorName = 'Test Device';
      const pairingCode = '123456';
      bool acceptCalled = false;
      bool rejectCalled = false;
      
      // 构建对话框
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionRequestDialog(
              initiatorIp: initiatorIp,
              initiatorName: initiatorName,
              pairingCode: pairingCode,
              onAccept: () {
                acceptCalled = true;
              },
              onReject: () {
                rejectCalled = true;
              },
            ),
          ),
        ),
      );
      
      // 点击接受按钮
      await tester.tap(find.text('接受'));
      await tester.pump();
      
      // 验证按钮状态变化
      expect(find.text('正在连接...'), findsOneWidget);
      
      // 等待动画完成
      await tester.pump(const Duration(milliseconds: 600));
      
      // 验证回调被调用
      expect(acceptCalled, true);
      expect(rejectCalled, false);
    });
    
    testWidgets('点击拒绝按钮应调用onReject回调', (WidgetTester tester) async {
      // 安排测试数据
      const initiatorIp = '192.168.1.101';
      const initiatorName = 'Test Device';
      const pairingCode = '123456';
      bool acceptCalled = false;
      bool rejectCalled = false;
      
      // 构建对话框
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionRequestDialog(
              initiatorIp: initiatorIp,
              initiatorName: initiatorName,
              pairingCode: pairingCode,
              onAccept: () {
                acceptCalled = true;
              },
              onReject: () {
                rejectCalled = true;
              },
            ),
          ),
        ),
      );
      
      // 点击拒绝按钮
      await tester.tap(find.text('拒绝'));
      await tester.pump();
      
      // 验证按钮状态变化
      expect(find.text('正在拒绝...'), findsOneWidget);
      
      // 等待动画完成
      await tester.pump(const Duration(milliseconds: 400));
      
      // 验证回调被调用
      expect(acceptCalled, false);
      expect(rejectCalled, true);
    });
    
    testWidgets('按钮在处理中应被禁用', (WidgetTester tester) async {
      // 安排测试数据
      const initiatorIp = '192.168.1.101';
      const initiatorName = 'Test Device';
      const pairingCode = '123456';
      
      // 构建对话框
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionRequestDialog(
              initiatorIp: initiatorIp,
              initiatorName: initiatorName,
              pairingCode: pairingCode,
              onAccept: () {},
              onReject: () {},
            ),
          ),
        ),
      );
      
      // 点击接受按钮
      await tester.tap(find.text('接受'));
      await tester.pump();
      
      // 验证拒绝按钮被禁用
      final rejectButton = tester.widget<TextButton>(find.byType(TextButton));
      expect(rejectButton.onPressed, isNull);
      
      // 验证接受按钮被禁用
      final acceptButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(acceptButton.onPressed, isNull);
    });
  });
} 