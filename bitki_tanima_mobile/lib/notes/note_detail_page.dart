import 'package:flutter/material.dart';
import '../services/notes_service.dart';

// Not detay sayfasını gösteren bir StatefulWidget
// Bu sayfa, bir notu düzenlemek veya görüntülemek için kullanılır.
class NoteDetailPage extends StatefulWidget {
  // Düzenlenecek notun benzersiz kimliği (ID).
  final String noteId;
  // Notun başlangıç metni, eğer varsa.
  final String? initialText;

  // Kurucu metodu, not ID'sini ve başlangıç metnini alır.
  const NoteDetailPage({super.key, required this.noteId, this.initialText});

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

// NoteDetailPage için durum yönetimi sınıfı.
class _NoteDetailPageState extends State<NoteDetailPage> {
  // TextField'ın içeriğini kontrol etmek için kullanılan bir denetleyici.
  late final TextEditingController _ctrl;

  // Sayfa ilk oluşturulduğunda çalışan metot.
  @override
  void initState() {
    super.initState();
    // TextEditingController'ı, widget'tan gelen başlangıç metniyle başlatıyoruz.
    _ctrl = TextEditingController(text: widget.initialText ?? '');
  }

  // Sayfa bellekten çıkarılırken çalışan metot.
  @override
  void dispose() {
    // TextEditingController'ı temizleyip bellekten serbest bırakıyoruz.
    // Bu, bellek sızıntılarını önlemek için önemlidir.
    _ctrl.dispose();
    super.dispose();
  }

  // Notu kaydetme işlemini yapan asenkron metot.
  Future<void> _save() async {
    // TextField'daki metni alıp boşlukları temizliyoruz.
    final text = _ctrl.text.trim();
    // Eğer metin boşsa, kaydetme işlemini yapmadan çıkıyoruz.
    if (text.isEmpty) return;
    try {
      // NotesService üzerinden notu güncelliyoruz.
      await NotesService.updateNote(id: widget.noteId, text: text);
      // Widget hala ekranda değilse (unmounted), işlem yapmadan dönüyoruz.
      // Bu, asenkron işlemler sırasında oluşabilecek hataları engeller.
      if (!mounted) return;
      // Başarılı bir şekilde kaydedilince kullanıcıya "Kaydedildi" mesajını gösteriyoruz.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kaydedildi')));
    } catch (e) {
      // Kaydetme işlemi sırasında bir hata oluşursa, kullanıcıya bir mesaj gösteriyoruz.
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kaydedilemedi: $e')));
    }
  }

  // Sayfanın kullanıcı arayüzünü (UI) oluşturan metot.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sayfanın üst kısmındaki uygulama çubuğu (app bar).
      appBar: AppBar(
        // Başlık metni.
        title: const Text('Not Detayı'),
        // Uygulama çubuğundaki eylemler (sağdaki butonlar).
        actions: [
          // Kaydetme butonu.
          IconButton(
            // Butonun üzerine gelince çıkan açıklama metni.
            tooltip: 'Kaydet',
            // Butonun ikonu.
            icon: const Icon(Icons.save),
            // Butona basıldığında _save metodu çalıştırılır.
            onPressed: _save,
          ),
        ],
      ),
      // Uygulama çubuğunun altındaki ana içerik alanı.
      body: Padding(
        // İçeriğe 16 birimlik boşluk (padding) ekliyoruz.
        padding: const EdgeInsets.all(16),
        child: TextField(
          // Metin alanını _ctrl ile bağlıyoruz.
          controller: _ctrl,
          // Birden fazla satır yazmaya izin veriyoruz.
          maxLines: null,
          // Çok satırlı metin girişi için klavye türünü ayarlıyoruz.
          keyboardType: TextInputType.multiline,
          // Metin alanının görünüm ayarları.
          decoration: const InputDecoration(
            // Metin alanına dış çerçeve ekliyoruz.
            border: OutlineInputBorder(),
            // Kullanıcıya rehberlik eden ipucu metni.
            hintText: 'Notunuzu yazın…',
          ),
        ),
      ),
    );
  }
}
