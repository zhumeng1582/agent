import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/auth_provider.dart';
import '../../core/constants/theme_provider.dart';
import '../../core/constants/locale_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  int _currentTab = 0; // 0: 邮箱, 1: 手机, 2: 微信

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final locale = ref.watch(localeProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chat_bubble_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'AI Chat',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _t('welcome', locale),
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const Spacer(),
            // Login tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildTab(0, _t('email', locale), isDarkMode),
                  _buildTab(1, _t('phone', locale), isDarkMode),
                  _buildTab(2, '微信', isDarkMode),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Tab content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildTabContent(isDarkMode, locale),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String title, bool isDarkMode) {
    final isSelected = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(bool isDarkMode, Locale locale) {
    switch (_currentTab) {
      case 0:
        return _EmailLoginForm(isDarkMode: isDarkMode, locale: locale);
      case 1:
        return _PhoneLoginForm(isDarkMode: isDarkMode, locale: locale);
      case 2:
        return _WechatLoginForm(isDarkMode: isDarkMode);
      default:
        return const SizedBox();
    }
  }

  String _t(String key, Locale locale) {
    final Map<String, Map<String, String>> translations = {
      'welcome': {'en': 'Sign in to continue', 'zh': '登录继续', 'zh_TW': '登入繼續'},
      'email': {'en': 'Email', 'zh': '邮箱', 'zh_TW': '郵箱'},
      'phone': {'en': 'Phone', 'zh': '手机', 'zh_TW': '手機'},
      'login': {'en': 'Login', 'zh': '登录', 'zh_TW': '登入'},
      'register': {'en': 'Register', 'zh': '注册', 'zh_TW': '註冊'},
      'password': {'en': 'Password', 'zh': '密码', 'zh_TW': '密碼'},
      'sendCode': {'en': 'Send Code', 'zh': '发送验证码', 'zh_TW': '發送驗證碼'},
      'loginWithWechat': {'en': 'Login with WeChat', 'zh': '微信登录', 'zh_TW': '微信登入'},
      'or': {'en': 'or', 'zh': '或', 'zh_TW': '或'},
    };
    final localeKey = locale.countryCode != null ? '${locale.languageCode}_${locale.countryCode}' : locale.languageCode;
    return translations[key]?[localeKey] ?? translations[key]?['zh'] ?? key;
  }
}

class _EmailLoginForm extends ConsumerStatefulWidget {
  final bool isDarkMode;
  final Locale locale;

  const _EmailLoginForm({required this.isDarkMode, required this.locale});

  @override
  ConsumerState<_EmailLoginForm> createState() => _EmailLoginFormState();
}

class _EmailLoginFormState extends ConsumerState<_EmailLoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _t(String key) {
    final Map<String, Map<String, String>> translations = {
      'email': {'en': 'Email', 'zh': '邮箱', 'zh_TW': '郵箱'},
      'password': {'en': 'Password', 'zh': '密码', 'zh_TW': '密碼'},
      'login': {'en': 'Login', 'zh': '登录', 'zh_TW': '登入'},
      'register': {'en': 'Register', 'zh': '注册', 'zh_TW': '註冊'},
    };
    final localeKey = widget.locale.countryCode != null
        ? '${widget.locale.languageCode}_${widget.locale.countryCode}'
        : widget.locale.languageCode;
    return translations[key]?[localeKey] ?? translations[key]?['zh'] ?? key;
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    final success = await ref.read(authProvider.notifier).loginWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
    setState(() => _isLoading = false);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(authProvider).error ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: _t('email'),
            filled: true,
            fillColor: widget.isDarkMode ? Colors.grey[800] : Colors.white,
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
            labelText: _t('password'),
            filled: true,
            fillColor: widget.isDarkMode ? Colors.grey[800] : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _login,
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
              : Text(_t('login')),
        ),
      ],
    );
  }
}

class _PhoneLoginForm extends ConsumerStatefulWidget {
  final bool isDarkMode;
  final Locale locale;

  const _PhoneLoginForm({required this.isDarkMode, required this.locale});

  @override
  ConsumerState<_PhoneLoginForm> createState() => _PhoneLoginFormState();
}

class _PhoneLoginFormState extends ConsumerState<_PhoneLoginForm> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _usePassword = true;
  bool _codeSent = false;
  int _countdown = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String _t(String key) {
    final Map<String, Map<String, String>> translations = {
      'phone': {'en': 'Phone', 'zh': '手机号', 'zh_TW': '手機號'},
      'password': {'en': 'Password', 'zh': '密码', 'zh_TW': '密碼'},
      'code': {'en': 'Verification Code', 'zh': '验证码', 'zh_TW': '驗證碼'},
      'sendCode': {'en': 'Send Code', 'zh': '发送验证码', 'zh_TW': '發送驗證碼'},
      'login': {'en': 'Login', 'zh': '登录', 'zh_TW': '登入'},
      'usePassword': {'en': 'Use Password', 'zh': '密码登录', 'zh_TW': '密碼登入'},
      'useCode': {'en': 'Use Code', 'zh': '验证码登录', 'zh_TW': '驗證碼登入'},
      'register': {'en': 'Register', 'zh': '注册', 'zh_TW': '註冊'},
    };
    final localeKey = widget.locale.countryCode != null
        ? '${widget.locale.languageCode}_${widget.locale.countryCode}'
        : widget.locale.languageCode;
    return translations[key]?[localeKey] ?? translations[key]?['zh'] ?? key;
  }

  Future<void> _sendCode() async {
    if (_phoneController.text.length < 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('phone') + ' invalid'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    final success = await ref.read(authProvider.notifier).sendSmsCode(_phoneController.text);
    setState(() => _isLoading = false);
    if (success) {
      setState(() => _codeSent = true);
      _startCountdown();
    }
  }

  void _startCountdown() {
    setState(() => _countdown = 60);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_countdown > 0) {
        setState(() => _countdown--);
        return true;
      }
      return false;
    });
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    bool success;
    if (_usePassword) {
      success = await ref.read(authProvider.notifier).loginWithPhone(
            _phoneController.text,
            _passwordController.text,
          );
    } else {
      success = await ref.read(authProvider.notifier).verifySmsCode(
            _phoneController.text,
            _codeController.text,
          );
    }
    setState(() => _isLoading = false);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(authProvider).error ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: _t('phone'),
            filled: true,
            fillColor: widget.isDarkMode ? Colors.grey[800] : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_usePassword)
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: _t('password'),
              filled: true,
              fillColor: widget.isDarkMode ? Colors.grey[800] : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _t('code'),
                    filled: true,
                    fillColor: widget.isDarkMode ? Colors.grey[800] : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isLoading || _countdown > 0 ? null : _sendCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _codeSent ? Colors.grey : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(_countdown > 0 ? '${_countdown}s' : _t('sendCode')),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() {
            _usePassword = !_usePassword;
            _codeSent = false;
          }),
          child: Text(_usePassword ? _t('useCode') : _t('usePassword')),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _isLoading ? null : _login,
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
              : Text(_t('login')),
        ),
      ],
    );
  }
}

class _WechatLoginForm extends ConsumerWidget {
  final bool isDarkMode;

  const _WechatLoginForm({required this.isDarkMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // WeChat login button placeholder
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('微信登录开发中...'), backgroundColor: Colors.orange),
            );
          },
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.chat,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '微信登录',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '更多登录方式陆续支持',
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
          ),
        ),
      ],
    );
  }
}
