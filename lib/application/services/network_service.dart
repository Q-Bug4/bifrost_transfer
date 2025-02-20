import 'dart:async';
import '../../domain/models/device.dart';

/// Interface defining the core networking functionality for device discovery and connections
abstract class NetworkService {
  /// Start listening for incoming connections
  Future<void> startListening();

  /// Stop listening for incoming connections
  Future<void> stopListening();

  /// Connect to a device at the given address
  /// Returns true if connection was successful
  Future<bool> connectToDevice(String address);

  /// Disconnect from the currently connected device
  Future<void> disconnect();

  /// Get the current connection status
  Stream<ConnectionStatus> get connectionStatus;

  /// Get the current device's IP address
  Future<String> getCurrentDeviceAddress();

  /// Send data to the connected device
  Future<void> sendData(List<int> data);

  /// Receive data from the connected device
  Stream<List<int>> get incomingData;

  /// Get the list of discovered devices
  Stream<List<Device>> get discoveredDevices;

  /// Start discovering devices on the network
  Future<void> startDiscovery();

  /// Stop discovering devices
  Future<void> stopDiscovery();
}

/// Represents the current connection status
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error
} 