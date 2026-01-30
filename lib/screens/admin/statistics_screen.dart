// lib/screens/admin/statistics_screen.dart
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../services/pocketbase_service.dart';

class StatisticsScreen extends StatefulWidget {
  final String testId;
  final String testTitle;

  const StatisticsScreen({
    required this.testId,
    required this.testTitle,
    super.key,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<Map<String, dynamic>> _questions = [];
  List<RecordModel> _attempts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final testRecord = await PocketBaseService.pb
          .collection('tests')
          .getFirstListItem('id = "${widget.testId}"');

      final questionsList = testRecord.data['questions_data'] as List? ?? [];
      final questions = questionsList.cast<Map<String, dynamic>>();

      final attemptsResult = await PocketBaseService.pb
          .collection('attempts')
          .getList(filter: 'test_id = "${widget.testId}"');

      setState(() {
        _questions = questions;
        _attempts = attemptsResult.items;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red),
        );
        setState(() => _loading = false);
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
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white60 : Colors.grey;
    final progressBg = isDark ? Colors.grey[700] : Colors.grey[300];

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

    final totalParticipants = _attempts.length;

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
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        'میانگین نتایج',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'SB',
                          fontSize: 15,
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

              // عنوان آزمون و تعداد شرکت‌کننده
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    Text(
                      widget.testTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'تعداد شرکت‌کننده: $totalParticipants نفر',
                      style: TextStyle(fontSize: 16, color: secondaryTextColor),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // لیست سوالات و آمار
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _questions.isEmpty
                    ? Center(
                        child: Text(
                          'هیچ سوالی یافت نشد',
                          style: TextStyle(
                            fontSize: 18,
                            color: secondaryTextColor,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _questions.length,
                        itemBuilder: (_, i) {
                          final q = _questions[i];
                          final options =
                              (q['options'] as List?)?.cast<String>() ?? [];
                          final correctIndex = q['correct_index'] as int?;

                          final counts = List<int>.filled(options.length, 0);
                          for (final attempt in _attempts) {
                            final answersData = attempt.data['answers'];
                            Map<String, dynamic> answers = {};

                            if (answersData is Map) {
                              answers = Map<String, dynamic>.from(answersData);
                            }

                            final answerIndexStr = i.toString();
                            final answerIndex = answers[answerIndexStr] as int?;

                            if (answerIndex != null &&
                                answerIndex < counts.length) {
                              counts[answerIndex]++;
                            }
                          }

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            padding: const EdgeInsets.all(16),
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
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: primaryColor,
                                      child: Text(
                                        '${i + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'سوال ${i + 1}: ${q['text']}',
                                        style: TextStyle(
                                          fontFamily: 'SB',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ...options.asMap().entries.map((e) {
                                  final index = e.key;
                                  final text = e.value;
                                  final count = counts[index];
                                  final percentage = totalParticipants > 0
                                      ? (count / totalParticipants * 100)
                                            .round()
                                      : 0;
                                  final isCorrect = correctIndex == index;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isCorrect
                                              ? Icons.check_circle
                                              : Icons.circle_outlined,
                                          color: isCorrect
                                              ? const Color.fromARGB(
                                                  255,
                                                  0,
                                                  255,
                                                  8,
                                                )
                                              : (isDark
                                                    ? Colors.grey[400]
                                                    : Colors.grey),
                                          size: 24,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'گزینه ${index + 1}: $text',
                                                style: TextStyle(
                                                  fontFamily: 'dana',
                                                  fontSize: 15,
                                                  color: isCorrect
                                                      ? (isDark
                                                            ? const Color.fromARGB(
                                                                255,
                                                                0,
                                                                255,
                                                                13,
                                                              )
                                                            : Colors.green[800])
                                                      : textColor,
                                                  fontWeight: isCorrect
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              LinearProgressIndicator(
                                                value: percentage / 100,
                                                backgroundColor: progressBg,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(
                                                      isCorrect
                                                          ? const Color.fromARGB(
                                                              255,
                                                              0,
                                                              255,
                                                              8,
                                                            )
                                                          : primaryColor,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '$percentage% ($count نفر)',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: secondaryTextColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
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
