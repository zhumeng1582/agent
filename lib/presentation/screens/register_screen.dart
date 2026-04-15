import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/auth_provider.dart';
import '../../core/constants/theme_provider.dart';
import '../../core/constants/locale_provider.dart';
import 'home_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = ref.read(localeProvider);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  String _t(String key, Locale locale) {
    final Map<String, Map<String, String>> translations = {
      'register': {'en': 'Register', 'zh': '注册', 'zh_TW': '註冊'},
      'email': {'en': 'Email', 'zh': '邮箱', 'zh_TW': '郵箱'},
      'password': {'en': 'Password', 'zh': '密码', 'zh_TW': '密碼'},
      'nickname': {'en': 'Nickname', 'zh': '昵称', 'zh_TW': '暱稱'},
      'registerSuccess': {'en': 'Register success', 'zh': '注册成功', 'zh_TW': '註冊成功'},
      'emailPasswordRequired': {'en': 'Email and password are required', 'zh': '邮箱和密码不能为空', 'zh_TW': '郵箱和密碼不能為空'},
      'passwordWeak': {'en': 'Password must contain uppercase, lowercase, special char, min 8 chars', 'zh': '密码需包含大小写字母、特殊字符，至少8位', 'zh_TW': '密碼需包含大小寫字母、特殊字符，至少8位'},
      'registerFailed': {'en': 'Registration failed', 'zh': '注册失败', 'zh_TW': '註冊失敗'},
    };
    final localeKey = locale.countryCode != null ? '${locale.languageCode}_${locale.countryCode}' : locale.languageCode;
    return translations[key]?[localeKey] ?? translations[key]?['zh'] ?? key;
  }

  String? _validatePassword(String password) {
    if (password.length < 8) {
      return _t('passwordWeak', _locale);
    }
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    if (!hasUpper || !hasLower || !hasSpecial) {
      return _t('passwordWeak', _locale);
    }
    return null;
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final nickname = _nicknameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = _t('emailPasswordRequired', _locale);
        _isLoading = false;
      });
      return;
    }

    // Validate password strength
    final passwordError = _validatePassword(password);
    if (passwordError != null) {
      setState(() {
        _error = passwordError;
        _isLoading = false;
      });
      return;
    }

    final success = await ref.read(authProvider.notifier).registerWithEmail(
      email,
      password,
      nickname: nickname.isNotEmpty ? nickname : null,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (mounted) {
      setState(() {
        _error = ref.read(authProvider).error ?? _t('registerFailed', _locale);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                _t('register', locale),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: _t('nickname', locale),
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
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: _t('email', locale),
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
                  labelText: _t('password', locale),
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
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
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
                    : Text(_t('register', locale)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
