import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:bifrost_transfer/ui/widgets/connection_form_widget.dart';
import 'package:bifrost_transfer/application/states/connection_state_notifier.dart';
import 'package:bifrost_transfer/application/models/connection_model.dart';
import '../../mocks/mock_connection_state_notifier.mocks.dart';

void main() {
  group('ConnectionFormWidget', () {
    late MockConnectionStateNotifier mockConnectionStateNotifier;

    setUp(() {
      mockConnectionStateNotifier = MockConnectionStateNotifier();
    });

    testWidgets('初始状态应正确显示', (WidgetTester tester) async {
      // 设置初始状态
      when(mockConnectionStateNotifier.connectionState).thenReturn(
        ConnectionModel(status: ConnectionStatus.disconnected),
      );

      // 构建组件
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ConnectionStateNotifier>.value(
            value: mockConnectionStateNotifier,
            child: const Scaffold(
              body: ConnectionFormWidget(),
            ),
          ),
        ),
      );

      // 验证初始UI
      expect(find.text('连接到设备'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('连接'), findsOneWidget);
    });

    testWidgets('连接中状态应正确显示', (WidgetTester tester) async {
      // 设置初始状态
      when(mockConnectionStateNotifier.connectionState).thenReturn(
        ConnectionModel(
          status: ConnectionStatus.connecting,
          remoteIpAddress: '192.168.1.101',
        ),
      );

      // 构建组件
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ConnectionStateNotifier>.value(
            value: mockConnectionStateNotifier,
            child: const Scaffold(
              body: ConnectionFormWidget(),
            ),
          ),
        ),
      );

      // 验证连接中UI
      expect(find.text('正在连接到 192.168.1.101...'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
    });

    testWidgets('等待确认状态应显示配对码', (WidgetTester tester) async {
      // 设置初始状态
      when(mockConnectionStateNotifier.connectionState).thenReturn(
        ConnectionModel(
          status: ConnectionStatus.awaitingConfirmation,
          remoteIpAddress: '192.168.1.101',
          pairingCode: '123456',
        ),
      );

      // 构建组件
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ConnectionStateNotifier>.value(
            value: mockConnectionStateNotifier,
            child: const Scaffold(
              body: ConnectionFormWidget(),
            ),
          ),
        ),
      );

      // 验证等待确认UI
      expect(find.text('等待设备确认连接...'), findsOneWidget);
      expect(find.text('配对码: 123456'), findsOneWidget);
      expect(find.text('请确保目标设备上输入相同的配对码'), findsOneWidget);
    });

    testWidgets('已连接状态应正确显示', (WidgetTester tester) async {
      // 设置初始状态
      when(mockConnectionStateNotifier.connectionState).thenReturn(
        ConnectionModel(
          status: ConnectionStatus.connected,
          remoteIpAddress: '192.168.1.101',
          remoteDeviceName: 'Test Device',
        ),
      );

      // 构建组件
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ConnectionStateNotifier>.value(
            value: mockConnectionStateNotifier,
            child: const Scaffold(
              body: ConnectionFormWidget(),
            ),
          ),
        ),
      );

      // 验证已连接UI
      expect(find.text('已连接到 Test Device (192.168.1.101)'), findsOneWidget);
      expect(find.text('连接'), findsOneWidget); // 此时按钮文本仍为"连接"，但功能变为断开连接
    });

    testWidgets('连接失败状态应显示错误信息', (WidgetTester tester) async {
      // 设置初始状态
      when(mockConnectionStateNotifier.connectionState).thenReturn(
        ConnectionModel(status: ConnectionStatus.failed),
      );

      // 构建组件
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ConnectionStateNotifier>.value(
            value: mockConnectionStateNotifier,
            child: const Scaffold(
              body: ConnectionFormWidget(),
            ),
          ),
        ),
      );

      // 验证失败UI
      expect(find.text('连接失败'), findsOneWidget);
      expect(find.text('请检查IP地址是否正确，并确保目标设备已开启'), findsOneWidget);
    });

    testWidgets('点击连接按钮应调用initiateConnection', (WidgetTester tester) async {
      // 设置初始状态
      when(mockConnectionStateNotifier.connectionState).thenReturn(
        ConnectionModel(status: ConnectionStatus.disconnected),
      );
      when(mockConnectionStateNotifier.initiateConnection(any))
          .thenAnswer((_) async => {});

      // 构建组件
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ConnectionStateNotifier>.value(
            value: mockConnectionStateNotifier,
            child: const Scaffold(
              body: ConnectionFormWidget(),
            ),
          ),
        ),
      );

      // 输入IP地址
      await tester.enterText(find.byType(TextFormField), '192.168.1.101');

      // 点击连接按钮
      await tester.tap(find.text('连接'));
      await tester.pump();

      // 验证方法调用
      verify(mockConnectionStateNotifier.initiateConnection('192.168.1.101'))
          .called(1);
    });

    testWidgets('点击取消按钮应调用cancelConnection', (WidgetTester tester) async {
      // 设置初始状态
      when(mockConnectionStateNotifier.connectionState).thenReturn(
        ConnectionModel(
          status: ConnectionStatus.connecting,
          remoteIpAddress: '192.168.1.101',
        ),
      );
      when(mockConnectionStateNotifier.cancelConnection())
          .thenAnswer((_) async => {});

      // 构建组件
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ConnectionStateNotifier>.value(
            value: mockConnectionStateNotifier,
            child: const Scaffold(
              body: ConnectionFormWidget(),
            ),
          ),
        ),
      );

      // 点击取消按钮
      await tester.tap(find.text('取消'));
      await tester.pump();

      // 验证方法调用
      verify(mockConnectionStateNotifier.cancelConnection()).called(1);
    });

    testWidgets('连接UI元素应在同一行显示', (WidgetTester tester) async {
      // 设置初始状态
      when(mockConnectionStateNotifier.connectionState).thenReturn(
        ConnectionModel(status: ConnectionStatus.disconnected),
      );

      // 构建组件
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ConnectionStateNotifier>.value(
            value: mockConnectionStateNotifier,
            child: const Scaffold(
              body: ConnectionFormWidget(),
            ),
          ),
        ),
      );

      // 验证UI元素在同一行
      final rowFinder = find.byType(Row);
      expect(rowFinder, findsOneWidget);

      final textFinder = find.text('连接到设备');
      final textFieldFinder = find.byType(TextFormField);
      final buttonFinder = find.byType(ElevatedButton);

      expect(textFinder, findsOneWidget);
      expect(textFieldFinder, findsOneWidget);
      expect(buttonFinder, findsOneWidget);

      // 验证元素顺序
      final row = tester.widget<Row>(rowFinder);
      final children = row.children;
      expect(children[0], isA<Text>());
      expect(children[2], isA<Expanded>());
      expect(children[4], isA<ElevatedButton>());
    });
  });
}
