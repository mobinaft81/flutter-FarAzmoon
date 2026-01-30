// lib/screens/register_screen.dart
import 'package:fetrati_farazmoon/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/pocketbase_service.dart';
import 'admin/admin_home.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // تغییر از email به username
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // رنگ‌های داینامیک — دقیقاً مثل صفحه لاگین
    final backgroundGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xff0D1B2A), Color(0xff1B263B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [Color.fromARGB(255, 223, 235, 250), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    final primaryColor = isDark
        ? const Color.fromARGB(255, 2, 168, 201)
        : const Color(0xff1A237E);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: Stack(
            children: [
              // محتوای اصلی
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'ثبت‌نام استاد/معلم',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'حساب کاربری خود را برای ساخت و مدیریت آزمون ایجاد کنید',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: primaryColor.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 50),

                        _textField(
                          _fullNameController,
                          'نام و نام خانوادگی',
                          Icons.person_outline,
                        ),
                        const SizedBox(height: 16),

                        // تغییر: نام کاربری دلخواه به جای ایمیل
                        _textField(
                          _usernameController,
                          'نام کاربری دلخواه',
                          Icons.account_circle_outlined,
                          keyboardType: TextInputType.text,
                        ),
                        const SizedBox(height: 16),

                        _passwordField(
                          _passwordController,
                          'رمز عبور',
                          _obscurePassword,
                          () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _passwordField(
                          _confirmPasswordController,
                          'تکرار رمز عبور',
                          _obscureConfirmPassword,
                          () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                        ),
                        const SizedBox(height: 40),

                        _elevatedButton(
                          'ثبت‌نام و ورود',
                          primaryColor,
                          _register,
                          _isLoading,
                        ),

                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "قبلاً ثبت‌نام کرده‌اید؟ وارد شوید",
                            style: TextStyle(
                              color: primaryColor.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withOpacity(0.4)
                        : Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {
                      final themeService = Provider.of<ThemeService>(
                        context,
                        listen: false,
                      );
                      final current = themeService.themeMode;
                      final next = current == ThemeMode.dark
                          ? ThemeMode.light
                          : ThemeMode.dark;
                      themeService.setThemeMode(next);
                    },
                    icon: Consumer<ThemeService>(
                      builder: (context, theme, _) => Icon(
                        theme.themeMode == ThemeMode.dark
                            ? Icons.light_mode
                            : Icons.dark_mode,
                        color: isDark ? Colors.yellow : const Color(0xff1A237E),
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // کادر متنی معمولی
  Widget _textField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xff2D3748) : Colors.white;
    final borderColor = isDark ? const Color(0xff00D4FF) : Colors.grey.shade300;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textDirection: TextDirection.rtl,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.white70 : const Color(0xff1A237E),
        ),
        hintText: hint,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Color(0xff00D4FF), width: 2.5),
        ),
      ),
    );
  }

  Widget _passwordField(
    TextEditingController controller,
    String hint,
    bool obscure,
    VoidCallback toggle,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xff2D3748) : Colors.white;
    final borderColor = isDark ? const Color(0xff00D4FF) : Colors.grey.shade300;

    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        prefixIcon: Icon(
          Icons.lock_outline,
          color: isDark ? Colors.white70 : const Color(0xff1A237E),
        ),
        hintText: hint,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Color(0xff00D4FF), width: 2.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: isDark ? Colors.white70 : Colors.grey[600],
          ),
          onPressed: toggle,
        ),
      ),
    );
  }

  // دکمه ثبت‌نام
  Widget _elevatedButton(
    String text,
    Color color,
    VoidCallback onPressed,
    bool loading,
  ) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 8,
      ),
      child: loading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
              text,
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
    );
  }

  Future<void> _register() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final fullName = _fullNameController.text.trim();

    if (fullName.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showSnack('لطفاً همه فیلدها را پر کنید');
      return;
    }
    if (password != confirmPassword) {
      _showSnack('رمز عبور و تکرار آن یکسان نیست');
      return;
    }
    if (password.length < 6) {
      _showSnack('رمز عبور باید حداقل ۶ کاراکتر باشد');
      return;
    }
    if (username.length < 3) {
      _showSnack('نام کاربری باید حداقل ۳ کاراکتر باشد');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ایجاد کاربر با username
      await PocketBaseService.pb
          .collection('users')
          .create(
            body: {
              'username': username,
              'password': password,
              'passwordConfirm': confirmPassword,
              'name': fullName,
            },
          );

      // ورود با username
      await PocketBaseService.pb
          .collection('users')
          .authWithPassword(username, password);

      _showSnack('ثبت‌نام با موفقیت انجام شد!', Colors.green);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHome()),
        );
      }
    } catch (e) {
      print('خطای ثبت‌نام: $e'); // برای دیباگ
      String errorMsg = 'خطا در ثبت‌نام';
      if (e.toString().contains('username')) {
        errorMsg = 'این نام کاربری قبلاً استفاده شده است';
      }
      _showSnack(errorMsg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message, [Color? color]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: color ?? Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
