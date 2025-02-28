import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bifrost_transfer/application/services/connection_service.dart';
import 'package:bifrost_transfer/application/states/connection_state_notifier.dart';
import 'package:bifrost_transfer/application/models/connection_model.dart';
import 'package:bifrost_transfer/application/models/device_info_model.dart';

// 生成 mock 类
@GenerateNiceMocks([MockSpec<ConnectionService>()])
import 'connection_state_notifier_test.mocks.dart';

void main() {
  late MockConnectionService mockConnectionService;
  late ConnectionStateNotifier connectionStateNotifier;
  
  // 设置测试环境
  setUp(() {
    mockConnectionService = MockConnectionService();
    
    // 模拟设备信息
    final deviceInfo = DeviceInfoModel(
      deviceName: 'Test Device',
      ipAddress: '192.168.1.100',
    );
    
    // 模拟连接状态流
    final connectionStateController = StreamController<ConnectionModel>.broadcast();
    when(mockConnectionService.connectionStateStream).thenAnswer((_) => connectionStateController.stream);
    
    // 模拟连接请求流
    final connectionRequestController = StreamController<Map<String, dynamic>>.broadcast();
    when(mockConnectionService.connectionRequestStream).thenAnswer((_) => connectionRequestController.stream);
    
    // 模拟获取本地设备信息
    when(mockConnectionService.getLocalDeviceInfo()).thenAnswer((_) async => deviceInfo);
    
    // 创建被测试对象
    connectionStateNotifier = ConnectionStateNotifier(mockConnectionService);
    
    // 添加清理
    addTearDown(() {
      connectionStateController.close();
      connectionRequestController.close();
      connectionStateNotifier.dispose();
    });
  });
  
  // 测试初始化
  group('初始化', () {
    test('应正确获取本地设备信息', () async {
      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 验证结果
      expect(connectionStateNotifier.localDeviceInfo, isNotNull);
      expect(connectionStateNotifier.localDeviceInfo!.deviceName, 'Test Device');
      expect(connectionStateNotifier.localDeviceInfo!.ipAddress, '192.168.1.100');
      verify(mockConnectionService.getLocalDeviceInfo()).called(1);
    });
    
    test('初始连接状态应为断开连接', () {
      expect(connectionStateNotifier.connectionState.status, ConnectionStatus.disconnected);
    });
  });
  
  // 测试发起连接
  group('initiateConnection', () {
    test('正常情况 - 应调用服务的发起连接方法', () async {
      // 安排测试数据
      final targetIp = '192.168.1.101';
      
      // 模拟服务行为
      when(mockConnectionService.initiateConnection(targetIp)).thenAnswer((_) async => '123456');
      
      // 执行测试
      await connectionStateNotifier.initiateConnection(targetIp);
      
      // 验证结果
      verify(mockConnectionService.initiateConnection(targetIp)).called(1);
    });
    
    test('异常情况 - 服务抛出异常时应重新抛出', () async {
      // 安排测试数据
      final targetIp = '192.168.1.101';
      
      // 模拟服务行为 - 抛出异常
      when(mockConnectionService.initiateConnection(targetIp)).thenThrow(Exception('连接失败'));
      
      // 执行测试并验证异常
      expect(() => connectionStateNotifier.initiateConnection(targetIp), throwsA(isA<Exception>()));
    });
  });
  
  // 测试接受连接请求
  group('acceptConnectionRequest', () {
    test('正常情况 - 有待处理请求时应接受连接', () async {
      // 安排测试数据 - 模拟待处理的连接请求
      connectionStateNotifier.handleConnectionRequest({
        'deviceIp': '192.168.1.101',
        'deviceName': 'Test Device',
        'pairingCode': '123456',
      });
      
      // 模拟服务行为
      when(mockConnectionService.acceptConnection('192.168.1.101', '123456')).thenAnswer((_) async => true);
      
      // 执行测试
      await connectionStateNotifier.acceptConnectionRequest();
      
      // 验证结果
      verify(mockConnectionService.acceptConnection('192.168.1.101', '123456')).called(1);
      expect(connectionStateNotifier.pendingConnectionRequest, isNull);
    });
    
    test('异常情况 - 无待处理请求时不应调用服务', () async {
      // 执行测试
      await connectionStateNotifier.acceptConnectionRequest();
      
      // 验证结果
      verifyNever(mockConnectionService.acceptConnection(any, any));
    });
    
    test('异常情况 - 服务返回失败时应记录警告', () async {
      // 安排测试数据 - 模拟待处理的连接请求
      connectionStateNotifier.handleConnectionRequest({
        'deviceIp': '192.168.1.101',
        'deviceName': 'Test Device',
        'pairingCode': '123456',
      });
      
      // 模拟服务行为 - 返回失败
      when(mockConnectionService.acceptConnection('192.168.1.101', '123456')).thenAnswer((_) async => false);
      
      // 执行测试
      await connectionStateNotifier.acceptConnectionRequest();
      
      // 验证结果
      verify(mockConnectionService.acceptConnection('192.168.1.101', '123456')).called(1);
    });
  });
  
  // 测试拒绝连接请求
  group('rejectConnectionRequest', () {
    test('正常情况 - 有待处理请求时应拒绝连接', () async {
      // 安排测试数据 - 模拟待处理的连接请求
      connectionStateNotifier.handleConnectionRequest({
        'deviceIp': '192.168.1.101',
        'deviceName': 'Test Device',
        'pairingCode': '123456',
      });
      
      // 模拟服务行为
      when(mockConnectionService.rejectConnection('192.168.1.101')).thenAnswer((_) async {});
      
      // 执行测试
      await connectionStateNotifier.rejectConnectionRequest();
      
      // 验证结果
      verify(mockConnectionService.rejectConnection('192.168.1.101')).called(1);
      expect(connectionStateNotifier.pendingConnectionRequest, isNull);
    });
    
    test('异常情况 - 无待处理请求时不应调用服务', () async {
      // 执行测试
      await connectionStateNotifier.rejectConnectionRequest();
      
      // 验证结果
      verifyNever(mockConnectionService.rejectConnection(any));
    });
  });
  
  // 测试断开连接
  group('disconnect', () {
    test('应调用服务的断开连接方法', () async {
      // 模拟服务行为
      when(mockConnectionService.disconnect()).thenAnswer((_) async {});
      
      // 执行测试
      await connectionStateNotifier.disconnect();
      
      // 验证结果
      verify(mockConnectionService.disconnect()).called(1);
    });
    
    test('异常情况 - 服务抛出异常时应重新抛出', () async {
      // 模拟服务行为 - 抛出异常
      when(mockConnectionService.disconnect()).thenThrow(Exception('断开连接失败'));
      
      // 执行测试并验证异常
      expect(() => connectionStateNotifier.disconnect(), throwsA(isA<Exception>()));
    });
  });
  
  // 测试取消连接请求
  group('cancelConnection', () {
    test('应调用服务的取消连接请求方法', () async {
      // 模拟服务行为
      when(mockConnectionService.cancelConnection()).thenAnswer((_) async {});
      
      // 执行测试
      await connectionStateNotifier.cancelConnection();
      
      // 验证结果
      verify(mockConnectionService.cancelConnection()).called(1);
    });
    
    test('异常情况 - 服务抛出异常时应重新抛出', () async {
      // 模拟服务行为 - 抛出异常
      when(mockConnectionService.cancelConnection()).thenThrow(Exception('取消连接请求失败'));
      
      // 执行测试并验证异常
      expect(() => connectionStateNotifier.cancelConnection(), throwsA(isA<Exception>()));
    });
  });
  
  // 测试连接状态变化处理
  group('handleConnectionStateChange', () {
    test('应更新连接状态并通知监听器', () {
      // 安排测试数据
      final newState = ConnectionModel(
        status: ConnectionStatus.connected,
        remoteDeviceName: 'Remote Device',
        remoteIpAddress: '192.168.1.101',
      );
      
      // 监听通知
      bool notified = false;
      connectionStateNotifier.addListener(() {
        notified = true;
      });
      
      // 执行测试
      connectionStateNotifier.handleConnectionStateChange(newState);
      
      // 验证结果
      expect(connectionStateNotifier.connectionState.status, ConnectionStatus.connected);
      expect(connectionStateNotifier.connectionState.remoteDeviceName, 'Remote Device');
      expect(connectionStateNotifier.connectionState.remoteIpAddress, '192.168.1.101');
      expect(notified, true);
    });
    
    test('连接成功或失败时应清除待处理的连接请求', () {
      // 安排测试数据 - 模拟待处理的连接请求
      connectionStateNotifier.handleConnectionRequest({
        'deviceIp': '192.168.1.101',
        'deviceName': 'Test Device',
        'pairingCode': '123456',
      });
      
      // 执行测试 - 连接成功
      connectionStateNotifier.handleConnectionStateChange(ConnectionModel(
        status: ConnectionStatus.connected,
      ));
      
      // 验证结果
      expect(connectionStateNotifier.pendingConnectionRequest, isNull);
      
      // 重新设置待处理请求
      connectionStateNotifier.handleConnectionRequest({
        'deviceIp': '192.168.1.101',
        'deviceName': 'Test Device',
        'pairingCode': '123456',
      });
      
      // 执行测试 - 连接失败
      connectionStateNotifier.handleConnectionStateChange(ConnectionModel(
        status: ConnectionStatus.failed,
      ));
      
      // 验证结果
      expect(connectionStateNotifier.pendingConnectionRequest, isNull);
    });
  });
  
  // 测试连接请求处理
  group('handleConnectionRequest', () {
    test('应更新待处理的连接请求并通知监听器', () {
      // 安排测试数据
      final request = {
        'deviceIp': '192.168.1.101',
        'deviceName': 'Test Device',
        'pairingCode': '123456',
      };
      
      // 监听通知
      bool notified = false;
      connectionStateNotifier.addListener(() {
        notified = true;
      });
      
      // 执行测试
      connectionStateNotifier.handleConnectionRequest(request);
      
      // 验证结果
      expect(connectionStateNotifier.pendingConnectionRequest, isNotNull);
      expect(connectionStateNotifier.pendingConnectionRequest!['deviceIp'], '192.168.1.101');
      expect(connectionStateNotifier.pendingConnectionRequest!['deviceName'], 'Test Device');
      expect(connectionStateNotifier.pendingConnectionRequest!['pairingCode'], '123456');
      expect(notified, true);
    });
  });
} 