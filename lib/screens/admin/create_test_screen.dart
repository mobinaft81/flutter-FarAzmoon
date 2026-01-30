// lib/screens/admin/create_test_screen.dart
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../services/pocketbase_service.dart';

String _generateAccessCode() {
  final random = Random();
  return (100000 + random.nextInt(900000)).toString();
}

class CreateTestScreen extends StatefulWidget {
  final RecordModel? editTestRecord;

  const CreateTestScreen({super.key, this.editTestRecord});

  @override
  State<CreateTestScreen> createState() => _CreateTestScreenState();
}

class _CreateTestScreenState extends State<CreateTestScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _timeController;

  List<Map<String, dynamic>> _questions = [];

  final _questionTextController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  int _correctAnswerIndex = 0;

  bool _isPublic = false;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.editTestRecord?.data['title'] ?? '',
    );
    _descController = TextEditingController(
      text: widget.editTestRecord?.data['description'] ?? '',
    );

    // مقدار پیش‌فرض ۳۰ دقیقه
    final int existingDuration =
        widget.editTestRecord?.data['duration_minutes'] is num
        ? (widget.editTestRecord!.data['duration_minutes'] as num).toInt()
        : 30;
    _timeController = TextEditingController(text: existingDuration.toString());

    _isPublic = widget.editTestRecord?.data['is_public'] == true;

    final rawQuestions = widget.editTestRecord?.data['questions_data'];
    if (rawQuestions is List) {
      _questions = rawQuestions.map<Map<String, dynamic>>((q) {
        return {
          'id': q['id']?.toString() ?? const Uuid().v4(),
          'text': q['text']?.toString() ?? 'سوال بدون متن',
          'options': (q['options'] is List)
              ? List<String>.from(q['options'])
              : <String>[],
          'correct_index': (q['correct_index'] is int) ? q['correct_index'] : 0,
        };
      }).toList();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _timeController.dispose();
    _questionTextController.dispose();
    for (var c in _optionControllers) c.dispose();
    super.dispose();
  }

  void _addQuestion() {
    if (_questionTextController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً متن سؤال را وارد کنید')),
      );
      return;
    }

    final options = _optionControllers.map((c) => c.text.trim()).toList();
    if (options.any((o) => o.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('همه گزینه‌ها باید پر شوند')),
      );
      return;
    }

    final newQuestion = {
      'id': const Uuid().v4(),
      'text': _questionTextController.text.trim(),
      'options': options,
      'correct_index': _correctAnswerIndex,
    };

    setState(() {
      _questions.add(newQuestion);
      _questionTextController.clear();
      for (var c in _optionControllers) c.clear();
      _correctAnswerIndex = 0;
    });
  }

  Future<void> _saveTest() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عنوان آزمون نمی‌تواند خالی باشد')),
      );
      return;
    }
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('حداقل یک سؤال اضافه کنید')));
      return;
    }

    final String? currentAdminId = PocketBaseService.pb.authStore.model?.id;
    if (currentAdminId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطا: ادمین لاگین نشده است'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // زمان آزمون — حداقل 1 دقیقه، پیش‌فرض 30
    int durationMinutes = int.tryParse(_timeController.text.trim()) ?? 30;
    if (durationMinutes < 1) durationMinutes = 30;

    final body = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim().isEmpty
          ? ''
          : _descController.text.trim(),
      'duration_minutes': durationMinutes, // همیشه مقدار معتبر ارسال می‌شه
      'questions_data': jsonEncode(_questions),
      'access_code': _generateAccessCode(),
      'is_public': _isPublic,
      'created_by': currentAdminId,
    };

    try {
      if (widget.editTestRecord == null) {
        await PocketBaseService.pb.collection('tests').create(body: body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('آزمون با موفقیت ساخته شد!'),
            backgroundColor: Colors.green[600],
          ),
        );
      } else {
        await PocketBaseService.pb
            .collection('tests')
            .update(widget.editTestRecord!.id, body: body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('آزمون با موفقیت ویرایش شد!'),
            backgroundColor: Colors.green[600],
          ),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در ذخیره: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xff2D3748) : Colors.white;
    final borderColor = isDark ? const Color(0xff00D4FF) : Colors.grey.shade300;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textDirection: TextDirection.rtl,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          hintText: label == 'زمان آزمون (دقیقه)' ? 'پیش‌فرض: ۳۰ دقیقه' : null,
          hintStyle: TextStyle(
            color: isDark ? Colors.white38 : Colors.grey[500],
            fontSize: 14,
          ),
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
            borderSide: BorderSide(color: const Color(0xff00D4FF), width: 2.5),
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
        ? const Color.fromARGB(255, 1, 160, 192)
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
                    Expanded(
                      child: Text(
                        widget.editTestRecord == null
                            ? 'ایجاد آزمون جدید'
                            : 'ویرایش آزمون',
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

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTextField(_titleController, 'عنوان آزمون'),
                      _buildTextField(_descController, 'توضیحات (اختیاری)'),
                      _buildTextField(
                        _timeController,
                        'زمان آزمون (دقیقه)',
                        keyboardType: TextInputType.number,
                      ),

                      const SizedBox(height: 20),
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
                                ? 'همه افراد می‌توانند بدون کد وارد شوند'
                                : 'فقط افرادی که کد دسترسی دارند می‌توانند وارد شوند',
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
                      Text(
                        'افزودن سؤال',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),

                      const SizedBox(height: 16),
                      _buildTextField(_questionTextController, 'متن سؤال'),

                      ...List.generate(
                        4,
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: RadioListTile<int>(
                            title: TextField(
                              controller: _optionControllers[i],
                              decoration: InputDecoration(
                                labelText: 'گزینه ${i + 1}',
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xff2D3748)
                                    : Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? const Color(0xff00D4FF)
                                        : Colors.grey.shade300,
                                  ),
                                ),
                              ),
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            value: i,
                            groupValue: _correctAnswerIndex,
                            activeColor: primaryColor,
                            onChanged: (val) =>
                                setState(() => _correctAnswerIndex = val!),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _addQuestion,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          'افزودن این سؤال',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),

                      if (_questions.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'سؤالات اضافه شده (${_questions.length})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._questions.map(
                          (q) => Card(
                            color: cardBg,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                q['text'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              subtitle: Text(
                                'گزینه‌ها: ${(q['options'] as List).join(' | ')}\nپاسخ صحیح: گزینه ${(q['correct_index'] as int) + 1}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_forever,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () =>
                                    setState(() => _questions.remove(q)),
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: _saveTest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff43A047),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 80,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 8,
                        ),
                        child: Text(
                          widget.editTestRecord == null
                              ? 'ذخیره آزمون'
                              : 'به‌روزرسانی آزمون',
                          style: const TextStyle(
                            fontSize: 19,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
