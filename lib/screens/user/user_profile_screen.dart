// lib/screens/user/user_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../services/pocketbase_service.dart';

class UserProfileScreen extends StatefulWidget {
  final String studentCode; // کد ملی

  const UserProfileScreen({required this.studentCode, super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  RecordModel? _studentRecord;
  bool _loading = true;

  // کنترلرها برای فرم‌ها
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();

  // وضعیت باز بودن فرم‌ها
  bool _showPasswordForm = false;
  bool _showMobileForm = false;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    setState(() => _loading = true);
    try {
      final result = await PocketBaseService.pb
          .collection('allowed_students')
          .getList(
            filter: 'student_code = "${widget.studentCode}"',
            perPage: 1,
          );

      if (result.items.isNotEmpty) {
        setState(() {
          _studentRecord = result.items.first;
          final currentMobile =
              _studentRecord!.data['participant_mobile']?.toString().trim() ??
              '';
          _mobileCtrl.text = currentMobile;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری اطلاعات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _loading = false);
    }
  }

  // تغییر رمز عبور
  Future<void> _changePassword() async {
    final newPass = _newPasswordCtrl.text.trim();
    final confirmPass = _confirmPasswordCtrl.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      _showSnack('لطفاً هر دو فیلد را پر کنید');
      return;
    }
    if (newPass != confirmPass) {
      _showSnack('رمز عبور و تکرار آن یکسان نیست');
      return;
    }
    if (newPass.length < 6) {
      _showSnack('رمز عبور باید حداقل ۶ کاراکتر باشد');
      return;
    }

    try {
      await PocketBaseService.pb
          .collection('allowed_students')
          .update(_studentRecord!.id, body: {'password': newPass});

      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
      setState(() => _showPasswordForm = false);

      _showSnack('رمز عبور با موفقیت تغییر کرد', Colors.green);
      await _loadStudentData();
    } catch (e) {
      _showSnack('خطا در تغییر رمز: $e');
    }
  }

  // تغییر شماره تماس
  Future<void> _changeMobile() async {
    final mobile = _mobileCtrl.text.trim();

    if (mobile.isEmpty) {
      _showSnack('شماره تماس را وارد کنید');
      return;
    }
    if (mobile.length != 11 || !mobile.startsWith('09')) {
      _showSnack('شماره تماس باید ۱۱ رقمی و با ۰۹ شروع شود');
      return;
    }

    try {
      await PocketBaseService.pb
          .collection('allowed_students')
          .update(_studentRecord!.id, body: {'participant_mobile': mobile});

      setState(() => _showMobileForm = false);
      _showSnack('شماره تماس با موفقیت ذخیره شد', Colors.green);
      await _loadStudentData();
    } catch (e) {
      _showSnack('خطا در ذخیره شماره: $e');
    }
  }

  void _showSnack(String message, [Color? color]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color ?? Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? const Color(0xff00D4FF)
        : const Color(0xff1A237E);
    final cardBg = isDark ? const Color(0xff1E1E1E) : Colors.white;
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

    if (_loading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: backgroundGradient),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final name =
        _studentRecord?.data['student_name']?.toString().trim() ?? 'نامشخص';
    final studentId =
        _studentRecord?.data['student_id']?.toString().trim() ?? 'ثبت نشده';
    final mobile =
        _studentRecord?.data['participant_mobile']?.toString().trim() ??
        'ثبت نشده';
    final hasPassword =
        (_studentRecord?.data['password']?.toString().trim() ?? '').isNotEmpty;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // هدر — دقیقاً مثل بقیه صفحات کاربر
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.arrow_back,
                        color: primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'حساب کاربری',
                      style: TextStyle(
                        fontFamily: 'SB',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // کارت اطلاعات اصلی
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: primaryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: TextStyle(
                          fontFamily: 'SB',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 30),

                      _buildInfoRow('کد ملی', widget.studentCode, primaryColor),
                      _buildInfoRow('کد دانشجویی', studentId, primaryColor),
                      _buildInfoRow(
                        'شماره تماس',
                        mobile.isEmpty ? 'ثبت نشده' : mobile,
                        primaryColor,
                      ),
                      _buildInfoRow(
                        'وضعیت رمز عبور',
                        hasPassword ? 'تنظیم شده' : 'تنظیم نشده',
                        primaryColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // کارت تغییر رمز عبور
                _buildActionCard(
                  icon: Icons.lock_outline,
                  title: 'تغییر رمز عبور',
                  subtitle: hasPassword
                      ? 'رمز فعلی تنظیم شده است'
                      : 'رمز عبور تنظیم نشده',
                  onTap: () {
                    setState(() {
                      _showPasswordForm = !_showPasswordForm;
                      _showMobileForm = false;
                    });
                  },
                  isExpanded: _showPasswordForm,
                  child: Column(
                    children: [
                      TextField(
                        controller: _newPasswordCtrl,
                        obscureText: true,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: 'رمز جدید',
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xff2D3748)
                              : Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xff00D4FF)
                                  : Colors.grey[400]!,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xff00D4FF)
                                  : Colors.grey[400]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Color(0xff00D4FF),
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _confirmPasswordCtrl,
                        obscureText: true,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: 'تکرار رمز',
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xff2D3748)
                              : Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xff00D4FF)
                                  : Colors.grey[400]!,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xff00D4FF)
                                  : Colors.grey[400]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Color(0xff00D4FF),
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'ذخیره رمز جدید',
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
                  primaryColor: primaryColor,
                  cardBg: cardBg,
                  isDark: isDark,
                ),

                const SizedBox(height: 20),

                // کارت ثبت/تغییر شماره تماس
                _buildActionCard(
                  icon: Icons.phone_android,
                  title: 'ثبت یا تغییر شماره تماس',
                  subtitle: mobile.isEmpty
                      ? 'شماره تماس ثبت نشده'
                      : 'شماره فعلی: $mobile',
                  onTap: () {
                    setState(() {
                      _showMobileForm = !_showMobileForm;
                      _showPasswordForm = false;
                    });
                  },
                  isExpanded: _showMobileForm,
                  child: Column(
                    children: [
                      TextField(
                        controller: _mobileCtrl,
                        keyboardType: TextInputType.phone,
                        textAlign: TextAlign.center,
                        maxLength: 11,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: 'شماره موبایل (۰۹...)',
                          counterText: '',
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xff2D3748)
                              : Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xff00D4FF)
                                  : Colors.grey[400]!,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xff00D4FF)
                                  : Colors.grey[400]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Color(0xff00D4FF),
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _changeMobile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'ذخیره شماره تماس',
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
                  primaryColor: primaryColor,
                  cardBg: cardBg,
                  isDark: isDark,
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // کارت اکشن با قابلیت باز/بسته شدن — با تم داینامیک
  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isExpanded,
    required Widget child,
    required Color primaryColor,
    required Color cardBg,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, size: 32, color: primaryColor),
            title: Text(
              title,
              style: TextStyle(
                fontFamily: 'SB',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.grey,
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 28,
              color: primaryColor,
            ),
            onTap: onTap,
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: child,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color primaryColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white60 : Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'SB',
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
