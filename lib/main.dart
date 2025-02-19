import 'package:flutter/material.dart';
import 'common/theme.dart';
import 'ui/screens/main_screen.dart';
import 'application/di/service_locator.dart';

void main() {
  setupServiceLocator(); // Initialize service locator
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bifrost',
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
    );
  }
}
