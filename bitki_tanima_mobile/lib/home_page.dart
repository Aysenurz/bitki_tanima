<<<<<<< HEAD
=======
// lib/home_page.dart

>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui';

import 'translations.dart';
import 'result_page.dart';
import 'src/auth/auth_service.dart';

<<<<<<< HEAD
/// Uygulamanın ana sayfasını temsil eden bir StatefulWidget.
/// Bu sayfa, kullanıcının fotoğraf çekmesini veya galeriden seçmesini sağlar.
=======
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
class HomePage extends StatefulWidget {
  final String lang;
  final Function(String) changeLang;
  const HomePage({super.key, required this.lang, required this.changeLang});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
<<<<<<< HEAD
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
          builder: (_) =>
              ResultPage(imageFile: pickedFile.path, lang: widget.lang),
=======
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
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    // Mevcut dil için metinleri alır.
=======
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
    final t = AppTexts.values[widget.lang]!;

    return Scaffold(
      appBar: AppBar(
<<<<<<< HEAD
        title: Text(t["appTitle"]!), // Uygulama başlığı.
        actions: [
          // Ayarlar menüsü butonu.
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            onSelected: (value) {
              // Menüden 'lang' seçeneği seçilirse dil değiştirme diyalogunu gösterir.
=======
        title: Text(t["appTitle"]!),
        actions: [
          // Dil ayarları
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            onSelected: (value) {
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
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
<<<<<<< HEAD
                      t['language']!, // Çeviri kullanıldı
=======
                      widget.lang == "tr" ? "Dili Değiştir" : "Change Language",
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
                    ),
                  ],
                ),
              ),
            ],
          ),
<<<<<<< HEAD
          // Çıkış yapma butonu.
          IconButton(
            tooltip: t['signOut'], // Çeviri kullanıldı
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Çıkış yapmadan önce onay diyalog kutusu gösterir.
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(t['signOut']!), // Çeviri kullanıldı
                  content: Text(
                    t['signOutConfirm']!, // Çeviri kullanıldı
=======
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
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
<<<<<<< HEAD
                      child: Text(t['cancel']!), // Çeviri kullanıldı
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(t['yes']!), // Çeviri kullanıldı
=======
                      child: Text(tr ? 'İptal' : 'Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(tr ? 'Evet' : 'Yes'),
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
                    ),
                  ],
                ),
              );
<<<<<<< HEAD
              // Eğer onaylandıysa, AuthServisi'nden çıkış işlemini başlatır.
=======
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
              if (ok == true) await AuthServisi.instance.cikisYap();
            },
          ),
        ],
      ),
      body: Stack(
<<<<<<< HEAD
        fit: StackFit.expand, // Arka planın tüm alanı kaplamasını sağlar.
        children: [
          // Arka plan resmi.
          Image.asset("assets/plant_cover.jpg", fit: BoxFit.cover),
          // Resmin üzerine blur (bulanıklaştırma) efekti ekler.
=======
        fit: StackFit.expand,
        children: [
          Image.asset("assets/plant_cover.jpg", fit: BoxFit.cover),
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
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
<<<<<<< HEAD
                    t["welcome"]!, // Hoş geldin metni.
=======
                    t["welcome"]!,
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
<<<<<<< HEAD
                    t["intro"]!, // Çeviri kullanıldı
=======
                    widget.lang == "tr"
                        ? "Bu uygulama ile galerinizden ya da kameranızdan seçtiğiniz bitki fotoğrafını analiz ederek, bitkinin türü, familyası ve diğer bilgilerini öğrenebilirsiniz."
                        : "With this app, you can analyze a plant photo selected from your gallery or camera to learn its species, family, and other details.",
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 40),
<<<<<<< HEAD
                  // Galeri butonu.
                  FilledButton.icon(
                    icon: const Icon(Icons.image),
                    label: Text(t["selectGallery"]!),
                    onPressed: () => _pickImage(
                      ImageSource.gallery,
                    ), // Galeriye yönlendirir.
=======
                  FilledButton.icon(
                    icon: const Icon(Icons.image),
                    label: Text(t["selectGallery"]!),
                    onPressed: () => _pickImage(ImageSource.gallery),
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
<<<<<<< HEAD
                  // Kamera butonu.
                  FilledButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: Text(t["takePhoto"]!),
                    onPressed: () =>
                        _pickImage(ImageSource.camera), // Kamerayı açar.
=======
                  FilledButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: Text(t["takePhoto"]!),
                    onPressed: () => _pickImage(ImageSource.camera),
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
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

<<<<<<< HEAD
  /// Dil seçimi diyalog kutusunu gösteren metot.
  void _showLanguageDialog() {
    final t = AppTexts.values[widget.lang]!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t['language']!), // Çeviri kullanıldı
=======
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(widget.lang == "tr" ? "Dil Seç" : "Select Language"),
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.red),
              title: const Text("Türkçe"),
              onTap: () {
<<<<<<< HEAD
                widget.changeLang("tr"); // Dili Türkçe olarak değiştirir.
                Navigator.pop(context); // Diyalog kutusunu kapatır.
=======
                widget.changeLang("tr");
                Navigator.pop(context);
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.blue),
              title: const Text("English"),
              onTap: () {
<<<<<<< HEAD
                widget.changeLang("en"); // Dili İngilizce olarak değiştirir.
                Navigator.pop(context); // Diyalog kutusunu kapatır.
=======
                widget.changeLang("en");
                Navigator.pop(context);
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
              },
            ),
          ],
        ),
      ),
    );
  }
}
