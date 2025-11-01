<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // .env dosyasından çevresel değişkenleri okumak için
import 'package:firebase_core/firebase_core.dart'; // Firebase çekirdek kütüphanesi

import 'firebase_options.dart'; // Firebase yapılandırma ayarlarını içerir
import 'src/app.dart'; // Uygulamanın ana widget'ı olan MyRoot ve MyApp burada

/// Uygulamanın başlangıç noktası.
/// `main()` fonksiyonu, uygulamanın çalışmaya başladığı ilk yerdir.
Future<void> main() async {
  // Flutter widget sisteminin doğru bir şekilde başlatıldığından emin olur.
  // Asenkron işlemler (örn. Firebase başlatma) `runApp`'ten önce yapılacaksa gereklidir.
  WidgetsFlutterBinding.ensureInitialized();

  // .env dosyasından çevresel değişkenleri (API anahtarı gibi) yükler.
  // Bu işlem, API anahtarı gibi hassas bilgilerin kodda görünmesini engeller.
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // .env dosyası bulunamazsa veya yüklenemezse hata ayıklama konsoluna yazdırır.
    debugPrint("Error loading .env: $e");
  }

  // Firebase'i uygulamaya entegre eder ve başlatır.
  // `DefaultFirebaseOptions.currentPlatform` sayesinde, uygulamanın çalıştığı
  // platforma (Android, iOS, web vb.) uygun ayarlar otomatik olarak seçilir.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Uygulamanın ana widget'ını (MyRoot) çalıştırır ve
  // ekranın widget ağacını oluşturmasını sağlar.
=======
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart'; // flutterfire configure ile oluşur
import 'src/app.dart'; // MyRoot + MyApp burada

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env (opsiyonel)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Error loading .env: $e");
  }

  // Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
  runApp(const MyRoot());
}
