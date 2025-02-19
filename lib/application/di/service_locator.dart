import 'package:get_it/get_it.dart';
import '../services/device_info_service.dart';
import '../services/device_info_service_impl.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<DeviceInfoService>(() => DeviceInfoServiceImpl());
} 