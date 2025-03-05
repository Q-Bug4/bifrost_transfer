import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bifrost_transfer/application/services/socket_communication_service.dart';
import 'package:bifrost_transfer/application/services/connection_service_impl.dart';
import 'package:bifrost_transfer/application/models/connection_model.dart';
import 'package:bifrost_transfer/application/models/device_info_model.dart';
import 'package:bifrost_transfer/application/models/socket_message_model.dart';
import 'package:bifrost_transfer/application/models/connection_status.dart';
import 'package:bifrost_transfer/infrastructure/constants/network_constants.dart';
import '../../mocks/mock_socket_communication_service.mocks.dart';

void main() {
  late MockSocketCommunicationService mockSocketService;
  late ConnectionServiceImpl connectionService;
  late StreamController<SocketMessageModel> messageStreamController;
  late StreamController<bool> connectionStateStreamController;
  late StreamController<ConnectionStatus> connectionStatusStreamController;

  setUp(() async {
    mockSocketService = MockSocketCommunicationService();
    messageStreamController = StreamController<SocketMessageModel>.broadcast();
    connectionStateStreamController = StreamController<bool>.broadcast();
    connectionStatusStreamController =
        StreamController<ConnectionStatus>.broadcast();

    when(mockSocketService.messageStream)
        .thenAnswer((_) => messageStreamController.stream);
    when(mockSocketService.connectionStateStream)
        .thenAnswer((_) => connectionStateStreamController.stream);
    when(mockSocketService.connectionStatusStream)
        .thenAnswer((_) => connectionStatusStreamController.stream);
    when(mockSocketService.isConnected).thenReturn(false);
    when(mockSocketService.startServer()).thenAnswer((_) async {});
    when(mockSocketService.stopServer()).thenAnswer((_) async {});
    when(mockSocketService.disconnectFromDevice()).thenAnswer((_) async {});
    when(mockSocketService.sendMessage(any)).thenAnswer((_) async {});

    connectionService = ConnectionServiceImpl(mockSocketService);
    await Future.delayed(Duration.zero); // 等待初始化完成
  });

  tearDown(() async {
    await connectionService.dispose();
    await messageStreamController.close();
    await connectionStateStreamController.close();
    await connectionStatusStreamController.close();
  });

  group('getLocalDeviceInfo', () {
    test('正常情况 - 应返回有效的设备信息', () async {
      final deviceInfo = await connectionService.getLocalDeviceInfo();
      expect(deviceInfo, isA<DeviceInfoModel>());
      expect(deviceInfo.deviceName, isNotEmpty);
      expect(deviceInfo.ipAddress, isNotEmpty);
    });
  });

  group('initiateConnection', () {
    test('正常情况 - 连接成功', () async {
      final targetIp = '192.168.1.2';
      when(mockSocketService.connectToDevice(targetIp, port: anyNamed('port')))
          .thenAnswer((_) async => true);

      final pairingCode = await connectionService.initiateConnection(targetIp);
      expect(pairingCode, isNotEmpty);
      verify(mockSocketService.connectToDevice(targetIp,
              port: NetworkConstants.LISTEN_PORT))
          .called(1);
      verify(mockSocketService.sendMessage(any)).called(1);
    });

    test('异常情况 - 连接失败', () async {
      final targetIp = '192.168.1.2';
      when(mockSocketService.connectToDevice(targetIp, port: anyNamed('port')))
          .thenAnswer((_) async => false);

      await expectLater(
        () => connectionService.initiateConnection(targetIp),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('连接失败'),
        )),
      );
      verify(mockSocketService.connectToDevice(targetIp,
              port: NetworkConstants.LISTEN_PORT))
          .called(1);
    });
  });

  group('acceptConnection', () {
    test('正常情况 - 接受连接成功', () async {
      final initiatorIp = '192.168.1.2';
      final pairingCode = '123456';

      // 模拟连接请求
      final deviceInfo = DeviceInfoModel(
        deviceName: 'Test Device',
        ipAddress: initiatorIp,
      );
      final message = SocketMessageModel.createConnectionRequest(
        deviceName: deviceInfo.deviceName,
        deviceIp: deviceInfo.ipAddress,
        pairingCode: pairingCode,
      );
      messageStreamController.add(message);
      await Future.delayed(Duration.zero);

      final result =
          await connectionService.acceptConnection(initiatorIp, pairingCode);
      expect(result, true);
      verify(mockSocketService.sendMessage(any)).called(1);
    });
  });

  group('rejectConnection', () {
    test('正常情况 - 拒绝连接成功', () async {
      final initiatorIp = '192.168.1.2';

      await connectionService.rejectConnection(initiatorIp);
      verify(mockSocketService.sendMessage(any)).called(1);
      verify(mockSocketService.disconnectFromDevice()).called(1);
    });
  });

  group('disconnect', () {
    test('正常情况 - 断开连接成功', () async {
      await connectionService.disconnect();
      verify(mockSocketService.sendMessage(any)).called(1);
      verify(mockSocketService.disconnectFromDevice()).called(1);
    });
  });

  group('cancelConnection', () {
    test('正常情况 - 取消连接成功', () async {
      await connectionService.cancelConnection();
      verify(mockSocketService.disconnectFromDevice()).called(1);
    });
  });

  group('connectionStateStream', () {
    test('应正确传递连接状态变化', () async {
      final states = <ConnectionModel>[];
      final subscription =
          connectionService.connectionStateStream.listen(states.add);

      connectionStatusStreamController.add(ConnectionStatus.connected);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      expect(states.length, 1);
      expect(states.first.status, ConnectionStatus.connected);

      await subscription.cancel();
    });
  });

  group('connectionRequestStream', () {
    test('应正确传递连接请求', () async {
      final requests = <Map<String, dynamic>>[];
      final subscription =
          connectionService.connectionRequestStream.listen(requests.add);

      final deviceInfo = DeviceInfoModel(
        deviceName: 'Test Device',
        ipAddress: '192.168.1.2',
      );
      final message = SocketMessageModel.createConnectionRequest(
        deviceName: deviceInfo.deviceName,
        deviceIp: deviceInfo.ipAddress,
        pairingCode: '123456',
      );

      messageStreamController.add(message);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      expect(requests.length, 1);
      expect(requests.first['deviceName'], deviceInfo.deviceName);
      expect(requests.first['deviceIp'], deviceInfo.ipAddress);
      expect(requests.first['pairingCode'], '123456');

      await subscription.cancel();
    });
  });
}
