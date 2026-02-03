import 'dart:convert';

import 'package:http/http.dart' as http;

class AiImageTaskStatus {
  const AiImageTaskStatus({required this.state, this.imageUrl});

  final String state;
  final String? imageUrl;
}

class AiImageApiService {
  AiImageApiService._();
  static final AiImageApiService shared = AiImageApiService._();

  static const String _apiKey = '4be3334cd55d4d81edc41c865e9ff192';
  static const String _createTaskUrl = 'https://api.kie.ai/api/v1/jobs/createTask';
  static const String _recordInfoUrl = 'https://api.kie.ai/api/v1/jobs/recordInfo';
  static const String _uploadImageUrl = 'https://kieai.redpandaai.co/api/file-base64-upload';

  Future<String> createTask({
    required String prompt,
    required String style,
    required String size,
    String outputFormat = 'png',
    List<String>? imageInput,
  }) async {
    final input = <String, dynamic>{
      'prompt': prompt,
      'output_format': outputFormat,
      'aspect_ratio': size,
      'resolution': '1K',
      'image_input': imageInput ?? [],
    };
    final body = <String, dynamic>{
      'model': 'nano-banana-pro',
      'callBackUrl': '',
      'input': input,
    };
    final response = await http.post(
      Uri.parse(_createTaskUrl),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw Exception('Create task failed: ${response.statusCode} ${response.body}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>?;
    final taskId = data?['taskId'] as String?;
    if (taskId == null || taskId.isEmpty) {
      throw Exception('No taskId in response: $json');
    }
    return taskId;
  }

  Future<AiImageTaskStatus> queryTaskStatus(String taskId) async {
    final url = Uri.parse('$_recordInfoUrl?taskId=$taskId');
    final response = await http.get(
      url,
      headers: <String, String>{
        'Authorization': 'Bearer $_apiKey',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Query task failed: ${response.statusCode} ${response.body}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>?;
    final state = data?['state'] as String? ?? '';
    String? imageUrl;
    if (state == 'success') {
      final resultJsonStr = data?['resultJson'] as String?;
      if (resultJsonStr != null && resultJsonStr.isNotEmpty) {
        try {
          final resultJson = jsonDecode(resultJsonStr) as Map<String, dynamic>;
          final urls = resultJson['resultUrls'] as List<dynamic>?;
          if (urls != null && urls.isNotEmpty) {
            imageUrl = urls.first as String?;
          }
        } catch (_) {}
      }
    }
    return AiImageTaskStatus(state: state, imageUrl: imageUrl);
  }

  Future<String> uploadImage(List<int> jpegBytes) async {
    final base64Str = base64Encode(jpegBytes);
    final dataUrl = 'data:image/jpeg;base64,$base64Str';
    final body = <String, dynamic>{
      'base64Data': dataUrl,
      'uploadPath': 'images',
      'fileName': 'zeeno-image-${DateTime.now().millisecondsSinceEpoch}.jpg',
    };
    final response = await http.post(
      Uri.parse(_uploadImageUrl),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw Exception('Upload failed: ${response.statusCode} ${response.body}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      final url = data['downloadUrl'] as String? ?? data['url'] as String?;
      if (url != null) return url;
    }
    if (data is String) return data;
    final url = json['url'] as String?;
    if (url != null) return url;
    throw Exception('No URL in response: $json');
  }
}
