import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../home_page.dart';
import '../translations.dart'; // Uygulama metinlerinin çevirileri burada.
import '../language_selection_page.dart'; // Dil seçme sayfası.
import 'auth/giris_sayfasi.dart'; // Giriş sayfası.
import 'auth/auth_service.dart'; // Kimlik doğrulama işlemleri servisi.

// ✅ Notlar sayfası
import '../notes/notes_page.dart';

/// Uygulamanın en üst düzey (kök) widget'ı.
/// Bu widget, Firebase kimlik doğrulama durumunu (oturum açmış mı, açmamış mı?)
/// dinler ve bu bilgiyi tüm alt widget'lara sağlar (Provider kullanarak).
class MyRoot extends StatelessWidget {
  const MyRoot({super.key});
  @override
  Widget build(BuildContext context) {
    // StreamProvider, FirebaseAuth'ın auth durumundaki değişiklikleri dinler.
    // 'value' olarak, authStateChanges() Stream'ini veririz.
    // 'initialData' olarak, uygulamanın başladığı andaki mevcut kullanıcıyı (varsa) veririz.
    // Bu sayede, alt widget'lar her an kullanıcı durumuna erişebilir.
    return StreamProvider<User?>.value(
      value: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      child: const MyApp(),
    );
  }
}

/// Uygulamanın ana widget'ı.
/// Bu widget, kullanıcının durumuna (oturum açmış mı, dil seçmiş mi?) göre
/// hangi sayfanın gösterileceğine karar verir.
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Uygulamanın mevcut dilini tutan değişken.
  String? lang;
  // Dili değiştiren ve arayüzü yeniden çizen metot.
  void changeLang(String newLang) => setState(() => lang = newLang);

  @override
  Widget build(BuildContext context) {
    // Provider'ı kullanarak kullanıcının durumunu (User nesnesi) dinliyoruz.
    final user = context.watch<User?>();
    // Uygulama başlığını seçilen dile göre alıyoruz.
    final String title = AppTexts.values[lang ?? "tr"]!["appTitle"]!;

    // 1) Dil seçimi henüz yapılmadıysa
    if (lang == null) {
      return MaterialApp(
        title: title,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
        // Dil seçim sayfasını, üstünde AppBar olan bir kabuk içine koyuyoruz.
        home: _ShellScaffold(
          title: title,
          lang: lang ?? 'tr',
          user: user,
          onLangChanged: changeLang,
          child: LanguageSelectionPage(onLangSelected: changeLang),
        ),
      );
    }

    // 2) Dil seçilmiş, ancak kullanıcı oturum açmamışsa
    if (user == null) {
      return MaterialApp(
        title: title,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
        // Giriş sayfasını, üstünde AppBar olan bir kabuk içine koyuyoruz.
        home: _ShellScaffold(
          title: title,
          lang: lang!,
          user: user,
          onLangChanged: changeLang,
          child: GirisSayfasi(lang: lang!),
        ),
      );
    }

    // 3) Dil seçilmiş ve kullanıcı oturum açmışsa
    // Ana uygulama arayüzünü (alt menü/sekme yapısı) gösteriyoruz.
    return MaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: _TabsScaffold(lang: lang!, onLangChanged: changeLang),
    );
  }
}

/// Dil/Giriş sayfaları için ortak bir AppBar'a sahip iskelet widget.
/// Bu, kod tekrarını önler.
class _ShellScaffold extends StatelessWidget {
  final String title;
  final String lang;
  final User? user;
  final void Function(String) onLangChanged;
  final Widget child; // İçine yerleştirilecek sayfa widget'ı.

  const _ShellScaffold({
    super.key,
    required this.title,
    required this.lang,
    required this.user,
    required this.onLangChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Düzeltme: Burada da metinler AppTexts'ten çekilmeliydi.
    final t = AppTexts.values[lang]!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t['appTitle']!,
        ), // ✅ Düzeltme: title değişkeni yerine AppTexts'ten çekildi
        actions: [
          // Dil seçimi için açılır menü butonu.
          PopupMenuButton<String>(
            tooltip: t['language']!, // ✅ Düzeltme
            icon: const Icon(Icons.language),
            onSelected: onLangChanged,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'tr', child: Text('🇹🇷 Türkçe')),
              PopupMenuItem(value: 'en', child: Text('🇬🇧 English')),
            ],
          ),
          // Eğer kullanıcı oturum açmışsa çıkış yap butonunu göster.
          if (user != null)
            IconButton(
              tooltip: t['signOut']!, // ✅ Düzeltme
              icon: const Icon(Icons.logout),
              onPressed: () async {
                // Çıkış yapmadan önce onay penceresi göster.
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(t['signOut']!), // ✅ Düzeltme
                    content: Text(t['signOutConfirm']!), // ✅ Düzeltme
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(t['cancel']!), // ✅ Düzeltme
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(t['yes']!), // ✅ Düzeltme
                      ),
                    ],
                  ),
                );
                // Onay geldiyse AuthServisi üzerinden çıkış yap.
                if (ok == true) await AuthServisi.instance.cikisYap();
              },
            ),
        ],
      ),
      body: child,
    );
  }
}

