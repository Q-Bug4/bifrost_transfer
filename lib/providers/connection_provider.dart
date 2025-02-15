import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device.dart';
import '../services/network_service.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  receivingRequest,
  awaitingConfirmation,
  connected,
  error,
}

class DeviceConnectionState {
  final Device? device;
  final ConnectionStatus status;
  final String? errorMessage;
  final List<String> messages;

  DeviceConnectionState({
    this.device,
    this.status = ConnectionStatus.disconnected,
    this.errorMessage,
    this.messages = const [],
  });

  DeviceConnectionState copyWith({
    Device? device,
    ConnectionStatus? status,
    String? errorMessage,
    List<String>? messages,
  }) {
    return DeviceConnectionState(
      device: device ?? this.device,
      status: status ?? this.status,
      errorMessage: errorMessage,
      messages: messages ?? this.messages,
    );
  }
}

final connectionStateProvider =
    StateNotifierProvider<ConnectionNotifier, DeviceConnectionState>((ref) {
  return ConnectionNotifier(ref.read(networkServiceProvider));
});

class ConnectionNotifier extends StateNotifier<DeviceConnectionState> {
  final NetworkService _networkService;
  StreamSubscription? _messageSubscription;

  ConnectionNotifier(this._networkService)
      : super(DeviceConnectionState()) {
    // 监听网络服务的消息
    _messageSubscription = _networkService.messageStream?.listen(_handleMessage);
  }

  void _handleMessage(String message) {
    final messages = List<String>.from(state.messages)..add(message);
    state = state.copyWith(messages: messages);

    if (message.contains('收到配对请求')) {
      // 从消息中提取设备名称
      final deviceNameStart = message.indexOf('设备:') + 4;
      final deviceName = message.substring(deviceNameStart).trim();
      
      state = state.copyWith(
        status: ConnectionStatus.receivingRequest,
        device: Device(
          name: deviceName,
          ipAddress: 'Unknown', // 这里可以从连接中获取IP
        ),
      );
    } else if (message.contains('pair_response')) {
      if (message.contains('accepted')) {
        state = state.copyWith(
          status: ConnectionStatus.connected,
          device: state.device?.copyWith(isConnected: true),
        );
      } else if (message.contains('rejected')) {
        state = state.copyWith(
          status: ConnectionStatus.disconnected,
          errorMessage: '连接被拒绝',
        );
      }
    } else if (message.contains('error:')) {
      state = state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: message.substring(message.indexOf(':') + 1).trim(),
      );
    }
  }

  Future<void> connect(String name, String ipAddress) async {
    state = state.copyWith(
      device: Device(name: name, ipAddress: ipAddress),
      status: ConnectionStatus.connecting,
      errorMessage: null,
      messages: [],
    );

    final status = await _networkService.connect(ipAddress, name);
    if (status == ConnectionStatus.error) {
      state = state.copyWith(
        status: status,
        errorMessage: '连接失败',
      );
    } else {
      state = state.copyWith(status: status);
    }
  }

  Future<void> acceptConnection() async {
    await _networkService.acceptConnection();
    state = state.copyWith(
      status: ConnectionStatus.connected,
      device: state.device?.copyWith(isConnected: true),
    );
  }

  Future<void> rejectConnection() async {
    await _networkService.rejectConnection();
    state = state.copyWith(
      status: ConnectionStatus.disconnected,
      device: state.device?.copyWith(isConnected: false),
    );
  }

  Future<void> disconnect() async {
    await _networkService.disconnect();
    state = DeviceConnectionState();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
}
