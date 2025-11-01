<<<<<<< HEAD
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
=======
// lib/src/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../home_page.dart';
import '../translations.dart';
import '../language_selection_page.dart';
import '../plant_detail_page.dart'; // Favorilerden detay için gerekli
import 'auth/giris_sayfasi.dart';
import 'auth/auth_service.dart';

/// Auth durumunu tüm uygulamaya sağlayan kök widget
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
class MyRoot extends StatelessWidget {
  const MyRoot({super.key});
  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    // StreamProvider, FirebaseAuth'ın auth durumundaki değişiklikleri dinler.
    // 'value' olarak, authStateChanges() Stream'ini veririz.
    // 'initialData' olarak, uygulamanın başladığı andaki mevcut kullanıcıyı (varsa) veririz.
    // Bu sayede, alt widget'lar her an kullanıcı durumuna erişebilir.
=======
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
    return StreamProvider<User?>.value(
      value: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      child: const MyApp(),
    );
  }
}

<<<<<<< HEAD
/// Uygulamanın ana widget'ı.
/// Bu widget, kullanıcının durumuna (oturum açmış mı, dil seçmiş mi?) göre
/// hangi sayfanın gösterileceğine karar verir.
=======
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
<<<<<<< HEAD
  // Uygulamanın mevcut dilini tutan değişken.
  String? lang;
  // Dili değiştiren ve arayüzü yeniden çizen metot.
=======
  String? lang;
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
  void changeLang(String newLang) => setState(() => lang = newLang);

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    // Provider'ı kullanarak kullanıcının durumunu (User nesnesi) dinliyoruz.
    final user = context.watch<User?>();
    // Uygulama başlığını seçilen dile göre alıyoruz.
    final String title = AppTexts.values[lang ?? "tr"]!["appTitle"]!;

    // 1) Dil seçimi henüz yapılmadıysa
=======
    final user = context.watch<User?>();

    final String title =
        AppTexts.values[lang ?? "tr"]?["appTitle"] ?? "Bitki Tanıma";

    // 1) Dil seçimi yoksa
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
    if (lang == null) {
      return MaterialApp(
        title: title,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
<<<<<<< HEAD
        // Dil seçim sayfasını, üstünde AppBar olan bir kabuk içine koyuyoruz.
=======
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
        home: _ShellScaffold(
          title: title,
          lang: lang ?? 'tr',
          user: user,
          onLangChanged: changeLang,
          child: LanguageSelectionPage(onLangSelected: changeLang),
        ),
      );
    }

<<<<<<< HEAD
    // 2) Dil seçilmiş, ancak kullanıcı oturum açmamışsa
=======
    // 2) Dil seçildi; kullanıcı yoksa
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
    if (user == null) {
      return MaterialApp(
        title: title,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
<<<<<<< HEAD
        // Giriş sayfasını, üstünde AppBar olan bir kabuk içine koyuyoruz.
=======
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
        home: _ShellScaffold(
          title: title,
          lang: lang!,
          user: user,
          onLangChanged: changeLang,
          child: GirisSayfasi(lang: lang!),
        ),
      );
    }

<<<<<<< HEAD
    // 3) Dil seçilmiş ve kullanıcı oturum açmışsa
    // Ana uygulama arayüzünü (alt menü/sekme yapısı) gösteriyoruz.
=======
    // 3) Kullanıcı var -> Tabs (alt menü)
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
    return MaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: _TabsScaffold(lang: lang!, onLangChanged: changeLang),
    );
  }
}

<<<<<<< HEAD
/// Dil/Giriş sayfaları için ortak bir AppBar'a sahip iskelet widget.
/// Bu, kod tekrarını önler.
=======
/// Dil/Giriş sayfaları için üstte AppBar'lı kabuk
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
class _ShellScaffold extends StatelessWidget {
  final String title;
  final String lang;
  final User? user;
  final void Function(String) onLangChanged;
<<<<<<< HEAD
  final Widget child; // İçine yerleştirilecek sayfa widget'ı.
=======
  final Widget child;
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af

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
<<<<<<< HEAD
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
=======
    final tr = (lang == 'tr');
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          PopupMenuButton<String>(
            tooltip: tr ? 'Dil' : 'Language',
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
            icon: const Icon(Icons.language),
            onSelected: onLangChanged,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'tr', child: Text('🇹🇷 Türkçe')),
              PopupMenuItem(value: 'en', child: Text('🇬🇧 English')),
            ],
          ),
<<<<<<< HEAD
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
=======
          if (user != null)
            IconButton(
              tooltip: tr ? 'Çıkış Yap' : 'Sign Out',
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(tr ? 'Çıkış Yap' : 'Sign Out'),
                    content: Text(
                      tr
                          ? 'Hesabınızdan çıkmak istiyor musunuz?'
                          : 'Do you want to sign out?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(tr ? 'İptal' : 'Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(tr ? 'Evet' : 'Yes'),
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
                      ),
                    ],
                  ),
                );
<<<<<<< HEAD
                // Onay geldiyse AuthServisi üzerinden çıkış yap.
=======
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
                if (ok == true) await AuthServisi.instance.cikisYap();
              },
            ),
        ],
      ),
      body: child,
    );
  }
}

