import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Not detay sayfasını import ediyoruz.
import 'note_detail_page.dart';

// Notları listeleyen bir StatefulWidget
class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

// Not listesi sayfasının durumunu yöneten sınıf
class _NotesPageState extends State<NotesPage> {
  // Firebase kimlik doğrulama (authentication) servisine erişim.
  final _auth = FirebaseAuth.instance;
  // Firestore veritabanına erişim.
  final _db = FirebaseFirestore.instance;

  // Mevcut kullanıcının notlarının bulunduğu Firestore koleksiyonunu döndüren bir getter.
  // Eğer kullanıcı giriş yapmadıysa null döner.
  CollectionReference<Map<String, dynamic>>? get _col {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    // 'users' koleksiyonunda, kullanıcının UID'sine ait belgeyi bulup,
    // içindeki 'notes' alt koleksiyonuna erişiyoruz.
    return _db.collection('users').doc(uid).collection('notes');
  }

  // Yeni bir not oluşturma işlemini başlatan asenkron metot.
  Future<void> _createNote() async {
    final col = _col;
    // Eğer kullanıcı oturum açmadıysa hata mesajı göster ve çık.
    if (col == null) {
      _snack('Oturum yok (giriş yap).');
      return;
    }

    // Firestore'da rastgele ID'ye sahip yeni bir belge oluşturuyoruz.
    final doc = col.doc();
    // Bu belgeye başlangıç verilerini (boş metin, oluşturulma ve güncellenme zamanları) yazıyoruz.
    await doc.set({
      'text': '',
      'createdAt':
          FieldValue.serverTimestamp(), // Firestore'un sunucu saatini kullanıyoruz.
      'updatedAt':
          FieldValue.serverTimestamp(), // Firestore'un sunucu saatini kullanıyoruz.
    });

    // Widget hala ekranda değilse (unmounted), işlem yapmadan dönüyoruz.
    if (!mounted) return;
    // Yeni oluşturulan notun detay sayfasına yönlendiriyoruz.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteDetailPage(noteId: doc.id, initialText: ''),
      ),
    );
  }

  // Bir notu silme işlemini yapan asenkron metot.
  Future<void> _deleteNote(String id) async {
    final col = _col;
    if (col == null) return;

    // Kullanıcıya notu silmek isteyip istemediğini soran bir onay penceresi gösteriyoruz.
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Notu sil'),
        content: const Text('Bu notu kalıcı olarak silmek istiyor musun?'),
        actions: [
          // Vazgeç butonu.
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          // Sil butonu.
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    // Eğer kullanıcı "Sil" butonuna bastıysa, Firestore'dan notu siliyoruz.
    if (ok == true) {
      await col.doc(id).delete();
    }
  }

  // Verilen bir metnin önizlemesini oluşturan yardımcı metot.
  String _previewOf(String s) {
    // Tüm satır sonlarını boşlukla değiştirip boşlukları temizliyoruz.
    final oneLine = s.replaceAll('\n', ' ').trim();
    // Eğer metin boşsa, "(boş not)" metnini döndürüyoruz.
    if (oneLine.isEmpty) return '(boş not)';
    // Eğer metin 60 karakterden uzunsa, ilk 60 karakterini alıp sonuna '…' ekliyoruz.
    return oneLine.length > 60 ? '${oneLine.substring(0, 60)}…' : oneLine;
  }

  // Timestamp türündeki veriyi okunabilir bir tarih ve saat formatına dönüştüren yardımcı metot.
  String _fmtTs(Timestamp? ts) {
    // Eğer Timestamp null ise '-' döndürüyoruz.
    if (ts == null) return '-';
    // Timestamp'i DateTime objesine dönüştürüyoruz.
    final d = ts.toDate();
    // Tek basamaklı sayıların başına '0' ekleyen yardımcı fonksiyon.
    String two(int n) => n.toString().padLeft(2, '0');
    // Yıl-ay-gün saat:dakika formatında string oluşturup döndürüyoruz.
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  // Kullanıcıya kısa bir bildirim (snackbar) gösteren yardımcı metot.
  void _snack(String m) {
    // Widget hala ekranda değilse (unmounted), işlem yapmadan dönüyoruz.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  // Sayfanın kullanıcı arayüzünü (UI) oluşturan metot.
  @override
  Widget build(BuildContext context) {
    // Not koleksiyonuna erişim.
    final col = _col;

    return Scaffold(
      // Uygulama çubuğu (app bar).
      appBar: AppBar(title: const Text('Notlarım')),
      // Sağ alttaki kayan aksiyon butonu.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNote, // Butona basıldığında yeni not oluştur.
        icon: const Icon(Icons.note_add), // Butonun ikonu.
        label: const Text('Yeni Not'), // Butonun etiketi.
      ),
      // Ana içerik alanı.
      body: col == null
          // Eğer oturum yoksa, oturum bulunamadı mesajını göster.
          ? const Center(child: Text('Oturum bulunamadı.'))
          // Eğer oturum varsa, StreamBuilder ile notları veritabanından dinlemeye başla.
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              // Notları 'updatedAt' alanına göre azalan (en yeni üste) şekilde sıralayarak dinliyoruz.
              stream: col.orderBy('updatedAt', descending: true).snapshots(),
              builder: (context, snap) {
                // Veri bekleniyorsa yüklenme göstergesi (CircularProgressIndicator) göster.
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Hata oluştuysa hata mesajını göster.
                if (snap.hasError) {
                  return Center(child: Text('Hata: ${snap.error}'));
                }
                // Veri geldiyse belgeleri al. Eğer yoksa boş bir liste kullan.
                final docs = snap.data?.docs ?? [];
                // Not yoksa kullanıcıya bilgilendirme mesajı göster.
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Henüz not yok. Sağ alttan yeni not ekleyebilirsin.',
                    ),
                  );
                }

                // Notları liste olarak gösteren bir ListView oluştur.
                return ListView.separated(
                  itemCount: docs.length, // Listedeki eleman sayısı.
                  // Her not arasına bir çizgi ekle.
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  // Her not için bir liste öğesi (ListTile) oluştur.
                  itemBuilder: (_, i) {
                    final d = docs[i];
                    final id = d.id;
                    final data = d.data();
                    final text = (data['text'] as String?) ?? '';
                    final createdAt = data['createdAt'] as Timestamp?;
                    final updatedAt = data['updatedAt'] as Timestamp?;

                    return ListTile(
                      // Notun önizlemesini başlık olarak göster.
                      title: Text(
                        _previewOf(text),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Notun oluşturulma ve güncellenme tarihlerini göster.
                      subtitle: Text(
                        'Güncelleme: ${_fmtTs(updatedAt)}   •   Oluşturma: ${_fmtTs(createdAt)}',
                      ),
                      // Notun yanındaki ikon.
                      leading: const Icon(Icons.note_outlined),
                      // Sağdaki silme butonu.
                      trailing: IconButton(
                        tooltip: 'Sil',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            _deleteNote(id), // Butona basıldığında notu sil.
                      ),
                      // Liste elemanına tıklandığında not detay sayfasına git.
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                NoteDetailPage(noteId: id, initialText: text),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
