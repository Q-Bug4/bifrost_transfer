import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';

import 'application/states/device_state.dart';
import 'application/services/device_pairing_service.dart';
import 'ui/screens/device_list_screen.dart';

void main() {
  // 初始化日志
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final state = DeviceState(DevicePairingService());
        // 确保在创建后立即初始化
        Future.microtask(() => state.initialize());
        return state;
      },
      child: MaterialApp(
        title: 'Bifrost Transfer',
        navigatorKey: DeviceState.navigatorKey,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF1E1E1E),
          dialogBackgroundColor: const Color(0xFF2D2D2D),
          useMaterial3: true,
        ),
        home: const DeviceListScreen(),
      ),
    );
  }
}
