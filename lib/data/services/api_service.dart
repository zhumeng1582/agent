import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String? _baseUrl;
  static String? _accessToken;
  static String? _refreshToken;
  static SharedPreferences? _prefs;
  static bool _isInitialized = false;

  static late Dio _dio;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  static Future<void> configure({required String baseUrl}) async {
    _baseUrl = baseUrl;
    _prefs = await SharedPreferences.getInstance();
    await _loadTokens();
    _isInitialized = true;

    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl!,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        debugPrint('[ApiService] >>> ${options.method} ${options.uri}');
        if (options.data != null) {
          debugPrint('[ApiService] >>> Body: ${options.data is FormData ? 'FormData' : jsonEncode(options.data)}');
        }
        // Add auth header
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('[ApiService] <<< ${response.statusCode} ${response.requestOptions.uri}');
        final dataStr = response.data is String ? response.data as String : jsonEncode(response.data);
        debugPrint('[ApiService] <<< Response: ${dataStr.length > 500 ? '${dataStr.substring(0, 500)}...' : dataStr}');
        handler.next(response);
      },
      onError: (error, handler) {
        debugPrint('[ApiService] <<< ERROR: ${error.message ?? error.type.name}');
        debugPrint('[ApiService] <<< Response: ${error.response?.data ?? 'no response'}');
        handler.next(error);
      },
    ));

    // Add log interceptor
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      logPrint: (obj) => debugPrint('[ApiService] $obj'),
    ));
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

  static Future<ApiResponse> _handleDioError(DioException error) async {
    if (error.response?.statusCode == 401 && _refreshToken != null) {
      debugPrint('[ApiService] Got 401, trying to refresh token...');
      final refreshed = await _refreshTokenIfNeeded();
      if (refreshed) {
        return ApiResponse(success: false, error: 'Token refreshed, please retry', statusCode: 401);
      } else {
        await clearTokens();
        return ApiResponse(success: false, error: 'Session expired', statusCode: 401);
      }
    }

    String errorMsg = 'Request failed';
    if (error.response?.data != null) {
      try {
        if (error.response?.data is String) {
          final data = jsonDecode(error.response!.data);
          errorMsg = data['detail'] ?? errorMsg;
        } else {
          errorMsg = error.response?.data['detail'] ?? errorMsg;
        }
      } catch (_) {}
    }
    return ApiResponse(success: false, error: errorMsg, statusCode: error.response?.statusCode);
  }

  static Future<bool> _refreshTokenIfNeeded() async {
    if (_refreshToken == null || _baseUrl == null) return false;

    try {
      final response = await Dio().post(
        '$_baseUrl/api/v1/auth/refresh',
        data: {'refresh_token': _refreshToken},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = response.data;
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
    try {
      final response = await _dio.get(endpoint);
      return ApiResponse(success: true, data: response.data);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  static Future<ApiResponse> post(String endpoint, {Map<String, dynamic>? body, int timeoutSeconds = 30}) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: body,
        options: Options(responseType: timeoutSeconds == 60 ? ResponseType.bytes : ResponseType.json),
      );
      return ApiResponse(success: true, data: response.data);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  static Future<ApiResponse> patch(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await _dio.patch(endpoint, data: body);
      return ApiResponse(success: true, data: response.data);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  static Future<ApiResponse> delete(String endpoint) async {
    try {
      final response = await _dio.delete(endpoint);
      return ApiResponse(success: true, data: response.data);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
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
      final response = await Dio().post(
        '$_baseUrl/api/v1/auth/login',
        data: FormData.fromMap({
          'username': email,
          'password': password,
        }),
        options: Options(headers: {'Content-Type': 'application/x-www-form-urlencoded'}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return ApiResponse(success: true, data: response.data);
      } else {
        return ApiResponse(success: false, error: 'Login failed', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      return _handleDioError(e);
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

  // Password endpoints
  static Future<ApiResponse> forgotPassword({String? email, String? phone}) async {
    return post('/api/v1/auth/password/forgot', body: {
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
    });
  }

  static Future<ApiResponse> resetPassword({String? email, String? phone, required String code, required String newPassword}) async {
    return post('/api/v1/auth/password/reset', body: {
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'code': code,
      'new_password': newPassword,
    });
  }

  static Future<ApiResponse> changePassword(String oldPassword, String newPassword) async {
    return post('/api/v1/auth/password/change', body: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  // Usage endpoint
  static Future<ApiResponse> getUsage() async {
    return get('/api/v1/usage');
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
      final response = await _dio.post(
        '/api/v1/ai/tts',
        data: {
          'text': text,
          if (voiceId != null) 'voice_id': voiceId,
        },
        options: Options(responseType: ResponseType.bytes),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        return ApiResponse(success: true, data: {'bytes': response.data});
      } else {
        String error = 'TTS failed';
        try {
          error = response.data['detail'] ?? error;
        } catch (_) {}
        return ApiResponse(success: false, error: error, statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      return _handleDioError(e);
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
