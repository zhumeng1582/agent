import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'ai_service.dart';

class MiniMaxService implements AIService {
  final String _apiKey;
  final String _baseUrl = 'https://api.minimaxi.com/v1';

  MiniMaxService(this._apiKey);

  @override
  Future<ChatResponse> chat(List<Map<String, String>> messages) async {
    try {
      final requestBody = {
        'model': 'MiniMax-M2.7',
        'messages': messages,
      };
      debugPrint('MiniMax 请求: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/text/chatcompletion_v2'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);
      debugPrint('MiniMax 响应: $data');

      if (response.statusCode == 200) {
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'];
          final content = message['content'] ?? '抱歉，我没有收到回复';
          final reasoning = message['reasoning_content'] as String?;
          return ChatResponse(content: content, reasoning: reasoning);
        }
        final baseResp = data['base_resp'];
        if (baseResp != null) {
          return ChatResponse(content: 'API错误: ${baseResp['status_code']} - ${baseResp['status_msg']}');
        }
        return ChatResponse(content: 'API返回格式未知: $data');
      } else {
        return ChatResponse(content: 'API错误: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      return ChatResponse(content: '网络错误: $e');
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

  /// 发起文生视频任务，返回 task_id
  Future<String> createVideoTask(String prompt, {int duration = 6, String resolution = '768P'}) async {
    try {
      // 视频API使用 minimaxi.com 而非 minimax.chat
      final videoUrl = 'https://api.minimaxi.com/v1/video_generation';
      final response = await http.post(
        Uri.parse(videoUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'prompt': prompt,
          'model': 'MiniMax-Hailuo-2.3',
          'duration': duration,
          'resolution': resolution,
        }),
      );

      debugPrint('Video task creation response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final taskId = data['task_id'] as String?;
        if (taskId != null && taskId.isNotEmpty) {
          debugPrint('Video task created: $taskId');
          return taskId;
        }
        // 检查API错误信息
        final baseResp = data['base_resp'];
        if (baseResp != null) {
          throw Exception('API错误: ${baseResp['status_code']} - ${baseResp['status_msg']}');
        }
        throw Exception('No task_id in response');
      } else {
        throw Exception('Video API错误: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('视频任务创建异常: $e');
      rethrow;
    }
  }

  /// 发起图生视频任务，返回 task_id
  Future<String> createImageToVideoTask(String prompt, String imageUrl, {int duration = 6, String resolution = '768P'}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/video_generation'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'prompt': prompt,
          'first_frame_image': imageUrl,
          'model': 'MiniMax-Hailuo-2.3',
          'duration': duration,
          'resolution': resolution,
        }),
      );

      debugPrint('Image to video task creation response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final taskId = data['task_id'] as String?;
        if (taskId != null) {
          debugPrint('Image to video task created: $taskId');
          return taskId;
        }
        throw Exception('No task_id in response');
      } else {
        throw Exception('Video API错误: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('图生视频任务创建异常: $e');
      rethrow;
    }
  }

  /// 查询视频任务状态，返回 video_url 或状态
  Future<Map<String, dynamic>> queryVideoTaskStatus(String taskId) async {
    try {
      // 视频API使用 minimaxi.com 而非 minimax.chat
      final queryUrl = 'https://api.minimaxi.com/v1/query/video_generation?task_id=$taskId';
      final response = await http.get(
        Uri.parse(queryUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
        },
      );

      debugPrint('Video task status response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['status'] ?? 'Unknown',
          'video_url': data['video_url'] ?? data['file_id'] ?? '',
          'error': data['error_message'] ?? (data['base_resp'] != null ? data['base_resp']['status_msg'] : ''),
        };
      } else {
        return {
          'status': 'Fail',
          'error': 'API错误: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('视频任务查询异常: $e');
      return {
        'status': 'Fail',
        'error': e.toString(),
      };
    }
  }

  /// 获取视频文件并保存到本地，返回本地文件路径
  Future<String> downloadVideo(String videoUrl, String savePath) async {
    try {
      final response = await http.get(Uri.parse(videoUrl));
      debugPrint('Video download URL: $videoUrl');
      debugPrint('Video download response status: ${response.statusCode}');
      debugPrint('Video download content length: ${response.contentLength}');
      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        final fileSize = await file.length();
        debugPrint('Video saved to: $savePath, size: $fileSize bytes');
        if (fileSize < 1000) {
          throw Exception('下载的视频文件过小，可能下载失败');
        }
        return savePath;
      } else {
        throw Exception('下载视频失败: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('视频下载异常: $e');
      rethrow;
    }
  }

  /// 根据 file_id 获取视频下载链接
  Future<String?> getVideoDownloadUrl(String fileId) async {
    try {
      final url = 'https://api.minimaxi.com/v1/files/retrieve?file_id=$fileId';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
        },
      );

      debugPrint('File retrieve response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['file']?['download_url'] as String?;
      } else {
        debugPrint('获取下载链接失败: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('获取下载链接异常: $e');
      return null;
    }
  }

  /// 语音识别 - 将音频文件转写为文字
  Future<String> speechToText(String audioPath) async {
    try {
      final file = File(audioPath);
      final bytes = await file.readAsBytes();
      final base64Audio = base64Encode(bytes);

      debugPrint('开始语音识别，文件大小: ${bytes.length} bytes');

      // 尝试不同的API端点
      final endpoints = [
        '$_baseUrl/speech/s2t',
        '$_baseUrl/v1/speech/s2t',
        '$_baseUrl/asr',
        '$_baseUrl/speech_to_text',
      ];

      String? lastError;
      for (final endpoint in endpoints) {
        try {
          debugPrint('尝试端点: $endpoint');

          final response = await http.post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': 'speech-01-hd',
              'audio_file': base64Audio,
              'language_boost': 'zh',
              'response_format': 'json',
            }),
          );

          debugPrint('Speech to text response status: ${response.statusCode}');
          debugPrint('Speech to text response body: ${response.body}');

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            String? text;
            if (data['data'] != null && data['data']['text'] != null) {
              text = data['data']['text'] as String;
            } else if (data['text'] != null) {
              text = data['text'] as String;
            } else if (data['data'] != null && data['data']['text'] is List) {
              final textList = data['data']['text'] as List;
              text = textList.join('');
            }

            if (text != null && text.isNotEmpty) {
              return text;
            }
          } else if (response.statusCode == 404) {
            lastError = '404';
            continue; // 尝试下一个端点
          } else {
            lastError = '${response.statusCode}: ${response.body}';
            break;
          }
        } catch (e) {
          lastError = e.toString();
          continue;
        }
      }

      throw Exception('语音识别API错误: $lastError');
    } catch (e) {
      debugPrint('语音识别异常: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> generateFollowUpTopics(String userMessage, String conversationContext) async {
    try {
      final contextPart = conversationContext.isNotEmpty
          ? '对话上下文：\n$conversationContext\n\n'
          : '';

      final response = await http.post(
        Uri.parse('$_baseUrl/text/chatcompletion_v2'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'MiniMax-M2.7',
          'messages': [
            {'role': 'user', 'content': '$contextPart基于用户最新问题和对话上下文，推测用户可能想追问的2-3个相关话题。每个话题用一句话概括，简洁明了。直接输出话题列表，每行一个，不要编号，不要解释。\n\n用户最新问题：$userMessage'}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          String content = choices[0]['message']['content'] ?? '';
          // Parse lines and filter empty ones
          final topics = content
              .split('\n')
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty)
              .take(3)
              .toList();
          return topics;
        }
        return [];
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('生成追问话题失败: $e');
      return [];
    }
  }
}
