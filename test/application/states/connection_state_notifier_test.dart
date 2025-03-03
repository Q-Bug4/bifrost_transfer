import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:bifrost_transfer/application/models/connection_model.dart';
import 'package:bifrost_transfer/application/models/device_info_model.dart';
import 'package:bifrost_transfer/application/services/connection_service.dart';
import 'package:bifrost_transfer/application/services/device_info_service.dart';
import 'package:bifrost_transfer/application/states/connection_state_notifier.dart';
import 'package:bifrost_transfer/application/models/connection_status.dart';
import '../../mocks/mock_connection_service.mocks.dart';

// 使用生成的MockDeviceInfoService
class MockDeviceInfoService extends Mock implements DeviceInfoService {
  @override
  Future<DeviceInfoModel> getDeviceInfo() async {
    return DeviceInfoModel(
      deviceName: 'Test Device',
      ipAddress: '192.168.1.100',
    );
  }
}

void main() {
  group('ConnectionStateNotifier Tests', () {
    late MockConnectionService mockConnectionService;
    late MockDeviceInfoService mockDeviceInfoService;
    late ConnectionStateNotifier connectionStateNotifier;

    // 模拟连接状态流控制器
    late StreamController<ConnectionModel> connectionStateStreamController;

    // 模拟连接请求流控制器
    late StreamController<Map<String, dynamic>>
        connectionRequestStreamController;

    setUp(() {
      mockConnectionService = MockConnectionService();
      mockDeviceInfoService = MockDeviceInfoService();

      // 初始化流控制器
      connectionStateStreamController =
          StreamController<ConnectionModel>.broadcast();
      connectionRequestStreamController =
          StreamController<Map<String, dynamic>>.broadcast();

      // 设置连接服务的模拟行为
      when(mockConnectionService.connectionStateStream)
          .thenAnswer((_) => connectionStateStreamController.stream);

      when(mockConnectionService.connectionRequestStream)
          .thenAnswer((_) => connectionRequestStreamController.stream);
    });

    tearDown(() {
      // 关闭流控制器
      connectionStateStreamController.close();
      connectionRequestStreamController.close();
    });

    test('初始状态应为断开连接', () async {
      // 创建被测试对象
      connectionStateNotifier = ConnectionStateNotifier(
        connectionService: mockConnectionService,
        deviceInfoService: mockDeviceInfoService,
      );

      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));

      expect(connectionStateNotifier.connectionState.status,
          equals(ConnectionStatus.disconnected));
      expect(connectionStateNotifier.pendingConnectionRequest, isNull);
    });

    test('发起连接应更新状态为连接中', () async {
      // 设置连接服务的模拟行为
      when(mockConnectionService.initiateConnection('192.168.1.101'))
          .thenAnswer((_) async => '123456');

      // 创建被测试对象
      connectionStateNotifier = ConnectionStateNotifier(
        connectionService: mockConnectionService,
        deviceInfoService: mockDeviceInfoService,
      );

      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));

      // 执行发起连接
      await connectionStateNotifier.initiateConnection('192.168.1.101');

      // 验证状态更新
      expect(connectionStateNotifier.connectionState.status,
          equals(ConnectionStatus.connecting));
      expect(connectionStateNotifier.connectionState.remoteIpAddress,
          equals('192.168.1.101'));
      expect(connectionStateNotifier.connectionState.isInitiator, isTrue);

      // 验证服务调用
      verify(mockConnectionService.initiateConnection('192.168.1.101'))
          .called(1);
    });

    test('连接成功应更新状态为已连接', () async {
      // 创建被测试对象
      connectionStateNotifier = ConnectionStateNotifier(
        connectionService: mockConnectionService,
        deviceInfoService: mockDeviceInfoService,
      );

      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));

      // 设置初始状态
      connectionStateNotifier.updateConnectionState(
        ConnectionModel(
          status: ConnectionStatus.connecting,
          remoteIpAddress: '192.168.1.101',
          isInitiator: true,
        ),
      );

      // 模拟连接成功回调
      connectionStateNotifier.onConnectionEstablished(
        remoteDeviceName: 'Remote Device',
        remoteIpAddress: '192.168.1.101',
      );

      // 验证状态更新
      expect(connectionStateNotifier.connectionState.status,
          equals(ConnectionStatus.connected));
      expect(connectionStateNotifier.connectionState.remoteDeviceName,
          equals('Remote Device'));
      expect(connectionStateNotifier.connectionState.remoteIpAddress,
          equals('192.168.1.101'));
    });

    test('连接失败应更新状态为失败', () async {
      // 创建被测试对象
      connectionStateNotifier = ConnectionStateNotifier(
        connectionService: mockConnectionService,
        deviceInfoService: mockDeviceInfoService,
      );

      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));

      // 设置初始状态
      connectionStateNotifier.updateConnectionState(
        ConnectionModel(
          status: ConnectionStatus.connecting,
          remoteIpAddress: '192.168.1.101',
          isInitiator: true,
        ),
      );

      // 模拟连接失败回调
      connectionStateNotifier.onConnectionFailed(
        reason: '连接超时',
      );

      // 验证状态更新
      expect(connectionStateNotifier.connectionState.status,
          equals(ConnectionStatus.failed));
      expect(connectionStateNotifier.connectionState.failureReason,
          equals('连接超时'));
    });

    test('接收连接请求应更新待处理请求', () async {
      // 创建被测试对象
      connectionStateNotifier = ConnectionStateNotifier(
        connectionService: mockConnectionService,
        deviceInfoService: mockDeviceInfoService,
      );

      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));

      // 模拟接收连接请求
      connectionStateNotifier.onConnectionRequested(
        initiatorName: 'Initiator Device',
        initiatorIp: '192.168.1.101',
        pairingCode: '123456',
      );

      // 验证待处理请求更新
      expect(connectionStateNotifier.pendingConnectionRequest, isNotNull);
      expect(connectionStateNotifier.pendingConnectionRequest!['deviceName'],
          equals('Initiator Device'));
      expect(connectionStateNotifier.pendingConnectionRequest!['deviceIp'],
          equals('192.168.1.101'));
      expect(connectionStateNotifier.pendingConnectionRequest!['pairingCode'],
          equals('123456'));
    });

    test('接受连接请求应更新状态为已连接', () async {
      // 设置连接服务的模拟行为
      when(mockConnectionService.acceptConnection('192.168.1.101', '123456'))
          .thenAnswer((_) async => true);

      // 创建被测试对象
      connectionStateNotifier = ConnectionStateNotifier(
        connectionService: mockConnectionService,
        deviceInfoService: mockDeviceInfoService,
      );

      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));

      // 设置待处理请求
      connectionStateNotifier.onConnectionRequested(
        initiatorName: 'Initiator Device',
        initiatorIp: '192.168.1.101',
        pairingCode: '123456',
      );

      // 执行接受连接
      await connectionStateNotifier.acceptConnectionRequest();

      // 验证状态更新
      expect(connectionStateNotifier.connectionState.status,
          equals(ConnectionStatus.connecting));
      expect(connectionStateNotifier.connectionState.isInitiator, isFalse);
      expect(connectionStateNotifier.pendingConnectionRequest, isNull);

      // 验证服务调用
      verify(mockConnectionService.acceptConnection('192.168.1.101', '123456'))
          .called(1);
    });

    test('拒绝连接请求应清除待处理请求', () async {
      // 设置连接服务的模拟行为
      when(mockConnectionService.rejectConnection('192.168.1.101'))
          .thenAnswer((_) async => {});

      // 创建被测试对象
      connectionStateNotifier = ConnectionStateNotifier(
        connectionService: mockConnectionService,
        deviceInfoService: mockDeviceInfoService,
      );

      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));

      // 设置待处理请求
      connectionStateNotifier.onConnectionRequested(
        initiatorName: 'Initiator Device',
        initiatorIp: '192.168.1.101',
        pairingCode: '123456',
      );

      // 执行拒绝连接
      await connectionStateNotifier.rejectConnectionRequest();

      // 验证待处理请求清除
      expect(connectionStateNotifier.pendingConnectionRequest, isNull);

      // 验证服务调用
      verify(mockConnectionService.rejectConnection('192.168.1.101')).called(1);
    });

    test('断开连接应更新状态为断开连接', () async {
      // 设置连接服务的模拟行为
      when(mockConnectionService.disconnect()).thenAnswer((_) async => true);

      // 创建被测试对象
      connectionStateNotifier = ConnectionStateNotifier(
        connectionService: mockConnectionService,
        deviceInfoService: mockDeviceInfoService,
      );

      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));

      // 设置初始状态为已连接
      connectionStateNotifier.updateConnectionState(
        ConnectionModel(
          status: ConnectionStatus.connected,
          remoteDeviceName: 'Remote Device',
          remoteIpAddress: '192.168.1.101',
        ),
      );

      // 执行断开连接
      await connectionStateNotifier.disconnect();

      // 验证状态更新
      expect(connectionStateNotifier.connectionState.status,
          equals(ConnectionStatus.disconnected));

      // 验证服务调用
      verify(mockConnectionService.disconnect()).called(1);
    });
  });
}
