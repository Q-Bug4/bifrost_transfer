import 'dart:async';
import '../models/socket_message_model.dart';

/// Socket通信服务接口
abstract class SocketCommunicationService {
  /// 当前是否已连接
  bool get isConnected;
  
  /// 消息流，用于接收来自远程设备的消息
  Stream<SocketMessageModel> get messageStream;
  
  /// 连接状态流，用于监听连接状态变化
  Stream<bool> get connectionStatusStream;
  
  /// 启动Socket服务器
  /// 
  /// 启动服务器，监听指定端口，等待客户端连接
  /// 
  /// 返回：启动成功返回true，否则返回false
  Future<void> startServer();
  
  /// 停止Socket服务器
  /// 
  /// 停止服务器，关闭所有连接
  Future<void> stopServer();
  
  /// 连接到远程设备
  /// 
  /// [ip] 远程设备IP地址
  /// [port] 远程设备端口号，默认为8000
  /// 
  /// 返回：连接成功返回true，否则返回false
  Future<bool> connectToDevice(String ip, {int port});
  
  /// 断开与远程设备的连接
  /// 
  /// 主动断开与远程设备的连接
  Future<void> disconnectFromDevice();
  
  /// 发送消息到远程设备
  /// 
  /// [message] 要发送的消息
  /// 
  /// 返回：发送成功返回true，否则返回false
  Future<bool> sendMessage(SocketMessageModel message);
  
  /// 释放资源
  /// 
  /// 释放所有资源，包括关闭Socket连接、停止服务器等
  void dispose();
} 