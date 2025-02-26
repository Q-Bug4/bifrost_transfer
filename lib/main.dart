import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

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
    return MaterialApp(
      title: 'Bifrost Transfer',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Bifrost Transfer'),
        ),
        body: const Center(
          child: Text('Welcome to Bifrost Transfer'),
        ),
      ),
    );
  }
}