import 'dart:convert';

import 'package:http/http.dart' as http;

const String _baseUrl = 'https://open.bigmodel.cn/api/paas/v4/chat/completions';
const String _apiKey = '6c802014b9f24b29b28d87fca4ea6f2d.XWO5yY1rQwogaOr8';
const String _model = 'glm-4-flash';

const String _systemPrompt =
    'You are a music guide. Help users with anything about music: songwriting, production, genres, instruments, or recommendations. Always reply in English.';

class ZhipuChatService {
  ZhipuChatService._();
  static final ZhipuChatService shared = ZhipuChatService._();

  Future<String?> sendChat(List<Map<String, String>> messages) async {
    final list = <Map<String, dynamic>>[
      {'role': 'system', 'content': _systemPrompt},
      ...messages.map((m) => {'role': m['role'], 'content': m['content'] ?? ''}),
    ];
    final body = {
      'model': _model,
      'messages': list,
      'temperature': 0.7,
      'max_tokens': 1024,
    };
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode != 200) {
        return null;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) return null;
      final first = choices.first as Map<String, dynamic>;
      final message = first['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;
      return content?.trim();
    } catch (_) {
      return null;
    }
  }
}
