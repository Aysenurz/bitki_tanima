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

  runApp(const MyRoot());
}
