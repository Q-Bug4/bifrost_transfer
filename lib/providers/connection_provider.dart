import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device.dart';
import '../services/network_service.dart';

final connectionStateProvider = StateNotifierProvider<ConnectionNotifier, Device?>((ref) {
  return ConnectionNotifier(ref.watch(networkServiceProvider));
});

class ConnectionNotifier extends StateNotifier<Device?> {
  final NetworkService _networkService;
  
  ConnectionNotifier(this._networkService) : super(null);

  Future<void> connect(String name, String ipAddress) async {
    state = Device(name: name, ipAddress: ipAddress);
    
    final isConnected = await _networkService.testConnection(ipAddress);
    if (isConnected) {
      state = state?.copyWith(isConnected: true);
    } else {
      state = null;
    }
  }

  void disconnect() {
    state = null;
  }
}
