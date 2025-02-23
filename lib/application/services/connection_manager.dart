import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';

import '../models/device_info.dart';
import '../models/network_message.dart';
import 'network_service.dart';

class ConnectionManager {
  final Logger _logger = Logger('ConnectionManager');
  final NetworkService _networkService = NetworkService();
  final Map<String, StreamSubscription> _messageSubscriptions = {};
  final StreamController<NetworkMessage> _messageController = StreamController<NetworkMessage>.broadcast();

  Stream<NetworkMessage> get messageStream => _messageController.stream;

  // 单例模式
  static final ConnectionManager _instance = ConnectionManager._internal();
  factory ConnectionManager() => _instance;
  ConnectionManager._internal();

  // 初始化
  Future<void> initialize() async {
    try {
      await _networkService.initialize();
      _setupMessageHandling();
      _logger.info('ConnectionManager initialized');
    } catch (e) {
      _logger.severe('Failed to initialize ConnectionManager: $e');
      rethrow;
    }
  }

  // 设置消息处理
  void _setupMessageHandling() {
    _networkService.messageStream.listen(
      (message) => _handleNetworkMessage(message),
      onError: (e) => _logger.severe('Error handling network message: $e'),
    );
  }

  // 处理网络消息
  void _handleNetworkMessage(NetworkMessage message) {
    switch (message.type) {
      case 'discovery':
        _handleDiscoveryMessage(message);
        break;
      case 'pairing_request':
        _handlePairingRequest(message);
        break;
      case 'pairing_response':
        _handlePairingResponse(message);
        break;
      case 'pairing_confirmation':
        _handlePairingConfirmation(message);
        break;
      default:
        _logger.warning('Unknown message type: ${message.type}');
    }
  }

  // 处理设备发现消息
  void _handleDiscoveryMessage(NetworkMessage message) {
    _logger.info('Received discovery message: ${message.data}');
    // 这里可以添加设备到可用设备列表
  }

  // 处理配对请求
  void _handlePairingRequest(NetworkMessage message) {
    _logger.info('Received pairing request: ${message.data}');
    
    // 从消息中获取设备信息
    final deviceInfo = DeviceInfo(
      deviceId: message.deviceId,
      deviceName: message.data['deviceName'] ?? 'Unknown Device',
      ipAddress: message.data['ipAddress'] ?? '',
      deviceType: DeviceType.unknown,
      connectionStatus: ConnectionStatus.pairing,
    );

    // 发送到状态管理器，由UI层处理配对请求
    _messageController.add(NetworkMessage(
      type: 'show_pairing_request',
      deviceId: message.deviceId,
      data: {
        'deviceInfo': deviceInfo.toJson(),
        'pairingCode': message.data['pairingCode'],
      },
    ));
  }

  // 处理配对响应
  void _handlePairingResponse(NetworkMessage message) {
    _logger.info('Received pairing response: ${message.data}');
    final accepted = message.data['accepted'] as bool;
    
    if (accepted) {
      // 发送配对确认
      sendPairingConfirmation(
        DeviceInfo(
          deviceId: message.deviceId,
          deviceName: message.data['deviceName'] ?? 'Unknown Device',
          ipAddress: message.data['ipAddress'] ?? '',
          deviceType: DeviceType.unknown,
          connectionStatus: ConnectionStatus.connected,
        ),
        true,
      );
    } else {
      // 通知UI配对被拒绝
      _messageController.add(NetworkMessage(
        type: 'pairing_rejected',
        deviceId: message.deviceId,
        data: {'message': message.data['message'] ?? '配对被拒绝'},
      ));
    }
  }

  // 处理配对确认
  void _handlePairingConfirmation(NetworkMessage message) {
    _logger.info('Received pairing confirmation: ${message.data}');
    final confirmed = message.data['confirmed'] as bool;
    
    if (confirmed) {
      // 通知UI配对成功
      _messageController.add(NetworkMessage(
        type: 'pairing_completed',
        deviceId: message.deviceId,
        data: {'message': '配对成功'},
      ));
    }
  }

