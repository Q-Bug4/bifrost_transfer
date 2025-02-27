import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:logging/logging.dart';
import '../models/socket_message_model.dart';
import 'socket_communication_service.dart';
import '../../infrastructure/constants/network_constants.dart';

/// Socket通信服务实现类
class SocketCommunicationServiceImpl implements SocketCommunicationService {
  /// 日志记录器
  final _logger = Logger('SocketCommunicationServiceImpl');
  
  /// 服务器Socket
  ServerSocket? _server;
  
  /// 客户端Socket
  Socket? _clientSocket;
  
  /// 消息控制器
  final _messageController = StreamController<SocketMessageModel>.broadcast();
  
  /// 连接状态控制器
  final _connectionStatusController = StreamController<bool>.broadcast();
  
  /// 心跳检测计时器
  Timer? _heartbeatTimer;
  
  /// 心跳响应超时计时器
  Timer? _heartbeatTimeoutTimer;
  
  /// 最后一次收到心跳响应的时间
  DateTime? _lastHeartbeatResponse;
  
  /// 连接重试次数
  int _connectionRetryCount = 0;
  
  /// 当前是否已连接
  bool _isConnected = false;
  
  @override
  bool get isConnected => _isConnected;
  
  @override
  Stream<SocketMessageModel> get messageStream => _messageController.stream;
  
  @override
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  
  @override
  Future<void> startServer() async {
    if (_server != null) {
      _logger.info('服务器已经在运行');
      return;
    }
    
    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, NetworkConstants.LISTEN_PORT);
      _logger.info('服务器启动成功，监听端口: ${NetworkConstants.LISTEN_PORT}');
      
