import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/auth_provider.dart';
import '../../core/constants/theme_provider.dart';
import '../../core/constants/locale_provider.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  int _currentTab = 0; // 0: 邮箱, 1: 手机
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 80),
            // AI Logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: SvgPicture.asset(
                'assets/icons/ai_logo.svg',
                width: 48,
                height: 48,
              ),
            ),
            const SizedBox(height: 40),
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
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Tab content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildTabContent(isDarkMode, locale),
            ),
            const Spacer(),
            // WeChat login at bottom
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildWechatLoginButton(isDarkMode, locale),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildWechatLoginButton(bool isDarkMode, Locale locale) {
    return Column(
      children: [
        const Text(
          '—— 其他登录方式 ——',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('微信登录开发中...'), backgroundColor: Colors.orange),
            );
          },
          child: SvgPicture.asset(
            'assets/icons/wechat.svg',
            width: 48,
            height: 48,
          ),
        ),
      ],
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
      'loginFailed': {'en': 'Login failed', 'zh': '登录失败', 'zh_TW': '登入失敗'},
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
  void initState() {
    super.initState();
    _loadLastLogin();
  }

  Future<void> _loadLastLogin() async {
    final lastLogin = await ref.read(authProvider.notifier).getLastLogin();
    if (lastLogin != null && lastLogin['method'] == 'email' && mounted) {
      _emailController.text = lastLogin['identifier'] ?? '';
    }
  }

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
      'forgotPassword': {'en': 'Forgot Password?', 'zh': '忘记密码？', 'zh_TW': '忘記密碼？'},
      'loginFailed': {'en': 'Login failed', 'zh': '登录失败', 'zh_TW': '登入失敗'},
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
    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (mounted) {
      final error = ref.read(authProvider).error ?? _t('loginFailed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
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
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: _t('password'),
            filled: true,
            fillColor: widget.isDarkMode ? Colors.grey[800] : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
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
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                );
              },
              child: Text(
                _t('register'),
                style: TextStyle(
                  color: AppColors.primary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                );
              },
              child: Text(
                _t('forgotPassword'),
                style: TextStyle(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
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
  void initState() {
    super.initState();
    _loadLastLogin();
  }

  Future<void> _loadLastLogin() async {
    final lastLogin = await ref.read(authProvider.notifier).getLastLogin();
    if (lastLogin != null && lastLogin['method'] == 'phone' && mounted) {
      _phoneController.text = lastLogin['identifier'] ?? '';
    }
  }

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
    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (mounted) {
      final error = ref.read(authProvider).error ?? _t('loginFailed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
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
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: _t('password'),
              filled: true,
              fillColor: widget.isDarkMode ? Colors.grey[800] : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
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
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegisterScreen()),
            );
          },
          child: Text(
            _t('register'),
            style: TextStyle(
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
