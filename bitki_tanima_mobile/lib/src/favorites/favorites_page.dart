import 'package:flutter/material.dart';
import 'package:bitki_tanima_mobile/services/favorites_service.dart' as fs;
import 'package:bitki_tanima_mobile/src/favorites/favorite_detail_page.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoriler')),
      body: StreamBuilder<List<fs.FavoritePlant>>(
        stream: fs.FavoritesService.stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snap.data ?? <fs.FavoritePlant>[];
          if (items.isEmpty) {
            return const Center(child: Text('Henüz favori eklenmemiş.'));
          }

          bool _validUrl(String? u) => (u ?? '').startsWith('http');

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final f = items[i];

              final thumb =
                  f.extraImages.isNotEmpty && _validUrl(f.extraImages.first)
                  ? f.extraImages.first
                  : (_validUrl(f.thumbnailUrl) ? f.thumbnailUrl : null);

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: (thumb != null)
                          ? Image.network(thumb, fit: BoxFit.cover)
                          : Container(
                              color: Colors.green.withOpacity(0.12),
                              child: const Icon(Icons.eco, size: 28),
                            ),
                    ),
                  ),
                  title: Text(
                    f.displayName.isNotEmpty ? f.displayName : f.scientificName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((f.note ?? '').trim().isNotEmpty)
                        Text(
                          '📝 ${f.note}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (f.family != null) Text('👪 ${f.family}'),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FavoriteDetailPage(plant: f),
                      ),
                    );
                  },
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        final ctrl = TextEditingController(text: f.note ?? '');
                        final newNote = await showDialog<String>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Not'),
                            content: TextField(controller: ctrl, maxLines: 3),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('İptal'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.pop(context, ctrl.text.trim()),
                                child: const Text('Kaydet'),
                              ),
                            ],
                          ),
                        );
                        if (newNote != null) {
                          await fs.FavoritesService.updateNote(f.id, newNote);
                        }
                      } else if (v == 'delete') {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Sil'),
                            content: const Text(
                              'Favoriden kaldırmak istiyor musun?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('İptal'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Sil'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await fs.FavoritesService.delete(f.id);
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Notu düzenle')),
                      PopupMenuItem(value: 'delete', child: Text('Sil')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
