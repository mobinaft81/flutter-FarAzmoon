// lib/screens/login_screen.dart
import 'package:fetrati_farazmoon/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../services/pocketbase_service.dart';
import 'admin/admin_home.dart';
import 'register_screen.dart';
import 'user/user_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController(); // نام کاربری استاد
  final _passCtrl = TextEditingController();
  final _nationalCodeCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();
  final _publicTestCodeCtrl = TextEditingController();

  bool _obscurePasswordTeacher = true;
  bool _obscurePasswordStudent = true;
  bool _loadingTeacher = false;
  bool _loadingStudent = false;
  bool _loadingPublic = false;

  int _mode = 0; // 0: انتخاب نقش | 1: استاد | 2: دانش‌آموز | 3: عمومی

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
    final buttonColor = isDark
        ? const Color.fromARGB(255, 45, 127, 143)
        : Colors.green;
    final textFieldFill = isDark ? const Color(0xff2D3748) : Colors.white;
    final textFieldBorderColor = isDark
        ? const Color(0xff00D4FF)
        : const Color.fromARGB(255, 139, 139, 139);

    // // رنگ‌های مخصوص دیالوگ (داینامیک)
    // final dialogBg = isDark ? const Color(0xff1E1E1E) : Colors.white;
    // final dialogTitleColor = isDark
    //     ? const Color(0xff00D4FF)
    //     : const Color(0xff1A237E);
    // final dialogTextColor = isDark
    //     ? Colors.white70
    //     : const Color.fromRGBO(97, 97, 97, 1);
    // final dialogHintColor = isDark ? Colors.grey[400] : Colors.grey;
    // final dialogFillColor = isDark ? const Color(0xff2D3748) : Colors.grey[50];
    // final dialogErrorColor = Colors.red[400]!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Text(
                          'ورود به سامانه',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'فرآزمون',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Image.asset(
                              'assets/images/check-box.png',
                              width: 40,
                              colorBlendMode: BlendMode.srcIn,
                              color: primaryColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 60),

                        if (_mode == 0) ...[
                          _bigButton(
                            'من دانش‌آموز/دانشجو هستم',
                            Icons.school,
                            buttonColor,
                            () => setState(() => _mode = 2),
                          ),
                          const SizedBox(height: 20),
                          _bigButton(
                            'ورود به آزمون عمومی',
                            Icons.public,
                            Colors.blue,
                            () => setState(() => _mode = 3),
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            onPressed: () => setState(() => _mode = 1),
                            icon: Icon(Icons.person, color: primaryColor),
                            label: const Text(
                              'من استاد/معلم هستم',
                              style: TextStyle(fontSize: 18),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: primaryColor, width: 2.5),
                              minimumSize: const Size(double.infinity, 65),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ] else if (_mode == 1)
                          ..._teacherLogin(
                            primaryColor,
                            textFieldFill,
                            textFieldBorderColor,
                          )
                        else if (_mode == 2) ...[
                          Text(
                            'ورود دانش‌آموز/دانشجو',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: buttonColor,
                            ),
                          ),
                          const SizedBox(height: 30),
                          _textField(
                            _nationalCodeCtrl,
                            'کد ملی',
                            '__________',
                            TextInputType.number,
                            maxLength: 10,
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _studentIdCtrl,
                            obscureText: _obscurePasswordStudent,
                            keyboardType: TextInputType.text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22),
                            decoration: InputDecoration(
                              labelText: 'رمز عبور',
                              hintText: 'password',
                              filled: true,
                              fillColor: textFieldFill,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: textFieldBorderColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: textFieldBorderColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xff00D4FF),
                                  width: 2,
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePasswordStudent
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey[600],
                                ),
                                onPressed: () => setState(
                                  () => _obscurePasswordStudent =
                                      !_obscurePasswordStudent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          _elevatedButton(
                            'ورود به پنل من',
                            buttonColor,
                            _loginWithNationalAndStudentId,
                            _loadingStudent,
                          ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: () => setState(() => _mode = 0),
                            child: Icon(Icons.arrow_back, color: buttonColor),
                          ),
                        ] else if (_mode == 3) ...[
                          Text(
                            'ورود به آزمون عمومی',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 30),
                          _textField(
                            _publicTestCodeCtrl,
                            'کد آزمون',
                            '______',
                            TextInputType.number,
                            maxLength: 6,
                            fontSize: 32,
                          ),
                          const SizedBox(height: 40),
                          _elevatedButton(
                            'ورود به آزمون',
                            Colors.blue,
                            _enterPublicTest,
                            _loadingPublic,
                          ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: () => setState(() => _mode = 0),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.blue,
                            ),
                          ),
                        ],
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

  Widget _bigButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 30),
      label: Text(
        title,
        style: const TextStyle(fontSize: 20, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 70),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 8,
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label,
    String hint,
    TextInputType keyboardType, {
    int? maxLength,
    double fontSize = 22,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textAlign: TextAlign.center,
      maxLength: maxLength,
      style: TextStyle(
        fontSize: fontSize,
        letterSpacing: maxLength == 10 ? 6 : 8,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        filled: true,
        fillColor: isDark ? const Color(0xff2D3748) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xff00D4FF)
                : const Color.fromARGB(255, 122, 122, 122),
            width: isDark ? 2 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xff00D4FF)
                : const Color.fromARGB(255, 114, 114, 114),
            width: isDark ? 2 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: const Color(0xff00D4FF), width: 2.5),
        ),
      ),
    );
  }

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
        minimumSize: const Size(double.infinity, 60),
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

  List<Widget> _teacherLogin(
    Color primaryColor,
    Color fillColor,
    Color borderColor,
  ) {
    return [
      Text(
        'ورود استاد/معلم',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
      const SizedBox(height: 20),
      TextField(
        controller: _usernameCtrl,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          hintText: 'نام کاربری',
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Color(0xff00D4FF), width: 2.5),
          ),
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _passCtrl,
        obscureText: _obscurePasswordTeacher,
        decoration: InputDecoration(
          hintText: 'رمز عبور',
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Color(0xff00D4FF), width: 2.5),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePasswordTeacher ? Icons.visibility_off : Icons.visibility,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.grey[600],
            ),
            onPressed: () => setState(
              () => _obscurePasswordTeacher = !_obscurePasswordTeacher,
            ),
          ),
        ),
      ),
      const SizedBox(height: 30),
      _elevatedButton(
        'ورود استاد/معلم',
        primaryColor,
        _loginTeacher,
        _loadingTeacher,
      ),
      const SizedBox(height: 16),
      TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
        ),
        child: const Text(
          'ثبت‌نام جدید',
          style: TextStyle(color: Color.fromARGB(255, 111, 130, 240)),
        ),
      ),
      TextButton(
        onPressed: () => setState(() => _mode = 0),
        child: Icon(Icons.arrow_back, color: primaryColor),
      ),
    ];
  }

  Future<void> _loginTeacher() async {
    final username = _usernameCtrl.text.trim();
    final password = _passCtrl.text;

    if (username.isEmpty || password.isEmpty) {
      _showSnack('لطفاً نام کاربری و رمز را وارد کنید');
      return;
    }

    setState(() => _loadingTeacher = true);

    try {
      await PocketBaseService.pb
          .collection('users')
          .authWithPassword(username, password);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminHome()),
          (route) => false,
        );
      }
    } catch (e) {
      _showSnack('نام کاربری یا رمز عبور اشتباه است');
    } finally {
      if (mounted) setState(() => _loadingTeacher = false);
    }
  }

  Future<void> _loginWithNationalAndStudentId() async {
    final nationalCode = _nationalCodeCtrl.text.trim();
    final input = _studentIdCtrl.text.trim();

    if (nationalCode.length != 10) {
      _showSnack('کد ملی باید ۱۰ رقمی باشد');
      return;
    }
    if (input.isEmpty) {
      _showSnack('رمز عبور را وارد کنید');
      return;
    }

    setState(() => _loadingStudent = true);
    try {
      final passwordResult = await PocketBaseService.pb
          .collection('allowed_students')
          .getList(
            filter: 'student_code = "$nationalCode" && password = "$input"',
            perPage: 1,
          );

      if (passwordResult.items.isNotEmpty) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => UserHome(studentCode: nationalCode),
            ),
            (route) => false,
          );
        }
        return;
      }

      final studentIdResult = await PocketBaseService.pb
          .collection('allowed_students')
          .getList(
            filter: 'student_code = "$nationalCode" && student_id = "$input"',
            perPage: 1,
          );

      if (studentIdResult.items.isNotEmpty) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => UserHome(studentCode: nationalCode),
            ),
            (route) => false,
          );
        }
        return;
      }

      _showSnack('کد ملی یا رمز عبور اشتباه است');
    } catch (e) {
      _showSnack('خطا در ورود. دوباره امتحان کنید');
    } finally {
      if (mounted) setState(() => _loadingStudent = false);
    }
  }

  Future<void> _enterPublicTest() async {
    final code = _publicTestCodeCtrl.text.trim();
    if (code.length != 6) {
      _showSnack('کد آزمون باید ۶ رقمی باشد');
      return;
    }

    setState(() => _loadingPublic = true);
    try {
      final result = await PocketBaseService.pb
          .collection('tests')
          .getList(
            filter: 'access_code = "$code" && is_public = true',
            page: 1,
            perPage: 1,
          );

      if (result.items.isEmpty) throw 'آزمون عمومی با این کد پیدا نشد';

      final testId = result.items.first.id;

      setState(() => _loadingPublic = false);

      final guestInfo = await showDialog<Map<String, String>?>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final nameCtrl = TextEditingController();
          final mobileCtrl = TextEditingController();

          String? nameError;
          String? mobileError;

          final isDark = Theme.of(context).brightness == Brightness.dark;
          final dialogBg = isDark ? const Color(0xff1E1E1E) : Colors.white;
          final dialogTitleColor = isDark
              ? const Color(0xff00D4FF)
              : const Color(0xff1A237E);
          final dialogTextColor = isDark
              ? Colors.white70
              : const Color.fromRGBO(97, 97, 97, 1);
          final dialogHintColor = isDark ? Colors.grey[400] : Colors.grey;
          final dialogFillColor = isDark
              ? const Color(0xff2D3748)
              : Colors.grey[50];
          final dialogErrorColor = Colors.red[400]!;

          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: dialogBg,
              elevation: 20,
              contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              title: Column(
                children: [
                  Icon(Icons.person_add, size: 60, color: dialogTitleColor),
                  const SizedBox(height: 16),
                  Text(
                    'اطلاعات شرکت‌کننده',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SB',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: dialogTitleColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'برای ثبت نتیجه آزمون، لطفاً اطلاعات زیر را وارد کنید',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: dialogTextColor),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'نام و نام خانوادگی',
                        hintStyle: TextStyle(color: dialogHintColor),
                        errorText: nameError,
                        errorStyle: TextStyle(color: dialogErrorColor),
                        filled: true,
                        fillColor: dialogFillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xff00D4FF)
                                : Colors.grey[400]!,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xff00D4FF),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: mobileCtrl,
                      keyboardType: TextInputType.phone,
                      textAlign: TextAlign.center,
                      maxLength: 11,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'شماره موبایل (مثال: ۰۹۱۲۳۴۵۶۷۸۹)',
                        hintStyle: TextStyle(color: dialogHintColor),
                        errorText: mobileError,
                        errorStyle: TextStyle(color: dialogErrorColor),
                        counterText: '',
                        filled: true,
                        fillColor: dialogFillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xff00D4FF)
                                : Colors.grey[400]!,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xff00D4FF),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: isDark ? Colors.grey[600]! : Colors.grey,
                          ),
                        ),
                        child: Text(
                          'لغو',
                          style: TextStyle(
                            fontFamily: 'SB',
                            fontSize: 16,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          final mobile = mobileCtrl.text.trim();

                          nameError = name.isEmpty ? 'نام الزامی است' : null;
                          mobileError = _validateMobile(mobile);

                          if (nameError != null || mobileError != null) {
                            setDialogState(() {});
                            return;
                          }

                          try {
                            final nameCheck = await PocketBaseService.pb
                                .collection('attempts')
                                .getList(
                                  filter:
                                      'test_id = "$testId" && participant_name = "$name"',
                                  perPage: 1,
                                );
                            if (nameCheck.items.isNotEmpty) {
                              nameError = 'این نام قبلاً استفاده شده';
                              setDialogState(() {});
                              return;
                            }

                            final mobileCheck = await PocketBaseService.pb
                                .collection('attempts')
                                .getList(
                                  filter:
                                      'test_id = "$testId" && participant_mobile = "$mobile"',
                                  perPage: 1,
                                );
                            if (mobileCheck.items.isNotEmpty) {
                              mobileError = 'این شماره قبلاً استفاده شده';
                              setDialogState(() {});
                              return;
                            }
                          } catch (e) {}

                          Navigator.pop(ctx, {'name': name, 'mobile': mobile});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: dialogTitleColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'تایید و ورود',
                          style: TextStyle(
                            fontFamily: 'SB',
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );

      if (guestInfo == null) return;

      final displayName = '${guestInfo['name']} (${guestInfo['mobile']})';
      final guestId = 'guest_${const Uuid().v4()}';

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => UserHome(
              publicTestId: testId,
              guestId: guestId,
              guestName: displayName,
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      _showSnack('کد آزمون اشتباه است یا عمومی نیست');
    } finally {
      if (mounted) setState(() => _loadingPublic = false);
    }
  }

  String? _validateMobile(String mobile) {
    if (mobile.isEmpty) return 'شماره موبایل الزامی است';
    if (mobile.length != 11 || !mobile.startsWith('09')) {
      return 'شماره موبایل باید ۱۱ رقمی و با ۰۹ شروع شود';
    }
    return null;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.center),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