<<<<<<< HEAD
/// Kullanıcı giriş yaptıktan sonra gösterilen ana iskelet.
/// Alt kısmında sekmeler arası geçişi sağlayan NavigationBar bulunur.
=======
/// Girişten sonra: Alt NavigationBar'lı ana iskelet
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
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
<<<<<<< HEAD
  // Hangi sekmenin seçili olduğunu tutan indeks.
=======
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
  int _index = 0;

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    // Düzeltme: Burada da metinler AppTexts'ten çekilmeliydi.
    final t = AppTexts.values[widget.lang]!;

    // Sekmelerdeki sayfaların listesi.
    final pages = <Widget>[
      HomePage(lang: widget.lang, changeLang: widget.onLangChanged),
      NotesPage(lang: widget.lang),
=======
    final pages = <Widget>[
      HomePage(lang: widget.lang, changeLang: widget.onLangChanged),
      _FavoritesPage(lang: widget.lang),
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
      _SettingsPage(lang: widget.lang, onLangChanged: widget.onLangChanged),
    ];

    return Scaffold(
<<<<<<< HEAD
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
=======
      body: IndexedStack(index: _index, children: pages),
      // 🔍 FAB (arama) kaldırıldı
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favoriler',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}

/// -------- Favoriler sekmesi: Firestore'dan liste --------
class _FavoritesPage extends StatelessWidget {
  final String lang;
  const _FavoritesPage({required this.lang});

  @override
  Widget build(BuildContext context) {
    final uid = AuthServisi.instance.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Giriş yapmalısınız.')));
    }

    final favCol = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .orderBy('savedAt', descending: true);

    final tr = (lang == 'tr');

    return Scaffold(
      appBar: AppBar(title: Text(tr ? 'Favoriler' : 'Favorites')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: favCol.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                tr
                    ? 'Henüz favori bitki yok.\nSonuç ekranındaki kalp ile ekleyebilirsin.'
                    : 'No favorites yet.\nAdd from the result page via heart.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final fav = docs[i];
              final plantId = fav.id;

              final plantDoc = FirebaseFirestore.instance
                  .collection('plants')
                  .doc(plantId)
                  .get();

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: plantDoc,
                builder: (context, pSnap) {
                  final p = pSnap.data?.data();
                  final nameTr = (p?['names']?['tr'] ?? plantId) as String;
                  final nameEn = (p?['names']?['en'] ?? '') as String;
                  final thumb = (p?['thumbnails'] as List?)
                      ?.cast<String>()
                      .firstOrNull;

                  return ListTile(
                    leading: thumb != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              thumb,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.local_florist),
                    title: Text(
                      lang == 'tr'
                          ? nameTr
                          : (nameEn.isNotEmpty ? nameEn : nameTr),
                    ),
                    subtitle: Text(lang == 'tr' ? nameEn : nameTr),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              PlantDetailPage(plantId: plantId, lang: lang),
                        ),
                      );
                    },
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'note') {
                          final note = await _editNoteDialog(
                            context,
                            initial: (fav.data()['note'] ?? '') as String,
                            tr: tr,
                          );
                          if (note != null) {
                            await fav.reference.set({
                              'note': note,
                            }, SetOptions(merge: true));
                          }
                        } else if (v == 'delete') {
                          await fav.reference.delete();
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'note',
                          child: Text(
                            tr ? 'Not ekle/düzenle' : 'Add/Edit note',
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(tr ? 'Favoriden kaldır' : 'Remove'),
                        ),
                      ],
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

  Future<String?> _editNoteDialog(
    BuildContext context, {
    required String initial,
    required bool tr,
  }) async {
    final c = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr ? 'Not' : 'Note'),
        content: TextField(
          controller: c,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: tr
                ? 'Bu bitkiyle ilgili notun…'
                : 'Your note about this plant…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr ? 'İptal' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, c.text.trim()),
            child: Text(tr ? 'Kaydet' : 'Save'),
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
          ),
        ],
      ),
    );
  }
}

/// ---- Ayarlar sekmesi (dil + çıkış) ----
<<<<<<< HEAD
/// Bu sayfa, dil değiştirme ve çıkış yapma seçeneklerini içerir.
=======
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
class _SettingsPage extends StatelessWidget {
  final String lang;
  final void Function(String) onLangChanged;
  const _SettingsPage({required this.lang, required this.onLangChanged});

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
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
=======
    final tr = (lang == 'tr');
    return Scaffold(
      appBar: AppBar(title: Text(tr ? 'Ayarlar' : 'Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(tr ? 'Dil' : 'Language'),
            subtitle: Text(tr ? 'Uygulama dili' : 'App language'),
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
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
<<<<<<< HEAD
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
=======
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(tr ? 'Çıkış Yap' : 'Sign Out'),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(tr ? 'Çıkış Yap' : 'Sign Out'),
                  content: Text(
                    tr
                        ? 'Hesabınızdan çıkmak istiyor musunuz?'
                        : 'Do you want to sign out?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(tr ? 'İptal' : 'Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(tr ? 'Evet' : 'Yes'),
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
                    ),
                  ],
                ),
              );
<<<<<<< HEAD
              // Onay geldiyse AuthServisi üzerinden çıkış yap.
=======
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
              if (ok == true) await AuthServisi.instance.cikisYap();
            },
          ),
        ],
      ),
    );
  }
}
<<<<<<< HEAD
=======

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
