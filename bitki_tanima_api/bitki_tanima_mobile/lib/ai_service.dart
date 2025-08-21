// lib/ai_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AIService {
  // .env okunmadan çalışmasın
  bool get isEnabled {
    if (!dotenv.isInitialized) return false;
    final key = dotenv.env['OPENAI_API_KEY'];
    return key != null && key.trim().isNotEmpty;
  }

  Future<Map<String, dynamic>?> enrich({
    required String lang,
    required String scientificName,
    required List<dynamic>? commonNames,
    required String description,
    String? family,
    String? habitat,
    String? uses,
  }) async {
    if (!isEnabled) return null;

    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.trim().isEmpty) return null;

    try {
      final sys = (lang == 'tr')
          ? 'Sen bir botanik asistanısın. Kısa ve anlaşılır yaz.'
          : 'You are a botany assistant. Write short and clear.';

      final user =
          'Scientific: $scientificName\n'
          'Common: ${commonNames?.join(", ") ?? "-"}\n'
          'Family: ${family ?? "-"}\n'
          'Habitat: ${habitat ?? "-"}\n'
          'Uses: ${uses ?? "-"}\n'
          'Desc: $description\n'
          'Return JSON with keys: better_description, care (array of 3), fun_fact. '
          'Language: ${lang == "tr" ? "Turkish" : "English"}';

      final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
      final res = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': 'gpt-4o-mini',
              'temperature': 0.7,
              'messages': [
                {'role': 'system', 'content': sys},
                {'role': 'user', 'content': user},
              ],
              'response_format': {'type': 'json_object'},
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (res.statusCode != 200) {
        debugPrint('AI error: ${res.statusCode} ${res.body}');
        return null;
      }

      final root = jsonDecode(res.body) as Map<String, dynamic>;
      final content =
          root['choices']?[0]?['message']?['content']?.toString() ?? '{}';
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      return parsed;
    } catch (e) {
      debugPrint('AI enrich exception: $e');
      return null;
    }
  }
}
