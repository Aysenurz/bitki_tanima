import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'src/auth/auth_service.dart';

/// Belirli bir bitkinin detaylarını gösteren StatelessWidget.
/// Bilgileri Firestore'dan gerçek zamanlı olarak çeker.
class PlantDetailPage extends StatelessWidget {
  /// Detayları görüntülenecek bitkinin benzersiz kimliği (ID).
  final String plantId;

  /// Uygulamanın mevcut dili.
  final String lang;

  const PlantDetailPage({super.key, required this.plantId, required this.lang});

  @override
  Widget build(BuildContext context) {
    // Dilin Türkçe olup olmadığını kontrol eden kısa bir değişken.
    final tr = lang == 'tr';
    // Firestore'daki 'plants' koleksiyonundaki ilgili bitki belgesine (document) referans.
    final doc = FirebaseFirestore.instance.collection('plants').doc(plantId);

    // Oturum açmış kullanıcının ID'sini (uid) alır. Favori işlemleri için gereklidir.
    final uid = AuthServisi.instance.uid;

    /// Bu widget, Firestore'dan gelen verilerle gerçek zamanlı olarak güncellenir.
    /// `stream: doc.snapshots()` ile bitki belgesindeki değişiklikler sürekli dinlenir.
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: doc.snapshots(),
      builder: (context, snap) {
        // Veri gelene kadar yükleniyor göstergesi.
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Gelen veriyi (data) alır ve null kontrolü yapar.
        final d = snap.data!.data();
        // Eğer belge bulunamazsa (null ise), hata mesajı gösterir.
        if (d == null) {
          return Scaffold(
            appBar: AppBar(title: Text(tr ? 'Bitki' : 'Plant')),
            body: Center(
              child: Text(tr ? 'Kayıt bulunamadı.' : 'No record found.'),
            ),
          );
        }

        // Firestore'dan gelen verileri değişkenlere atar.
        // Veri yoksa varsayılan değerler atanır.
        final nameTr = (d['names']?['tr'] ?? plantId) as String;
        final nameEn = (d['names']?['en'] ?? '') as String;
        final family = (d['family'] ?? '-') as String;
        // Açıklamayı önce mevcut dile göre, sonra Türkçe veya İngilizce olarak bulmaya çalışır.
        final desc =
            (d['description']?[lang] ??
                    (d['description']?['tr'] ?? d['description']?['en'] ?? '-'))
                as String;
        final care = (d['care'] as List?)?.cast<String>() ?? const [];
        final thumbs = (d['thumbnails'] as List?)?.cast<String>() ?? const [];

        // Kullanıcının favori belgesine referans. Kullanıcı oturum açmamışsa null olur.
        final favRef = (uid == null)
            ? null
            : FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('favorites')
                  .doc(plantId);

        return Scaffold(
          appBar: AppBar(
            // Başlık olarak önce yerel adı, yoksa İngilizce adı, o da yoksa bilimsel adı gösterir.
            title: Text(tr ? nameTr : (nameEn.isNotEmpty ? nameEn : nameTr)),
            actions: [
              // Kullanıcı oturum açtıysa favori butonunu gösterir.
              if (favRef != null)
                // Bu StreamBuilder, favori belgesinin varlığını gerçek zamanlı olarak dinler.
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: favRef.snapshots(),
                  builder: (context, f) {
                    // Belge varsa 'isFav' true olur.
                    final isFav = f.data?.exists == true;
                    return IconButton(
                      icon: Icon(
                        // Favori durumuna göre kalp simgesini değiştirir.
                        isFav ? Icons.favorite : Icons.favorite_outline,
                      ),
                      tooltip: isFav
                          ? (tr ? 'Favoriden kaldır' : 'Remove favorite')
                          : (tr ? 'Favorilere ekle' : 'Add favorite'),
                      onPressed: () async {
                        // Butona basıldığında favori durumunu değiştirir.
                        if (isFav) {
                          await favRef.delete(); // Favoriden kaldırır.
                        } else {
                          // Favorilere ekler ve ekleme zamanını kaydeder.
                          await favRef.set({
                            'savedAt': FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));
                        }
                      },
                    );
                  },
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Eğer bitkinin fotoğrafı varsa gösterir.
              if (thumbs.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    thumbs.first,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 12),
              // Bitki ailesi bilgisi
              Text(
                tr ? 'Aile' : 'Family',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(family),
              const SizedBox(height: 12),
              // Bitki açıklaması
              Text(
                tr ? 'Açıklama' : 'Description',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(desc),
              // Eğer bakım önerileri varsa gösterir.
              if (care.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  tr ? 'Bakım Önerileri' : 'Care Tips',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                // Bakım önerilerini madde işaretli liste olarak gösterir.
                ...care.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('• $e'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