      _server!.listen(
        _handleClientConnection,
        onError: (error) {
          _logger.severe('服务器错误: $error');
        },
        onDone: () {
          _logger.info('服务器已关闭');
        },
        cancelOnError: false,
      );
    } catch (e) {
      _logger.severe('启动服务器失败: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> stopServer() async {
    await _server?.close();
    _server = null;
    _logger.info('服务器已停止');
  }
  
  @override
  Future<bool> connectToDevice(String ip, {int port = NetworkConstants.LISTEN_PORT}) async {
    if (_clientSocket != null) {
      _logger.warning('已经连接到设备，请先断开连接');
      return false;
    }
    
    _connectionRetryCount = 0;
    return _attemptConnection(ip, port);
  }
  
  /// 尝试连接到远程设备
  Future<bool> _attemptConnection(String ip, int port) async {
    try {
      _logger.info('尝试连接到设备: $ip:$port (尝试 ${_connectionRetryCount + 1}/${NetworkConstants.MAX_CONNECTION_RETRIES})');
      
      // 设置连接超时时间为3秒
      _clientSocket = await Socket.connect(ip, port, 
          timeout: const Duration(seconds: 3));
      
      _logger.info('成功连接到设备: $ip:$port');
      
      // 设置Socket数据处理
      _setupSocketListeners(_clientSocket!);
      
      // 更新连接状态
      _updateConnectionStatus(true);
      
      // 启动心跳检测
      _startHeartbeat();
      
      return true;
    } catch (e) {
      _logger.warning('连接到设备失败: $ip:$port, 错误: $e');
      
      // 如果还有重试次数，则重试
      if (_connectionRetryCount < NetworkConstants.MAX_CONNECTION_RETRIES) {
        _connectionRetryCount++;
        
        // 延迟一段时间后重试
        await Future.delayed(Duration(milliseconds: NetworkConstants.RETRY_INTERVAL_MS));
        return _attemptConnection(ip, port);
      }
      
      _updateConnectionStatus(false);
      return false;
    }
  }
  
  @override
  Future<void> disconnectFromDevice() async {
    // 停止心跳检测
    _stopHeartbeat();
    
    // 发送断开连接消息
    if (_clientSocket != null && _isConnected) {
      try {
        final disconnectMessage = SocketMessageModel.createDisconnect(
          reason: '用户主动断开连接',
        );
        
        await sendMessage(disconnectMessage);
        
        // 等待一小段时间，确保消息发送完成
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        _logger.warning('发送断开连接消息失败: $e');
      }
    }
    
    // 关闭Socket
    await _clientSocket?.close();
    _clientSocket = null;
    
    // 更新连接状态
    _updateConnectionStatus(false);
    
    _logger.info('已断开与远程设备的连接');
  }
  
  @override
  Future<bool> sendMessage(SocketMessageModel message) async {
    if (_clientSocket == null || !_isConnected) {
      _logger.warning('未连接到设备，无法发送消息');
      return false;
    }
    
    try {
      final jsonStr = message.toJson();
      final data = utf8.encode(jsonStr);
      
      // 添加消息长度前缀（4字节整数）
      final dataLength = data.length;
      final header = ByteData(4)..setUint32(0, dataLength, Endian.big);
      final headerList = header.buffer.asUint8List();
      
      // 发送消息长度和消息内容
      _clientSocket!.add(headerList);
      _clientSocket!.add(data);
      await _clientSocket!.flush();
      
      _logger.fine('发送消息: ${message.type}, 长度: $dataLength 字节');
      return true;
    } catch (e) {
      _logger.severe('发送消息失败: $e');
      
      // 如果发送失败，可能是连接已断开
      if (_isConnected) {
        _handleConnectionLost();
      }
      
      return false;
    }
  }
  
  /// 处理客户端连接
  void _handleClientConnection(Socket client) {
    _logger.info('接收到客户端连接: ${client.remoteAddress.address}:${client.remotePort}');
    
    // 如果已经有连接，拒绝新的连接
    if (_clientSocket != null && _isConnected) {
      _logger.warning('已有连接，拒绝新的连接请求');
      client.close();
      return;
    }
    
    // 保存客户端Socket
    _clientSocket = client;
    
    // 设置Socket数据处理
    _setupSocketListeners(client);
    
    // 更新连接状态
    _updateConnectionStatus(true);
    
    // 启动心跳检测
    _startHeartbeat();
  }
  
  /// 设置Socket监听器
  void _setupSocketListeners(Socket socket) {
    // 用于缓存不完整的消息
    List<int> buffer = [];
    int? expectedLength;
    
    socket.listen(
      (data) {
        // 将新数据添加到缓冲区
        buffer.addAll(data);
        
        // 处理缓冲区中的所有完整消息
        while (buffer.isNotEmpty) {
          // 如果还没有读取消息长度
          if (expectedLength == null) {
            // 如果缓冲区中的数据不足以读取长度（4字节），等待更多数据
            if (buffer.length < 4) {
              break;
            }
            
            // 读取消息长度
            final headerBytes = Uint8List.fromList(buffer.sublist(0, 4));
            final header = ByteData.view(headerBytes.buffer);
            expectedLength = header.getUint32(0, Endian.big);
            
            // 从缓冲区中移除长度字节
            buffer = buffer.sublist(4);
          }
          
          // 如果缓冲区中的数据不足以读取完整消息，等待更多数据
          if (buffer.length < expectedLength!) {
            break;
          }
          
          // 读取完整消息
          final messageBytes = buffer.sublist(0, expectedLength!);
          final messageStr = utf8.decode(messageBytes);
          
          // 从缓冲区中移除已处理的消息
          buffer = buffer.sublist(expectedLength!);
          expectedLength = null;
          
          // 解析并处理消息
          _handleMessage(messageStr);
        }
      },
      onError: (error) {
        _logger.severe('Socket错误: $error');
        _handleConnectionLost();
      },
      onDone: () {
        _logger.info('Socket连接已关闭');
        _handleConnectionLost();
      },
      cancelOnError: false,
    );
  }
  
  /// 处理接收到的消息
  void _handleMessage(String messageStr) {
    try {
      final message = SocketMessageModel.fromJson(messageStr);
      _logger.fine('接收到消息: ${message.type}');
      
      // 处理心跳消息
      if (message.type == SocketMessageType.PING) {
        // 收到PING，回复PONG
        sendMessage(SocketMessageModel.createPong());
        return;
      } else if (message.type == SocketMessageType.PONG) {
        // 收到PONG，更新最后心跳响应时间
        _lastHeartbeatResponse = DateTime.now();
        _heartbeatTimeoutTimer?.cancel();
        return;
      } else if (message.type == SocketMessageType.DISCONNECT) {
        // 收到断开连接消息，主动断开连接
        _logger.info('收到断开连接消息: ${message.data['reason'] ?? '无原因'}');
        disconnectFromDevice();
        return;
      }
      
      // 将消息发送到消息流
      _messageController.add(message);
    } catch (e) {
      _logger.severe('处理消息失败: $e, 消息内容: $messageStr');
    }
  }
  
  /// 处理连接丢失
  void _handleConnectionLost() {
    if (!_isConnected) {
      return;
    }
    
    _logger.warning('连接丢失');
    
    // 停止心跳检测
    _stopHeartbeat();
    
    // 关闭Socket
    _clientSocket?.close();
    _clientSocket = null;
    
    // 更新连接状态
    _updateConnectionStatus(false);
  }
  
  /// 更新连接状态
  void _updateConnectionStatus(bool connected) {
    if (_isConnected != connected) {
      _isConnected = connected;
      _connectionStatusController.add(connected);
      _logger.info('连接状态更新: $connected');
    }
  }
  
  /// 启动心跳检测
  void _startHeartbeat() {
    // 停止现有的心跳检测
    _stopHeartbeat();
    
    // 设置最后心跳响应时间为当前时间
    _lastHeartbeatResponse = DateTime.now();
    
    // 启动心跳检测定时器
    _heartbeatTimer = Timer.periodic(
      Duration(milliseconds: NetworkConstants.HEARTBEAT_INTERVAL_MS),
      (_) => _sendHeartbeat(),
    );
    
    _logger.info('心跳检测已启动，间隔: ${NetworkConstants.HEARTBEAT_INTERVAL_MS} ms');
  }
  
  /// 停止心跳检测
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    
    _heartbeatTimeoutTimer?.cancel();
    _heartbeatTimeoutTimer = null;
    
    _lastHeartbeatResponse = null;
    
    _logger.info('心跳检测已停止');
  }
  
  /// 发送心跳检测
  void _sendHeartbeat() {
    if (!_isConnected || _clientSocket == null) {
      _stopHeartbeat();
      return;
    }
    
    // 发送PING消息
    sendMessage(SocketMessageModel.createPing());
    
    // 设置心跳响应超时计时器
    _heartbeatTimeoutTimer?.cancel();
    _heartbeatTimeoutTimer = Timer(
      Duration(milliseconds: NetworkConstants.HEARTBEAT_TIMEOUT_MS),
      _handleHeartbeatTimeout,
    );
  }
  
  /// 处理心跳响应超时
  void _handleHeartbeatTimeout() {
    if (!_isConnected) {
      return;
    }
    
    final now = DateTime.now();
    final lastResponse = _lastHeartbeatResponse;
    
    if (lastResponse == null || now.difference(lastResponse).inMilliseconds > NetworkConstants.HEARTBEAT_TIMEOUT_MS) {
      _logger.warning('心跳响应超时，断开连接');
      _handleConnectionLost();
    }
  }
  
  @override
  void dispose() {
    _stopHeartbeat();
    
    _clientSocket?.close();
    _clientSocket = null;
    
    _server?.close();
    _server = null;
    
    _messageController.close();
    _connectionStatusController.close();
    
    _logger.info('Socket通信服务已释放资源');
  }
} 