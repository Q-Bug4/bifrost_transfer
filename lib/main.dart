import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'application/services/connection_service.dart';
import 'application/services/device_info_service.dart';
import 'application/states/connection_state_notifier.dart';
import 'application/di/service_locator.dart';
import 'ui/screens/home_screen.dart';

void main() {
  // 初始化日志
  _setupLogging();

  // 初始化服务定位器
  ServiceLocator.init();

  runApp(const MyApp());
}

/// 设置日志
void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final getIt = GetIt.instance;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ConnectionStateNotifier>(
          create: (_) => ConnectionStateNotifier(
            connectionService: getIt<ConnectionService>(),
            deviceInfoService: getIt<DeviceInfoService>(),
          ),
        ),
        ...ServiceLocator.getAllProviders(),
      ],
      child: MaterialApp(
        title: 'Bifrost Transfer',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
