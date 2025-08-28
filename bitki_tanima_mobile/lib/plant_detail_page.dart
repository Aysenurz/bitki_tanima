import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'src/auth/auth_service.dart';

class PlantDetailPage extends StatelessWidget {
  final String plantId;
  final String lang;
  const PlantDetailPage({super.key, required this.plantId, required this.lang});

  @override
  Widget build(BuildContext context) {
    final tr = lang == 'tr';
    final doc = FirebaseFirestore.instance.collection('plants').doc(plantId);

    final uid = AuthServisi.instance.uid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: doc.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final d = snap.data!.data();
        if (d == null) {
          return Scaffold(
            appBar: AppBar(title: Text(tr ? 'Bitki' : 'Plant')),
            body: Center(
              child: Text(tr ? 'Kayıt bulunamadı.' : 'No record found.'),
            ),
          );
        }

        final nameTr = (d['names']?['tr'] ?? plantId) as String;
        final nameEn = (d['names']?['en'] ?? '') as String;
        final family = (d['family'] ?? '-') as String;
        final desc =
            (d['description']?[lang] ??
                    (d['description']?['tr'] ?? d['description']?['en'] ?? '-'))
                as String;
        final care = (d['care'] as List?)?.cast<String>() ?? const [];
        final thumbs = (d['thumbnails'] as List?)?.cast<String>() ?? const [];

        final favRef = (uid == null)
            ? null
            : FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('favorites')
                  .doc(plantId);

        return Scaffold(
          appBar: AppBar(
            title: Text(tr ? nameTr : (nameEn.isNotEmpty ? nameEn : nameTr)),
            actions: [
              if (favRef != null)
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: favRef.snapshots(),
                  builder: (context, f) {
                    final isFav = f.data?.exists == true;
                    return IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_outline,
                      ),
                      tooltip: isFav
                          ? (tr ? 'Favoriden kaldır' : 'Remove favorite')
                          : (tr ? 'Favorilere ekle' : 'Add favorite'),
                      onPressed: () async {
                        if (isFav) {
                          await favRef.delete();
                        } else {
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
              Text(
                tr ? 'Aile' : 'Family',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(family),
              const SizedBox(height: 12),
              Text(
                tr ? 'Açıklama' : 'Description',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(desc),
              if (care.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  tr ? 'Bakım Önerileri' : 'Care Tips',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
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
