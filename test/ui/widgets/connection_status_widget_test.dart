import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:bifrost_transfer/ui/widgets/connection_status_widget.dart';
import 'package:bifrost_transfer/application/states/connection_state_notifier.dart';
import 'package:bifrost_transfer/application/models/connection_model.dart';
import '../../mocks/mock_connection_state_notifier.mocks.dart';

void main() {
  group('ConnectionStatusWidget', () {
    late MockConnectionStateNotifier mockConnectionStateNotifier;

    setUp(() {
      mockConnectionStateNotifier = MockConnectionStateNotifier();
    });

    testWidgets('未连接状态应正确显示', (WidgetTester tester) async {
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
              body: ConnectionStatusWidget(),
            ),
          ),
        ),
      );

      // 验证UI
      expect(find.text('未连接'), findsOneWidget);
    });

    testWidgets('连接中状态应正确显示', (WidgetTester tester) async {
      // 设置初始状态
      when(mockConnectionStateNotifier.connectionState).thenReturn(
        ConnectionModel(status: ConnectionStatus.connecting),
      );

      // 构建组件
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ConnectionStateNotifier>.value(
            value: mockConnectionStateNotifier,
            child: const Scaffold(
              body: ConnectionStatusWidget(),
            ),
          ),
        ),
      );

      // 验证UI
      expect(find.text('连接中...'), findsOneWidget);
    });

    testWidgets('等待确认状态应正确显示', (WidgetTester tester) async {
      // 设置初始状态
      when(mockConnectionStateNotifier.connectionState).thenReturn(
        ConnectionModel(status: ConnectionStatus.awaitingConfirmation),
      );

      // 构建组件
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ConnectionStateNotifier>.value(
            value: mockConnectionStateNotifier,
            child: const Scaffold(
              body: ConnectionStatusWidget(),
            ),
          ),
        ),
      );

      // 验证UI
      expect(find.text('等待确认...'), findsOneWidget);
    });

    testWidgets('已连接状态应正确显示', (WidgetTester tester) async {
      // 设置初始状态
      when(mockConnectionStateNotifier.connectionState).thenReturn(
        ConnectionModel(
          status: ConnectionStatus.connected,
          remoteDeviceName: 'Test Device',
        ),
      );

      // 构建组件
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ConnectionStateNotifier>.value(
            value: mockConnectionStateNotifier,
            child: const Scaffold(
              body: ConnectionStatusWidget(),
            ),
          ),
        ),
      );

      // 验证UI
      expect(find.text('已连接到 Test Device'), findsOneWidget);
    });

    testWidgets('连接失败状态应正确显示', (WidgetTester tester) async {
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
              body: ConnectionStatusWidget(),
            ),
          ),
        ),
      );

      // 验证UI
      expect(find.text('连接失败'), findsOneWidget);
    });
  });
}
