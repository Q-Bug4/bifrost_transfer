import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connection_provider.dart';
import '../utils/logger.dart';

final networkServiceProvider = Provider((ref) => NetworkService());

class NetworkService {
  static const _tag = 'NetworkService';
  Socket? _socket;
  ServerSocket? _server;
  final int _port = 38818;
  
  StreamController<String>? _messageController;
  Stream<String>? get messageStream => _messageController?.stream;

  // 初始化服务器
  Future<void> initialize() async {
    await _cleanup();
    _messageController = StreamController<String>.broadcast();
    await _startServer();
  }

  Future<void> _startServer() async {
    try {
      if (_server != null) {
        await _server!.close();
        _server = null;
      }

      _server = await ServerSocket.bind(InternetAddress.anyIPv4, _port);
      _addMessage('服务器启动在端口 $_port');

      _server!.listen(
        (Socket client) {
          _addMessage('收到来自 ${client.remoteAddress.address} 的连接');
          
          client.listen(
            (List<int> data) {
              final message = utf8.decode(data);
              _addMessage('收到消息: $message');
              
              try {
                final json = jsonDecode(message);
                if (json['type'] == 'pair_request') {
                  _addMessage('收到配对请求，来自设备: ${json['device_name']}');
                  _socket = client;
                } else if (json['type'] == 'pair_response') {
                  _addMessage('收到配对响应: ${json['status']}');
                }
              } catch (e) {
                _addMessage('解析消息失败: $e');
              }
            },
            onError: (error) {
              _addMessage('客户端错误: $error');
              client.destroy();
            },
            onDone: () {
              _addMessage('客户端断开连接');
              if (_socket == client) {
                _socket = null;
              }
              client.destroy();
            },
          );
        },
        onError: (error) {
          _addMessage('服务器错误: $error');
        },
        onDone: () {
          _addMessage('服务器关闭');
        },
      );
    } catch (e) {
      _addMessage('启动服务器失败: $e');
      rethrow;
    }
  }

  void _addMessage(String message) {
    Logger.log(_tag, message);
    _messageController?.add(message);
  }

  Future<ConnectionStatus> connect(String address, String deviceName) async {
    try {
      if (_messageController == null || _messageController!.isClosed) {
        _messageController = StreamController<String>.broadcast();
      }

      _addMessage('正在连接到 $address:$_port...');

      // 尝试连接到目标设备
      _socket = await Socket.connect(address, _port, timeout: const Duration(seconds: 5));
      _addMessage('已连接到 $address');

      // 设置Socket选项以减少延迟
      _socket!.setOption(SocketOption.tcpNoDelay, true);

      // 监听Socket事件
      _socket!.listen(
        (data) {
          final message = utf8.decode(data);
          _addMessage('收到数据: $message');
          try {
            final json = jsonDecode(message);
            if (json['type'] == 'pair_response') {
              _addMessage('收到配对响应: ${json['status']}');
            }
          } catch (e) {
            _addMessage('解析数据失败: $e');
          }
        },
        onError: (error) {
          _addMessage('连接错误: $error');
          _cleanup();
        },
        onDone: () {
          _addMessage('连接已关闭');
          _cleanup();
        },
      );

      // 发送配对请求
      final pairRequest = {
        'type': 'pair_request',
        'device_name': deviceName,
      };
      final requestJson = jsonEncode(pairRequest);
      _socket!.write(requestJson);
      _addMessage('已发送配对请求');

      return ConnectionStatus.awaitingConfirmation;
    } on SocketException catch (e) {
      _addMessage('连接失败: ${e.message}');
      return ConnectionStatus.error;
    } catch (e) {
      _addMessage('发生错误: $e');
      return ConnectionStatus.error;
    }
  }

  Future<void> acceptConnection() async {
    if (_socket != null) {
      try {
        final response = {
          'type': 'pair_response',
          'status': 'accepted',
        };
        final responseJson = jsonEncode(response);
        _socket!.write(responseJson);
        _addMessage('已接受连接请求');
      } catch (e) {
        _addMessage('发送接受响应失败: $e');
        rethrow;
      }
    }
  }

  Future<void> rejectConnection() async {
    if (_socket != null) {
      try {
        final response = {
          'type': 'pair_response',
          'status': 'rejected',
        };
        final responseJson = jsonEncode(response);
        _socket!.write(responseJson);
        _addMessage('已拒绝连接请求');
      } catch (e) {
        _addMessage('发送拒绝响应失败: $e');
      } finally {
        await disconnect();
      }
    }
  }

  Future<void> disconnect() async {
    if (_socket != null) {
      try {
        await _socket!.flush();
        _socket!.destroy();
        _socket = null;
      } catch (e) {
        Logger.error(_tag, '断开连接时发生错误', e);
      }
    }
  }

  Future<void> _cleanup() async {
    try {
      await disconnect();
      
      if (_server != null) {
        await _server!.close();
        _server = null;
      }
      
      await _messageController?.close();
      _messageController = null;
    } catch (e) {
      Logger.error(_tag, '清理资源时发生错误', e);
    }
  }
}
