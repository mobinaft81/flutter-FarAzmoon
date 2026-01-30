// // lib/screens/user/take_test_screen.dart
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:uuid/uuid.dart';
// import 'package:pocketbase/pocketbase.dart';

// import '../../services/pocketbase_service.dart';
// import 'user_home.dart';

// class TakeTestScreen extends StatefulWidget {
//   final String testId;
//   final String? studentCode;
//   final String? studentName;
//   final String? guestId;
//   final String? guestName;

//   const TakeTestScreen({
//     required this.testId,
//     this.studentCode,
//     this.studentName,
//     this.guestId,
//     this.guestName,
//     super.key,
//   });

//   @override
//   State<TakeTestScreen> createState() => _TakeTestScreenState();
// }

// class _TakeTestScreenState extends State<TakeTestScreen>
//     with SingleTickerProviderStateMixin {
//   RecordModel? _testRecord;
//   List<Map<String, dynamic>> _questions = [];
//   Map<int, int> _answers = {};
//   late int _remainingSeconds;
//   Timer? _timer;
//   bool _loading = true;
//   bool _isSubmitting = false;
//   String? _errorMessage;
//   String? _currentGuestId;

//   @override
//   void initState() {
//     super.initState();
//     _currentGuestId = widget.guestId ?? const Uuid().v4();
//     _loadTest();
//   }

//   // تابع امن برای تبدیل رشته تاریخ به DateTime (پشتیبانی از دو فرمت)
//   DateTime _safeParseDateTime(String dateStr) {
//     String trimmed = dateStr.trim();

//     // اول سعی کن فرمت استاندارد ISO (با T)
//     try {
//       return DateTime.parse(trimmed);
//     } catch (e) {
//       // اگر نشد، فرمت "YYYY-MM-DD HH:MM:SS" رو امتحان کن
//       final parts = trimmed.split(' ');
//       if (parts.length == 2) {
//         final datePart = parts[0];
//         final timePart = parts[1];

//         final dateParts = datePart.split('-');
//         final timeParts = timePart.split(':');

//         if (dateParts.length == 3 && timeParts.length == 3) {
//           return DateTime(
//             int.parse(dateParts[0]),
//             int.parse(dateParts[1]),
//             int.parse(dateParts[2]),
//             int.parse(timeParts[0]),
//             int.parse(timeParts[1]),
//             int.parse(timeParts[2]),
//           );
//         }
//       }
//       // اگر هیچ‌کدوم کار نکرد، زمان فعلی رو برگردون
//       return DateTime.now();
//     }
//   }

//   Future<void> _loadTest() async {
//     try {
//       final testRecord = await PocketBaseService.pb
//           .collection('tests')
//           .getOne(widget.testId);

//       final questionsList = testRecord.data['questions_data'] as List? ?? [];
//       final questions = questionsList.cast<Map<String, dynamic>>();

//       final DateTime now = DateTime.now();

//       final String? startStr = testRecord.data['start_at'];
//       final String? endStr = testRecord.data['end_at'];

//       // اگر زمان تنظیم نشده باشه → 30 دقیقه پیش‌فرض
//       if (startStr == null ||
//           startStr.trim().isEmpty ||
//           endStr == null ||
//           endStr.trim().isEmpty) {
//         _remainingSeconds = 30 * 60;
//       } else {
//         DateTime startAt;
//         DateTime endAt;

//         try {
//           startAt = _safeParseDateTime(startStr);
//           endAt = _safeParseDateTime(endStr);
//         } catch (e) {
//           _remainingSeconds = 30 * 60;
//           startAt = now;
//           endAt = now.add(const Duration(minutes: 30));
//         }

//         // چک شروع آزمون
//         if (now.isBefore(startAt)) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(
//                   'آزمون از ساعت ${startAt.hour.toString().padLeft(2, '0')}:${startAt.minute.toString().padLeft(2, '0')} شروع می‌شود',
//                 ),
//                 backgroundColor: Colors.orange,
//                 duration: const Duration(seconds: 6),
//               ),
//             );
//             Navigator.pop(context);
//           }
//           return;
//         }

//         // چک پایان آزمون
//         if (now.isAfter(endAt)) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text('زمان آزمون به پایان رسیده است'),
//                 backgroundColor: Colors.red,
//                 duration: Duration(seconds: 6),
//               ),
//             );
//             Navigator.pop(context);
//           }
//           return;
//         }

//         // زمان باقی‌مانده
//         _remainingSeconds = endAt.difference(now).inSeconds;
//         if (_remainingSeconds < 0) _remainingSeconds = 0;
//       }

