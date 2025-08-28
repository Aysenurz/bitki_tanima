// lib/src/auth/auth_service.dart
//
// Firebase Auth işlemleri için servis katmanı.
// - Email/Şifre ile kayıt, giriş, çıkış
// - Şifre sıfırlama
// - Profil güncelleme (adSoyad, fotoUrl)
// - Yeniden doğrulama (kritik işlemler öncesi)
// - Hesap silme
// - Firestore'da users/{uid} profil dokümanı oluşturma (ilk girişte)
//
// Kullanım:
// final auth = AuthServisi.instance;
// await auth.girisYap(email: "...", sifre: "...");

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthHatasi implements Exception {
  final String kod;
  final String mesaj;
  AuthHatasi(this.kod, this.mesaj);
  @override
  String toString() => 'AuthHatasi($kod): $mesaj';
}

class AuthServisi {
  AuthServisi._();
  static final AuthServisi instance = AuthServisi._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Aktif kullanıcı (yoksa null)
  User? get mevcutKullanici => _auth.currentUser;

  /// Kullanıcı ID (yoksa null)
  String? get uid => _auth.currentUser?.uid;

  /// Auth durum akışı (giriş/çıkış değişimlerini yayınlar)
  Stream<User?> get authDurumuAkisi => _auth.authStateChanges();

  /// Email/şifre ile kayıt ol. İsteğe bağlı profil adı verebilirsin.
  Future<UserCredential> kayitOl({
    required String email,
    required String sifre,
    String? adSoyad,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: sifre,
      );

      if (adSoyad != null && adSoyad.trim().isNotEmpty) {
        await cred.user?.updateDisplayName(adSoyad.trim());
      }

      // İlk kayıt sonrası profil dokümanı (yoksa) oluştur
      await _ilkKullanimProfilOlustur(cred.user);

      return cred;
    } on FirebaseAuthException catch (e) {
      throw AuthHatasi(e.code, _hataCevir(e));
    } catch (e) {
      throw AuthHatasi('unknown', 'Beklenmeyen bir hata oluştu: $e');
    }
  }

  /// Email/şifre ile giriş yap.
  Future<UserCredential> girisYap({
    required String email,
    required String sifre,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: sifre,
      );

      // Girişte de profil dokümanı yoksa oluştur
      await _ilkKullanimProfilOlustur(cred.user);

      return cred;
    } on FirebaseAuthException catch (e) {
      throw AuthHatasi(e.code, _hataCevir(e));
    } catch (e) {
      throw AuthHatasi('unknown', 'Beklenmeyen bir hata oluştu: $e');
    }
  }

  /// Çıkış yap.
  Future<void> cikisYap() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthHatasi(e.code, _hataCevir(e));
    } catch (e) {
      throw AuthHatasi('unknown', 'Çıkış yapılırken hata oluştu: $e');
    }
  }

  /// Şifre sıfırlama maili gönder.
  Future<void> sifreSifirla(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthHatasi(e.code, _hataCevir(e));
    } catch (e) {
      throw AuthHatasi('unknown', 'Şifre sıfırlama sırasında hata: $e');
    }
  }

  /// Profil bilgilerini güncelle (adSoyad, fotoUrl).
  Future<void> profilGuncelle({String? adSoyad, String? fotoUrl}) async {
    try {
      final u = _auth.currentUser;
      if (u == null) throw AuthHatasi('no-user', 'Oturum bulunamadı.');

      if (adSoyad != null) await u.updateDisplayName(adSoyad.trim());
      if (fotoUrl != null) await u.updatePhotoURL(fotoUrl.trim());

      // Firestore profilini de eşitle
      await _db.collection('users').doc(u.uid).set({
        if (adSoyad != null) 'profile.displayName': adSoyad.trim(),
        if (fotoUrl != null) 'profile.photoURL': fotoUrl.trim(),
        'profile.updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseAuthException catch (e) {
      throw AuthHatasi(e.code, _hataCevir(e));
    } catch (e) {
      throw AuthHatasi('unknown', 'Profil güncellenemedi: $e');
    }
  }

  /// Kritik işlemler öncesi yeniden doğrulama (ör. hesap silme).
  Future<void> emailIleYenidenDogrula({
    required String email,
    required String sifre,
  }) async {
    try {
      final u = _auth.currentUser;
      if (u == null) throw AuthHatasi('no-user', 'Oturum bulunamadı.');

      final cred = EmailAuthProvider.credential(
        email: email.trim(),
        password: sifre,
      );
      await u.reauthenticateWithCredential(cred);
    } on FirebaseAuthException catch (e) {
      throw AuthHatasi(e.code, _hataCevir(e));
    } catch (e) {
      throw AuthHatasi('unknown', 'Yeniden doğrulama başarısız: $e');
    }
  }

  /// Hesabı sil (Firebase Auth + users/{uid} dokümanı).
  Future<void> hesapSil() async {
    try {
      final u = _auth.currentUser;
      if (u == null) throw AuthHatasi('no-user', 'Oturum bulunamadı.');

      // Önce Firestore profilini sil
      await _db.collection('users').doc(u.uid).delete().catchError((_) {
        // Profil dokümanı olmayabilir; sessiz geçiyoruz.
      });

      // Ardından auth hesabını sil
      await u.delete();
    } on FirebaseAuthException catch (e) {
      // requires-recent-login durumunda önce yeniden doğrulama iste.
      throw AuthHatasi(e.code, _hataCevir(e));
    } catch (e) {
      throw AuthHatasi('unknown', 'Hesap silinemedi: $e');
    }
  }

  /// İlk giriş/kayıt anında users/{uid} dokümanı oluşturur (yoksa).
  Future<void> _ilkKullanimProfilOlustur(User? u) async {
    if (u == null) return;
    final ref = _db.collection('users').doc(u.uid);
    final sn = await ref.get();
    if (sn.exists) return;

    await ref.set({
      'profile': {
        'uid': u.uid,
        'email': u.email,
        'displayName': u.displayName,
        'photoURL': u.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      },
      // Varsayılan ayarlar (dil/tema) — istersen burada değiştir
      'settings': {'language': 'tr', 'theme': 'system', 'notifications': true},
    }, SetOptions(merge: true));
  }

  /// FirebaseAuthException -> Türkçe mesaj
  String _hataCevir(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'user-disabled':
        return 'Bu kullanıcı devre dışı bırakılmış.';
      case 'user-not-found':
        return 'Bu e-posta ile kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Şifre hatalı.';
      case 'email-already-in-use':
        return 'Bu e-posta zaten kullanımda.';
      case 'weak-password':
        return 'Şifre çok zayıf. Daha güçlü bir şifre deneyin.';
      case 'operation-not-allowed':
        return 'Bu işlem şu anda izinli değil.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Lütfen sonra tekrar deneyin.';
      case 'network-request-failed':
        return 'Ağ hatası. İnternet bağlantınızı kontrol edin.';
      case 'requires-recent-login':
        return 'Bu işlem için lütfen tekrar giriş yapın (yeniden doğrulama gerekli).';
      default:
        return e.message ?? 'Bilinmeyen bir hata oluştu.';
    }
  }
}
