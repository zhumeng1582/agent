import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/theme_provider.dart';
import '../../core/constants/locale_provider.dart';
import '../../data/services/api_service.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _codeSent = false;
  String? _email;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String _t(String key) {
    final Map<String, Map<String, String>> translations = {
      'forgotPassword': {'en': 'Forgot Password', 'zh': '忘记密码', 'zh_TW': '忘記密碼'},
      'email': {'en': 'Email', 'zh': '邮箱', 'zh_TW': '郵箱'},
      'sendCode': {'en': 'Send Code', 'zh': '发送验证码', 'zh_TW': '發送驗證碼'},
      'resetPassword': {'en': 'Reset Password', 'zh': '重置密码', 'zh_TW': '重置密碼'},
      'code': {'en': 'Verification Code', 'zh': '验证码', 'zh_TW': '驗證碼'},
      'newPassword': {'en': 'New Password', 'zh': '新密码', 'zh_TW': '新密碼'},
      'codeSent': {'en': 'Code sent to your email', 'zh': '验证码已发送到邮箱', 'zh_TW': '驗證碼已發送到郵箱'},
      'resetSuccess': {'en': 'Password reset successfully', 'zh': '密码重置成功', 'zh_TW': '密碼重置成功'},
      'emailRequired': {'en': 'Please enter your email', 'zh': '请输入邮箱', 'zh_TW': '請輸入郵箱'},
      'codeRequired': {'en': 'Please enter the code', 'zh': '请输入验证码', 'zh_TW': '請輸入驗證碼'},
      'passwordRequired': {'en': 'Please enter new password', 'zh': '请输入新密码', 'zh_TW': '請輸入新密碼'},
      'resetFailed': {'en': 'Failed to reset password', 'zh': '密码重置失败', 'zh_TW': '密碼重置失敗'},
    };
    final locale = ref.watch(localeProvider);
    final localeKey = locale.countryCode != null ? '${locale.languageCode}_${locale.countryCode}' : locale.languageCode;
    return translations[key]?[localeKey] ?? translations[key]?['zh'] ?? key;
  }

  Future<void> _sendCode() async {
    if (_emailController.text.isEmpty) {
      setState(() => _error = _t('emailRequired'));
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.forgotPassword(email: _emailController.text);
      if (response.success) {
        setState(() {
          _codeSent = true;
          _email = _emailController.text;
        });
      } else {
        setState(() => _error = response.error ?? 'Failed to send code');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(_t('forgotPassword')),
        backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _codeSent ? _buildResetForm(isDarkMode) : _buildSendForm(isDarkMode),
        ),
      ),
    );
  }

  Widget _buildSendForm(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: _t('email'),
            filled: true,
            fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(_t('sendCode')),
        ),
      ],
    );
  }

  Widget _buildResetForm(bool isDarkMode) {
    final _codeController = TextEditingController();
    final _passwordController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_t('codeSent'), style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey)),
        const SizedBox(height: 24),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: _t('code'),
            filled: true,
            fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: _t('newPassword'),
            filled: true,
            fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : () async {
            if (_codeController.text.isEmpty) {
              setState(() => _error = _t('codeRequired'));
              return;
            }
            if (_passwordController.text.isEmpty) {
              setState(() => _error = _t('passwordRequired'));
              return;
            }

            setState(() {
              _isLoading = true;
              _error = null;
            });

            try {
              final response = await ApiService.resetPassword(
                email: _email,
                code: _codeController.text,
                newPassword: _passwordController.text,
              );
              if (response.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_t('resetSuccess'))),
                );
                Navigator.pop(context);
              } else {
                setState(() => _error = response.error ?? _t('resetFailed'));
              }
            } catch (e) {
              setState(() => _error = e.toString());
            } finally {
              setState(() => _isLoading = false);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(_t('resetPassword')),
        ),
      ],
    );
  }
}
