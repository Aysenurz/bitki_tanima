import 'package:flutter/material.dart';

/// Kullanıcıdan dil seçimi yapmasını isteyen ve bir kez seçim yapıldıktan sonra
/// bu bilgiyi üst widget'a (ebeveyne) ileten bir StatelessWidget.
class LanguageSelectionPage extends StatelessWidget {
  /// Dil seçimi yapıldığında çağrılacak olan geri çağırım (callback) fonksiyonu.
  final void Function(String) onLangSelected;
  const LanguageSelectionPage({super.key, required this.onLangSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Arka plan rengini hafif yeşil yapar.
      backgroundColor: Colors.green.shade50,
      body: Center(
        // İçeriği ekranın ortasına hizalar.
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            // Sütundaki elemanları dikeyde ortalar.
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Büyük bir dil simgesi gösterir.
              const Icon(Icons.language, size: 100, color: Colors.green),
              const SizedBox(height: 20),
              // Kullanıcıya dil seçmesini söyleyen metin.
              const Text(
                "Lütfen Dil Seçiniz\nPlease Select Language",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              // Türkçe dilini seçmek için dolu (Filled) bir buton.
              FilledButton(
                // Butona tıklandığında, geri çağırım fonksiyonuna 'tr' dil kodunu gönderir.
                onPressed: () => onLangSelected("tr"),
                child: const Text("🇹🇷 Türkçe"),
              ),
              const SizedBox(height: 12),
              // İngilizce dilini seçmek için tonlu (Tonal) bir buton.
              FilledButton.tonal(
                // Butona tıklandığında, geri çağırım fonksiyonuna 'en' dil kodunu gönderir.
                onPressed: () => onLangSelected("en"),
                child: const Text("🇬🇧 English"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
