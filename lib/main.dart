import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'application/services/connection_service.dart';
import 'application/states/connection_state_notifier.dart';
import 'ui/screens/home_screen.dart';
import 'infrastructure/di/service_locator.dart';

void main() {
  // 初始化日志
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  // 初始化服务定位器
  setupServiceLocator();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 注册连接服务
        Provider<ConnectionService>(
          create: (_) => serviceLocator<ConnectionService>(),
        ),
        // 注册连接状态管理器
        ChangeNotifierProxyProvider<ConnectionService, ConnectionStateNotifier>(
          create: (context) => ConnectionStateNotifier(
            Provider.of<ConnectionService>(context, listen: false),
          ),
          update: (context, connectionService, previous) => 
            previous ?? ConnectionStateNotifier(connectionService),
        ),
      ],
      child: MaterialApp(
        title: 'Bifrost Transfer',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
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