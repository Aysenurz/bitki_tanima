// lib/config.dart
import 'package:flutter/foundation.dart';

class AppConfig {
  static String get apiBase {
    if (kIsWeb) {
      final host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
      return 'http://$host:8000';
    }
    // PC'nin güncel IP'si:
    return "http://192.168.1.44";
  }
}
