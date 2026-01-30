// lib/services/excel_service.dart
import 'package:excel/excel.dart';
import 'dart:typed_data';

class ExcelService {
  Future<List<Map<String, dynamic>>> parseExcel(Uint8List bytes) async {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return [];
    final sheet = excel.tables.values.first;

    List<Map<String, dynamic>> parsed = [];

    for (int r = 1; r < sheet.maxRows; r++) {
      final row = sheet.row(r);
      if (row.isEmpty) continue;

      final question = row[0]?.value?.toString().trim() ?? '';
      if (question.isEmpty) continue;

      final opt1 = row[1]?.value?.toString().trim() ?? '';
      final opt2 = row[2]?.value?.toString().trim() ?? '';
      final opt3 = row[3]?.value?.toString().trim() ?? '';
      final opt4 = row[4]?.value?.toString().trim() ?? '';

      int? correctIndex;
      if (row.length > 5) {
        final correctRaw = row[5]?.value?.toString().trim();
        if (correctRaw != null && correctRaw.isNotEmpty) {
          final parsedIndex = int.tryParse(correctRaw);
          if (parsedIndex != null && parsedIndex >= 1 && parsedIndex <= 4) {
            correctIndex = parsedIndex - 1; // تبدیل به 0-3
          }
        }
      }

      final explanation = row.length > 6
          ? row[6]?.value?.toString().trim() ?? ''
          : '';

      parsed.add({
        'question': question,
        'options': [opt1, opt2, opt3, opt4],
        'correctIndex': correctIndex,
        'explanation': explanation,
        'row': r + 1,
      });
    }

    return parsed;
  }

  // این تابع حتماً باید باشه!
  List<String> validateParsed(List<Map<String, dynamic>> data) {
    List<String> errors = [];

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final row = (item['row'] ?? i + 2);

      if (item['question'] == null ||
          (item['question'] as String).trim().isEmpty) {
        errors.add('ردیف $row: متن سؤال خالی است');
        continue;
      }

      final options = item['options'] as List<dynamic>;
      final emptyOptions = options
          .asMap()
          .entries
          .where((e) => e.value == null || e.value.toString().trim().isEmpty)
          .map((e) => e.key + 1)
          .toList();

      if (emptyOptions.isNotEmpty) {
        errors.add('ردیف $row: گزینه‌های خالی: ${emptyOptions.join(', ')}');
      }

      final correctIndex = item['correctIndex'] as int?;
      if (correctIndex == null || correctIndex < 0 || correctIndex >= 4) {
        errors.add('ردیف $row: گزینه صحیح نامعتبر است (باید ۱ تا ۴ باشد)');
      }
    }

    return errors;
  }
}
