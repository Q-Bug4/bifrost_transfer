/// 网络相关常量
class NetworkConstants {
  /// 私有构造函数，防止实例化
  NetworkConstants._();
  
  /// 监听端口
  static const int LISTEN_PORT = 30080;
  
  /// 数据传输端口
  static const int DATA_PORT = 30081;
  
  /// 控制端口
  static const int CONTROL_PORT = 30082;
  
  /// 连接请求超时（毫秒）
  static const int CONNECTION_REQUEST_TIMEOUT_MS = 10000;
  
  /// 配对确认超时（毫秒）
  static const int PAIRING_CONFIRMATION_TIMEOUT_MS = 30000;
  
  /// 心跳检测间隔（毫秒）
  static const int HEARTBEAT_INTERVAL_MS = 5000;
  
  /// 心跳响应超时（毫秒）
  static const int HEARTBEAT_TIMEOUT_MS = 3000;
  
  /// 最大连接重试次数
  static const int MAX_CONNECTION_RETRIES = 3;
  
  /// 重试间隔（毫秒）
  static const int RETRY_INTERVAL_MS = 2000;
  
  /// 协议版本
  static const String PROTOCOL_VERSION = "1.0";
} 