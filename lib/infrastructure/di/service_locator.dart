import 'package:get_it/get_it.dart';
import '../../application/services/connection_service.dart';
import '../../application/services/connection_service_impl.dart';
import '../../application/services/socket_communication_service.dart';
import '../../application/services/socket_communication_service_impl.dart';

/// 全局服务定位器实例
final GetIt serviceLocator = GetIt.instance;

/// 初始化服务定位器
void setupServiceLocator() {
  // 注册Socket通信服务
  serviceLocator.registerLazySingleton<SocketCommunicationService>(
    () => SocketCommunicationServiceImpl(),
  );
  
  // 注册连接服务
  serviceLocator.registerLazySingleton<ConnectionService>(
    () => ConnectionServiceImpl(serviceLocator<SocketCommunicationService>()),
  );
} 