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
class MyRoot extends StatelessWidget {
  const MyRoot({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamProvider<User?>.value(
      value: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      child: const MyApp(),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? lang;
  void changeLang(String newLang) => setState(() => lang = newLang);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();

    final String title =
        AppTexts.values[lang ?? "tr"]?["appTitle"] ?? "Bitki Tanıma";

    // 1) Dil seçimi yoksa
    if (lang == null) {
      return MaterialApp(
        title: title,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
        home: _ShellScaffold(
          title: title,
          lang: lang ?? 'tr',
          user: user,
          onLangChanged: changeLang,
          child: LanguageSelectionPage(onLangSelected: changeLang),
        ),
      );
    }

    // 2) Dil seçildi; kullanıcı yoksa
    if (user == null) {
      return MaterialApp(
        title: title,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
        home: _ShellScaffold(
          title: title,
          lang: lang!,
          user: user,
          onLangChanged: changeLang,
          child: GirisSayfasi(lang: lang!),
        ),
      );
    }

    // 3) Kullanıcı var -> Tabs (alt menü)
    return MaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: _TabsScaffold(lang: lang!, onLangChanged: changeLang),
    );
  }
}

/// Dil/Giriş sayfaları için üstte AppBar'lı kabuk
class _ShellScaffold extends StatelessWidget {
  final String title;
  final String lang;
  final User? user;
  final void Function(String) onLangChanged;
  final Widget child;

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
    final tr = (lang == 'tr');
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          PopupMenuButton<String>(
            tooltip: tr ? 'Dil' : 'Language',
            icon: const Icon(Icons.language),
            onSelected: onLangChanged,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'tr', child: Text('🇹🇷 Türkçe')),
              PopupMenuItem(value: 'en', child: Text('🇬🇧 English')),
            ],
          ),
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
                      ),
                    ],
                  ),
                );
                if (ok == true) await AuthServisi.instance.cikisYap();
              },
            ),
        ],
      ),
      body: child,
    );
  }
}

/// Girişten sonra: Alt NavigationBar'lı ana iskelet
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
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(lang: widget.lang, changeLang: widget.onLangChanged),
      _FavoritesPage(lang: widget.lang),
      _SettingsPage(lang: widget.lang, onLangChanged: widget.onLangChanged),
    ];

    return Scaffold(
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
          ),
        ],
      ),
    );
  }
}

/// ---- Ayarlar sekmesi (dil + çıkış) ----
class _SettingsPage extends StatelessWidget {
  final String lang;
  final void Function(String) onLangChanged;
  const _SettingsPage({required this.lang, required this.onLangChanged});

  @override
  Widget build(BuildContext context) {
    final tr = (lang == 'tr');
    return Scaffold(
      appBar: AppBar(title: Text(tr ? 'Ayarlar' : 'Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(tr ? 'Dil' : 'Language'),
            subtitle: Text(tr ? 'Uygulama dili' : 'App language'),
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
                    ),
                  ],
                ),
              );
              if (ok == true) await AuthServisi.instance.cikisYap();
            },
          ),
        ],
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
