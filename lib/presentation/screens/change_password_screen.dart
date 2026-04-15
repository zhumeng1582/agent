import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/theme_provider.dart';
import '../../core/constants/locale_provider.dart';
import '../../data/services/api_service.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  String? _error;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  String _t(String key) {
    final Map<String, Map<String, String>> translations = {
      'changePassword': {'en': 'Change Password', 'zh': '修改密码', 'zh_TW': '修改密碼'},
      'oldPassword': {'en': 'Current Password', 'zh': '当前密码', 'zh_TW': '當前密碼'},
      'newPassword': {'en': 'New Password', 'zh': '新密码', 'zh_TW': '新密碼'},
      'confirm': {'en': 'Confirm', 'zh': '确认', 'zh_TW': '確認'},
      'passwordRequired': {'en': 'Please enter password', 'zh': '请输入密码', 'zh_TW': '請輸入密碼'},
      'changeSuccess': {'en': 'Password changed successfully', 'zh': '密码修改成功', 'zh_TW': '密碼修改成功'},
      'changeFailed': {'en': 'Failed to change password', 'zh': '密码修改失败', 'zh_TW': '密碼修改失敗'},
      'wrongPassword': {'en': 'Incorrect password', 'zh': '密码错误', 'zh_TW': '密碼錯誤'},
      'noPassword': {'en': 'No password set for this account', 'zh': '该账户未设置密码', 'zh_TW': '該賬戶未設置密碼'},
    };
    final locale = ref.watch(localeProvider);
    final localeKey = locale.countryCode != null ? '${locale.languageCode}_${locale.countryCode}' : locale.languageCode;
    return translations[key]?[localeKey] ?? translations[key]?['zh'] ?? key;
  }

  Future<void> _changePassword() async {
    if (_oldPasswordController.text.isEmpty || _newPasswordController.text.isEmpty) {
      setState(() => _error = _t('passwordRequired'));
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.changePassword(
        _oldPasswordController.text,
        _newPasswordController.text,
      );
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('changeSuccess'))),
        );
        Navigator.pop(context);
      } else {
        final errorMsg = response.error ?? '';
        if (errorMsg.contains('401') || errorMsg.contains('Incorrect')) {
          setState(() => _error = _t('wrongPassword'));
        } else if (errorMsg.contains('No password')) {
          setState(() => _error = _t('noPassword'));
        } else {
          setState(() => _error = _t('changeFailed'));
        }
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
        title: Text(_t('changePassword')),
        backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _oldPasswordController,
                obscureText: _obscureOld,
                decoration: InputDecoration(
                  labelText: _t('oldPassword'),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureOld ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureOld = !_obscureOld),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: _t('newPassword'),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
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
                    : Text(_t('confirm')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
