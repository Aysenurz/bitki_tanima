<<<<<<< HEAD
import 'package:flutter/foundation.dart';

/// Uygulamanın çeşitli yapılandırma ayarlarını barındıran sınıf.
class AppConfig {
  /// API'nin temel URL'sini döndüren statik getter.
  static String get apiBase {
    // kIsWeb, uygulamanın web platformunda çalışıp çalışmadığını kontrol eden bir Flutter sabitidir.
    if (kIsWeb) {
      // Eğer uygulama web'de çalışıyorsa, API adresi olarak mevcut web sayfasının adresini kullanıyoruz.
      // Uri.base.host, mevcut URL'nin ana sunucusunu (host) verir.
      // Eğer bu boşsa, yerel geliştirme için 'localhost' kullanıyoruz.
      final host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
      // API'nin çalıştığı varsayılan port olan 8000'i ekliyoruz.
      return 'http://$host:8000';
    }
    // Eğer uygulama mobil (Android/iOS) platformunda çalışıyorsa,
    // API adresi olarak geliştirme bilgisayarının sabit IP adresini kullanıyoruz.
    // Bu adres, mobil cihazın aynı Wi-Fi ağına bağlı olması durumunda çalışır.
    // "192.168.1.44" gibi bir adres, yerel ağda bir cihaza erişmek için kullanılır.
    return "http://192.168.1.42";
=======
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
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
  }
}
