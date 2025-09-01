import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Yapay zeka (OpenAI) servisleri için bir sınıf.
/// Bu servis, verilen bitki bilgilerini daha zengin ve anlaşılır hale getirmek için kullanılır.
class AIService {
  // OPENAI_API_KEY'in .env dosyasından okunup okunamadığını kontrol eder.
  // Bu kontrol, servisin kullanıma hazır olup olmadığını belirler.
  bool get isEnabled {
    // .env dosyası henüz yüklenmediyse false döner.
    if (!dotenv.isInitialized) return false;
    // API anahtarını .env dosyasından okur.
    final key = dotenv.env['OPENAI_API_KEY'];
    // Anahtar null değilse ve boşluklardan arındırılmış hali boş değilse true döner.
    return key != null && key.trim().isNotEmpty;
  }

  /// Verilen bitki bilgilerini yapay zeka ile zenginleştiren asenkron metot.
  /// Yapay zekadan daha iyi bir açıklama, bakım bilgileri ve ilginç bir bilgi ister.
  Future<Map<String, dynamic>?> enrich({
    required String lang, // Dil kodu (örn: 'tr', 'en').
    required String scientificName, // Bilimsel adı.
    required List<dynamic>? commonNames, // Yaygın adları.
    required String description, // Mevcut açıklama.
    String? family, // Aile bilgisi.
    String? habitat, // Yaşam alanı bilgisi.
    String? uses, // Kullanım alanları bilgisi.
  }) async {
    // Servis etkin değilse işlemi yapmadan çıkar.
    if (!isEnabled) return null;

    // API anahtarını tekrar kontrol eder, çünkü isEnabled kontrolü sırasında boşalmış olabilir.
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.trim().isEmpty) return null;

    try {
      // Yapay zekaya verilecek "sistem mesajını" dile göre hazırlar.
      // Bu, yapay zekanın hangi rolde konuşacağını belirler.
      final sys = (lang == 'tr')
          ? 'Sen bir botanik asistanısın. Kısa ve anlaşılır yaz.'
          : 'You are a botany assistant. Write short and clear.';

      // Yapay zekaya verilecek "kullanıcı mesajını" hazırlar.
      // Bu mesaj, yapay zekanın işlem yapması için gereken tüm bitki bilgilerini içerir.
      final user =
          'Scientific: $scientificName\n'
          'Common: ${commonNames?.join(", ") ?? "-"}\n'
          'Family: ${family ?? "-"}\n'
          'Habitat: ${habitat ?? "-"}\n'
          'Uses: ${uses ?? "-"}\n'
          'Desc: $description\n'
          'Return JSON with keys: better_description, care (array of 3), fun_fact. '
          'Language: ${lang == "tr" ? "Turkish" : "English"}';

      // OpenAI API'sinin sohbet tamamlama (chat completions) uç noktasını ayarlar.
      final uri = Uri.parse('https://api.openai.com/v1/chat/completions');

      // HTTP POST isteği gönderir.
      final res = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': 'gpt-4o-mini', // Kullanılacak yapay zeka modeli.
              'temperature':
                  0.7, // Yaratıcılık/rastgelelik seviyesi (0.0 - 2.0).
              'messages': [
                {'role': 'system', 'content': sys}, // Sistem mesajı.
                {'role': 'user', 'content': user}, // Kullanıcı mesajı.
              ],
              // Yanıtın JSON formatında gelmesini istiyoruz.
              'response_format': {'type': 'json_object'},
            }),
          )
          .timeout(
            const Duration(seconds: 25),
          ); // İstek için 25 saniye zaman aşımı belirler.

      // HTTP yanıt kodunu kontrol eder. 200 (OK) değilse hata mesajını yazdırıp null döner.
      if (res.statusCode != 200) {
        debugPrint('AI error: ${res.statusCode} ${res.body}');
        return null;
      }

      // Gelen yanıtı JSON olarak ayrıştırır.
      final root = jsonDecode(res.body) as Map<String, dynamic>;
      // Yapay zekanın gönderdiği asıl içeriğe erişir.
      final content =
          root['choices']?[0]?['message']?['content']?.toString() ?? '{}';
      // İçeriği tekrar JSON olarak ayrıştırır.
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      return parsed; // Ayrıştırılmış veriyi döndürür.
    } catch (e) {
      // Herhangi bir hata oluşursa (ağ hatası, zaman aşımı vb.), hata mesajını yazdırıp null döner.
      debugPrint('AI enrich exception: $e');
      return null;
    }
  }
}
