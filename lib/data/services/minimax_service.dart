import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
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
          'model': 'abab5.5s-chat',
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
          'model': 'abab5.5s-chat',
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
          'model': 'abab5.5s-chat',
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
          'model': 'abab5.5s-chat',
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
}
