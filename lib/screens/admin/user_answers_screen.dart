// lib/screens/admin/user_answers_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pocketbase/pocketbase.dart';

class UserAnswersScreen extends StatelessWidget {
  final RecordModel attemptRecord;
  final RecordModel testRecord;
  final String studentName;

  const UserAnswersScreen({
    required this.attemptRecord,
    required this.testRecord,
    required this.studentName,
    super.key,
  });

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

    // استخراج سوالات و پاسخ‌های کاربر
    final List questions = testRecord.data['questions_data'] ?? [];
    final Map<String, dynamic> userAnswersMap =
        attemptRecord.data['answers'] ?? {};

    // تاریخ سابمیت با fallback امن
    DateTime date;
    final submittedAtStr = attemptRecord.data['submitted_at'] as String?;
    if (submittedAtStr != null && submittedAtStr.isNotEmpty) {
      try {
        date = DateTime.parse(submittedAtStr);
      } catch (e) {
        date = DateTime.parse(attemptRecord.created);
      }
    } else {
      date = DateTime.parse(attemptRecord.created);
    }

    final int totalQuestions = questions.length;
    final int score = (attemptRecord.data['score'] as num?)?.toInt() ?? 0;

    // محاسبه تعداد جواب‌های درست
    int calculateCorrectAnswers() {
      if (questions.isEmpty) return 0;
      int correct = 0;
      for (int i = 0; i < questions.length; i++) {
        final q = questions[i] as Map<String, dynamic>;
        final correctIndex = q['correct_index'] as int?;
        if (correctIndex == null) continue;

        final userAnswerIndex = userAnswersMap[i.toString()] as int?;
        if (userAnswerIndex != null && userAnswerIndex == correctIndex) {
          correct++;
        }
      }
      return correct;
    }

    final int correctAnswersCount = calculateCorrectAnswers();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'جزئیات پاسخ‌ها :',
                            style: TextStyle(
                              fontFamily: 'SB',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          Text(
                            studentName,
                            style: TextStyle(
                              fontFamily: 'SB',
                              fontSize: 15,
                              color: primaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset('assets/images/logo.png', width: 44),
                    ),
                  ],
                ),
              ),

              // کارت اطلاعات کلی
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'تعداد جواب‌های درست: $correctAnswersCount از $totalQuestions',
                      style: TextStyle(
                        fontFamily: 'SB',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[600],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'نمره نهایی: $score از ۲۰',
                      style: TextStyle(
                        fontFamily: 'SB',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: score >= 12
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'تاریخ ثبت: ${intl.DateFormat('yyyy/MM/dd – HH:mm').format(date)}',
                      style: TextStyle(
                        fontFamily: 'SB',
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              // لیست سوالات
              Expanded(
                child: questions.isEmpty
                    ? Center(
                        child: Text(
                          'هیچ سوالی در این آزمون وجود ندارد',
                          style: TextStyle(
                            fontSize: 18,
                            color: isDark ? Colors.white70 : Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: questions.length,
                        itemBuilder: (context, i) {
                          final q = questions[i] as Map<String, dynamic>;
                          final options =
                              (q['options'] as List?)?.cast<String>() ?? [];
                          final correctIndex = q['correct_index'] as int?;
                          final userAnswerIndex =
                              userAnswersMap[i.toString()] as int?;

                          final bool isCorrect =
                              userAnswerIndex == correctIndex;
                          final bool noAnswer = userAnswerIndex == null;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: noAnswer
                                    ? Colors.orange.withOpacity(
                                        isDark ? 0.7 : 0.6,
                                      )
                                    : isCorrect
                                    ? Colors.green.withOpacity(
                                        isDark ? 0.7 : 0.6,
                                      )
                                    : Colors.red.withOpacity(
                                        isDark ? 0.7 : 0.6,
                                      ),
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
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: noAnswer
                                            ? Colors.orange[100]
                                            : isCorrect
                                            ? Colors.green[100]
                                            : Colors.red[100],
                                        child: Icon(
                                          noAnswer
                                              ? Icons.help_outline
                                              : isCorrect
                                              ? Icons.check
                                              : Icons.close,
                                          color: noAnswer
                                              ? Colors.orange
                                              : isCorrect
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontFamily: 'SB',
                                              fontSize: 17,
                                              color: primaryColor,
                                            ),
                                            children: [
                                              const TextSpan(
                                                text: 'سوال ',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              TextSpan(
                                                text: '${i + 1}: ',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              TextSpan(
                                                text: q['text'] ?? 'بدون متن',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // پاسخ کاربر
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: noAnswer
                                          ? (isDark
                                                ? Colors.orange[900]
                                                : Colors.orange[50])
                                          : isCorrect
                                          ? (isDark
                                                ? Colors.green[900]
                                                : Colors.green[50])
                                          : (isDark
                                                ? Colors.red[900]
                                                : Colors.red[50]),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          noAnswer ? Icons.info : Icons.person,
                                          color: noAnswer
                                              ? Colors.orange[700]
                                              : primaryColor,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            noAnswer
                                                ? 'پاسخی ثبت نشده'
                                                : 'پاسخ کاربر: گزینه ${userAnswerIndex + 1} → ${options[userAnswerIndex]}',
                                            style: TextStyle(
                                              fontFamily: 'SB',
                                              fontSize: 15,
                                              color: noAnswer
                                                  ? (isDark
                                                        ? const Color.fromARGB(
                                                            255,
                                                            255,
                                                            235,
                                                            206,
                                                          )
                                                        : Colors.orange[700])
                                                  : primaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            softWrap: true,
                                            overflow: TextOverflow.visible,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // پاسخ صحیح
                                  if (correctIndex != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.green[900]
                                            : Colors.green[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'پاسخ صحیح: گزینه ${correctIndex + 1} → ${options[correctIndex]}',
                                              style: TextStyle(
                                                fontFamily: 'SB',
                                                fontSize: 15,
                                                color: isDark
                                                    ? const Color.fromARGB(
                                                        255,
                                                        223,
                                                        255,
                                                        224,
                                                      )
                                                    : Colors.green[800],
                                                fontWeight: FontWeight.bold,
                                              ),
                                              softWrap: true,
                                              overflow: TextOverflow.visible,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
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
