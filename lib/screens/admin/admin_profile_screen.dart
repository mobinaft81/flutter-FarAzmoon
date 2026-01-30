// lib/screens/admin/admin_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../services/pocketbase_service.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordSectionOpen = false; // وضعیت باز/بسته بودن بخش تغییر رمز
  bool _showOldPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  String? _errorMessage;

  RecordModel? _adminRecord;

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
  }

  Future<void> _loadAdminInfo() async {
    try {
      final userModel = PocketBaseService.pb.authStore.model;
      if (userModel != null && userModel is RecordModel) {
        setState(() => _adminRecord = userModel);
      }
    } catch (e) {
      setState(() => _errorMessage = 'خطا در بارگذاری اطلاعات');
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'رمز عبور جدید و تکرار آن مطابقت ندارند');
      return;
    }
    if (_newPasswordController.text.length < 6) {
      setState(() => _errorMessage = 'رمز عبور باید حداقل ۶ کاراکتر باشد');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await PocketBaseService.pb
          .collection('users')
          .update(
            PocketBaseService.pb.authStore.model!.id,
            body: {
              'oldPassword': _oldPasswordController.text.trim(),
              'password': _newPasswordController.text.trim(),
              'passwordConfirm': _confirmPasswordController.text.trim(),
            },
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رمز عبور با موفقیت تغییر کرد'),
          backgroundColor: Colors.green,
        ),
      );

      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      // بعد از تغییر موفق، بخش رو ببند
      setState(() => _isPasswordSectionOpen = false);
    } catch (e) {
      String msg = 'خطایی رخ داد';
      if (e.toString().contains('oldPassword')) {
        msg = 'رمز عبور فعلی اشتباه است';
      }
      setState(() => _errorMessage = msg);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? const Color.fromARGB(255, 2, 142, 170)
        : const Color(0xff1A237E);
    final cardBg = isDark ? const Color(0xff1E1E1E) : Colors.white;

    final String adminName =
        _adminRecord?.data['name']?.toString().trim().isNotEmpty == true
        ? _adminRecord!.data['name']
        : 'مدیر سیستم';

    final String adminUsername = _adminRecord?.data['username'] ?? 'نامشخص';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  colors: [Color(0xff0D1B2A), Color(0xff1B263B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : const LinearGradient(
                  colors: [Color.fromARGB(255, 223, 235, 250), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // هدر
              Container(
                height: 50,
                margin: const EdgeInsets.all(15),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.arrow_back,
                        color: primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Text(
                        'حساب کاربری ادمین',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'SB',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset('assets/images/logo.png', width: 44),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: primaryColor.withOpacity(0.2),
                        child: Icon(
                          Icons.admin_panel_settings,
                          size: 60,
                          color: primaryColor,
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        adminName,
                        style: TextStyle(
                          fontFamily: 'SB',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 6),
                          Text(
                            '$adminUsername',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.white70 : Colors.grey[800],
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.alternate_email,
                            size: 18,
                            color: isDark ? Colors.white70 : Colors.grey[700],
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),
                      Text(
                        'مدیر سیستم فرازمون',
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // بخش کشویی تغییر رمز عبور با آیکون چشم
                      Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDark ? 0.3 : 0.08,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: primaryColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              onTap: () {
                                setState(
                                  () => _isPasswordSectionOpen =
                                      !_isPasswordSectionOpen,
                                );
                              },
                              leading: Icon(
                                Icons.lock_outline,
                                color: primaryColor,
                                size: 28,
                              ),
                              title: Text(
                                'تغییر رمز عبور',
                                style: TextStyle(
                                  fontFamily: 'SB',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              trailing: AnimatedRotation(
                                turns: _isPasswordSectionOpen ? 0.5 : 0,
                                duration: const Duration(milliseconds: 300),
                                child: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: primaryColor,
                                  size: 28,
                                ),
                              ),
                            ),

                            AnimatedCrossFade(
                              firstChild: const SizedBox.shrink(),
                              secondChild: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                child: Column(
                                  children: [
                                    // رمز عبور فعلی
                                    TextField(
                                      controller: _oldPasswordController,
                                      obscureText: !_showOldPassword,
                                      textDirection: TextDirection.ltr,
                                      decoration: InputDecoration(
                                        labelText: 'رمز عبور فعلی',
                                        filled: true,
                                        fillColor: isDark
                                            ? const Color(0xff2D3748)
                                            : Colors.grey[100],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _showOldPassword
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                          ),
                                          onPressed: () => setState(
                                            () => _showOldPassword =
                                                !_showOldPassword,
                                          ),
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // رمز عبور جدید
                                    TextField(
                                      controller: _newPasswordController,
                                      obscureText: !_showNewPassword,
                                      textDirection: TextDirection.ltr,
                                      decoration: InputDecoration(
                                        labelText: 'رمز عبور جدید',
                                        filled: true,
                                        fillColor: isDark
                                            ? const Color(0xff2D3748)
                                            : Colors.grey[100],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _showNewPassword
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                          ),
                                          onPressed: () => setState(
                                            () => _showNewPassword =
                                                !_showNewPassword,
                                          ),
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // تکرار رمز عبور جدید
                                    TextField(
                                      controller: _confirmPasswordController,
                                      obscureText: !_showConfirmPassword,
                                      textDirection: TextDirection.ltr,
                                      decoration: InputDecoration(
                                        labelText: 'تکرار رمز عبور جدید',
                                        filled: true,
                                        fillColor: isDark
                                            ? const Color(0xff2D3748)
                                            : Colors.grey[100],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _showConfirmPassword
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                          ),
                                          onPressed: () => setState(
                                            () => _showConfirmPassword =
                                                !_showConfirmPassword,
                                          ),
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),

                                    if (_errorMessage != null) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 20),

                                    SizedBox(
                                      width: double.infinity,
                                      height: 55,
                                      child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _changePassword,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                          elevation: 6,
                                        ),
                                        child: _isLoading
                                            ? const CircularProgressIndicator(
                                                color: Colors.white,
                                              )
                                            : const Text(
                                                'تغییر رمز عبور',
                                                style: TextStyle(
                                                  fontFamily: 'SB',
                                                  fontSize: 17,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              crossFadeState: _isPasswordSectionOpen
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 300),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
