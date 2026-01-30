// lib/screens/admin/view_results_screen.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:universal_html/html.dart' as html;
import 'package:pocketbase/pocketbase.dart';

import 'statistics_screen.dart';
import 'user_answers_screen.dart';
import '../../services/pocketbase_service.dart';
import 'dart:io' show File, Platform, Process;

class ViewResultsScreen extends StatefulWidget {
  final String testId;
  final String testTitle;

  const ViewResultsScreen({
    required this.testId,
    required this.testTitle,
    super.key,
  });

  @override
  State<ViewResultsScreen> createState() => _ViewResultsScreenState();
}

class _ViewResultsScreenState extends State<ViewResultsScreen> {
  List<RecordModel> _attempts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAttempts();
  }

  Future<void> _loadAttempts() async {
    setState(() => _loading = true);
    try {
      final result = await PocketBaseService.pb
          .collection('attempts')
          .getList(
            filter: 'test_id = "${widget.testId}"',
            sort: '-submitted_at,-created',
          );

      setState(() {
        _attempts = result.items;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری نتایج: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _exportToExcel() async {
    if (_attempts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('هیچ نتیجه‌ای برای خروجی وجود ندارد'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final excel = Excel.createExcel();
      final sheet = excel['نتایج آزمون'];
      excel.setDefaultSheet('نتایج آزمون');

      sheet.appendRow([
        TextCellValue('ردیف'),
        TextCellValue('نام شرکت‌کننده'),
        TextCellValue('کد ملی'),
        TextCellValue('شماره تماس'),
        TextCellValue('نمره'),
      ]);

      for (int i = 0; i < _attempts.length; i++) {
        final a = _attempts[i];
        final name = (a.data['student_name']?.toString().trim() ?? '').isEmpty
            ? 'مهمان'
            : a.data['student_name'];
        final code = (a.data['student_code']?.toString().trim() ?? '');
        final mobile = (a.data['participant_mobile']?.toString().trim() ?? '');
        final score = (a.data['score'] as num?)?.toInt() ?? 0;

        sheet.appendRow([
          TextCellValue('${i + 1}'),
          TextCellValue(name),
          TextCellValue(code.isEmpty ? '-' : code),
          TextCellValue(mobile.isEmpty ? '-' : mobile),
          IntCellValue(score),
        ]);
      }

      // تبدیل به Uint8List
      final List<int>? encodedList = excel.encode();
      if (encodedList == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا در ساخت فایل اکسل'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final Uint8List bytes = Uint8List.fromList(encodedList);

      final safeTitle = widget.testTitle.replaceAll(
        RegExp(r'[<>:"/\\|?*]'),
        '_',
      );
      final defaultFileName =
          'نتایج_${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      // === وب ===
      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', defaultFileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('دانلود فایل اکسل شروع شد'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

      // === اندروید، iOS، ویندوز، مک، لینوکس ===
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'ذخیره فایل اکسل نتایج آزمون',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: bytes, // همیشه bytes رو بفرست (مهم‌ترین تغییر)
      );

      if (outputFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ذخیره فایل لغو شد'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // برای دسکتاپ (ویندوز/مک/لینوکس) اگر file_picker خودش ذخیره نکرد، دستی بنویس
      if (!Platform.isAndroid && !Platform.isIOS) {
        try {
          final file = File(outputFile);
          await file.create(recursive: true); // مطمئن شو مسیر وجود داره
          await file.writeAsBytes(bytes);
          print('فایل دستی ذخیره شد در: $outputFile');
        } catch (writeError) {
          print('خطا در نوشتن دستی فایل: $writeError');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطا در ذخیره فایل: $writeError'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // پیام موفقیت
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('فایل اکسل با موفقیت ذخیره شد'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 8),
          action: Platform.isWindows
              ? SnackBarAction(
                  label: 'باز کردن پوشه',
                  textColor: Colors.white,
                  onPressed: () {
                    final directory = File(outputFile).parent;
                    Process.run('explorer', [directory.path]);
                  },
                )
              : null,
        ),
      );
    } catch (e, stack) {
      print('خطا در خروجی اکسل: $e\n$stack');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در ساخت یا ذخیره فایل: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
            colors: [Color.fromARGB(255, 206, 225, 248), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    final titleColor = isDark ? Colors.white : const Color(0xff1A237E);
    final subtitleColor = isDark ? Colors.white70 : Colors.grey[800];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                height: 60,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    Expanded(
                      child: Text(
                        'نتایج آزمون',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'SB',
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset('assets/images/logo.png', width: 50),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Text(
                  widget.testTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 62,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [Color(0xff0288D1), Color(0xff81D4FA)]
                            : [Color(0xff42A5F5), Color(0xff90CAF9)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _attempts.isEmpty
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StatisticsScreen(
                                  testId: widget.testId,
                                  testTitle: widget.testTitle,
                                ),
                              ),
                            ),
                      icon: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.bar_chart_rounded,
                          color: primaryColor,
                          size: 26,
                        ),
                      ),
                      label: const Text(
                        'میانگین نتایج و آمار سوالات',
                        style: TextStyle(
                          fontFamily: 'SB',
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        disabledBackgroundColor: Colors.grey[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 62,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [Color(0xff2E7D32), Color(0xff81C784)]
                            : [Color(0xff66BB6A), Color(0xffA5D6A7)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isDark ? Color(0xff2E7D32) : Color(0xff66BB6A))
                                  .withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _attempts.isEmpty ? null : _exportToExcel,
                      icon: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.download_rounded,
                          color: isDark ? Color(0xff2E7D32) : Color(0xff388E3C),
                          size: 26,
                        ),
                      ),
                      label: const Text(
                        'خروجی اکسل نتایج',
                        style: TextStyle(
                          fontFamily: 'SB',
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        disabledBackgroundColor: Colors.grey[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: _loading
                    ? Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      )
                    : _attempts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sentiment_dissatisfied,
                              size: 80,
                              color: isDark ? Colors.white60 : Colors.grey[600],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'هنوز کسی آزمون نداده',
                              style: TextStyle(
                                fontSize: 18,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _attempts.length,
                        itemBuilder: (context, i) {
                          final a = _attempts[i];
                          final name =
                              (a.data['student_name']?.toString().trim() ?? '')
                                  .isEmpty
                              ? 'مهمان'
                              : a.data['student_name'];
                          final code =
                              (a.data['student_code']?.toString().trim() ?? '');
                          final score = (a.data['score'] as num?)?.toInt() ?? 0;

                          DateTime date = DateTime.parse(a.created);
                          final submittedAtStr =
                              a.data['submitted_at'] as String?;
                          if (submittedAtStr != null &&
                              submittedAtStr.isNotEmpty) {
                            try {
                              date = DateTime.parse(submittedAtStr);
                            } catch (e) {}
                          }

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
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
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              leading: CircleAvatar(
                                radius: 26,
                                backgroundColor: isDark
                                    ? primaryColor.withOpacity(0.3)
                                    : Colors.green[100],
                                child: Text(
                                  name[0].toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: 'SB',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                              title: Text(
                                name,
                                style: TextStyle(
                                  fontFamily: 'SB',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: titleColor,
                                ),
                              ),
                              subtitle: Text(
                                'کد ملی: ${code.isEmpty ? 'نامشخص' : code}\nنمره: $score | ${intl.DateFormat('yyyy/MM/dd – HH:mm').format(date)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: subtitleColor,
                                ),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                color: primaryColor,
                                size: 20,
                              ),
                              onTap: () async {
                                try {
                                  final testRecord = await PocketBaseService.pb
                                      .collection('tests')
                                      .getOne(widget.testId);
                                  if (!mounted) return;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UserAnswersScreen(
                                        attemptRecord: a,
                                        testRecord: testRecord,
                                        studentName:
                                            '$name${code.isNotEmpty ? ' ($code)' : ''}',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('خطا: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
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
