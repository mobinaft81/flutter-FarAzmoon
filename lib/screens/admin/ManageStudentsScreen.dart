// lib/screens/admin/manage_students_screen.dart
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../services/pocketbase_service.dart';

class ManageStudentsScreen extends StatefulWidget {
  final String testId;
  final String testTitle;

  const ManageStudentsScreen({
    required this.testId,
    required this.testTitle,
    super.key,
  });

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  List<RecordModel> _students = [];
  bool _loading = true;

  final _codeCtrl = TextEditingController(); // کد ملی
  final _studentIdCtrl = TextEditingController(); // کد دانشجویی
  final _nameCtrl = TextEditingController(); // نام

  Color primaryColor = const Color(
    0xff1A237E,
  ); // مقدار اولیه برای جلوگیری از LateError

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _studentIdCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _loading = true);
    try {
      final result = await PocketBaseService.pb
          .collection('allowed_students')
          .getList(filter: 'test_id = "${widget.testId}"', sort: '-created');

      setState(() {
        _students = result.items;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _addStudent() async {
    final nationalCode = _codeCtrl.text.trim();
    final studentId = _studentIdCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    // چک کد ملی
    if (nationalCode.isEmpty ||
        nationalCode.length != 10 ||
        !RegExp(r'^\d+$').hasMatch(nationalCode)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('کد ملی باید ۱۰ رقم عددی باشد'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // چک کد دانشجویی
    if (studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('کد دانشجویی الزامی است'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // چک تکراری کد ملی
      final existingNational = await PocketBaseService.pb
          .collection('allowed_students')
          .getList(
            filter:
                'test_id = "${widget.testId}" && student_code = "$nationalCode"',
          );

      if (existingNational.items.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('این کد ملی قبلاً در این آزمون اضافه شده است'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // چک تکراری کد دانشجویی
      final existingStudentId = await PocketBaseService.pb
          .collection('allowed_students')
          .getList(
            filter: 'test_id = "${widget.testId}" && student_id = "$studentId"',
          );

      if (existingStudentId.items.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('این کد دانشجویی قبلاً در این آزمون اضافه شده است'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // چک تکراری نام (اگر وارد شده باشد)
      if (name.isNotEmpty) {
        final existingName = await PocketBaseService.pb
            .collection('allowed_students')
            .getList(
              filter: 'test_id = "${widget.testId}" && student_name = "$name"',
            );

        if (existingName.items.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('این نام قبلاً در این آزمون اضافه شده است'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      // افزودن دانش‌آموز
      await PocketBaseService.pb
          .collection('allowed_students')
          .create(
            body: {
              'test_id': widget.testId,
              'student_code': nationalCode,
              'student_id': studentId,
              'student_name': name,
            },
          );

      _codeCtrl.clear();
      _studentIdCtrl.clear();
      _nameCtrl.clear();
      _loadStudents();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('دانش‌آموز/دانشجو با موفقیت اضافه شد'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در افزودن: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteStudent(String id) async {
    try {
      await PocketBaseService.pb.collection('allowed_students').delete(id);
      _loadStudents();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('دانش‌آموز/دانشجو حذف شد'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در حذف: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xff2D3748) : Colors.white;
    final borderColor = isDark ? const Color(0xff00D4FF) : Colors.grey.shade300;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textAlign: TextAlign.center,
      maxLength: maxLength,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: maxLength == 10 ? '۱۰ رقم' : null,
        counterText: '',
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Color(0xff00D4FF), width: 2.5),
        ),
        prefixIcon: Icon(
          label.contains('کد ملی')
              ? Icons.badge
              : label.contains('کد دانشجویی')
              ? Icons.vpn_key
              : Icons.person_outline,
          color: primaryColor,
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    primaryColor = isDark
        ? const Color(0xff00D4FF)
        : const Color(0xff1A237E); // اینجا مقداردهی می‌شه
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

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
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
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        'افراد مجاز - ${widget.testTitle}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'SB',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset('assets/images/logo.png', width: 44),
                    ),
                  ],
                ),
              ),

              // فرم افزودن دانش‌آموز
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Card(
                  color: cardBg,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        _textField(
                          _codeCtrl,
                          'کد ملی',
                          keyboardType: TextInputType.number,
                          maxLength: 10,
                        ),
                        const SizedBox(height: 16),
                        _textField(_studentIdCtrl, 'کد دانشجویی (اجباری)'),
                        const SizedBox(height: 16),
                        _textField(_nameCtrl, 'نام و نام خانوادگی (اختیاری)'),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton.icon(
                            onPressed: _addStudent,
                            icon: const Icon(Icons.person_add_alt_1, size: 25),
                            label: const Text(
                              'افزودن دانش‌آموز/دانشجو',
                              style: TextStyle(fontFamily: 'SB', fontSize: 15),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // لیست دانش‌آموزان
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _students.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_alt_outlined,
                              size: 80,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'هنوز دانش‌آموز/دانشجویی اضافه نشده',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        itemCount: _students.length,
                        itemBuilder: (context, i) {
                          final s = _students[i];
                          final studentName =
                              (s.data['student_name']?.toString().trim() ?? '')
                                  .isEmpty
                              ? 'نام ثبت نشده'
                              : s.data['student_name'];
                          final studentId =
                              s.data['student_id']?.toString().trim() ??
                              'ثبت نشده';

                          return Card(
                            color: cardBg,
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.green[100],
                                child: Text(
                                  studentName[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                              title: Text(
                                'کد ملی: ${s.data['student_code'] ?? 'نامشخص'}',
                                style: TextStyle(
                                  fontFamily: 'SB',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('کد دانشجویی: $studentId'),
                                  const SizedBox(height: 4),
                                  Text(
                                    studentName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: studentName != 'نام ثبت نشده'
                                          ? (isDark
                                                ? Colors.white70
                                                : Colors.black87)
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_forever,
                                  color: Colors.redAccent,
                                  size: 30,
                                ),
                                onPressed: () => _deleteStudent(s.id),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
