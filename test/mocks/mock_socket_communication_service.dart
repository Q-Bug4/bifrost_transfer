import 'dart:async';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bifrost_transfer/application/services/socket_communication_service.dart';
import 'package:bifrost_transfer/application/models/socket_message_model.dart';

// 生成 mock 类
@GenerateNiceMocks([MockSpec<SocketCommunicationService>()])
class _MockSocketCommunicationService extends Mock implements SocketCommunicationService {}

// 导出生成的 mock 类
export 'mock_socket_communication_service.mocks.dart'; 