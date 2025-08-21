import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:bitki_tanima_mobile/services/favorites_service.dart' as fs;

class FavoriteDetailPage extends StatelessWidget {
  final fs.FavoritePlant plant;
  const FavoriteDetailPage({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    final p = plant;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.displayName.isNotEmpty ? p.displayName : 'Bitki'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (p.extraImages.isNotEmpty || (p.thumbnailUrl ?? '').isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                p.extraImages.isNotEmpty
                    ? p.extraImages.first
                    : (p.thumbnailUrl ?? ''),
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 12),

          Text(
            p.scientificName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          if (p.family != null) Text('Aile: ${p.family}'),
          if (p.score != null)
            Text('Skor: ${(p.score! * 100).toStringAsFixed(1)}%'),

          const SizedBox(height: 10),
          if ((p.description ?? '').isNotEmpty)
            Text(p.description!, style: const TextStyle(height: 1.35)),

          if (p.care.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Bakım Önerileri',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ...p.care.map((e) => Text('• $e')),
          ],

          if ((p.funFact ?? '').isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('✨ ${p.funFact!}'),
          ],

          const SizedBox(height: 16),
          Row(
            children: [
              if ((p.wikiUrl ?? '').isNotEmpty)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => launchUrlString(p.wikiUrl!),
                    icon: const Icon(Icons.link),
                    label: const Text('Wikipedia'),
                  ),
                ),
              if ((p.wikiUrl ?? '').isNotEmpty && (p.powoUrl ?? '').isNotEmpty)
                const SizedBox(width: 12),
              if ((p.powoUrl ?? '').isNotEmpty)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => launchUrlString(p.powoUrl!),
                    icon: const Icon(Icons.public),
                    label: const Text('POWO'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