  // 连接到设备
  Future<bool> connectToDevice(DeviceInfo device) async {
    try {
      _logger.info('Connecting to device: ${device.deviceName} (${device.ipAddress})');
      
      final connected = await _networkService.connectToDevice(device);
      if (!connected) {
        _logger.warning('Failed to connect to device: ${device.deviceName}');
        device.connectionStatus = ConnectionStatus.disconnected;
        return false;
      }

      device.connectionStatus = ConnectionStatus.connecting;
      _logger.info('Connected to device: ${device.deviceName}');
      return true;
    } catch (e) {
      _logger.severe('Error connecting to device: ${device.deviceName} - $e');
      device.connectionStatus = ConnectionStatus.disconnected;
      return false;
    }
  }

  // 断开与设备的连接
  Future<void> disconnectDevice(DeviceInfo device) async {
    try {
      await _networkService.disconnectFromDevice(device.ipAddress);
      device.connectionStatus = ConnectionStatus.disconnected;
      _logger.info('Disconnected from device: ${device.deviceName}');
    } catch (e) {
      _logger.warning('Error disconnecting from device: ${device.deviceName} - $e');
    }
  }

  // 发送消息
  Future<bool> sendMessage(String ipAddress, NetworkMessage message) async {
    try {
      _logger.info('Sending message to $ipAddress: ${message.type}');
      return await _networkService.sendMessage(ipAddress, message);
    } catch (e) {
      _logger.severe('Error sending message: $e');
      return false;
    }
  }

  // 发送配对码到设备
  Future<bool> sendPairingCode(DeviceInfo device, String pairingCode) async {
    try {
      final message = NetworkMessage(
        type: 'pairing_request',
        deviceId: device.deviceId,
        data: {
          'pairingCode': pairingCode,
          'deviceName': device.deviceName,
          'deviceType': device.deviceType.toString(),
          'ipAddress': device.ipAddress,
        },
      );

      final sent = await sendMessage(device.ipAddress, message);
      if (sent) {
        device.connectionStatus = ConnectionStatus.pairing;
        _logger.info('Sent pairing code to device: ${device.deviceName}');
      } else {
        _logger.warning('Failed to send pairing code to device: ${device.deviceName}');
      }
      return sent;
    } catch (e) {
      _logger.severe('Error sending pairing code: ${device.deviceName} - $e');
      return false;
    }
  }

  // 发送配对确认
  Future<bool> sendPairingConfirmation(DeviceInfo device, bool confirmed) async {
    try {
      final message = NetworkMessage(
        type: 'pairing_confirmation',
        deviceId: device.deviceId,
        data: {'confirmed': confirmed},
      );

      final sent = await _networkService.sendMessage(device.ipAddress, message);
      if (sent) {
        device.connectionStatus = confirmed ? ConnectionStatus.connected : ConnectionStatus.disconnected;
        _logger.info('Sent pairing confirmation to device: ${device.deviceName}');
      } else {
        _logger.warning('Failed to send pairing confirmation to device: ${device.deviceName}');
      }
      return sent;
    } catch (e) {
      _logger.severe('Error sending pairing confirmation: ${device.deviceName} - $e');
      return false;
    }
  }

  // 获取连接状态
  ConnectionStatus getConnectionStatus(DeviceInfo device) {
    return device.connectionStatus;
  }

  // 关闭管理器
  Future<void> dispose() async {
    try {
      // 取消所有消息订阅
      for (final subscription in _messageSubscriptions.values) {
        await subscription.cancel();
      }
      _messageSubscriptions.clear();

      // 关闭网络服务
      await _networkService.dispose();
      
      _logger.info('ConnectionManager disposed');
    } catch (e) {
      _logger.severe('Error disposing ConnectionManager: $e');
    }
  }
} 