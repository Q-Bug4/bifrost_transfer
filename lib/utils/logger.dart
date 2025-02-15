import 'package:flutter/foundation.dart';

class Logger {
  static void log(String tag, String message) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      debugPrint('[$timestamp] $tag: $message');
    }
  }

  static void error(String tag, String message, [dynamic error]) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      debugPrint('[$timestamp] $tag ERROR: $message');
      if (error != null) {
        debugPrint('Error details: $error');
      }
    }
  }
}
