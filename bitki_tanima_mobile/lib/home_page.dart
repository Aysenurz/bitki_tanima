import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Fotoğraf çekmek ve galeriden seçmek için kullanılır.
import 'dart:ui'; // BackdropFilter gibi görsel efektler için kullanılır.

import 'translations.dart'; // Uygulama metinleri için çeviri sınıfı.
import 'result_page.dart'; // Analiz sonuçlarının gösterileceği sayfa.
import 'src/auth/auth_service.dart'; // Oturum yönetimi servisi.

/// Uygulamanın ana sayfasını temsil eden bir StatefulWidget.
/// Bu sayfa, kullanıcının fotoğraf çekmesini veya galeriden seçmesini sağlar.
class HomePage extends StatefulWidget {
  final String lang; // Uygulamanın mevcut dilini tutar.
  final Function(String) changeLang; // Dili değiştiren metot.
  const HomePage({super.key, required this.lang, required this.changeLang});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Fotoğraf seçme işlemleri için ImagePicker'ın bir örneği.
  final picker = ImagePicker();

  /// Galeriden veya kameradan bir resim seçen asenkron metot.
  /// Seçilen resmin dosya yolunu (path) ResultPage'e gönderir.
  Future<void> _pickImage(ImageSource source) async {
    // Belirtilen kaynaktan (galeri veya kamera) resim seçimi yapar.
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null && mounted) {
      // Bir resim seçildiyse ve widget hala aktifse (mounted),
      // ResultPage'e geçiş yapar ve resim dosyasının yolunu iletir.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultPage(
            imageFile:
                pickedFile.path, // ✅ Yalnızca resmin dosya yolunu gönderir.
            lang: widget.lang,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mevcut dil için metinleri alır.
    final t = AppTexts.values[widget.lang]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t["appTitle"]!), // Uygulama başlığı.
        actions: [
          // Ayarlar menüsü butonu.
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            onSelected: (value) {
              // Menüden 'lang' seçeneği seçilirse dil değiştirme diyalogunu gösterir.
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
          // Çıkış yapma butonu.
          IconButton(
            tooltip: widget.lang == 'tr' ? 'Çıkış Yap' : 'Sign Out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final tr = widget.lang == 'tr';
              // Çıkış yapmadan önce onay diyalog kutusu gösterir.
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
              // Eğer onaylandıysa, AuthServisi'nden çıkış işlemini başlatır.
              if (ok == true) await AuthServisi.instance.cikisYap();
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand, // Arka planın tüm alanı kaplamasını sağlar.
        children: [
          // Arka plan resmi.
          Image.asset("assets/plant_cover.jpg", fit: BoxFit.cover),
          // Resmin üzerine blur (bulanıklaştırma) efekti ekler.
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
                    t["welcome"]!, // Hoş geldin metni.
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    // Açıklama metni.
                    widget.lang == "tr"
                        ? "Bu uygulama ile galerinizden ya da kameranızdan seçtiğiniz bitki fotoğrafını analiz ederek, bitkinin türü, familyası ve diğer bilgilerini öğrenebilirsiniz."
                        : "With this app, you can analyze a plant photo selected from your gallery or camera to learn its species, family, and other details.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 40),
                  // Galeri butonu.
                  FilledButton.icon(
                    icon: const Icon(Icons.image),
                    label: Text(t["selectGallery"]!),
                    onPressed: () => _pickImage(
                      ImageSource.gallery,
                    ), // Galeriye yönlendirir.
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Kamera butonu.
                  FilledButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: Text(t["takePhoto"]!),
                    onPressed: () =>
                        _pickImage(ImageSource.camera), // Kamerayı açar.
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

  /// Dil seçimi diyalog kutusunu gösteren metot.
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
                widget.changeLang("tr"); // Dili Türkçe olarak değiştirir.
                Navigator.pop(context); // Diyalog kutusunu kapatır.
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.blue),
              title: const Text("English"),
              onTap: () {
                widget.changeLang("en"); // Dili İngilizce olarak değiştirir.
                Navigator.pop(context); // Diyalog kutusunu kapatır.
              },
            ),
          ],
        ),
      ),
    );
  }
}
