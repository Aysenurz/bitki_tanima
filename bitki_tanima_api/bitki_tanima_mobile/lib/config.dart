// lib/config.dart
import 'package:flutter/foundation.dart';

class AppConfig {
  /// API'nin temel adresi.
  ///
  /// - Web (Chrome) için: Uygulamanın açıldığı host'u otomatik alır.
  ///   Örnek: PC’de Chrome ile açtıysan "localhost", telefondan
  ///   PC’nin IP’siyle açtıysan "192.168.1.xx" otomatik olur.
  ///
  /// - Android (native) için: PC’nin **LAN IP** adresini elle veriyoruz.
  ///   (ipconfig'de gördüğün IPv4: örn. 192.168.1.42)
  static String get apiBase {
    if (kIsWeb) {
      // Web’de çalışıyorsak, uygulamanın açıldığı host’u al:
      // Örnek: http://localhost:xxxxx → host: "localhost"
      //        http://192.168.1.42:xxxxx → host: "192.168.1.42"
      final host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
      return 'http://$host:8000';
    }

    // Android cihazdan erişeceğin PC IP'sini BURAYA yaz.
    // ipconfig çıktındaki IPv4 (ör. 192.168.1.42)
    return 'http://192.168.1.42:8000';
  }
}
