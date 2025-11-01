import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'src/auth/auth_service.dart';

<<<<<<< HEAD
/// Belirli bir bitkinin detaylarını gösteren StatelessWidget.
/// Bilgileri Firestore'dan gerçek zamanlı olarak çeker.
class PlantDetailPage extends StatelessWidget {
  /// Detayları görüntülenecek bitkinin benzersiz kimliği (ID).
  final String plantId;

  /// Uygulamanın mevcut dili.
  final String lang;

=======
class PlantDetailPage extends StatelessWidget {
  final String plantId;
  final String lang;
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
  const PlantDetailPage({super.key, required this.plantId, required this.lang});

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
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
=======
    final tr = lang == 'tr';
    final doc = FirebaseFirestore.instance.collection('plants').doc(plantId);

    final uid = AuthServisi.instance.uid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: doc.snapshots(),
      builder: (context, snap) {
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
<<<<<<< HEAD

        // Gelen veriyi (data) alır ve null kontrolü yapar.
        final d = snap.data!.data();
        // Eğer belge bulunamazsa (null ise), hata mesajı gösterir.
=======
        final d = snap.data!.data();
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
        if (d == null) {
          return Scaffold(
            appBar: AppBar(title: Text(tr ? 'Bitki' : 'Plant')),
            body: Center(
              child: Text(tr ? 'Kayıt bulunamadı.' : 'No record found.'),
            ),
          );
        }

<<<<<<< HEAD
        // Firestore'dan gelen verileri değişkenlere atar.
        // Veri yoksa varsayılan değerler atanır.
        final nameTr = (d['names']?['tr'] ?? plantId) as String;
        final nameEn = (d['names']?['en'] ?? '') as String;
        final family = (d['family'] ?? '-') as String;
        // Açıklamayı önce mevcut dile göre, sonra Türkçe veya İngilizce olarak bulmaya çalışır.
=======
        final nameTr = (d['names']?['tr'] ?? plantId) as String;
        final nameEn = (d['names']?['en'] ?? '') as String;
        final family = (d['family'] ?? '-') as String;
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
        final desc =
            (d['description']?[lang] ??
                    (d['description']?['tr'] ?? d['description']?['en'] ?? '-'))
                as String;
        final care = (d['care'] as List?)?.cast<String>() ?? const [];
        final thumbs = (d['thumbnails'] as List?)?.cast<String>() ?? const [];

<<<<<<< HEAD
        // Kullanıcının favori belgesine referans. Kullanıcı oturum açmamışsa null olur.
=======
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
        final favRef = (uid == null)
            ? null
            : FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('favorites')
                  .doc(plantId);

        return Scaffold(
          appBar: AppBar(
<<<<<<< HEAD
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
=======
            title: Text(tr ? nameTr : (nameEn.isNotEmpty ? nameEn : nameTr)),
            actions: [
              if (favRef != null)
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: favRef.snapshots(),
                  builder: (context, f) {
                    final isFav = f.data?.exists == true;
                    return IconButton(
                      icon: Icon(
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
                        isFav ? Icons.favorite : Icons.favorite_outline,
                      ),
                      tooltip: isFav
                          ? (tr ? 'Favoriden kaldır' : 'Remove favorite')
                          : (tr ? 'Favorilere ekle' : 'Add favorite'),
                      onPressed: () async {
<<<<<<< HEAD
                        // Butona basıldığında favori durumunu değiştirir.
                        if (isFav) {
                          await favRef.delete(); // Favoriden kaldırır.
                        } else {
                          // Favorilere ekler ve ekleme zamanını kaydeder.
=======
                        if (isFav) {
                          await favRef.delete();
                        } else {
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
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
<<<<<<< HEAD
              // Eğer bitkinin fotoğrafı varsa gösterir.
=======
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
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
<<<<<<< HEAD
              // Bitki ailesi bilgisi
=======
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
              Text(
                tr ? 'Aile' : 'Family',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(family),
              const SizedBox(height: 12),
<<<<<<< HEAD
              // Bitki açıklaması
=======
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
              Text(
                tr ? 'Açıklama' : 'Description',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(desc),
<<<<<<< HEAD
              // Eğer bakım önerileri varsa gösterir.
=======
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
              if (care.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  tr ? 'Bakım Önerileri' : 'Care Tips',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
<<<<<<< HEAD
                // Bakım önerilerini madde işaretli liste olarak gösterir.
=======
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
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
