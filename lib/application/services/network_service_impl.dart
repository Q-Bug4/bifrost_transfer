import 'dart:async';
import 'dart:io';
import '../../domain/models/device.dart';
import 'network_service.dart';

class NetworkServiceImpl implements NetworkService {
  static const defaultPort = 8080;
  
  ServerSocket? _server;
  Socket? _socket;
  final _connectionStatusController = StreamController<ConnectionStatus>.broadcast();
  final _incomingDataController = StreamController<List<int>>.broadcast();
  final _discoveredDevicesController = StreamController<List<Device>>.broadcast();
  Timer? _discoveryTimer;
  final List<Device> _devices = [];
  
  @override
  Stream<ConnectionStatus> get connectionStatus => _connectionStatusController.stream;

  @override
  Stream<List<int>> get incomingData => _incomingDataController.stream;

  @override
  Stream<List<Device>> get discoveredDevices => _discoveredDevicesController.stream;

  @override
  Future<void> startDiscovery() async {
    _discoveryTimer?.cancel();
    _discoveryTimer = Timer.periodic(const Duration(seconds: 5), (_) => _discoverDevices());
    await _discoverDevices();
  }

  @override
  Future<void> stopDiscovery() async {
    _discoveryTimer?.cancel();
    _discoveryTimer = null;
    _devices.clear();
    _discoveredDevicesController.add([]);
  }

  Future<void> _discoverDevices() async {
    try {
      final interfaces = await NetworkInterface.list();
      final localIps = interfaces
          .expand((interface) => interface.addresses)
          .where((addr) => addr.type == InternetAddressType.IPv4)
          .map((addr) => addr.address)
          .toList();

      for (final localIp in localIps) {
        final parts = localIp.split('.');
        if (parts.length == 4) {
          final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
          
          for (var i = 1; i <= 255; i++) {
            final targetIp = '$subnet.$i';
            if (!localIps.contains(targetIp)) {
              try {
                final socket = await Socket.connect(
                  targetIp,
                  defaultPort,
                  timeout: const Duration(milliseconds: 100),
                );
                
                final device = Device(
                  name: 'Device at $targetIp',
                  address: targetIp,
                  type: DeviceType.other,
                  isConnected: socket.address.address == _socket?.remoteAddress.address,
                );
                
                if (!_devices.any((d) => d.address == device.address)) {
                  _devices.add(device);
                  _discoveredDevicesController.add(List.from(_devices));
                }
                
                await socket.close();
              } catch (_) {
                // Device not available or timeout
              }
            }
          }
        }
      }
    } catch (e) {
      // Handle network scanning error
      print('Error during device discovery: $e');
    }
  }

  @override
  Future<bool> connectToDevice(String address) async {
    try {
      _connectionStatusController.add(ConnectionStatus.connecting);
      
      // Close existing connection if any
      await disconnect();
      
      // Connect to the remote device
      _socket = await Socket.connect(address, defaultPort);
      _setupSocketListeners(_socket!);
      
      _connectionStatusController.add(ConnectionStatus.connected);
      return true;
    } catch (e) {
      _connectionStatusController.add(ConnectionStatus.error);
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
    _connectionStatusController.add(ConnectionStatus.disconnected);
  }

  @override
  Future<String> getCurrentDeviceAddress() async {
    try {
      final interfaces = await NetworkInterface.list();
      // Filter for IPv4 addresses and prefer non-loopback
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
      // Fallback to first IPv4 address found
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4) {
            return addr.address;
          }
        }
      }
      throw Exception('No IPv4 address found');
    } catch (e) {
      throw Exception('Failed to get device address: $e');
    }
  }

  @override
  Future<void> sendData(List<int> data) async {
    if (_socket == null) {
      throw Exception('Not connected to any device');
    }
    _socket!.add(data);
    await _socket!.flush();
  }

  @override
  Future<void> startListening() async {
    if (_server != null) return;
    
    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, defaultPort);
      _server!.listen(_handleConnection);
    } catch (e) {
      _connectionStatusController.add(ConnectionStatus.error);
      throw Exception('Failed to start listening: $e');
    }
  }

  @override
  Future<void> stopListening() async {
    await _server?.close();
    _server = null;
  }

  void _handleConnection(Socket socket) {
    // Only accept one connection at a time
    if (_socket != null) {
      socket.close();
      return;
    }
    
    _socket = socket;
    _setupSocketListeners(socket);
    _connectionStatusController.add(ConnectionStatus.connected);
  }

  void _setupSocketListeners(Socket socket) {
    socket.listen(
      (data) => _incomingDataController.add(data),
      onError: (error) {
        _connectionStatusController.add(ConnectionStatus.error);
        disconnect();
      },
      onDone: () {
        _connectionStatusController.add(ConnectionStatus.disconnected);
        disconnect();
      },
    );
  }

  @override
  void dispose() {
    stopListening();
    disconnect();
    stopDiscovery();
    _connectionStatusController.close();
    _incomingDataController.close();
    _discoveredDevicesController.close();
  }
} 