import 'dart:async';
import '../models/socket_message_model.dart';
import '../models/connection_status.dart';

/// Socket通信服务接口
abstract class SocketCommunicationService {
  /// 初始化服务
  Future<void> init();

  /// 发送消息
  Future<void> sendMessage(SocketMessageModel message);

  /// 接收消息流
  Stream<SocketMessageModel> get messageStream;

  /// 关闭连接
  Future<void> close();

  /// 是否已连接
  bool get isConnected;

  /// 连接状态流
  Stream<bool> get connectionStateStream;

  /// 连接状态详细信息流
  Stream<ConnectionStatus> get connectionStatusStream;

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

  /// 释放资源
  ///
  /// 释放所有资源，包括关闭Socket连接、停止服务器等
  void dispose();
}
