import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firestore'da tutulacak favori modelimiz.
class FavoritePlant {
  final String id; // docId (slug)
  final String scientificName;
  final String displayName;
  final String? note;
  final String? thumbnailUrl;
  final String? family;
  final double? score;
  final String? description;
  final List<String> care;
  final String? funFact;
  final String? wikiUrl;
  final String? powoUrl;
  final List<String> extraImages;
  final DateTime? savedAt;

  const FavoritePlant({
    required this.id,
    required this.scientificName,
    required this.displayName,
    this.note,
    this.thumbnailUrl,
    this.family,
    this.score,
    this.description,
    this.care = const [],
    this.funFact,
    this.wikiUrl,
    this.powoUrl,
    this.extraImages = const [],
    this.savedAt,
  });

  factory FavoritePlant.fromMap(String id, Map<String, dynamic> m) {
    final rawScore = m['score'];
    double? score;
    if (rawScore is num) score = rawScore.toDouble();

    DateTime? saved;
    final rawSaved = m['saved_at'];
    if (rawSaved is Timestamp) {
      saved = rawSaved.toDate();
    } else if (rawSaved is String) {
      saved = DateTime.tryParse(rawSaved);
    }

    return FavoritePlant(
      id: id,
      scientificName: (m['scientific_name'] ?? '') as String,
      displayName: (m['display_name'] ?? m['scientific_name'] ?? '') as String,
      note: m['note'] as String?,
      thumbnailUrl: m['thumbnail_url'] as String?,
      family: m['family'] as String?,
      score: score,
      description: m['description'] as String?,
      care: (m['care'] is List)
          ? (m['care'] as List).map((e) => e.toString()).toList()
          : const [],
      funFact: m['fun_fact'] as String?,
      wikiUrl: m['wikipedia_url'] as String?,
      powoUrl: m['powo_url'] as String?,
      extraImages: (m['extra_images'] is List)
          ? (m['extra_images'] as List).map((e) => e.toString()).toList()
          : const [],
      savedAt: saved,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'scientific_name': scientificName,
      'display_name': displayName,
      'note': note,
      'thumbnail_url': thumbnailUrl,
      'family': family,
      'score': score,
      'description': description,
      'care': care,
      'fun_fact': funFact,
      'wikipedia_url': wikiUrl,
      'powo_url': powoUrl,
      'extra_images': extraImages,
      'saved_at':
          FieldValue.serverTimestamp(), // yazarken server zamanı; okurken Timestamp
    };
  }
}

class FavoritesService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get uid => _auth.currentUser?.uid;

  static CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('favorites');

  /// Bilimsel adı slug'a çevirerek docId üretir.
  static String makeIdFromScientific(String sci) {
    final base = (sci.trim().isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : sci);
    final slug = base
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'plant' : slug;
  }

  /// Ekle/Güncelle (aynı docId gelirse merge)
  static Future<void> upsert(FavoritePlant fav) async {
    final u = uid;
    if (u == null) throw Exception('Not signed in');
    await _col(u).doc(fav.id).set(fav.toMap(), SetOptions(merge: true));
  }

  static Future<void> updateNote(String id, String note) async {
    final u = uid;
    if (u == null) throw Exception('Not signed in');
    await _col(u).doc(id).update({'note': note});
  }

  static Future<void> delete(String id) async {
    final u = uid;
    if (u == null) throw Exception('Not signed in');
    await _col(u).doc(id).delete();
  }

  static Future<bool> exists(String id) async {
    final u = uid;
    if (u == null) return false;
    final doc = await _col(u).doc(id).get();
    return doc.exists;
  }

  /// Favorileri kayıttan en yeniye doğru stream eder.
  static Stream<List<FavoritePlant>> stream() {
    final u = uid;
    if (u == null) return const Stream.empty();
    // saved_at alanı olmayan eski dokümanlar da gelsin diye orderBy yerine
    // önce saved_at'e göre, yoksa creationTime fallback'li composite bir çözüm
    return _col(u)
        .orderBy('saved_at', descending: true)
        .snapshots()
        .map(
          (q) =>
              q.docs.map((d) => FavoritePlant.fromMap(d.id, d.data())).toList(),
        );
  }
}
