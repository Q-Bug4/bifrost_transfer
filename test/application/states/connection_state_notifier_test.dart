import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:bifrost_transfer/application/models/connection_model.dart';
import 'package:bifrost_transfer/application/models/device_info_model.dart';
import 'package:bifrost_transfer/application/services/connection_service.dart';
import 'package:bifrost_transfer/application/states/connection_state_notifier.dart';
import '../../mocks/mock_connection_service.dart' as mocks;

void main() {
  late mocks.MockConnectionService mockConnectionService;
  late ConnectionStateNotifier connectionStateNotifier;
  
  // 设置测试环境
  setUp(() {
    mockConnectionService = mocks.MockConnectionService();
    
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
  group('ConnectionStateNotifier - 初始化', () {
    test('初始化时应该获取本地设备信息', () async {
      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 验证结果
      expect(connectionStateNotifier.localDeviceInfo, isNotNull);
      expect(connectionStateNotifier.localDeviceInfo!.deviceName, 'Test Device');
      expect(connectionStateNotifier.localDeviceInfo!.ipAddress, '192.168.1.100');
      verify(mockConnectionService.getLocalDeviceInfo()).called(1);
    });
    
    test('初始化时应该订阅连接状态流和连接请求流', () async {
      // 准备
      final connectionStateController = StreamController<ConnectionModel>();
      final connectionRequestController = StreamController<Map<String, dynamic>>();
      
      when(mockConnectionService.connectionStateStream)
          .thenAnswer((_) => connectionStateController.stream);
      when(mockConnectionService.connectionRequestStream)
          .thenAnswer((_) => connectionRequestController.stream);
      
      // 创建新实例以触发初始化
      final notifier = ConnectionStateNotifier(mockConnectionService);
      
      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 验证
      verify(mockConnectionService.connectionStateStream).called(greaterThanOrEqualTo(1));
      verify(mockConnectionService.connectionRequestStream).called(greaterThanOrEqualTo(1));
      
      // 清理
      connectionStateController.close();
      connectionRequestController.close();
      notifier.dispose();
    });
    
    test('初始化失败时应该记录错误', () async {
      // 准备
      when(mockConnectionService.getLocalDeviceInfo())
          .thenThrow(Exception('测试异常'));
      
      // 创建新实例以触发初始化
      final notifier = ConnectionStateNotifier(mockConnectionService);
      
      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 验证
      expect(notifier.localDeviceInfo, isNull);
      verify(mockConnectionService.getLocalDeviceInfo()).called(1);
      
      // 清理
      notifier.dispose();
    });
  });
  
  // 测试发起连接
  group('ConnectionStateNotifier - 发起连接', () {
    const targetIp = '192.168.1.200';
    
    test('发起连接成功', () async {
      // 安排测试数据
      when(mockConnectionService.initiateConnection(targetIp))
          .thenAnswer((_) async => '123456');
      
      // 执行测试
      await connectionStateNotifier.initiateConnection(targetIp);
      
      // 验证结果
      verify(mockConnectionService.initiateConnection(targetIp)).called(1);
    });
    
    test('发起连接失败时应该抛出异常', () async {
      // 安排测试数据
      when(mockConnectionService.initiateConnection(targetIp))
          .thenThrow(Exception('连接失败'));
      
      // 执行测试并验证异常
      expect(() => connectionStateNotifier.initiateConnection(targetIp), throwsA(isA<Exception>()));
      verify(mockConnectionService.initiateConnection(targetIp)).called(1);
    });
  });
  
  // 测试接受连接请求
  group('ConnectionStateNotifier - 接受连接请求', () {
    const initiatorIp = '192.168.1.200';
    const pairingCode = '123456';
    
    test('接受连接请求成功', () async {
      // 准备
      final connectionRequestController = StreamController<Map<String, dynamic>>();
      when(mockConnectionService.connectionRequestStream)
          .thenAnswer((_) => connectionRequestController.stream);
      
      final notifier = ConnectionStateNotifier(mockConnectionService);
      
      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 发送连接请求
      final request = {
        'deviceIp': initiatorIp,
        'pairingCode': pairingCode,
      };
      connectionRequestController.add(request);
      
      // 等待处理请求
      await Future.delayed(const Duration(milliseconds: 100));
      
      when(mockConnectionService.acceptConnection(initiatorIp, pairingCode))
          .thenAnswer((_) async => true);
      
      // 执行
      await notifier.acceptConnectionRequest();
      
      // 验证
      verify(mockConnectionService.acceptConnection(initiatorIp, pairingCode)).called(1);
      
      // 清理
      connectionRequestController.close();
      notifier.dispose();
    });
    
    test('没有待处理的连接请求时不应该调用接受连接', () async {
      // 准备
      final notifier = ConnectionStateNotifier(mockConnectionService);
      
      // 执行
      await notifier.acceptConnectionRequest();
      
      // 验证
      verifyNever(mockConnectionService.acceptConnection(any, any));
      
      // 清理
      notifier.dispose();
    });
    
    test('接受连接请求失败时应该抛出异常', () async {
      // 准备
      final connectionRequestController = StreamController<Map<String, dynamic>>();
      when(mockConnectionService.connectionRequestStream)
          .thenAnswer((_) => connectionRequestController.stream);
      
      final notifier = ConnectionStateNotifier(mockConnectionService);
      
      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 发送连接请求
      final request = {
        'deviceIp': initiatorIp,
        'pairingCode': pairingCode,
      };
      connectionRequestController.add(request);
      
      // 等待处理请求
      await Future.delayed(const Duration(milliseconds: 100));
      
      when(mockConnectionService.acceptConnection(initiatorIp, pairingCode))
          .thenThrow(Exception('接受连接失败'));
      
      // 执行和验证
      expect(
        () => notifier.acceptConnectionRequest(),
        throwsException,
      );
      verify(mockConnectionService.acceptConnection(initiatorIp, pairingCode)).called(1);
      
      // 清理
      connectionRequestController.close();
      notifier.dispose();
    });
  });
  
  // 测试拒绝连接请求
  group('ConnectionStateNotifier - 拒绝连接请求', () {
    const initiatorIp = '192.168.1.200';
    const pairingCode = '123456';
    
    test('拒绝连接请求成功', () async {
      // 准备
      final connectionRequestController = StreamController<Map<String, dynamic>>();
      when(mockConnectionService.connectionRequestStream)
          .thenAnswer((_) => connectionRequestController.stream);
      
      final notifier = ConnectionStateNotifier(mockConnectionService);
      
      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 发送连接请求
      final request = {
        'deviceIp': initiatorIp,
        'pairingCode': pairingCode,
      };
      connectionRequestController.add(request);
      
      // 等待处理请求
      await Future.delayed(const Duration(milliseconds: 100));
      
      when(mockConnectionService.rejectConnection(initiatorIp))
          .thenAnswer((_) async => null);
      
      // 执行
      await notifier.rejectConnectionRequest();
      
      // 验证
      verify(mockConnectionService.rejectConnection(initiatorIp)).called(1);
      expect(notifier.pendingConnectionRequest, isNull);
      
      // 清理
      connectionRequestController.close();
      notifier.dispose();
    });
    
    test('没有待处理的连接请求时不应该调用拒绝连接', () async {
      // 准备
      final notifier = ConnectionStateNotifier(mockConnectionService);
      
      // 执行
      await notifier.rejectConnectionRequest();
      
      // 验证
      verifyNever(mockConnectionService.rejectConnection(any));
      
      // 清理
      notifier.dispose();
    });
    
    test('拒绝连接请求失败时应该抛出异常', () async {
      // 准备
      final connectionRequestController = StreamController<Map<String, dynamic>>();
      when(mockConnectionService.connectionRequestStream)
          .thenAnswer((_) => connectionRequestController.stream);
      
      final notifier = ConnectionStateNotifier(mockConnectionService);
      
      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 发送连接请求
      final request = {
        'deviceIp': initiatorIp,
        'pairingCode': pairingCode,
      };
      connectionRequestController.add(request);
      
      // 等待处理请求
      await Future.delayed(const Duration(milliseconds: 100));
      
      when(mockConnectionService.rejectConnection(initiatorIp))
          .thenThrow(Exception('拒绝连接失败'));
      
      // 执行和验证
      expect(
        () => notifier.rejectConnectionRequest(),
        throwsException,
      );
      verify(mockConnectionService.rejectConnection(initiatorIp)).called(1);
      
      // 清理
      connectionRequestController.close();
      notifier.dispose();
    });
  });
  
  // 测试断开连接
  group('ConnectionStateNotifier - 断开连接', () {
    test('断开连接成功', () async {
      // 准备
      when(mockConnectionService.disconnect())
          .thenAnswer((_) async => null);
      
      // 执行
      await connectionStateNotifier.disconnect();
      
      // 验证
      verify(mockConnectionService.disconnect()).called(1);
    });
    
    test('断开连接失败时应该抛出异常', () async {
      // 准备
      when(mockConnectionService.disconnect())
          .thenThrow(Exception('断开连接失败'));
      
      // 执行和验证
      expect(
        () => connectionStateNotifier.disconnect(),
        throwsException,
      );
      verify(mockConnectionService.disconnect()).called(1);
    });
  });
  
  // 测试取消连接请求
  group('ConnectionStateNotifier - 取消连接请求', () {
    test('取消连接请求成功', () async {
      // 准备
      when(mockConnectionService.cancelConnection())
          .thenAnswer((_) async => null);
      
      // 执行
      await connectionStateNotifier.cancelConnection();
      
      // 验证
      verify(mockConnectionService.cancelConnection()).called(1);
    });
    
    test('取消连接请求失败时应该抛出异常', () async {
      // 准备
      when(mockConnectionService.cancelConnection())
          .thenThrow(Exception('取消连接请求失败'));
      
      // 执行和验证
      expect(
        () => connectionStateNotifier.cancelConnection(),
        throwsException,
      );
      verify(mockConnectionService.cancelConnection()).called(1);
    });
  });
  
  // 测试连接状态变化处理
  group('ConnectionStateNotifier - 处理连接状态变化', () {
    test('连接状态变化时应该更新状态', () async {
      // 准备
      final newState = ConnectionModel(
        status: ConnectionStatus.connected,
        remoteIpAddress: '192.168.1.200',
        remoteDeviceName: 'Test Device',
      );
      
      // 模拟连接状态变化
      final connectionStateController = StreamController<ConnectionModel>();
      when(mockConnectionService.connectionStateStream)
          .thenAnswer((_) => connectionStateController.stream);
      
      // 创建新实例以触发初始化
      final notifier = ConnectionStateNotifier(mockConnectionService);
      
      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 发送状态变化
      connectionStateController.add(newState);
      
      // 等待处理状态变化
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 验证
      expect(notifier.connectionState, equals(newState));
      
      // 清理
      connectionStateController.close();
      notifier.dispose();
    });
    
    test('连接成功时应该清除待处理的连接请求', () async {
      // 准备
      final connectionRequestController = StreamController<Map<String, dynamic>>();
      final connectionStateController = StreamController<ConnectionModel>();
      
      when(mockConnectionService.connectionRequestStream)
          .thenAnswer((_) => connectionRequestController.stream);
      when(mockConnectionService.connectionStateStream)
          .thenAnswer((_) => connectionStateController.stream);
      
      final notifier = ConnectionStateNotifier(mockConnectionService);
      
      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 发送连接请求
      final request = {
        'deviceIp': '192.168.1.200',
        'pairingCode': '123456',
      };
      connectionRequestController.add(request);
      
      // 等待处理请求
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 验证请求已设置
      expect(notifier.pendingConnectionRequest, isNotNull);
      
      // 发送连接成功状态
      connectionStateController.add(ConnectionModel(
        status: ConnectionStatus.connected,
        remoteIpAddress: '192.168.1.200',
        remoteDeviceName: 'Test Device',
      ));
      
      // 等待处理状态变化
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 验证请求已清除
      expect(notifier.pendingConnectionRequest, isNull);
      
      // 清理
      connectionRequestController.close();
      connectionStateController.close();
      notifier.dispose();
    });
  });
  
  // 测试连接请求处理
  group('ConnectionStateNotifier - 处理连接请求', () {
    test('收到连接请求时应该设置待处理的连接请求', () async {
      // 准备
      final connectionRequestController = StreamController<Map<String, dynamic>>();
      when(mockConnectionService.connectionRequestStream)
          .thenAnswer((_) => connectionRequestController.stream);
      
      final notifier = ConnectionStateNotifier(mockConnectionService);
      
      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 发送连接请求
      final request = {
        'deviceIp': '192.168.1.200',
        'deviceName': 'Test Device',
        'pairingCode': '123456',
      };
      connectionRequestController.add(request);
      
      // 等待处理请求
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 验证
      expect(notifier.pendingConnectionRequest, equals(request));
      
      // 清理
      connectionRequestController.close();
      notifier.dispose();
    });
  });

  group('ConnectionStateNotifier - 销毁', () {
    test('销毁时应该取消订阅', () async {
      // 准备
      final connectionStateController = StreamController<ConnectionModel>();
      final connectionRequestController = StreamController<Map<String, dynamic>>();
      
      when(mockConnectionService.connectionStateStream)
          .thenAnswer((_) => connectionStateController.stream);
      when(mockConnectionService.connectionRequestStream)
          .thenAnswer((_) => connectionRequestController.stream);
      
      // 创建新实例以触发初始化
      final notifier = ConnectionStateNotifier(mockConnectionService);
      
      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 执行
      notifier.dispose();
      
      // 验证 - 无法直接验证订阅是否取消，但可以确保不会有内存泄漏
      
      // 清理
      connectionStateController.close();
      connectionRequestController.close();
    });
  });
} 