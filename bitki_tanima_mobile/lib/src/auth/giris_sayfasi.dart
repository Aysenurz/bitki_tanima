import 'package:flutter/material.dart';
import 'auth_service.dart';

class GirisSayfasi extends StatefulWidget {
  final String lang;
  const GirisSayfasi({super.key, required this.lang});

  @override
  State<GirisSayfasi> createState() => _GirisSayfasiState();
}

class _GirisSayfasiState extends State<GirisSayfasi> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _sifre = TextEditingController();
  bool _kayitModu = false;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _sifre.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_form.currentState!.validate()) return;

    setState(() => _loading = true);
    final email = _email.text.trim();
    final sifre = _sifre.text;

    try {
      if (_kayitModu) {
        await AuthServisi.instance.kayitOl(email: email, sifre: sifre);
      } else {
        await AuthServisi.instance.girisYap(email: email, sifre: sifre);
      }
      // Başarılı olursa StreamProvider sayesinde otomatik Home'a gider
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = widget.lang == 'tr';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _kayitModu
              ? (tr ? 'Kayıt Ol' : 'Sign Up')
              : (tr ? 'Giriş Yap' : 'Sign In'),
        ),
      ),
      // Sayfanın içeriğini kaydırılabilir yapmak için SingleChildScrollView eklendi.
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Resim (Logo)
                    Image.asset(
                      'assets/images/logo.png',
                      height: 120, // Logonun yüksekliği
                    ),
                    const SizedBox(height: 24), // Logonun altındaki boşluk
                    // E-posta alanı
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: tr ? 'E-posta' : 'Email',
                        prefixIcon: const Icon(Icons.email),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? (tr ? 'Zorunlu' : 'Required')
                          : null,
                    ),
                    const SizedBox(height: 12),
                    // Şifre alanı
                    TextFormField(
                      controller: _sifre,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: tr ? 'Şifre' : 'Password',
                        prefixIcon: const Icon(Icons.lock),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? (tr ? 'En az 6 karakter' : 'Min 6 chars')
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Giriş Yap butonu
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _kayitModu
                                    ? (tr ? 'Kayıt Ol' : 'Sign Up')
                                    : (tr ? 'Giriş Yap' : 'Sign In'),
                              ),
                      ),
                    ),
                    // Hesap yok butonu
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              setState(() => _kayitModu = !_kayitModu);
                            },
                      child: Text(
                        _kayitModu
                            ? (tr
                                  ? 'Hesabın var mı? Giriş Yap'
                                  : 'Already have an account? Sign In')
                            : (tr
                                  ? 'Hesabın yok mu? Kayıt Ol'
                                  : 'No account? Sign Up'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
