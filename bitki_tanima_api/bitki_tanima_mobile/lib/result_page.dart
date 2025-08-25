// lib/result_page.dart
//
// 🔧 Bu sürümde yapılanlar:
// - AppBar'daki eski _FavoriteButton kaldırıldı (sadece savedAt yazıyordu).
// - Yerine, tüm sonucu Firestore'a eksiksiz kaydeden _saveToFavorites() eklendi.
// - 'saved_at' alan adı standartlaştırıldı (FavoritesService ile uyumlu).
// - Çifte import (kIsWeb) düzeltildi.
// - Anlaşılır Türkçe yorumlar eklendi.

import 'dart:async'; // TimeoutException için
import 'dart:convert'; // jsonDecode
import 'dart:io' show File; // Mobilde fotoğrafı göstermek için
import 'dart:ui'; // BackdropFilter blur

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint; // tek satırda
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';

// NOT: Cloud Firestore'ı burada direkt kullanmıyoruz; favori kaydını
// FavoritesService üzerinden yapacağız. O yüzden bu import gerekli değil.
// import 'package:cloud_firestore/cloud_firestore.dart';

import 'src/auth/auth_service.dart';
import 'translations.dart';
import 'config.dart';

// ✅ Favori servisimiz ve model (tam veriyi kaydetmek için)
import 'services/favorites_service.dart';

class ResultPage extends StatefulWidget {
  final XFile imageFile; // Seçilen/çekilen fotoğraf (XFile)
  final String lang; // 'tr' veya 'en'

  const ResultPage({super.key, required this.imageFile, required this.lang});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  bool loading = true; // Ekranda loader göstermek için
  String error = ""; // Hata mesajı (varsa)
  Map<String, dynamic>? data; // API'den gelen JSON
  List<String> extraImages = []; // Ek görseller (grid için)

  @override
  void initState() {
    super.initState();
    _sendImage(); // Sayfa açılır açılmaz fotoğrafı API'ye yollarız
  }

  // 📡 Fotoğrafı FastAPI /predict'e gönderir
  Future<void> _sendImage() async {
    final apiUrl = Uri.parse('${AppConfig.apiBase}/predict');
    debugPrint('API URL => $apiUrl');

    try {
      final req = http.MultipartRequest('POST', apiUrl)
        ..fields['organ'] = 'leaf'
        ..fields['lang'] = widget.lang;

      if (kIsWeb) {
        // Web: XFile -> bytes
        final bytes = await widget.imageFile.readAsBytes();
        req.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: widget.imageFile.name,
          ),
        );
      } else {
        // Android/iOS: dosya yolundan ekle
        req.files.add(
          await http.MultipartFile.fromPath('file', widget.imageFile.path),
        );
      }

      // 10 sn zaman aşımı
      final resp = await req.send().timeout(const Duration(seconds: 10));
      final body = await resp.stream.bytesToString();

      if (resp.statusCode != 200) {
        throw Exception('API ${resp.statusCode}: $body');
      }

