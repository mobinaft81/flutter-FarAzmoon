// lib/screens/admin/import_excel_screen.dart
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:fetrati_farazmoon/services/excel_service.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../../services/pocketbase_service.dart';

String _generateAccessCode() {
  final random = Random();
  return (100000 + random.nextInt(900000)).toString();
}

class ImportExcelScreen extends StatefulWidget {
  const ImportExcelScreen({super.key});

  @override
  State<ImportExcelScreen> createState() => _ImportExcelScreenState();
}

class _ImportExcelScreenState extends State<ImportExcelScreen> {
  List<Map<String, dynamic>> parsed = [];
  List<String> errors = [];
  final ExcelService _excel = ExcelService();
  bool loading = false;
  final _title = TextEditingController();

  bool _isPublic = false;

  Future<void> pickFile() async {
    setState(() {
      loading = true;
      parsed.clear();
      errors.clear();
    });

    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (res == null || res.files.isEmpty) {
      setState(() => loading = false);
      return;
    }

    final file = res.files.single;
    Uint8List bytes;

    if (file.bytes != null) {
      bytes = file.bytes!;
    } else if (file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    } else {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('خطا در خواندن فایل')));
      return;
    }

    try {
      parsed = await _excel.parseExcel(bytes);
      errors = _excel.validateParsed(parsed);
    } catch (e) {
      errors = ['خطا در خواندن فایل اکسل: $e'];
    }

    setState(() => loading = false);
  }

  Future<void> saveAsTest() async {
    if (parsed.isEmpty || errors.isNotEmpty) return;

    setState(() => loading = true);

    try {
      final String? currentAdminId = PocketBaseService.pb.authStore.model?.id;

      if (currentAdminId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا: ادمین لاگین نشده است'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => loading = false);
        return;
      }

      final List<Map<String, dynamic>> questions = parsed.map((p) {
        final List<String> optionsList =
            (p['options'] as List?)
                ?.map((e) => e?.toString().trim() ?? '')
                .where((e) => e.isNotEmpty)
                .toList() ??
            [];

        return {
          'id': const Uuid().v4(),
          'text': p['question']?.toString().trim() ?? 'بدون متن',
          'options': optionsList,
          'correct_index':
              ((p['correctIndex'] as num?)?.toInt() ?? 1), // 1-based to 0-based
        };
      }).toList();

      final body = {
        'title': _title.text.isEmpty
            ? 'آزمون وارد شده از اکسل'
            : _title.text.trim(),
        'description': 'وارد شده از فایل اکسل',
        'duration_minutes': 30, // مقدار پیش‌فرض — خطا رو حل می‌کنه
        'questions_data': jsonEncode(questions),
        'access_code': _generateAccessCode(),
        'is_public': _isPublic,
        'created_by': currentAdminId,
      };

      await PocketBaseService.pb.collection('tests').create(body: body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('آزمون با موفقیت از اکسل ذخیره شد!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ذخیره: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget _buildField(TextEditingController controller, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xff2D3748) : Colors.white;
    final borderColor = isDark ? const Color(0xff00D4FF) : Colors.grey.shade300;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        textDirection: TextDirection.rtl,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontFamily: 'SB', fontSize: 15),
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
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? const Color.fromARGB(255, 2, 122, 146)
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

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                height: 60,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'وارد کردن از اکسل',
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
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xff2A2A2A)
                              : const Color.fromARGB(255, 255, 241, 184),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDark ? 0.3 : 0.05,
                              ),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📘 راهنمای فرمت فایل اکسل',
                              style: TextStyle(
                                fontFamily: 'SB',
                                fontSize: 15,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'فایل اکسل باید شامل ستون‌های زیر باشد:',
                              style: TextStyle(
                                fontFamily: 'dana',
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '• question → متن سؤال\n'
                              '• option1 → گزینه اول\n'
                              '• option2 → گزینه دوم\n'
                              '• option3 → گزینه سوم\n'
                              '• option4 → گزینه چهارم\n'
                              '• correctIndex → شماره گزینه درست (از 1 تا 4)\n'
                              '• explanation → (اختیاری) توضیح سؤال',
                              style: TextStyle(
                                fontFamily: 'dana',
                                fontSize: 13,
                                height: 1.6,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'مثال:\nquestion | option1 | option2 | option3 | option4 | correctIndex',
                              style: TextStyle(
                                fontFamily: 'dana',
                                fontSize: 12,
                                color: primaryColor.withOpacity(0.8),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),

                      _buildField(_title, 'عنوان آزمون (اختیاری)'),

                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDark ? 0.3 : 0.08,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CheckboxListTile(
                          title: Text(
                            'آزمون عمومی باشد',
                            style: TextStyle(
                              fontFamily: 'SB',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          subtitle: Text(
                            _isPublic
                                ? 'همه می‌توانند بدون کد وارد شوند'
                                : 'فقط با کد دسترسی قابل ورود است',
                            style: const TextStyle(fontSize: 13),
                          ),
                          value: _isPublic,
                          activeColor: const Color(0xff43A047),
                          onChanged: (val) =>
                              setState(() => _isPublic = val ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),

                      const SizedBox(height: 24),

                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 32,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 8,
                        ),
                        icon: const Icon(
                          Icons.attach_file,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'انتخاب فایل اکسل',
                          style: TextStyle(
                            fontFamily: 'SB',
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: pickFile,
                      ),

                      const SizedBox(height: 20),
                      if (loading)
                        const Center(child: CircularProgressIndicator()),

                      if (errors.isNotEmpty) ...[
                        Text(
                          'خطاهای فایل:',
                          style: TextStyle(
                            color: Colors.red[400],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        ...errors.map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              '• $e',
                              style: TextStyle(
                                color: Colors.redAccent[700],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],

                      if (parsed.isNotEmpty && errors.isEmpty)
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  isDark ? 0.3 : 0.1,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'پیش‌نمایش سوالات (${parsed.length} سوال)',
                                style: TextStyle(
                                  fontFamily: 'SB',
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: parsed.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 30),
                                itemBuilder: (_, i) {
                                  final p = parsed[i];
                                  final question =
                                      p['question']?.toString().trim() ??
                                      'بدون متن';
                                  final options = (p['options'] as List)
                                      .map((e) => e.toString().trim())
                                      .toList();
                                  final correctIndexInDb =
                                      ((p['correctIndex'] as num?)?.toInt() ??
                                      1);

                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xff2A2A2A)
                                          : Colors.grey[50],
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.grey[700]!
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: primaryColor,
                                              child: Text(
                                                '${i + 1}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                question,
                                                style: TextStyle(
                                                  fontFamily: 'SB',
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                  color: primaryColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        ...options.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final text = entry.value;
                                          final isCorrect =
                                              index == correctIndexInDb;
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 6,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  isCorrect
                                                      ? Icons.check_circle
                                                      : Icons
                                                            .radio_button_unchecked,
                                                  color: isCorrect
                                                      ? Colors.green
                                                      : Colors.grey,
                                                  size: 24,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    'گزینه ${index + 1}: $text',
                                                    style: TextStyle(
                                                      fontFamily: 'dana',
                                                      fontSize: 15,
                                                      color: isCorrect
                                                          ? (isDark
                                                                ? Colors
                                                                      .green[300]
                                                                : Colors
                                                                      .green[800])
                                                          : (isDark
                                                                ? Colors.white70
                                                                : Colors
                                                                      .black87),
                                                      fontWeight: isCorrect
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 30),

                      ElevatedButton(
                        onPressed: parsed.isNotEmpty && errors.isEmpty
                            ? saveAsTest
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff43A047),
                          disabledBackgroundColor: Colors.grey.shade400,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 60,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 8,
                        ),
                        child: const Text(
                          'ذخیره آزمون در فرازمون',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontFamily: 'SB',
                          ),
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
}
