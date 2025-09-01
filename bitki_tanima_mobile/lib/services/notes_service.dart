import 'package:cloud_firestore/cloud_firestore.dart';
import '../src/auth/auth_service.dart';

class NotesService {
  static final _db = FirebaseFirestore.instance;

  static String _uid() {
    final uid = AuthServisi.instance.uid;
    if (uid == null) {
      throw Exception('Not işlemleri için önce giriş yapmalısınız.');
    }
    return uid;
  }

  /// Yeni not ekler ve *oluşturulan doc id*’sini döner
  static Future<String> addNote({required String text}) async {
    final uid = _uid();
    final ref = await _db.collection('users').doc(uid).collection('notes').add({
      'text': text,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Varolan notu günceller
  static Future<void> updateNote({
    required String id,
    required String text,
  }) async {
    final uid = _uid();
    await _db.collection('users').doc(uid).collection('notes').doc(id).update({
      'text': text,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Notları (güncellenme tarihine göre) canlı olarak döner
  static Stream<QuerySnapshot<Map<String, dynamic>>> notesStream() {
    final uid = _uid();
    return _db
        .collection('users')
        .doc(uid)
        .collection('notes')
        .orderBy('updated_at', descending: true)
        .snapshots();
  }

  /// Notu siler
  static Future<void> deleteNote(String id) async {
    final uid = _uid();
    await _db.collection('users').doc(uid).collection('notes').doc(id).delete();
  }
}