      final jsonResp = jsonDecode(body) as Map<String, dynamic>;
      setState(() {
        data = jsonResp;
        extraImages =
            (jsonResp['extra_images'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        loading = false;
        error = '';
      });
    } on TimeoutException {
      setState(() {
        loading = false;
        error =
            'Sunucuya ulaşılamadı (zaman aşımı). Base: ${AppConfig.apiBase}';
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  // 🔑 Favori docId üretmek için (bilimsel addan slug)
  String _derivePlantId() {
    final id = (data?['plant_id'] ?? data?['id'] ?? '').toString().trim();
    if (id.isNotEmpty) return id;
    final sci = (data?['scientific_name'] ?? '').toString();
    return _slugify(sci);
  }

  // küçük harf, boşlukları '-' yap, alfasayısal dışını temizle
  String _slugify(String s) {
    final lowered = s.toLowerCase().trim();
    final slug = lowered
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'unknown-plant' : slug;
  }

  String _scoreStr(dynamic s) {
    if (s == null) return "-";
    final num? v = (s is num) ? s : num.tryParse(s.toString());
    if (v == null) return "-";
    final p = (v * 100).clamp(0, 100).toStringAsFixed(1);
    return "%$p";
  }

  String _familyEmoji(String? family) {
    final f = (family ?? "").toLowerCase();
    if (f.contains("rosaceae")) return "🌹";
    if (f.contains("asteraceae")) return "🌼";
    if (f.contains("araceae")) return "🍃";
    if (f.contains("lamiaceae")) return "🌿";
    if (f.contains("orchid")) return "🪷";
    return "🪴";
  }

  Widget _aiChip() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.green.shade700.withOpacity(0.9),
      borderRadius: BorderRadius.circular(999),
    ),
    child: const Text(
      "⚡ AI",
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
    ),
  );

  Widget _title(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
    ),
  );

  Widget _kv(String k, String v, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
            height: 1.25,
          ),
          children: [
            TextSpan(
              text: "$k: ",
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text: v,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13.5)),
    );
  }

  Future<void> _openUrl(String url) async {
    final ok = await launchUrlString(url, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.lang == "tr" ? "Bağlantı açılamadı" : "Could not open link",
          ),
        ),
      );
    }
  }

  // 🌐 Wikipedia/POWO butonlarını akıllı yapan yardımcı
  Widget _smartLinkButton({
    required String title,
    String? primary,
    List<dynamic>? candidates,
    Color? color,
  }) {
    if ((primary == null || primary.trim().isEmpty) &&
        (candidates == null || candidates.isEmpty)) {
      return const SizedBox.shrink();
    }
    final cand = (candidates ?? const []).map((e) => e.toString()).toList();
    return Expanded(
      child: GestureDetector(
        onLongPress: cand.isEmpty
            ? null
            : () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => SafeArea(
                    child: ListView(
                      padding: const EdgeInsets.all(8),
                      children: [
                        const ListTile(title: Text("Alternatif bağlantılar")),
                        for (final u in cand)
                          ListTile(
                            leading: const Icon(Icons.link),
                            title: Text(
                              u,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _openUrl(u);
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
        child: FilledButton.icon(
          onPressed: () =>
              _openUrl((primary ?? (cand.isNotEmpty ? cand.first : "")).trim()),
          icon: const Icon(Icons.link),
          label: Text(title),
          style: FilledButton.styleFrom(
            backgroundColor: color ?? Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  // ❤️ Tüm sonucu Firestore'a EKLEYEN/GÜNCELLEYEN fonksiyon
  Future<void> _saveToFavorites() async {
    // 1) Giriş kontrolü
    if (AuthServisi.instance.uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.lang == 'tr'
                ? 'Lütfen önce giriş yapın'
                : 'Please sign in first',
          ),
        ),
      );
      return;
    }
    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kaydedilecek sonuç verisi yok.')),
      );
      return;
    }

    // 2) API alanlarını oku
    final sci = (data!['scientific_name'] ?? '').toString().trim();
    if (sci.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bilimsel ad yok, kaydedilemedi.')),
      );
      return;
    }
    final commons =
        (data!['common_names'] as List?)?.map((e) => e.toString()).toList() ??
        const [];
    final display = commons.isNotEmpty ? commons.first : sci;

    final List<String> imgs =
        (data!['extra_images'] as List?)?.map((e) => e.toString()).toList() ??
        const [];
    final thumb = imgs.isNotEmpty ? imgs.first : null;

    final double? score = (data!['score'] is num)
        ? (data!['score'] as num).toDouble()
        : null;

    // 3) DocId (slug)
    final id = FavoritesService.makeIdFromScientific(sci);

    // 4) Modeli doldur (FavoritesService.toMap() saved_at'i serverTimestamp ile yazar)
    final fav = FavoritePlant(
      id: id,
      scientificName: sci,
      displayName: display,
      thumbnailUrl: thumb,
      family: (data!['family']?.toString()),
      score: score,
      description: (data!['description']?.toString()),
      care:
          ((data!['care'] as List?)?.map((e) => e.toString()).toList()) ??
          const [],
      funFact: (data!['fun_fact']?.toString()),
      wikiUrl: (data!['wikipedia_url']?.toString()),
      powoUrl: (data!['powo_url']?.toString()),
      extraImages: imgs,
      // savedAt: null  // toMap içinde serverTimestamp ile otomatik
    );

    // 5) Firestore'a yaz
    try {
      final existed = await FavoritesService.exists(id);
      await FavoritesService.upsert(fav);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existed ? 'Favori güncellendi' : 'Favorilere eklendi'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kaydedilemedi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTexts.values[widget.lang]!;

    final sci = data?["scientific_name"] ?? "-";
    final family = data?["family"] ?? "-";
    final score = _scoreStr(data?["score"]);
    final commons =
        (data?["common_names"] as List?)?.cast<String>() ?? const [];
    final desc = data?["description"] ?? "-";
    final care = (data?["care"] as List?)?.cast<String>() ?? const [];
    final fun = (data?["fun_fact"] as String?)?.trim() ?? "";
    final wiki = data?["wikipedia_url"] as String?;
    final powo = data?["powo_url"] as String?;
    final wikiC = (data?["wikipedia_candidates"] as List?) ?? const [];
    final powoC = (data?["powo_candidates"] as List?) ?? const [];
    final aiUsed = data?["ai_used"] == true;
    final aiError = data?["ai_error"] as String?;

    return Scaffold(
      appBar: AppBar(
        title: Text(t["appTitle"]!),
        actions: [
          // ✅ Eski _FavoriteButton yerine doğrudan kaydetme butonu:
          if (!loading &&
              error.isEmpty &&
              data != null &&
              AuthServisi.instance.uid != null)
            IconButton(
              tooltip: widget.lang == 'tr'
                  ? 'Favorilere ekle/güncelle'
                  : 'Add/Update favorite',
              icon: const Icon(Icons.favorite_border),
              onPressed: _saveToFavorites,
            ),
        ],
      ),
      body: loading
          ? Center(child: BilgiliLoading(lang: widget.lang))
          : error.isNotEmpty
          ? Center(child: Text("❌ $error"))
          : Stack(
              children: [
                // Blur arka plan: çekilen fotoğrafı tam ekranda flu gösteriyoruz
                if (kIsWeb)
                  Image.network(
                    widget.imageFile.path,
                    fit: BoxFit.cover,
                    height: double.infinity,
                    width: double.infinity,
                  )
                else
                  Image.file(
                    File(widget.imageFile.path),
                    fit: BoxFit.cover,
                    height: double.infinity,
                    width: double.infinity,
                  ),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(color: Colors.black.withOpacity(0.35)),
                ),

                // İçerik
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Üst görsel kartı
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        children: [
                          if (kIsWeb)
                            Image.network(
                              widget.imageFile.path,
                              height: 260,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          else
                            Image.file(
                              File(widget.imageFile.path),
                              height: 260,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (aiUsed)
                            Positioned(top: 12, right: 12, child: _aiChip()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Kimlik kartı
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _title("${_familyEmoji(family)}  Bilimsel Kimlik"),
                            _kv(
                              "🔬 ${t["scientificName"] ?? "Scientific Name"}",
                              sci,
                              bold: true,
                            ),
                            if (commons.isNotEmpty) ...[
                              _kv(
                                "🌸 ${t["commonNames"] ?? "Common Names"}",
                                "",
                              ),
                              Wrap(
                                spacing: 10,
                                runSpacing: 6,
                                children: commons.map(_pill).toList(),
                              ),
                            ],
                            _kv("📊 ${t["score"] ?? "Score"}", score),
                            _kv("🌳 ${t["family"] ?? "Family"}", family),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Açıklama kartı
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _title("📖 Açıklama"),
                            Text(
                              desc,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.35,
                              ),
                            ),
                            if (aiUsed) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.bolt,
                                    size: 16,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.lang == "tr"
                                        ? "Yapay zekâ ile zenginleştirildi"
                                        : "Enriched by AI",
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (aiError != null &&
                                aiError.trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                aiError,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Bakım önerileri
                    if (care.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _title("🪴 Bakım Önerileri"),
                              ...care.map(
                                (e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text("• $e"),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Fun fact
                    if (fun.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            "✨ $fun",
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Ek görseller
                    if (extraImages.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _title("🖼 Ek Görseller"),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: extraImages.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                itemBuilder: (_, i) => ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    extraImages[i],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Dış link butonları
                    Row(
                      children: [
                        _smartLinkButton(
                          title: "Wikipedia",
                          primary: wiki,
                          candidates: wikiC,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        _smartLinkButton(
                          title: "POWO",
                          primary: powo,
                          candidates: powoC,
                          color: Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ],
            ),
    );
  }
}

// ⏳ Şık yükleme animasyonu + bilgi döndürme
class BilgiliLoading extends StatefulWidget {
  final String lang;
  const BilgiliLoading({super.key, required this.lang});

  @override
  State<BilgiliLoading> createState() => _BilgiliLoadingState();
}

class _BilgiliLoadingState extends State<BilgiliLoading>
    with SingleTickerProviderStateMixin {
  static const _dotCount = 8;
  static const _dotSize = 12.0;
  static const _dotSpacing = 10.0;

  int _index = 0;

  static const List<String> _factsTr = [
    "🌱 Bitkiler fotosentez ile kendi besinlerini üretir.",
    "🍃 Bir ağacın yaprakları yılda milyonlarca litre suyu buharlaştırır.",
    "🌻 Ayçiçekleri gün boyunca güneşi takip eder.",
    "🌳 Dünya’da 3 trilyondan fazla ağaç olduğu tahmin edilir.",
    "🌵 Kaktüsler suyu gövdelerinde depolar ve dikenleri yapraktır.",
    "🌺 Arılar olmadan birçok bitki tohum oluşturamaz.",
    "🌲 Ağaçlar karbondioksiti emer, oksijen üretir.",
    "🍂 Sonbaharda yapraklar klorofil kaybeder ve renklenir.",
    "🍒 Kiraz ağaçları ilkbaharda kısa sürede çiçeklenir.",
    "🌴 Palmiyeler sıcak ve tropik iklimleri sever.",
    "🍄 Mantarlar bitki değil, ayrı bir canlı âlemidir.",
    "🌾 Buğday milyonlarca insanın ana besin kaynağıdır.",
    "🪴 Bazı ev bitkileri havadaki toksinleri azaltabilir.",
    "🌿 Nane ferahlatıcı aromasıyla bilinir.",
    "🌼 Papatyalar sabah açıp akşam kapanabilir.",
    "🌽 Mısır, dünyada en çok yetiştirilen tahıllardandır.",
    "🍎 Elma ağaçları uygun bakımda 100 yıl yaşayabilir.",
    "🌹 Güllerin binlerce kültivarı vardır.",
    "🌍 Amazon ormanları gezegenin akciğerleri sayılır.",
    "🧱 Bitki kökleri toprağı erozyondan korur.",
  ];

  static const List<String> _factsEn = [
    "🌱 Plants make their own food through photosynthesis.",
    "🍃 A tree’s leaves can evaporate millions of liters of water per year.",
    "🌻 Sunflowers track the sun across the sky.",
    "🌳 Earth is estimated to have over three trillion trees.",
    "🌵 A cactus spine is actually a leaf.",
    "🌺 Without bees, many plants couldn’t set seed.",
    "🌲 Trees absorb carbon dioxide and release oxygen.",
    "🍂 In autumn, leaves lose chlorophyll and change color.",
    "🍒 Cherry trees bloom quickly in spring.",
    "🌴 Palms prefer warm, tropical climates.",
    "🍄 Fungi are not plants; they’re a separate kingdom.",
    "🌾 Wheat is a staple food for billions.",
    "🪴 Some houseplants can reduce indoor toxins.",
    "🌿 The mint family is rich in aromatic oils.",
    "🌼 Daisies can open in the morning and close at night.",
    "🌽 Maize is among the most cultivated cereals.",
    "🍎 Apple trees can live a century with good care.",
    "🌹 Roses have thousands of cultivars.",
    "🌍 The Amazon is often called the lungs of the planet.",
    "🧱 Plant roots help protect soil from erosion.",
  ];

  List<String> get _facts =>
      widget.lang.toLowerCase().startsWith('tr') ? _factsTr : _factsEn;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void initState() {
    super.initState();
    // Her 6 saniyede bir bilgi değiştir
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 6));
      if (!mounted) return false;
      setState(() => _index = (_index + 1) % _facts.length);
      return true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _scaleFor(double t, int i) {
    final phase = (t + i / _dotCount) % 1.0;
    return 0.5 + 0.5 * (1 - (2 * (phase - 0.5)).abs());
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Dairesel noktalar animasyonu
        AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            final t = _controller.value;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_dotCount, (i) {
                final s = _scaleFor(t, i);
                return Container(
                  width: _dotSize + 6,
                  height: _dotSize + 6,
                  margin: const EdgeInsets.symmetric(
                    horizontal: _dotSpacing / 2,
                  ),
                  alignment: Alignment.center,
                  child: Transform.scale(
                    scale: s,
                    child: Container(
                      width: _dotSize,
                      height: _dotSize,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.35 + 0.65 * s),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
        const SizedBox(height: 20),
        // Bilgi metni
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            "🌱 ${_facts[_index]}",
            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
