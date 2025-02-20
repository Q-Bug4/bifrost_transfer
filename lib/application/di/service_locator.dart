import 'package:get_it/get_it.dart';
import '../services/device_info_service.dart';
import '../services/device_info_service_impl.dart';
import '../services/network_service.dart';
import '../services/network_service_impl.dart';
import '../services/file_transfer_service.dart';
import '../services/file_transfer_service_impl.dart';
import '../services/text_transfer_service.dart';
import '../services/text_transfer_service_impl.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<DeviceInfoService>(() => DeviceInfoServiceImpl());
  getIt.registerLazySingleton<NetworkService>(() => NetworkServiceImpl());
  getIt.registerLazySingleton<FileTransferService>(
    () => FileTransferServiceImpl(getIt<NetworkService>()),
  );
  getIt.registerLazySingleton<TextTransferService>(
    () => TextTransferServiceImpl(getIt<NetworkService>()),
  );
} 