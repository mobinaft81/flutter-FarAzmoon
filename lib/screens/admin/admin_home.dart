// lib/screens/admin/admin_home.dart
import 'package:fetrati_farazmoon/screens/admin/ManageStudentsScreen.dart';
import 'package:fetrati_farazmoon/screens/admin/admin_profile_screen.dart';
import 'package:fetrati_farazmoon/screens/admin/create_test_screen.dart';
import 'package:fetrati_farazmoon/screens/admin/import_excel_screen.dart';
import 'package:fetrati_farazmoon/screens/admin/view_results_screen.dart';
import 'package:fetrati_farazmoon/screens/share_test_screen.dart';
import 'package:fetrati_farazmoon/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:universal_html/html.dart' as html show window;
import 'package:pocketbase/pocketbase.dart';

import '../../services/pocketbase_service.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  List<RecordModel> _tests = [];
  bool _loading = true;
  bool showContent = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    if (!PocketBaseService.isAdminLoggedIn()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      });
      return;
    }

    _loadTests();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeDialog();
    });
  }

  void _showWelcomeDialog() {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? const Color(0xff00D4FF)
        : const Color(0xff1A237E);
    final cardBg = isDark ? const Color(0xff1E1E1E) : Colors.white;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: cardBg,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school, size: 64, color: primaryColor),
            const SizedBox(height: 16),
            Text(
              'به پنل مدیریت فرازمون خوش آمدید',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SB',
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => showContent = true);
            },
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            label: const Text(
              'ورود به پنل',
              style: TextStyle(fontFamily: 'SB', color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadTests() async {
    setState(() => _loading = true);

    try {
      final String? adminId = PocketBaseService.pb.authStore.model?.id;

      if (adminId == null) {
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
        return;
      }

      final result = await PocketBaseService.pb
          .collection('tests')
          .getList(filter: 'created_by = "$adminId"', sort: '-created');

      if (mounted) {
        setState(() {
          _tests = result.items;
          _loading = false;
        });
      }
    } catch (e) {
      print('خطا در بارگذاری آزمون‌ها: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری آزمون‌ها: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _loading = false);
      }
    }
  }

  String _formatPersianDate(String isoString) {
    if (isoString.isEmpty) return 'نامشخص';
    try {
      final date = DateTime.parse(isoString).toLocal();
      final j = Jalali.fromDateTime(date).formatter;
      return '${j.d} ${j.mN} ${j.yyyy} - ${date.hour.toString().padLeft(2, '۰')}:${date.minute.toString().padLeft(2, '۰')}';
    } catch (e) {
      return 'نامشخص';
    }
  }

  String _toPersianNumber(int number) {
    const fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    return number.toString().split('').map((d) => fa[int.parse(d)]).join();
  }

  List<pw.TextSpan> buildMixedText(
    String text,
    pw.Font fontFa,
    pw.Font fontEn,
  ) {
    final spans = <pw.TextSpan>[];
    final regex = RegExp(r'([a-zA-Z0-9_]+|[().]+)');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(
          pw.TextSpan(
            text: text.substring(lastIndex, match.start),
            style: pw.TextStyle(font: fontFa, fontSize: 14),
          ),
        );
      }
      final matchedText = match.group(0)!;
      spans.add(
        pw.TextSpan(
          text: matchedText,
          style: pw.TextStyle(font: fontEn, fontSize: 14),
        ),
      );
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(
        pw.TextSpan(
          text: text.substring(lastIndex),
          style: pw.TextStyle(font: fontFa, fontSize: 14),
        ),
      );
    }

    return spans;
  }

  Future<void> _exportTestToPdf(RecordModel test) async {
    try {
      final fontFa = pw.Font.ttf(
        await rootBundle.load("assets/fonts/NotoNaskhArabic-Regular.ttf"),
      );
      final fontEn = fontFa;

      final pdf = pw.Document();

      final questions =
          (test.data['questions_data'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];

      pdf.addPage(
        pw.MultiPage(
          pageFormat: const PdfPageFormat(
            210 * PdfPageFormat.mm,
            297 * PdfPageFormat.mm,
          ),
          margin: const pw.EdgeInsets.all(40),
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: fontFa),
          header: (_) => pw.Center(
            child: pw.Text(
              test.data['title'] ?? 'آزمون',
              style: pw.TextStyle(
                font: fontFa,
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          build: (_) => [
            pw.SizedBox(height: 20),
            pw.Text(
              'مدت زمان: ${test.data['duration_minutes'] ?? 10} دقیقه',
              style: pw.TextStyle(font: fontFa, fontSize: 14),
            ),
            pw.Text(
              'تعداد سوالات: ${questions.length}',
              style: pw.TextStyle(font: fontFa, fontSize: 14),
            ),
            pw.Text(
              'تاریخ ساخت: ${_formatPersianDate(test.created)}',
              style: pw.TextStyle(font: fontFa, fontSize: 14),
            ),
            pw.Divider(height: 30),
            ...questions.asMap().entries.map((e) {
              final i = e.key + 1;
              final q = e.value;
              final options = (q['options'] as List?)?.cast<String>() ?? [];

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'سؤال ${_toPersianNumber(i)}: ',
                        style: pw.TextStyle(
                          font: fontFa,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.RichText(
                          textDirection: pw.TextDirection.rtl,
                          text: pw.TextSpan(
                            children: buildMixedText(
                              q['text'] ?? '',
                              fontFa,
                              fontEn,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  ...options.asMap().entries.map((opt) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(right: 30, bottom: 8),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            ' .${_toPersianNumber(opt.key + 1)}',
                            style: pw.TextStyle(font: fontFa, fontSize: 14),
                          ),
                          pw.Expanded(
                            child: pw.RichText(
                              textDirection: pw.TextDirection.rtl,
                              text: pw.TextSpan(
                                children: buildMixedText(
                                  opt.value,
                                  fontFa,
                                  fontEn,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  pw.SizedBox(height: 20),
                ],
              );
            }),
          ],
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename:
            'آزمون_${(test.data['title'] ?? 'بدون_عنوان').replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ساخت PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'خروج',
          style: TextStyle(fontFamily: 'SB', fontWeight: FontWeight.bold),
        ),
        content: const Text('آیا مطمئن هستید که می‌خواهید خارج شوید؟'),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('خیر', style: TextStyle(fontFamily: 'SB')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'بله، خارج شو',
              style: TextStyle(fontFamily: 'SB', color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      PocketBaseService.logoutAdmin();
      if (kIsWeb) {
        html.window.location.reload();
      } else {
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      }
    }
  }

  Widget _fancyButton(
    IconData icon,
    String label,
    Color c1,
    Color c2,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [c1, c2]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: c1.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 48),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'SB',
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenu(String value, RecordModel test) async {
    switch (value) {
      case 'results':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ViewResultsScreen(
              testId: test.id,
              testTitle: test.data['title'] ?? 'آزمون',
            ),
          ),
        );
        break;
      case 'students':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ManageStudentsScreen(
              testId: test.id,
              testTitle: test.data['title'] ?? '',
            ),
          ),
        );
        break;
      case 'edit':
        final updated = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateTestScreen(editTestRecord: test),
          ),
        );
        if (updated == true) _loadTests();
        break;
      case 'share':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => ShareTestScreen(testId: test.id),
        );
        break;
      case 'exportPdf':
        await _exportTestToPdf(test);
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'حذف آزمون',
              style: TextStyle(
                fontFamily: 'SB',
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            content: const Text(
              'آیا مطمئن هستید که می‌خواهید این آزمون را برای همیشه حذف کنید؟\n\nتمام افراد مجاز و نتایج هم حذف خواهند شد.',
              style: TextStyle(fontFamily: 'SM'),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'خیر، لغو کن',
                  style: TextStyle(fontFamily: 'SB'),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'بله، حذف کن',
                  style: TextStyle(fontFamily: 'SB', color: Colors.white),
                ),
              ),
            ],
          ),
        );

        if (confirm == true) {
          try {
            final attemptsRes = await PocketBaseService.pb
                .collection('attempts')
                .getList(filter: 'test_id = "${test.id}"');
            for (var a in attemptsRes.items) {
              await PocketBaseService.pb.collection('attempts').delete(a.id);
            }

            final allowedRes = await PocketBaseService.pb
                .collection('allowed_students')
                .getList(filter: 'test_id = "${test.id}"');
            for (var s in allowedRes.items) {
              await PocketBaseService.pb
                  .collection('allowed_students')
                  .delete(s.id);
            }

            await PocketBaseService.pb.collection('tests').delete(test.id);

            _loadTests();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('آزمون و تمام داده‌های مرتبط حذف شد'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('خطا در حذف: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
        break;
    }
  }

  Widget _buildContent() {
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

    return Container(
      decoration: BoxDecoration(gradient: backgroundGradient),
      child: Column(
        children: [
          Container(
            height: 50,
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
                  onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                  child: Icon(Icons.menu, color: primaryColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'پنل مدیریت ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SB',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _fancyButton(
                          Icons.add_circle_outline,
                          "ایجاد آزمون جدید",
                          const Color(0xff7986CB),
                          const Color(0xff3949AB),
                          () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreateTestScreen(),
                              ),
                            );
                            if (updated == true) _loadTests();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _fancyButton(
                          Icons.file_upload,
                          "وارد کردن از اکسل",
                          const Color(0xff66BB6A),
                          const Color(0xff43A047),
                          () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ImportExcelScreen(),
                              ),
                            );
                            if (updated == true) _loadTests();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _tests.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.hourglass_empty,
                                size: 80,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'هیچ آزمونی ساخته نشده',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'با دکمه‌های بالا شروع کنید',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _tests.length,
                          itemBuilder: (_, i) {
                            final t = _tests[i];
                            final qCount =
                                (t.data['questions_data'] as List?)?.length ??
                                0;

                            return Card(
                              color: cardBg,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 6,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: primaryColor,
                                  child: const Icon(
                                    Icons.quiz,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  t.data['title'] ?? 'بدون عنوان',
                                  style: const TextStyle(
                                    fontFamily: 'SB',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  "سوالات: $qCount | زمان: ${t.data['duration_minutes'] ?? 10} دقیقه | ساخت: ${_formatPersianDate(t.created)}",
                                  style: const TextStyle(fontSize: 13),
                                ),
                                trailing: PopupMenuButton<String>(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ), // گوشه‌های گرد منو
                                  elevation: 8,
                                  color: cardBg,
                                  onSelected: (v) => _handleMenu(v, t),
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'share',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.share,
                                            color: primaryColor,
                                          ),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'اشتراک‌گذاری',
                                            style: TextStyle(fontFamily: 'SB'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'students',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.people,
                                            color: primaryColor,
                                          ),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'افراد مجاز',
                                            style: TextStyle(fontFamily: 'SB'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.edit,
                                            color: Colors.orange,
                                          ),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'ویرایش',
                                            style: TextStyle(fontFamily: 'SB'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'results',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.bar_chart,
                                            color: Colors.green,
                                          ),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'نتایج',
                                            style: TextStyle(fontFamily: 'SB'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'exportPdf',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.picture_as_pdf,
                                            color: Colors.red,
                                          ),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'خروجی PDF',
                                            style: TextStyle(fontFamily: 'SB'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.delete_forever,
                                            color: Colors.red,
                                          ),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'حذف',
                                            style: TextStyle(
                                              fontFamily: 'SB',
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? const Color(0xff00D4FF)
        : const Color(0xff1A237E);
    final drawerBg = isDark ? const Color(0xff1E1E1E) : Colors.white;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.6,
        backgroundColor: drawerBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            bottomLeft: Radius.circular(30),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: Icon(
                    Provider.of<ThemeService>(context).themeMode ==
                            ThemeMode.dark
                        ? Icons.dark_mode
                        : Provider.of<ThemeService>(context).themeMode ==
                              ThemeMode.light
                        ? Icons.light_mode
                        : Icons.brightness_auto,
                    color: primaryColor,
                    size: 25,
                  ),
                  title: const Text(
                    'حالت نمایش',
                    style: TextStyle(fontFamily: 'SB', fontSize: 15),
                  ),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(25),
                        ),
                      ),
                      builder: (ctx) => SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'انتخاب حالت نمایش',
                                style: TextStyle(
                                  fontFamily: 'SB',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ListTile(
                                leading: const Icon(Icons.light_mode),
                                title: const Text('روشن'),
                                onTap: () {
                                  Provider.of<ThemeService>(
                                    context,
                                    listen: false,
                                  ).setThemeMode(ThemeMode.light);
                                  Navigator.pop(ctx);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.dark_mode),
                                title: const Text('تیره'),
                                onTap: () {
                                  Provider.of<ThemeService>(
                                    context,
                                    listen: false,
                                  ).setThemeMode(ThemeMode.dark);
                                  Navigator.pop(ctx);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.brightness_auto),
                                title: const Text('تطبیقی با سیستم'),
                                onTap: () {
                                  Provider.of<ThemeService>(
                                    context,
                                    listen: false,
                                  ).setThemeMode(ThemeMode.system);
                                  Navigator.pop(ctx);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const Divider(height: 10, thickness: 1),
                ListTile(
                  leading: Icon(
                    Icons.account_circle_outlined,
                    size: 28,
                    color: primaryColor,
                  ),
                  title: const Text(
                    'حساب کاربری',
                    style: TextStyle(fontFamily: 'SB', fontSize: 17),
                  ),
                  onTap: () {
                    _scaffoldKey.currentState?.closeEndDrawer();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminProfileScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.logout,
                    size: 25,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'خروج از حساب',
                    style: TextStyle(
                      fontFamily: 'SB',
                      fontSize: 15,
                      color: Colors.red,
                    ),
                  ),
                  onTap: () {
                    _scaffoldKey.currentState?.closeEndDrawer();
                    _logout(context);
                  },
                ),

                const Spacer(),
                Center(
                  child: Text(
                    'فرآزمون v1.0',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: showContent
            ? _buildContent()
            : const Center(
                child: CircularProgressIndicator(color: Color(0xff1A237E)),
              ),
      ),
    );
  }
}
