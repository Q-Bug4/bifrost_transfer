import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../services/file_picker_service.dart';
import '../services/file_picker_service_impl.dart';
import '../services/file_transfer_service.dart';
import '../services/file_transfer_service_impl.dart';
import '../states/file_transfer_state_notifier.dart';
import '../services/socket_communication_service.dart';
import '../services/socket_communication_service_impl.dart';
import '../services/connection_service.dart';
import '../services/connection_service_impl.dart';
import '../services/device_info_service.dart';
import '../services/device_info_service_impl.dart';
import '../services/text_transfer_service.dart';
import '../services/text_transfer_service_impl.dart';

/// 服务定位器
class ServiceLocator {
  /// 私有构造函数
  ServiceLocator._();

  /// 初始化服务定位器
  static void init() {
    final getIt = GetIt.instance;

    // 注册服务
    getIt.registerLazySingleton<FilePickerService>(
      () => FilePickerServiceImpl(),
    );

    getIt.registerLazySingleton<SocketCommunicationService>(
      () => SocketCommunicationServiceImpl(),
    );

    getIt.registerLazySingleton<FileTransferService>(
      () => FileTransferServiceImpl(
        socketService: getIt<SocketCommunicationService>(),
      ),
    );

    getIt.registerLazySingleton<FileTransferStateNotifier>(
      () => FileTransferStateNotifier(
        fileTransferService: getIt<FileTransferService>(),
      ),
    );

    getIt.registerLazySingleton<ConnectionService>(
      () => ConnectionServiceImpl(getIt<SocketCommunicationService>()),
    );

    getIt.registerLazySingleton<DeviceInfoService>(
      () => DeviceInfoServiceImpl(),
    );

    getIt.registerLazySingleton<TextTransferService>(
      () => TextTransferServiceImpl(getIt<SocketCommunicationService>()),
    );
  }

  /// 获取Provider列表
  static List<ChangeNotifierProvider<FileTransferStateNotifier>>
      getProviders() {
    final getIt = GetIt.instance;

    return [
      ChangeNotifierProvider<FileTransferStateNotifier>(
        create: (_) => getIt<FileTransferStateNotifier>(),
      ),
    ];
  }

  /// 获取Provider列表（包含值类型的Provider）
  static List<dynamic> getAllProviders() {
    final getIt = GetIt.instance;

    return [
      ...getProviders(),
      Provider<FilePickerService>(
        create: (_) => getIt<FilePickerService>(),
      ),
      Provider<FileTransferService>(
        create: (_) => getIt<FileTransferService>(),
      ),
      Provider<TextTransferService>(
        create: (_) => getIt<TextTransferService>(),
      ),
    ];
  }
}
