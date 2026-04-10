import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'ai_service.dart';

class MiniMaxService implements AIService {
  final String _apiKey;
  final String _baseUrl = 'https://api.minimax.chat/v1';

  MiniMaxService(this._apiKey);

  @override
  Future<String> chat(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/text/chatcompletion_v2'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'MiniMax-M2.7',
          'messages': [
            {'role': 'user', 'content': message}
          ],
        }),
      );

      final data = jsonDecode(response.body);
      print('MiniMax 响应: $data');

      if (response.statusCode == 200) {
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final content = choices[0]['message']['content'];
          return content ?? '抱歉，我没有收到回复';
        }
        final baseResp = data['base_resp'];
        if (baseResp != null) {
          return 'API错误: ${baseResp['status_code']} - ${baseResp['status_msg']}';
        }
        return 'API返回格式未知: $data';
      } else {
        return 'API错误: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      return '网络错误: $e';
    }
  }

  @override
  Future<String> chatImage(String message, String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('$_baseUrl/v1/moderation'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'MiniMax-M2.7',
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': message},
                {'type': 'image_url', 'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}}
              ]
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          return choices[0]['message']['content'] ?? '收到图片了';
        }
        return '收到图片 (无choices)';
      } else {
        return '收到图片 (API: ${response.statusCode})';
      }
    } catch (e) {
      return '收到图片 (错误: $e)';
    }
  }

  @override
  Future<String> chatVoice(String message, String audioPath) async {
    return '收到语音消息: $message';
  }

  @override
  Future<String> summarizeForTitle(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/text/chatcompletion_v2'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'MiniMax-M2.7',
          'messages': [
            {'role': 'user', 'content': '请用5-10个字简洁概括用户输入的意图，作为聊天标题。例如："编程问题求助"、"旅游规划咨询"、"美食推荐"。\n\n用户输入：$message\n\n直接输出标题，不要任何解释。'}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          String title = choices[0]['message']['content'] ?? '新聊天';
          // Clean up the title
          title = title.trim().replaceAll('"', '').replaceAll('\n', '');
          if (title.length > 20) {
            title = title.substring(0, 20);
          }
          return title;
        }
        return '新聊天';
      } else {
        return '新聊天';
      }
    } catch (e) {
      return '新聊天';
    }
  }

  @override
  Future<String> summarizeImageForTitle(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('$_baseUrl/text/chatcompletion_v2'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'MiniMax-M2.7',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
                },
                {
                  'type': 'text',
                  'text': '请描述这张图片的主题或用途，用5-10个字概括，作为聊天标题。例如："风景照片"、"产品截图"、"表情包"。直接输出标题，不要任何解释。'
                }
              ]
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          String title = choices[0]['message']['content'] ?? '图片';
          title = title.trim().replaceAll('"', '').replaceAll('\n', '');
          if (title.length > 20) {
            title = title.substring(0, 20);
          }
          return title;
        }
        return '图片';
      } else {
        return '图片';
      }
    } catch (e) {
      return '图片';
    }
  }

  @override
  Future<String> textToSpeech(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/t2a_v2'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'speech-2.8-hd',
          'text': text,
          'stream': false,
          'voice_setting': {
            'voice_id': 'female-tianmei',
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('TTS response body: ${response.body}');
        final data = jsonDecode(response.body);
        // MiniMax TTS returns base64 audio in data.audio
        if (data['data'] != null && data['data']['audio'] != null) {
          return data['data']['audio'] ?? '';
        }
        return '';
      } else {
        debugPrint('TTS API错误: ${response.statusCode} - ${response.body}');
        return '';
      }
    } catch (e) {
      debugPrint('TTS请求异常: $e');
      return '';
    }
  }

  @override
  Future<String> generateImage(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/image_generation'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'image-01',
          'prompt': prompt,
          'aspect_ratio': '1:1',
          'response_format': 'url',
          'n': 1,
          'prompt_optimizer': true,
        }),
      );

      debugPrint('Image generation response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageUrls = data['data']?['image_urls'] as List?;
        String? imageUrl;
        if (imageUrls != null && imageUrls.isNotEmpty) {
          imageUrl = imageUrls[0] as String?;
        }

        if (imageUrl != null && imageUrl.isNotEmpty) {
          // Return the URL directly
          debugPrint('Generated image URL: $imageUrl');
          return imageUrl;
        }
        return '';
      } else {
        debugPrint('Image API错误: ${response.statusCode} - ${response.body}');
        return '';
      }
    } catch (e) {
      debugPrint('图片生成异常: $e');
      return '';
    }
  }
}