//       if (mounted) {
//         setState(() {
//           _testRecord = testRecord;
//           _questions = questions;
//           _loading = false;
//         });
//       }

//       // شروع تایمر
//       _timer = Timer.periodic(const Duration(seconds: 1), (_) {
//         if (!mounted) return;
//         setState(() {
//           if (_remainingSeconds > 0) {
//             _remainingSeconds--;
//           } else {
//             _timer?.cancel();
//             _submitTest(auto: true);
//           }
//         });
//       });
//     } catch (e) {
//       print('خطا در بارگذاری آزمون: $e');
//       if (mounted) {
//         setState(() {
//           _loading = false;
//           _errorMessage = 'خطا در بارگذاری آزمون';
//         });
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }

//   int _calculateScore() {
//     int correct = 0;
//     for (int i = 0; i < _questions.length; i++) {
//       final q = _questions[i];
//       final selected = _answers[i];
//       final correctIndex = q['correct_index'] as int?;
//       if (selected != null && selected == correctIndex) correct++;
//     }
//     return correct;
//   }

//   Future<void> _submitTest({bool auto = false}) async {
//     if (_isSubmitting) return;
//     setState(() => _isSubmitting = true);
//     _timer?.cancel();

//     try {
//       final correctCount = _calculateScore();
//       final percentage = _questions.isEmpty
//           ? 0
//           : (correctCount / _questions.length) * 20;
//       final finalScore = percentage.round();

//       String participantName = 'مهمان';
//       String? participantMobile;
//       if (widget.guestName != null && widget.guestName!.contains(' (')) {
//         final parts = widget.guestName!.split(' (');
//         participantName = parts[0].trim();
//         participantMobile = parts[1].replaceAll(')', '').trim();
//       }

//       final Map<String, dynamic> answersJson = {};
//       _answers.forEach((key, value) => answersJson[key.toString()] = value);

//       final body = {
//         'test_id': widget.testId,
//         'student_code': widget.studentCode?.trim().isNotEmpty == true
//             ? widget.studentCode!.trim()
//             : null,
//         'student_name': widget.studentName?.trim().isNotEmpty == true
//             ? widget.studentName!.trim()
//             : participantName,
//         'guest_id': widget.studentCode == null ? _currentGuestId : null,
//         'participant_name': participantName.isEmpty ? 'مهمان' : participantName,
//         'participant_mobile': participantMobile,
//         'answers': answersJson,
//         'score': finalScore,
//         'submitted_at': DateTime.now().toIso8601String(),
//       };

//       await PocketBaseService.pb.collection('attempts').create(body: body);

//       if (!mounted) return;

//       final isDark = Theme.of(context).brightness == Brightness.dark;
//       final dialogBg = isDark ? const Color(0xff1E1E1E) : Colors.white;
//       final successColor = Colors.green[600]!;

//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (dialogContext) => PopScope(
//           canPop: false,
//           child: AlertDialog(
//             backgroundColor: dialogBg,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//             title: Text(
//               auto ? 'زمان به پایان رسید!' : 'آزمون با موفقیت ثبت شد!',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontFamily: 'SB',
//                 fontSize: 20,
//                 color: successColor,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(Icons.check_circle, size: 80, color: successColor),
//                 const SizedBox(height: 16),
//                 Text(
//                   'تعداد سوالات: ${_questions.length}',
//                   style: const TextStyle(fontFamily: 'SB'),
//                 ),
//                 Text(
//                   'درست: $correctCount',
//                   style: TextStyle(
//                     fontFamily: 'SB',
//                     color: successColor,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text(
//                   'غلط: ${_questions.length - correctCount}',
//                   style: TextStyle(fontFamily: 'SB', color: Colors.red[600]),
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   'نمره: $finalScore از ۲۰',
//                   style: TextStyle(
//                     fontFamily: 'SB',
//                     fontSize: 32,
//                     fontWeight: FontWeight.bold,
//                     color: finalScore >= 12 ? successColor : Colors.orange[700],
//                   ),
//                 ),
//               ],
//             ),
//             actions: [
//               Center(
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: successColor,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 40,
//                       vertical: 16,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                   ),
//                   onPressed: () {
//                     Navigator.of(dialogContext).pop();
//                     Navigator.of(context).pushAndRemoveUntil(
//                       MaterialPageRoute(
//                         builder: (_) => UserHome(
//                           studentCode: widget.studentCode,
//                           publicTestId: widget.studentCode == null
//                               ? widget.testId
//                               : null,
//                           guestId: widget.studentCode == null
//                               ? _currentGuestId
//                               : null,
//                           guestName: widget.guestName,
//                         ),
//                       ),
//                       (route) => false,
//                     );
//                   },
//                   child: const Text(
//                     'بازگشت به لیست آزمون‌ها',
//                     style: TextStyle(
//                       fontFamily: 'SB',
//                       color: Colors.white,
//                       fontSize: 16,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     } catch (e) {
//       print('خطا در ثبت آزمون: $e');
//       if (mounted) {
//         String errorMessage = 'خطا در ثبت نتیجه آزمون';
//         if (e.toString().contains('blank') ||
//             e.toString().contains('required')) {
//           errorMessage = 'لطفاً به همه سؤالات پاسخ دهید';
//         }
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(errorMessage, textAlign: TextAlign.center),
//             backgroundColor: Colors.red,
//             duration: const Duration(seconds: 6),
//           ),
//         );
//         setState(() => _isSubmitting = false);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final primaryColor = isDark
//         ? const Color(0xff00D4FF)
//         : const Color(0xff1A237E);
//     final cardBg = isDark ? const Color(0xff1E1E1E) : Colors.white;
//     final backgroundGradient = isDark
//         ? const LinearGradient(
//             colors: [Color(0xff0D1B2A), Color(0xff1B263B)],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           )
//         : const LinearGradient(
//             colors: [Color.fromARGB(255, 223, 235, 250), Colors.white],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           );

