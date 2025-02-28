import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bifrost_transfer/application/services/socket_communication_service.dart';
import 'package:bifrost_transfer/application/services/connection_service_impl.dart';
import 'package:bifrost_transfer/application/models/connection_model.dart';
import 'package:bifrost_transfer/application/models/device_info_model.dart';
import 'package:bifrost_transfer/application/models/socket_message_model.dart';
import 'package:bifrost_transfer/infrastructure/constants/network_constants.dart';
import '../../../test/mocks/mock_socket_communication_service.dart' as mocks;

void main() {
  late mocks.MockSocketCommunicationService mockSocketService;
  late ConnectionServiceImpl connectionService;

  // 设置测试环境
  setUp(() {
    mockSocketService = mocks.MockSocketCommunicationService();

    // 为 mockSocketService 的方法提供 stub
    final messageStreamController =
        StreamController<SocketMessageModel>.broadcast();
    final connectionStatusStreamController = StreamController<bool>.broadcast();

    // 模拟 messageStream
    when(mockSocketService.messageStream)
        .thenAnswer((_) => messageStreamController.stream);

    // 模拟 connectionStatusStream
    when(mockSocketService.connectionStatusStream)
        .thenAnswer((_) => connectionStatusStreamController.stream);

    // 模拟 isConnected
    when(mockSocketService.isConnected).thenReturn(false);

    // 模拟 startServer
    when(mockSocketService.startServer()).thenAnswer((_) async {});

    // 模拟 connectToDevice
    when(mockSocketService.connectToDevice(any, port: anyNamed('port')))
        .thenAnswer((_) async => true);

    // 模拟 sendMessage
    when(mockSocketService.sendMessage(any)).thenAnswer((_) async => true);

    connectionService = ConnectionServiceImpl(mockSocketService);

    // 注册 tearDown 回调，确保在每个测试结束后关闭 StreamController
    addTearDown(() {
      messageStreamController.close();
      connectionStatusStreamController.close();
    });
  });

  // 测试获取本地设备信息
  group('getLocalDeviceInfo', () {
    test('正常情况 - 应返回有效的设备信息', () async {
      // 执行测试
      final result = await connectionService.getLocalDeviceInfo();

      // 验证结果
      expect(result.deviceName.isNotEmpty, true);
      expect(result.ipAddress.isNotEmpty, true);
    });
  });

  // 测试发起连接
  group('initiateConnection', () {
    test('正常情况 - 连接成功', () async {
      // 安排测试数据
      final targetIp = '192.168.1.101';

      // 模拟 connectToDevice 成功
      when(mockSocketService.connectToDevice(any, port: anyNamed('port')))
          .thenAnswer((_) async => true);

      // 执行测试
      final pairingCode = await connectionService.initiateConnection(targetIp);

      // 验证结果
      expect(pairingCode.length, greaterThan(0));

      // 验证方法调用
      verify(mockSocketService.connectToDevice(any, port: anyNamed('port')))
          .called(1);

      // 验证发送了连接请求消息
      verify(mockSocketService.sendMessage(any)).called(1);
    });

    test('异常情况 - 连接失败', () async {
      // 安排测试数据
      final targetIp = '192.168.1.101';

      // 模拟 connectToDevice 失败
      when(mockSocketService.connectToDevice(any, port: anyNamed('port')))
          .thenAnswer((_) async => false);

      // 执行测试并验证异常
      expect(connectionService.initiateConnection(targetIp), throwsException);
    });
  });

  // 测试接受连接
  group('acceptConnection', () {
    test('正常情况 - 接受连接成功', () async {
      // 安排测试数据
      final initiatorIp = '192.168.1.101';
      final pairingCode = '123456';

      // 模拟 sendMessage 成功
      when(mockSocketService.sendMessage(any)).thenAnswer((_) async => true);

      // 执行测试
      final result =
          await connectionService.acceptConnection(initiatorIp, pairingCode);

      // 验证结果
      expect(result, true);

      // 验证发送了连接响应消息
      verify(mockSocketService.sendMessage(argThat(
          predicate<SocketMessageModel>((message) =>
              message.type == SocketMessageType.CONNECTION_RESPONSE &&
              message.data['accepted'] == true)))).called(1);
    });
  });

  // 测试拒绝连接
  group('rejectConnection', () {
    test('正常情况 - 拒绝连接成功', () async {
      // 安排测试数据
      final initiatorIp = '192.168.1.101';

      // 模拟 sendMessage 成功
      when(mockSocketService.sendMessage(any)).thenAnswer((_) async => true);

      // 执行测试
      await connectionService.rejectConnection(initiatorIp);

      // 验证发送了连接响应消息
      verify(mockSocketService.sendMessage(argThat(
          predicate<SocketMessageModel>((message) =>
              message.type == SocketMessageType.CONNECTION_RESPONSE &&
              message.data['accepted'] == false)))).called(1);
    });
  });

  // 测试断开连接
  group('disconnect', () {
    test('正常情况 - 断开连接成功', () async {
      // 模拟 disconnectFromDevice 成功
      when(mockSocketService.disconnectFromDevice()).thenAnswer((_) async {});

      // 执行测试
      await connectionService.disconnect();

      // 验证方法调用
      verify(mockSocketService.disconnectFromDevice()).called(1);
    });
  });

  // 测试取消连接
  group('cancelConnection', () {
    test('正常情况 - 取消连接成功', () async {
      // 模拟 disconnectFromDevice 成功
      when(mockSocketService.disconnectFromDevice()).thenAnswer((_) async {});

      // 执行测试
      await connectionService.cancelConnection();

      // 验证方法调用
      verify(mockSocketService.disconnectFromDevice()).called(1);
    });
  });

  // 测试连接状态流
  group('connectionStateStream', () {
    test('应正确传递连接状态变化', () async {
      // 模拟消息流
      final messageController = StreamController<SocketMessageModel>();
      when(mockSocketService.messageStream)
          .thenAnswer((_) => messageController.stream);

      // 模拟连接状态流
      final connectionStatusController = StreamController<bool>();
      when(mockSocketService.connectionStatusStream)
          .thenAnswer((_) => connectionStatusController.stream);

      // 初始化连接服务
      connectionService = ConnectionServiceImpl(mockSocketService);

      // 监听连接状态流
      final states = <ConnectionModel>[];
      final subscription =
          connectionService.connectionStateStream.listen(states.add);

      // 直接调用initiateConnection方法，这会更新连接状态
      try {
        await connectionService.initiateConnection('192.168.1.100');
      } catch (e) {
        // 忽略异常，我们只关心状态更新
      }

      // 等待状态更新
      await Future.delayed(const Duration(milliseconds: 500));

      // 验证结果
      expect(states.isNotEmpty, true);

      // 清理
      await subscription.cancel();
      await messageController.close();
      await connectionStatusController.close();
    });
  });

  // 测试连接请求流
  group('connectionRequestStream', () {
    test('应正确传递连接请求', () async {
      // 模拟消息流
      final messageController = StreamController<SocketMessageModel>();
      when(mockSocketService.messageStream)
          .thenAnswer((_) => messageController.stream);

      // 初始化连接服务
      connectionService = ConnectionServiceImpl(mockSocketService);

      // 监听连接请求流
      final requests = <Map<String, dynamic>>[];
      final subscription =
          connectionService.connectionRequestStream.listen(requests.add);

      // 模拟接收连接请求消息
      final requestMessage = SocketMessageModel(
        type: SocketMessageType.CONNECTION_REQUEST,
        data: {
          'deviceName': 'Test Device',
          'deviceIp': '192.168.1.101',
          'pairingCode': '123456',
        },
        timestamp: DateTime.now().millisecondsSinceEpoch,
        protocolVersion: NetworkConstants.PROTOCOL_VERSION,
      );

      // 确保订阅已经建立
      await Future.delayed(const Duration(milliseconds: 100));

      // 发送消息
      messageController.add(requestMessage);

      // 等待请求更新
      await Future.delayed(const Duration(milliseconds: 500));

      // 验证结果
      expect(requests.isNotEmpty, true);

      // 清理
      await subscription.cancel();
      await messageController.close();
    });
  });
}
