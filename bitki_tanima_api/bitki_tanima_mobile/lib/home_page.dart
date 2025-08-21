// lib/home_page.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui';

import 'translations.dart';
import 'result_page.dart';
import 'src/auth/auth_service.dart';

class HomePage extends StatefulWidget {
  final String lang;
  final Function(String) changeLang;
  const HomePage({super.key, required this.lang, required this.changeLang});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          // imagePath yerine imageFile olarak XFile nesnesini gönderiyoruz
          builder: (_) => ResultPage(imageFile: pickedFile, lang: widget.lang),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTexts.values[widget.lang]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t["appTitle"]!),
        actions: [
          // Dil ayarları
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            onSelected: (value) {
              if (value == "lang") _showLanguageDialog();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: "lang",
                child: Row(
                  children: [
                    const Icon(Icons.language, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      widget.lang == "tr" ? "Dili Değiştir" : "Change Language",
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Çıkış butonu (istersen kaldırabilirsin; Ayarlar sekmesinde de var)
          IconButton(
            tooltip: widget.lang == 'tr' ? 'Çıkış Yap' : 'Sign Out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final tr = widget.lang == 'tr';
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(tr ? 'Çıkış Yap' : 'Sign Out'),
                  content: Text(
                    tr
                        ? 'Hesabınızdan çıkmak istiyor musunuz?'
                        : 'Do you want to sign out?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(tr ? 'İptal' : 'Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(tr ? 'Evet' : 'Yes'),
                    ),
                  ],
                ),
              );
              if (ok == true) await AuthServisi.instance.cikisYap();
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("assets/plant_cover.jpg", fit: BoxFit.cover),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    t["welcome"]!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.lang == "tr"
                        ? "Bu uygulama ile galerinizden ya da kameranızdan seçtiğiniz bitki fotoğrafını analiz ederek, bitkinin türü, familyası ve diğer bilgilerini öğrenebilirsiniz."
                        : "With this app, you can analyze a plant photo selected from your gallery or camera to learn its species, family, and other details.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 40),
                  FilledButton.icon(
                    icon: const Icon(Icons.image),
                    label: Text(t["selectGallery"]!),
                    onPressed: () => _pickImage(ImageSource.gallery),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: Text(t["takePhoto"]!),
                    onPressed: () => _pickImage(ImageSource.camera),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(widget.lang == "tr" ? "Dil Seç" : "Select Language"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.red),
              title: const Text("Türkçe"),
              onTap: () {
                widget.changeLang("tr");
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.blue),
              title: const Text("English"),
              onTap: () {
                widget.changeLang("en");
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
