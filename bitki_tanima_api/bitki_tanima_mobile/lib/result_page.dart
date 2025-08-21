// lib/result_page.dart
import 'dart:convert';
import 'dart:io' show File; // Sadece File sınıfı için import
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // XFile için gerekli
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Web kontrolü için
import 'src/auth/auth_service.dart';
import 'translations.dart';

class ResultPage extends StatefulWidget {
  final XFile imageFile; // String imagePath yerine XFile nesnesi
  final String lang;
  const ResultPage({super.key, required this.imageFile, required this.lang});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  bool loading = true;
  String error = "";
  Map<String, dynamic>? data;
  List<String> extraImages = [];

  @override
  void initState() {
    super.initState();
    _sendImage();
  }

  Future<void> _sendImage() async {
    final apiUrl = Uri.parse(
      "http://192.168.1.37:8000/predict",
    ); // kendi IP adresinizi kontrol edin
    try {
      final req = http.MultipartRequest('POST', apiUrl);
      req.fields['organ'] = 'leaf';
      req.fields['lang'] = widget.lang;

      if (kIsWeb) {
        // Web için: Dosyayı bayt olarak okuyup gönderiyoruz
        final bytes = await widget.imageFile.readAsBytes();
        req.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: widget.imageFile.name,
          ),
        );
      } else {
        // Mobil için: Dosya yolundan gönderiyoruz
        req.files.add(
          await http.MultipartFile.fromPath('file', widget.imageFile.path),
        );
      }

      final resp = await req.send();
      final body = await resp.stream.bytesToString();
      if (resp.statusCode != 200) {
        throw Exception("API ${resp.statusCode}: $body");
      }

      final jsonResp = jsonDecode(body) as Map<String, dynamic>;
      setState(() {
        data = jsonResp;
        extraImages =
            (jsonResp["extra_images"] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  String _derivePlantId() {
    final id = (data?['plant_id'] ?? data?['id'] ?? '').toString().trim();
    if (id.isNotEmpty) return id;
    final sci = (data?['scientific_name'] ?? '').toString();
    return _slugify(sci);
  }

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

    final uid = AuthServisi.instance.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(t["appTitle"]!),
        actions: [
          if (!loading && error.isEmpty && data != null && uid != null)
            _FavoriteButton(
              uid: uid,
              plantId: _derivePlantId(),
              isTr: widget.lang == 'tr',
            ),
        ],
      ),
      body: loading
          ? Center(child: BilgiliLoading(lang: widget.lang))
          : error.isNotEmpty
          ? Center(child: Text("❌ $error"))
          : Stack(
              children: [
                if (kIsWeb)
                  Image.network(
                    widget.imageFile.path, // Web'de Image.network
                    fit: BoxFit.cover,
                    height: double.infinity,
                    width: double.infinity,
                  )
                else
                  Image.file(
                    File(widget.imageFile.path), // Mobil'de Image.file
                    fit: BoxFit.cover,
                    height: double.infinity,
                    width: double.infinity,
                  ),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(color: Colors.black.withOpacity(0.35)),
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        children: [
                          if (kIsWeb)
                            Image.network(
                              widget.imageFile.path, // Web'de Image.network
                              height: 260,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          else
                            Image.file(
                              File(
                                widget.imageFile.path,
                              ), // Mobil'de Image.file
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

/// AppBar'daki favori kalp butonu
class _FavoriteButton extends StatelessWidget {
  final String uid;
  final String plantId;
  final bool isTr;
  const _FavoriteButton({
    required this.uid,
    required this.plantId,
    required this.isTr,
  });

  @override
  Widget build(BuildContext context) {
    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(plantId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: favRef.snapshots(),
      builder: (context, snap) {
        final isFav = snap.data?.exists == true;
        return IconButton(
          tooltip: isFav
              ? (isTr ? 'Favorilerden çıkar' : 'Remove from Favorites')
              : (isTr ? 'Favorilere ekle' : 'Add to Favorites'),
          icon: Icon(isFav ? Icons.favorite : Icons.favorite_outline),
          onPressed: () async {
            if (isFav) {
              await favRef.delete();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isTr ? 'Favorilerden çıkarıldı' : 'Removed from favorites',
                  ),
                ),
              );
            } else {
              await favRef.set({
                'savedAt': FieldValue.serverTimestamp(),
                'notesCount': 0,
              }, SetOptions(merge: true));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isTr ? 'Favorilere eklendi' : 'Added to favorites',
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}

/// Yükleme ekranı: 20 bilgi, 6 sn’de bir değişir + sırayla büyüyüp küçülen noktalar
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
