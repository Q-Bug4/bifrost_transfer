import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:logging/logging.dart';

import '../models/device_info.dart';
import '../models/network_message.dart';

class NetworkService {
  static const int CONTROL_PORT = 30080;
  static const int DATA_PORT = 30081;
  static const Duration HEARTBEAT_INTERVAL = Duration(seconds: 30);
  static const Duration HEARTBEAT_TIMEOUT = Duration(seconds: 90);
  static const int MAX_RETRY_COUNT = 3;

  final Logger _logger = Logger('NetworkService');
  ServerSocket? _controlServer;
  final Map<String, Socket> _connections = {};
  final Map<String, Timer> _heartbeatTimers = {};
  final Map<String, StreamSubscription> _messageSubscriptions = {};
  final StreamController<NetworkMessage> _messageController = StreamController.broadcast();

  // 单例模式
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  Stream<NetworkMessage> get messageStream => _messageController.stream;

  // 初始化服务
  Future<void> initialize() async {
    try {
      await _startControlServer();
      _logger.info('Network service initialized');
    } catch (e) {
      _logger.severe('Failed to initialize network service: $e');
      rethrow;
    }
  }

  // 启动控制服务器
  Future<void> _startControlServer() async {
    try {
      _controlServer = await ServerSocket.bind(InternetAddress.anyIPv4, CONTROL_PORT);
      _logger.info('Control server started on port $CONTROL_PORT');

      _controlServer!.listen(
        (socket) => _handleNewConnection(socket),
        onError: (e) => _logger.severe('Control server error: $e'),
        onDone: () => _logger.info('Control server stopped'),
      );
    } catch (e) {
      _logger.severe('Failed to start control server: $e');
      rethrow;
    }
  }

  // 处理新连接
  void _handleNewConnection(Socket socket) {
    _logger.info('New connection from ${socket.remoteAddress.address}:${socket.remotePort}');
    
    // 创建消息处理器
    final subscription = _createMessageHandler(socket);
    
    // 开始心跳检测
    final timer = _startHeartbeat(socket);

    // 存储连接信息
    _connections[socket.remoteAddress.address] = socket;
    _messageSubscriptions[socket.remoteAddress.address] = subscription;
    _heartbeatTimers[socket.remoteAddress.address] = timer;

    // 监听连接关闭
    socket.done.then((_) => _handleDisconnection(socket.remoteAddress.address));
  }

  // 创建消息处理器
  StreamSubscription _createMessageHandler(Socket socket) {
    return socket
      .transform(StreamTransformer<Uint8List, String>.fromHandlers(
        handleData: (data, sink) => sink.add(utf8.decode(data)),
      ))
      .transform(const LineSplitter())
      .listen(
        (data) => _handleMessage(data, socket),
        onError: (e) => _logger.warning('Error handling message: $e'),
        onDone: () => _logger.info('Connection closed: ${socket.remoteAddress.address}'),
      );
  }

  // 处理消息
  void _handleMessage(String data, Socket socket) {
    try {
      final message = NetworkMessage.fromJson(jsonDecode(data));
      _logger.fine('Received message: $message');

      // 处理心跳消息
      if (message.type == 'heartbeat') {
        _resetHeartbeatTimer(socket.remoteAddress.address);
        return;
      }

      // 处理发现消息
      if (message.type == 'discovery') {
        // 将消息转发给上层处理
        _messageController.add(message);
        return;
      }

      // 处理配对请求
      if (message.type == 'pairing_request') {
        // 将消息转发给上层处理，包含发送方的IP地址
        final messageWithIp = NetworkMessage(
          type: message.type,
          deviceId: message.deviceId,
          data: {
            ...message.data,
            'ipAddress': socket.remoteAddress.address,
          },
        );
        _messageController.add(messageWithIp);
        return;
      }

      // 处理配对响应
      if (message.type == 'pairing_response') {
        // 将消息转发给上层处理
        _messageController.add(message);
        return;
      }

      // 处理配对确认
      if (message.type == 'pairing_confirmation') {
        // 将消息转发给上层处理
        _messageController.add(message);
        return;
      }

      _messageController.add(message);
    } catch (e) {
      _logger.warning('Failed to parse message: $e');
    }
  }