/// Kullanıcı giriş yaptıktan sonra gösterilen ana iskelet.
/// Alt kısmında sekmeler arası geçişi sağlayan NavigationBar bulunur.
class _TabsScaffold extends StatefulWidget {
  final String lang;
  final void Function(String) onLangChanged;
  const _TabsScaffold({
    super.key,
    required this.lang,
    required this.onLangChanged,
  });

  @override
  State<_TabsScaffold> createState() => _TabsScaffoldState();
}

class _TabsScaffoldState extends State<_TabsScaffold> {
  // Hangi sekmenin seçili olduğunu tutan indeks.
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // Düzeltme: Burada da metinler AppTexts'ten çekilmeliydi.
    final t = AppTexts.values[widget.lang]!;

    // Sekmelerdeki sayfaların listesi.
    final pages = <Widget>[
      HomePage(lang: widget.lang, changeLang: widget.onLangChanged),
      NotesPage(lang: widget.lang),
      _SettingsPage(lang: widget.lang, onLangChanged: widget.onLangChanged),
    ];

    return Scaffold(
      // Seçili indekse göre ilgili sayfayı gösterir, diğerlerini bellekte tutar.
      body: IndexedStack(index: _index, children: pages),
      // Uygulamanın altındaki navigasyon çubuğu.
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: t['home']!, // ✅ Düzeltme
          ),
          NavigationDestination(
            icon: const Icon(Icons.note_alt_outlined),
            selectedIcon: const Icon(Icons.note_alt),
            label: t['notes']!, // ✅ Düzeltme
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: t['settings']!, // ✅ Düzeltme
          ),
        ],
      ),
    );
  }
}

/// ---- Ayarlar sekmesi (dil + çıkış) ----
/// Bu sayfa, dil değiştirme ve çıkış yapma seçeneklerini içerir.
class _SettingsPage extends StatelessWidget {
  final String lang;
  final void Function(String) onLangChanged;
  const _SettingsPage({required this.lang, required this.onLangChanged});

  @override
  Widget build(BuildContext context) {
    // Düzeltme: Burada da metinler AppTexts'ten çekilmeliydi.
    final t = AppTexts.values[lang]!;
    return Scaffold(
      appBar: AppBar(title: Text(t['settings']!)), // ✅ Düzeltme
      body: ListView(
        children: [
          // Dil değiştirme seçeneği.
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(t['language']!), // ✅ Düzeltme
            subtitle: Text(
              lang == 'tr' ? 'Uygulama dili' : 'App language',
            ), // Bu satır için çeviri eklenmeli
            trailing: DropdownButton<String>(
              value: lang,
              onChanged: (v) {
                if (v != null) onLangChanged(v);
              },
              items: const [
                DropdownMenuItem(value: 'tr', child: Text('🇹🇷 Türkçe')),
                DropdownMenuItem(value: 'en', child: Text('🇬🇧 English')),
              ],
            ),
          ),
          const Divider(),
          // Çıkış yapma seçeneği.
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(t['signOut']!), // ✅ Düzeltme
            onTap: () async {
              // Çıkış yapmadan önce onay penceresi göster.
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(t['signOut']!), // ✅ Düzeltme
                  content: Text(t['signOutConfirm']!), // ✅ Düzeltme
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(t['cancel']!), // ✅ Düzeltme
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(t['yes']!), // ✅ Düzeltme
                    ),
                  ],
                ),
              );
              // Onay geldiyse AuthServisi üzerinden çıkış yap.
              if (ok == true) await AuthServisi.instance.cikisYap();
            },
          ),
        ],
      ),
    );
  }
}
