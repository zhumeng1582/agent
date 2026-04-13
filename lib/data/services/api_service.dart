import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String? _baseUrl;
  static String? _accessToken;
  static String? _refreshToken;
  static SharedPreferences? _prefs;
  static bool _isInitialized = false;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  static Future<void> configure({required String baseUrl}) async {
    _baseUrl = baseUrl;
    _prefs = await SharedPreferences.getInstance();
    await _loadTokens();
    _isInitialized = true;
  }

  static bool get isInitialized => _isInitialized;

  static Future<void> _loadTokens() async {
    if (_prefs == null) return;
    _accessToken = _prefs!.getString(_accessTokenKey);
    _refreshToken = _prefs!.getString(_refreshTokenKey);
    debugPrint('[ApiService] Tokens loaded: access=${_accessToken != null}, refresh=${_refreshToken != null}');
  }

  static Future<void> _saveTokens() async {
    if (_prefs == null) return;
    if (_accessToken != null) {
      await _prefs!.setString(_accessTokenKey, _accessToken!);
    } else {
      await _prefs!.remove(_accessTokenKey);
    }
    if (_refreshToken != null) {
      await _prefs!.setString(_refreshTokenKey, _refreshToken!);
    } else {
      await _prefs!.remove(_refreshTokenKey);
    }
    debugPrint('[ApiService] Tokens saved');
  }

  static void setTokens({required String accessToken, required String refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _saveTokens();
  }

  static Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    if (_prefs != null) {
      await _prefs!.remove(_accessTokenKey);
      await _prefs!.remove(_refreshTokenKey);
    }
    debugPrint('[ApiService] Tokens cleared');
  }

  static bool get isAuthenticated => _accessToken != null;

  static String? get accessToken => _accessToken;
  static String? get refreshToken => _refreshToken;

  static Future<Map<String, String>> get _headers async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  static Future<ApiResponse> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    int timeoutSeconds = 30,
  }) async {
    try {
      final headers = await _headers;
      final uri = Uri.parse('$_baseUrl$endpoint');

      http.Response response;
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(Duration(seconds: timeoutSeconds));
          break;
        case 'POST':
          response = await http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null).timeout(Duration(seconds: timeoutSeconds));
          break;
        case 'PATCH':
          response = await http.patch(uri, headers: headers, body: body != null ? jsonEncode(body) : null).timeout(Duration(seconds: timeoutSeconds));
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers).timeout(Duration(seconds: timeoutSeconds));
          break;
        default:
          return ApiResponse(success: false, error: 'Unknown method');
      }
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  static Future<ApiResponse> _handleResponse(http.Response response) async {
    // If 401, try to refresh token
    if (response.statusCode == 401 && _refreshToken != null) {
      debugPrint('[ApiService] Got 401, trying to refresh token...');
      final refreshed = await _refreshTokenIfNeeded();
      if (refreshed) {
        // Retry the request (caller should retry)
        return ApiResponse(success: false, error: 'Token refreshed, please retry', statusCode: 401);
      } else {
        // Refresh failed, clear tokens
        await clearTokens();
        return ApiResponse(success: false, error: 'Session expired', statusCode: 401);
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return ApiResponse(success: true, data: {});
      }
      try {
        final data = jsonDecode(response.body);
        return ApiResponse(success: true, data: data);
      } catch (e) {
        return ApiResponse(success: true, data: {'raw': response.body});
      }
    } else {
      String error = 'Request failed';
      try {
        final data = jsonDecode(response.body);
        error = data['detail'] ?? error;
      } catch (_) {}
      return ApiResponse(success: false, error: error, statusCode: response.statusCode);
    }
  }

  static Future<bool> _refreshTokenIfNeeded() async {
    if (_refreshToken == null || _baseUrl == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': _refreshToken}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access_token'] as String?;
        final newRefreshToken = data['refresh_token'] as String?;

        if (newAccessToken != null && newRefreshToken != null) {
          setTokens(accessToken: newAccessToken, refreshToken: newRefreshToken);
          debugPrint('[ApiService] Token refreshed successfully');
          return true;
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Token refresh failed: $e');
    }
    return false;
  }

  static Future<ApiResponse> get(String endpoint) async {
    return _request('GET', endpoint);
  }

  static Future<ApiResponse> post(String endpoint, {Map<String, dynamic>? body, int timeoutSeconds = 30}) async {
    return _request('POST', endpoint, body: body, timeoutSeconds: timeoutSeconds);
  }

  static Future<ApiResponse> patch(String endpoint, {Map<String, dynamic>? body}) async {
    return _request('PATCH', endpoint, body: body);
  }

  static Future<ApiResponse> delete(String endpoint) async {
    return _request('DELETE', endpoint);
  }

  // Auth endpoints
  static Future<ApiResponse> register(String email, String password, {String? nickname}) async {
    return post('/api/v1/auth/register', body: {
      'email': email,
      'password': password,
      if (nickname != null) 'nickname': nickname,
    });
  }

  static Future<ApiResponse> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/auth/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': email,
          'password': password,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return ApiResponse(success: true, data: data);
      } else {
        return ApiResponse(success: false, error: 'Login failed', statusCode: response.statusCode);
      }
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  static Future<ApiResponse> refreshAccessToken() async {
    if (_refreshToken == null) {
      return ApiResponse(success: false, error: 'No refresh token');
    }
    final success = await _refreshTokenIfNeeded();
    return ApiResponse(success: success);
  }

  static Future<ApiResponse> logout() async {
    if (_refreshToken == null) {
      await clearTokens();
      return ApiResponse(success: true);
    }
    return post('/api/v1/auth/logout', body: {
      'refresh_token': _refreshToken,
    });
  }

  // Phone Auth
  static Future<ApiResponse> phoneLogin(String phone, String password) async {
    return post('/api/v1/auth/phone/login', body: {
      'phone': phone,
      'password': password,
    });
  }

  static Future<ApiResponse> sendSmsCode(String phone) async {
    return post('/api/v1/auth/phone/send', body: {
      'phone': phone,
    });
  }

  static Future<ApiResponse> verifySmsCode(String phone, String code) async {
    return post('/api/v1/auth/phone/verify', body: {
      'phone': phone,
      'code': code,
    });
  }

  static Future<ApiResponse> phoneRegister(String phone, String password, {String? nickname}) async {
    return post('/api/v1/auth/phone/register', body: {
      'phone': phone,
      'password': password,
      if (nickname != null) 'nickname': nickname,
    });
  }

  static Future<ApiResponse> wechatLogin(String code) async {
    return post('/api/v1/auth/wechat/login', body: {
      'code': code,
    });
  }

  static Future<ApiResponse> getMe() async {
    return get('/api/v1/auth/me');
  }

  // Conversation endpoints
  static Future<ApiResponse> getConversations() async {
    return get('/api/v1/conversations');
  }

  static Future<ApiResponse> createConversation({String title = '新聊天'}) async {
    return post('/api/v1/conversations', body: {'title': title});
  }

  static Future<ApiResponse> getConversation(String id) async {
    return get('/api/v1/conversations/$id');
  }

  static Future<ApiResponse> updateConversation(String id, {String? title, bool? isPinned}) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (isPinned != null) body['is_pinned'] = isPinned;
    return patch('/api/v1/conversations/$id', body: body);
  }

  static Future<ApiResponse> deleteConversation(String id) async {
    return delete('/api/v1/conversations/$id');
  }

  // Message endpoints
  static Future<ApiResponse> getMessages(String conversationId) async {
    return get('/api/v1/conversations/$conversationId/messages');
  }

  static Future<ApiResponse> sendMessage(String conversationId, Map<String, dynamic> message) async {
    return post('/api/v1/conversations/$conversationId/messages', body: message);
  }

  static Future<ApiResponse> toggleFavorite(String conversationId, String messageId) async {
    return patch('/api/v1/conversations/$conversationId/messages/$messageId/favorite');
  }

  static Future<ApiResponse> deleteMessage(String conversationId, String messageId) async {
    return delete('/api/v1/conversations/$conversationId/messages/$messageId');
  }

  // AI Chat endpoint
  static Future<ApiResponse> chat(Map<String, dynamic> request) async {
    return post('/api/v1/ai/chat', body: request);
  }

  static Future<ApiResponse> chatInConversation(String conversationId, Map<String, dynamic> request) async {
    return post('/api/v1/ai/chat/$conversationId', body: request);
  }

  // AI Translation
  static Future<ApiResponse> translate(String text, {String targetLang = 'Chinese'}) async {
    return post('/api/v1/ai/translate', body: {
      'text': text,
      'target_lang': targetLang,
    });
  }

  // AI TTS (returns bytes)
  static Future<ApiResponse> textToSpeech(String text, {String? voiceId}) async {
    try {
      final headers = await _headers;
      final uri = Uri.parse('$_baseUrl/api/v1/ai/tts');
      final response = await http.post(
        uri,
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          if (voiceId != null) 'voice_id': voiceId,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(success: true, data: {'bytes': response.bodyBytes});
      } else {
        String error = 'TTS failed';
        try {
          final data = jsonDecode(response.body);
          error = data['detail'] ?? error;
        } catch (_) {}
        return ApiResponse(success: false, error: error, statusCode: response.statusCode);
      }
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  // AI Image Generation
  static Future<ApiResponse> generateImage(String prompt, {String? aspectRatio}) async {
    return post('/api/v1/ai/image/generate', body: {
      'prompt': prompt,
      if (aspectRatio != null) 'aspect_ratio': aspectRatio,
    });
  }

  // AI Image Description
  static Future<ApiResponse> describeImage(String imageUrl, {String message = '请描述这张图片'}) async {
    return post('/api/v1/ai/image/describe', body: {
      'image_url': imageUrl,
      'message': message,
    });
  }
}

class ApiResponse {
  final bool success;
  final dynamic data;
  final String? error;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
  });

  T? get<T>() => data is T ? data as T : null;
  List<T>? getList<T>() => data is List ? data.cast<T>() : null;
}