  // 发送消息
  Future<bool> sendMessage(String ipAddress, NetworkMessage message) async {
    try {
      final socket = _connections[ipAddress];
      if (socket == null) {
        _logger.warning('No connection to $ipAddress');
        return false;
      }

      socket.writeln(message.toString());
      await socket.flush();
      return true;
    } catch (e) {
      _logger.severe('Failed to send message: $e');
      return false;
    }
  }

  // 连接到设备
  Future<bool> connectToDevice(DeviceInfo device) async {
    if (_connections.containsKey(device.ipAddress)) {
      return true;
    }

    try {
      final socket = await Socket.connect(
        device.ipAddress,
        CONTROL_PORT,
        timeout: const Duration(seconds: 30),
      );

      _handleNewConnection(socket);

      // 发送设备发现消息
      final discoveryMessage = NetworkMessage(
        type: 'discovery',
        deviceId: device.deviceId,
        data: {
          'deviceName': device.deviceName,
          'deviceType': device.deviceType.toString(),
          'ipAddress': device.ipAddress,
        },
      );

      return await sendMessage(device.ipAddress, discoveryMessage);
    } catch (e) {
      _logger.severe('Failed to connect to device: $e');
      return false;
    }
  }

  // 断开连接
  Future<void> disconnectFromDevice(String ipAddress) async {
    final socket = _connections.remove(ipAddress);
    final subscription = _messageSubscriptions.remove(ipAddress);
    final timer = _heartbeatTimers.remove(ipAddress);

    try {
      await subscription?.cancel();
      timer?.cancel();
      await socket?.close();
    } catch (e) {
      _logger.warning('Error during disconnection: $e');
    }
  }

  // 开始心跳检测
  Timer _startHeartbeat(Socket socket) {
    final ipAddress = socket.remoteAddress.address;
    
    // 发送心跳消息
    void sendHeartbeat() {
      final message = NetworkMessage(
        type: 'heartbeat',
        deviceId: 'local',
        data: {'timestamp': DateTime.now().millisecondsSinceEpoch},
      );
      sendMessage(ipAddress, message);
    }

    // 设置心跳超时处理
    void handleHeartbeatTimeout() {
      _logger.warning('Heartbeat timeout for $ipAddress');
      
      // 发送配对拒绝消息
      final message = NetworkMessage(
        type: 'pairing_rejected',
        deviceId: 'local',
        data: {'message': '连接超时，配对失败'},
      );
      _messageController.add(message);

      disconnectFromDevice(ipAddress);
    }

    // 创建定时器
    final timer = Timer.periodic(HEARTBEAT_INTERVAL, (_) => sendHeartbeat());
    
    // 设置超时检测
    Timer(HEARTBEAT_TIMEOUT, handleHeartbeatTimeout);

    return timer;
  }

  // 重置心跳定时器
  void _resetHeartbeatTimer(String ipAddress) {
    _heartbeatTimers[ipAddress]?.cancel();
    final socket = _connections[ipAddress];
    if (socket != null) {
      _heartbeatTimers[ipAddress] = _startHeartbeat(socket);
    }
  }

  // 处理断开连接
  void _handleDisconnection(String ipAddress) {
    _logger.info('Handling disconnection for $ipAddress');
    disconnectFromDevice(ipAddress);
  }

  // 关闭服务
  Future<void> dispose() async {
    try {
      // 关闭所有连接
      for (final ipAddress in _connections.keys.toList()) {
        await disconnectFromDevice(ipAddress);
      }

      // 关闭控制服务器
      await _controlServer?.close();
      
      // 关闭消息控制器
      await _messageController.close();

      _logger.info('Network service disposed');
    } catch (e) {
      _logger.severe('Error disposing network service: $e');
    }
  }
} 