import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

import '../models/device_info.dart';
import '../models/network_message.dart';
import 'connection_manager.dart';

class DevicePairingService {
  static const String _pairedDevicesKey = 'paired_devices';
  final Logger _logger = Logger('DevicePairingService');
  final Random _random = Random.secure();
  late final SharedPreferences _preferences;
  final ConnectionManager _connectionManager = ConnectionManager();

  // 单例模式
  static final DevicePairingService _instance = DevicePairingService._internal();
  factory DevicePairingService() => _instance;
  DevicePairingService._internal();

  // 获取消息流
  Stream<NetworkMessage> get messageStream => _connectionManager.messageStream;

  // 初始化
  Future<void> initialize() async {
    try {
      _preferences = await SharedPreferences.getInstance();
      await _connectionManager.initialize();
      _logger.info('DevicePairingService initialized');
    } catch (e) {
      _logger.severe('Failed to initialize DevicePairingService: $e');
      rethrow;
    }
  }

  // 开始配对流程
  Future<bool> startPairing(DeviceInfo device, {String? pairingCode}) async {
    try {
      // 检查设备是否已配对
      final pairedDevices = await getPairedDevices();
      if (pairedDevices.contains(device)) {
        _logger.info('Device already paired: ${device.deviceName}');
        return true;
      }

      // 尝试连接设备
      device.connectionStatus = ConnectionStatus.connecting;
      final connected = await _connectionManager.connectToDevice(device);
      if (!connected) {
        _logger.warning('Failed to connect to device: ${device.deviceName}');
        return false;
      }

      // 使用提供的配对码或生成新的配对码
      final code = pairingCode ?? generatePairingCode();
      final message = NetworkMessage(
        type: 'pairing_request',
        deviceId: device.deviceId,
        data: {
          'pairingCode': code,
          'deviceName': device.deviceName,
          'deviceType': device.deviceType.toString(),
          'ipAddress': device.ipAddress,
        },
      );

      final sent = await _connectionManager.sendMessage(device.ipAddress, message);
      if (!sent) {
        _logger.warning('Failed to send pairing code to device: ${device.deviceName}');
        await _connectionManager.disconnectDevice(device);
        return false;
      }

      device.connectionStatus = ConnectionStatus.pairing;
      return true;
    } catch (e) {
      _logger.severe('Error during pairing process: ${device.deviceName} - $e');
      device.connectionStatus = ConnectionStatus.disconnected;
      await _connectionManager.disconnectDevice(device);
      return false;
    }
  }

  // 生成6位数字配对码
  String generatePairingCode() {
    final code = _random.nextInt(900000) + 100000; // 生成100000-999999之间的数字
    _logger.info('Generated pairing code: $code');
    return code.toString();
  }

  // 验证配对码
  Future<bool> verifyPairingCode(String inputCode, String expectedCode) async {
    final isValid = inputCode == expectedCode;
    _logger.info('Verifying pairing code: $inputCode, expected: $expectedCode, isValid: $isValid');
    return isValid;
  }

  // 确认配对
  Future<bool> confirmPairing(DeviceInfo device, bool confirmed) async {
    try {
      if (!confirmed) {
        await _connectionManager.sendPairingConfirmation(device, false);
        await _connectionManager.disconnectDevice(device);
        return false;
      }

      final sent = await _connectionManager.sendPairingConfirmation(device, true);
      if (!sent) {
        _logger.warning('Failed to send pairing confirmation: ${device.deviceName}');
        await _connectionManager.disconnectDevice(device);
        return false;
      }

      await savePairedDevice(device);
      return true;
    } catch (e) {
      _logger.severe('Error during pairing confirmation: ${device.deviceName} - $e');
      await _connectionManager.disconnectDevice(device);
      return false;
    }
  }

  // 保存已配对设备
  Future<void> savePairedDevice(DeviceInfo device) async {
    try {
      final pairedDevices = await getPairedDevices();
      if (!pairedDevices.contains(device)) {
        device.isPaired = true;
        pairedDevices.add(device);
        final devicesJson = pairedDevices.map((d) => d.toJson()).toList();
        await _preferences.setString(_pairedDevicesKey, jsonEncode(devicesJson));
        _logger.info('Saved paired device: ${device.deviceName}');
      }
    } catch (e) {
      _logger.severe('Error saving paired device: $e');
      rethrow;
    }
  }

  // 获取已配对设备列表
  Future<List<DeviceInfo>> getPairedDevices() async {
    try {
      final String? devicesJson = _preferences.getString(_pairedDevicesKey);
      if (devicesJson == null) return [];

      final List<dynamic> devicesList = jsonDecode(devicesJson);
      return devicesList
          .map((json) => DeviceInfo.fromJson(json))
          .toList();
    } catch (e) {
      _logger.severe('Error getting paired devices: $e');
      return [];
    }
  }

  // 移除已配对设备
  Future<void> removePairedDevice(String deviceId) async {
    try {
      final pairedDevices = await getPairedDevices();
      final device = pairedDevices.firstWhere(
        (d) => d.deviceId == deviceId,
        orElse: () => throw Exception('Device not found'),
      );

      await _connectionManager.disconnectDevice(device);
      pairedDevices.removeWhere((d) => d.deviceId == deviceId);
      
      final devicesJson = pairedDevices.map((d) => d.toJson()).toList();
      await _preferences.setString(_pairedDevicesKey, jsonEncode(devicesJson));
      _logger.info('Removed paired device: $deviceId');
    } catch (e) {
      _logger.severe('Error removing paired device: $e');
      rethrow;
    }
  }

  // 检查IP地址是否有效
  Future<bool> isValidIpAddress(String ipAddress) async {
    try {
      final result = await InternetAddress.lookup(ipAddress);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      _logger.warning('Invalid IP address: $ipAddress');
      return false;
    }
  }

  // 关闭服务
  Future<void> dispose() async {
    try {
      await _connectionManager.dispose();
      _logger.info('DevicePairingService disposed');
    } catch (e) {
      _logger.severe('Error disposing DevicePairingService: $e');
    }
  }
} 