//     if (_loading) {
//       return Scaffold(
//         body: Container(
//           decoration: BoxDecoration(gradient: backgroundGradient),
//           child: const Center(child: CircularProgressIndicator()),
//         ),
//       );
//     }

//     if (_errorMessage != null || _questions.isEmpty) {
//       return Scaffold(
//         body: Container(
//           decoration: BoxDecoration(gradient: backgroundGradient),
//           child: Center(
//             child: Text(
//               _errorMessage ?? 'هیچ سوالی وجود ندارد',
//               style: const TextStyle(fontSize: 18, color: Colors.redAccent),
//             ),
//           ),
//         ),
//       );
//     }

//     final hours = _remainingSeconds ~/ 3600;
//     final minutes = (_remainingSeconds % 3600) ~/ 60;
//     final seconds = _remainingSeconds % 60;

//     return PopScope(
//       canPop: false,
//       child: Scaffold(
//         body: SafeArea(
//           child: Container(
//             decoration: BoxDecoration(gradient: backgroundGradient),
//             child: Column(
//               children: [
//                 Container(
//                   height: 60,
//                   margin: const EdgeInsets.all(16),
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   decoration: BoxDecoration(
//                     color: cardBg,
//                     borderRadius: BorderRadius.circular(20),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
//                         blurRadius: 12,
//                         offset: const Offset(0, 6),
//                       ),
//                     ],
//                   ),
//                   child: Row(
//                     children: [
//                       const SizedBox(width: 20),
//                       Expanded(
//                         child: Text(
//                           _testRecord?.data['title'] ?? 'آزمون',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             fontFamily: 'SB',
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: primaryColor,
//                           ),
//                         ),
//                       ),
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(12),
//                         child: Image.asset('assets/images/logo.png', width: 46),
//                       ),
//                       const SizedBox(width: 12),
//                     ],
//                   ),
//                 ),

//                 Container(
//                   margin: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 8,
//                   ),
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: isDark
//                         ? Colors.orange[900]
//                         : Colors.orangeAccent[100],
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(Icons.timer, color: Colors.orange[700], size: 28),
//                       const SizedBox(width: 12),
//                       Text(
//                         'زمان باقی‌مانده: ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
//                         style: TextStyle(
//                           fontFamily: 'SB',
//                           fontSize: 17,
//                           fontWeight: FontWeight.bold,
//                           color: isDark
//                               ? Colors.orange[300]
//                               : Colors.orange[800],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 12),

//                 Expanded(
//                   child: ListView.builder(
//                     physics: const BouncingScrollPhysics(),
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     itemCount: _questions.length,
//                     itemBuilder: (_, i) {
//                       final q = _questions[i];
//                       final options =
//                           (q['options'] as List?)?.cast<String>() ?? [];
//                       return Container(
//                         margin: const EdgeInsets.symmetric(vertical: 8),
//                         decoration: BoxDecoration(
//                           color: cardBg,
//                           borderRadius: BorderRadius.circular(20),
//                           border: Border.all(
//                             color: primaryColor.withOpacity(0.4),
//                             width: 2,
//                           ),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(
//                                 isDark ? 0.3 : 0.1,
//                               ),
//                               blurRadius: 8,
//                               offset: const Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(20),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 '${i + 1}. ${q['text']}',
//                                 style: TextStyle(
//                                   fontFamily: 'SB',
//                                   fontSize: 17,
//                                   fontWeight: FontWeight.bold,
//                                   color: primaryColor,
//                                 ),
//                               ),
//                               const SizedBox(height: 16),
//                               ...List.generate(
//                                 options.length,
//                                 (j) => RadioListTile<int>(
//                                   title: Text(
//                                     options[j],
//                                     style: TextStyle(
//                                       fontFamily: 'dana',
//                                       fontSize: 15,
//                                       color: isDark
//                                           ? Colors.white70
//                                           : Colors.black87,
//                                     ),
//                                   ),
//                                   value: j,
//                                   groupValue: _answers[i],
//                                   activeColor: Colors.green[600],
//                                   onChanged: (val) =>
//                                       setState(() => _answers[i] = val!),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),

//                 Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: SizedBox(
//                     width: double.infinity,
//                     height: 60,
//                     child: ElevatedButton(
//                       onPressed: _isSubmitting ? null : () => _submitTest(),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green[600],
//                         foregroundColor: Colors.white,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                         elevation: 8,
//                       ),
//                       child: Text(
//                         _isSubmitting ? 'در حال ثبت...' : 'ثبت و پایان آزمون',
//                         style: const TextStyle(fontFamily: 'SB', fontSize: 18),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
// lib/screens/user/take_test_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../services/pocketbase_service.dart';
import 'user_home.dart';

class TakeTestScreen extends StatefulWidget {
  final String testId;
  final String? studentCode;
  final String? studentName;
  final String? guestId;
  final String? guestName;

  const TakeTestScreen({
    required this.testId,
    this.studentCode,
    this.studentName,
    this.guestId,
    this.guestName,
    super.key,
  });

  @override
  State<TakeTestScreen> createState() => _TakeTestScreenState();
}

class _TakeTestScreenState extends State<TakeTestScreen>
    with SingleTickerProviderStateMixin {
  RecordModel? _testRecord;
  List<Map<String, dynamic>> _questions = [];
  Map<int, int> _answers = {};
  late int _remainingSeconds;
  Timer? _timer;
  bool _loading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _currentGuestId;

  @override
  void initState() {
    super.initState();
    _currentGuestId = widget.guestId ?? const Uuid().v4();
    _loadTest();
  }

  Future<void> _loadTest() async {
    try {
      final testRecord = await PocketBaseService.pb
          .collection('tests')
          .getOne(widget.testId);

      final questionsList = testRecord.data['questions_data'] as List? ?? [];
      final questions = questionsList.cast<Map<String, dynamic>>();

      if (mounted) {
        setState(() {
          _testRecord = testRecord;
          _questions = questions;
          _remainingSeconds =
              (testRecord.data['duration_minutes'] as num?)?.toInt() ?? 30;
          _remainingSeconds *= 60;
          _loading = false;
        });
      }

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _remainingSeconds--);
        if (_remainingSeconds <= 0) {
          _timer?.cancel();
          _submitTest(auto: true);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = e.toString();
        });
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int _calculateScore() {
    int correct = 0;
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final selected = _answers[i];
      final correctIndex = q['correct_index'] as int?;
      if (selected != null && selected == correctIndex) correct++;
    }
    return correct;
  }

  Future<void> _submitTest({bool auto = false}) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    _timer?.cancel();

    try {
      final correctCount = _calculateScore();
      final percentage = _questions.isEmpty
          ? 0
          : (correctCount / _questions.length) * 20;
      final finalScore = percentage.round();

      String participantName = 'مهمان';
      String? participantMobile;
      if (widget.guestName != null && widget.guestName!.contains(' (')) {
        final parts = widget.guestName!.split(' (');
        participantName = parts[0].trim();
        participantMobile = parts[1].replaceAll(')', '').trim();
      }

      final Map<String, dynamic> answersJson = {};
      _answers.forEach((key, value) {
        answersJson[key.toString()] = value;
      });

      final body = {
        'test_id': widget.testId,
        'student_code': widget.studentCode?.trim().isNotEmpty == true
            ? widget.studentCode!.trim()
            : null,
        'student_name': widget.studentName?.trim().isNotEmpty == true
            ? widget.studentName!.trim()
            : participantName,
        'guest_id': widget.studentCode == null ? _currentGuestId : null,
        'participant_name': participantName.isEmpty ? 'مهمان' : participantName,
        'participant_mobile': participantMobile,
        'answers': answersJson,
        'score': finalScore,
        'submitted_at': DateTime.now().toIso8601String(),
      };

      await PocketBaseService.pb.collection('attempts').create(body: body);

      if (!mounted) return;

      // دیالوگ موفقیت — با تم داینامیک
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final dialogBg = isDark ? const Color(0xff1E1E1E) : Colors.white;
      final dialogTextColor = isDark ? Colors.white70 : Colors.black87;
      final successColor = Colors.green[600]!;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: dialogBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              auto ? 'زمان به پایان رسید!' : 'آزمون با موفقیت ثبت شد!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SB',
                fontSize: 20,
                color: successColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 80, color: successColor),
                const SizedBox(height: 16),
                Text(
                  'تعداد سوالات: ${_questions.length}',
                  style: TextStyle(fontFamily: 'SB', color: dialogTextColor),
                ),
                Text(
                  'درست: $correctCount',
                  style: TextStyle(
                    fontFamily: 'SB',
                    color: successColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'غلط: ${_questions.length - correctCount}',
                  style: TextStyle(fontFamily: 'SB', color: Colors.red[600]),
                ),
                const SizedBox(height: 16),
                Text(
                  'نمره: $finalScore از ۲۰',
                  style: TextStyle(
                    fontFamily: 'SB',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: finalScore >= 12 ? successColor : Colors.orange[700],
                  ),
                ),
              ],
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: successColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => UserHome(
                          studentCode: widget.studentCode,
                          publicTestId: widget.studentCode == null
                              ? widget.testId
                              : null,
                          guestId: widget.studentCode == null
                              ? _currentGuestId
                              : null,
                          guestName: widget.guestName,
                        ),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'بازگشت به لیست آزمون‌ها',
                    style: TextStyle(
                      fontFamily: 'SB',
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('خطا در ثبت آزمون: $e');
      if (mounted) {
        String errorMessage = 'خطا در ثبت نتیجه آزمون';
        if (e.toString().contains('blank') ||
            e.toString().contains('required')) {
          errorMessage = 'لطفاً به همه سؤالات پاسخ دهید';
        } else if (e.toString().contains('encodable')) {
          errorMessage = 'خطا در ارسال پاسخ‌ها. دوباره امتحان کنید';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, textAlign: TextAlign.center),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
        setState(() => _isSubmitting = false);
      }
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

    if (_errorMessage != null || _questions.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: backgroundGradient),
          child: Center(
            child: Text(
              _errorMessage ?? 'هیچ سوالی وجود ندارد',
              style: TextStyle(fontSize: 18, color: Colors.redAccent),
            ),
          ),
        ),
      );
    }

    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(gradient: backgroundGradient),
            child: Column(
              children: [
                // هدر آزمون
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
                      const SizedBox(width: 25),
                      Expanded(
                        child: Text(
                          _testRecord?.data['title'] ?? 'آزمون',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'SB',
                            fontSize: 18,
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

                // تایمر
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.orange[900]
                        : Colors.orangeAccent[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer, color: Colors.orange[300], size: 25),
                      const SizedBox(width: 12),
                      Text(
                        'زمان باقی‌مانده: $minutes دقیقه و ${seconds.toString().padLeft(2, '0')} ثانیه',
                        style: TextStyle(
                          fontFamily: 'SB',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.orange[200]
                              : Colors.orange[800],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // سوالات
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _questions.length,
                    itemBuilder: (_, i) {
                      final q = _questions[i];
                      final options =
                          (q['options'] as List?)?.cast<String>() ?? [];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.4),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDark ? 0.3 : 0.1,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${i + 1}. ${q['text']}',
                                style: TextStyle(
                                  fontFamily: 'SB',
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...List.generate(
                                options.length,
                                (j) => RadioListTile<int>(
                                  title: Text(
                                    options[j],
                                    style: TextStyle(
                                      fontFamily: 'dana',
                                      fontSize: 15,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  ),
                                  value: j,
                                  groupValue: _answers[i],
                                  activeColor: Colors.green[600],
                                  onChanged: (val) =>
                                      setState(() => _answers[i] = val!),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // دکمه ثبت
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : () => _submitTest(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                      ),
                      child: Text(
                        _isSubmitting ? 'در حال ثبت...' : 'ثبت و پایان آزمون',
                        style: const TextStyle(fontFamily: 'SB', fontSize: 15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
