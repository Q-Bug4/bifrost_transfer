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

// 生成 mock 类
@GenerateNiceMocks([MockSpec<SocketCommunicationService>()])
import 'connection_service_test.mocks.dart';

void main() {
  late MockSocketCommunicationService mockSocketService;
  late ConnectionServiceImpl connectionService;
  
  // 设置测试环境
  setUp(() {
    mockSocketService = MockSocketCommunicationService();
    connectionService = ConnectionServiceImpl(mockSocketService);
  });
  
  // 测试获取本地设备信息
  group('getLocalDeviceInfo', () {
    test('正常情况 - 应返回有效的设备信息', () async {
      // 安排测试数据
      final deviceInfo = DeviceInfoModel(
        deviceName: 'Test Device',
        ipAddress: '192.168.1.100',
      );
      
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
      
      // 模拟 Socket 服务行为
      when(mockSocketService.connectToDevice(targetIp, port: NetworkConstants.LISTEN_PORT))
          .thenAnswer((_) async => true);
      
      // 模拟消息流
      final messageController = StreamController<SocketMessageModel>();
      when(mockSocketService.messageStream).thenAnswer((_) => messageController.stream);
      
      // 模拟连接状态流
      final connectionStatusController = StreamController<bool>();
      when(mockSocketService.connectionStatusStream).thenAnswer((_) => connectionStatusController.stream);
      
      // 模拟发送消息成功
      when(mockSocketService.sendMessage(any)).thenAnswer((_) async => true);
      
      // 执行测试
      final pairingCode = await connectionService.initiateConnection(targetIp);
      
      // 验证结果
      expect(pairingCode.length, 6); // 配对码应为6位
      verify(mockSocketService.connectToDevice(targetIp, port: NetworkConstants.LISTEN_PORT)).called(1);
      verify(mockSocketService.sendMessage(any)).called(1);
      
      // 清理
      messageController.close();
      connectionStatusController.close();
    });
    
    test('异常情况 - 连接失败', () async {
      // 安排测试数据
      final targetIp = '192.168.1.101';
      
      // 模拟 Socket 服务行为 - 连接失败
      when(mockSocketService.connectToDevice(targetIp, port: NetworkConstants.LISTEN_PORT))
          .thenAnswer((_) async => false);
      
      // 模拟消息流
      final messageController = StreamController<SocketMessageModel>();
      when(mockSocketService.messageStream).thenAnswer((_) => messageController.stream);
      
      // 模拟连接状态流
      final connectionStatusController = StreamController<bool>();
      when(mockSocketService.connectionStatusStream).thenAnswer((_) => connectionStatusController.stream);
      
      // 执行测试并验证异常
      expect(() => connectionService.initiateConnection(targetIp), throwsA(isA<Exception>()));
      
      // 清理
      messageController.close();
      connectionStatusController.close();
    });
    
    test('异常情况 - 发送消息失败', () async {
      // 安排测试数据
      final targetIp = '192.168.1.101';
      
      // 模拟 Socket 服务行为 - 连接成功但发送消息失败
      when(mockSocketService.connectToDevice(targetIp, port: NetworkConstants.LISTEN_PORT))
          .thenAnswer((_) async => true);
      
      // 模拟消息流
      final messageController = StreamController<SocketMessageModel>();
      when(mockSocketService.messageStream).thenAnswer((_) => messageController.stream);
      
      // 模拟连接状态流
      final connectionStatusController = StreamController<bool>();
      when(mockSocketService.connectionStatusStream).thenAnswer((_) => connectionStatusController.stream);
      
      // 模拟发送消息失败
      when(mockSocketService.sendMessage(any)).thenAnswer((_) async => false);
      
      // 执行测试并验证异常
      expect(() => connectionService.initiateConnection(targetIp), throwsA(isA<Exception>()));
      
      // 清理
      messageController.close();
      connectionStatusController.close();
    });
  });
  
  // 测试接受连接
  group('acceptConnection', () {
    test('正常情况 - 接受连接成功', () async {
      // 安排测试数据
      final initiatorIp = '192.168.1.101';
      final pairingCode = '123456';
      
      // 模拟 Socket 服务行为
      when(mockSocketService.isConnected).thenReturn(true);
      when(mockSocketService.sendMessage(any)).thenAnswer((_) async => true);
      
      // 执行测试
      final result = await connectionService.acceptConnection(initiatorIp, pairingCode);
      
      // 验证结果
      expect(result, true);
      verify(mockSocketService.sendMessage(any)).called(1);
    });
    
    test('异常情况 - 未连接', () async {
      // 安排测试数据
      final initiatorIp = '192.168.1.101';
      final pairingCode = '123456';
      
      // 模拟 Socket 服务行为 - 未连接
      when(mockSocketService.isConnected).thenReturn(false);
      
      // 执行测试
      final result = await connectionService.acceptConnection(initiatorIp, pairingCode);
      
      // 验证结果
      expect(result, false);
      verifyNever(mockSocketService.sendMessage(any));
    });
    
    test('异常情况 - 发送消息失败', () async {
      // 安排测试数据
      final initiatorIp = '192.168.1.101';
      final pairingCode = '123456';
      
      // 模拟 Socket 服务行为 - 已连接但发送消息失败
      when(mockSocketService.isConnected).thenReturn(true);
      when(mockSocketService.sendMessage(any)).thenAnswer((_) async => false);
      
      // 执行测试
      final result = await connectionService.acceptConnection(initiatorIp, pairingCode);
      
      // 验证结果
      expect(result, false);
      verify(mockSocketService.sendMessage(any)).called(1);
    });
  });
  
  // 测试拒绝连接
  group('rejectConnection', () {
    test('正常情况 - 拒绝连接成功', () async {
      // 安排测试数据
      final initiatorIp = '192.168.1.101';
      
      // 模拟 Socket 服务行为
      when(mockSocketService.isConnected).thenReturn(true);
      when(mockSocketService.sendMessage(any)).thenAnswer((_) async => true);
      
      // 执行测试
      await connectionService.rejectConnection(initiatorIp);
      
      // 验证结果
      verify(mockSocketService.sendMessage(any)).called(1);
    });
    
    test('异常情况 - 未连接', () async {
      // 安排测试数据
      final initiatorIp = '192.168.1.101';
      
      // 模拟 Socket 服务行为 - 未连接
      when(mockSocketService.isConnected).thenReturn(false);
      
      // 执行测试
      await connectionService.rejectConnection(initiatorIp);
      
      // 验证结果
      verifyNever(mockSocketService.sendMessage(any));
    });
  });
  
  // 测试断开连接
  group('disconnect', () {
    test('正常情况 - 断开连接成功', () async {
      // 模拟 Socket 服务行为
      when(mockSocketService.isConnected).thenReturn(true);
      when(mockSocketService.sendMessage(any)).thenAnswer((_) async => true);
      when(mockSocketService.disconnectFromDevice()).thenAnswer((_) async {});
      
      // 执行测试
      await connectionService.disconnect();
      
      // 验证结果
      verify(mockSocketService.sendMessage(any)).called(1);
      verify(mockSocketService.disconnectFromDevice()).called(1);
    });
    
    test('异常情况 - 未连接', () async {
      // 模拟 Socket 服务行为 - 未连接
      when(mockSocketService.isConnected).thenReturn(false);
      
      // 执行测试
      await connectionService.disconnect();
      
      // 验证结果
      verifyNever(mockSocketService.sendMessage(any));
      verify(mockSocketService.disconnectFromDevice()).called(1);
    });
  });
  
  // 测试取消连接请求
  group('cancelConnection', () {
    test('正常情况 - 取消连接请求成功', () async {
      // 模拟 Socket 服务行为
      when(mockSocketService.isConnected).thenReturn(true);
      when(mockSocketService.sendMessage(any)).thenAnswer((_) async => true);
      when(mockSocketService.disconnectFromDevice()).thenAnswer((_) async {});
      
      // 执行测试
      await connectionService.cancelConnection();
      
      // 验证结果
      verify(mockSocketService.sendMessage(any)).called(1);
      verify(mockSocketService.disconnectFromDevice()).called(1);
    });
    
    test('异常情况 - 未连接', () async {
      // 模拟 Socket 服务行为 - 未连接
      when(mockSocketService.isConnected).thenReturn(false);
      
      // 执行测试
      await connectionService.cancelConnection();
      
      // 验证结果
      verifyNever(mockSocketService.sendMessage(any));
      verify(mockSocketService.disconnectFromDevice()).called(1);
    });
  });
  
  // 测试连接状态流
  group('connectionStateStream', () {
    test('应正确传递连接状态变化', () async {
      // 模拟消息流
      final messageController = StreamController<SocketMessageModel>();
      when(mockSocketService.messageStream).thenAnswer((_) => messageController.stream);
      
      // 模拟连接状态流
      final connectionStatusController = StreamController<bool>();
      when(mockSocketService.connectionStatusStream).thenAnswer((_) => connectionStatusController.stream);
      
      // 监听连接状态流
      final states = <ConnectionModel>[];
      final subscription = connectionService.connectionStateStream.listen(states.add);
      
      // 模拟连接状态变化
      connectionStatusController.add(true); // 连接成功
      
      // 等待状态更新
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 验证结果
      expect(states.isNotEmpty, true);
      expect(states.last.status, ConnectionStatus.connected);
      
      // 清理
      subscription.cancel();
      messageController.close();
      connectionStatusController.close();
    });
  });
  
  // 测试连接请求流
  group('connectionRequestStream', () {
    test('应正确传递连接请求', () async {
      // 模拟消息流
      final messageController = StreamController<SocketMessageModel>();
      when(mockSocketService.messageStream).thenAnswer((_) => messageController.stream);
      
      // 监听连接请求流
      final requests = <Map<String, dynamic>>[];
      final subscription = connectionService.connectionRequestStream.listen(requests.add);
      
      // 模拟接收连接请求消息
      final requestMessage = SocketMessageModel(
        type: 'CONNECTION_REQUEST',
        data: {
          'deviceName': 'Test Device',
          'deviceIp': '192.168.1.101',
          'pairingCode': '123456',
        },
        timestamp: DateTime.now().millisecondsSinceEpoch,
        protocolVersion: NetworkConstants.PROTOCOL_VERSION,
      );
      
      messageController.add(requestMessage);
      
      // 等待请求更新
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 验证结果
      expect(requests.isNotEmpty, true);
      expect(requests.last['deviceName'], 'Test Device');
      expect(requests.last['deviceIp'], '192.168.1.101');
      expect(requests.last['pairingCode'], '123456');
      
      // 清理
      subscription.cancel();
      messageController.close();
    });
  });
} 