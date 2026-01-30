// lib/screens/share_test_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/pocketbase_service.dart';

class ShareTestScreen extends StatefulWidget {
  final String testId;
  const ShareTestScreen({required this.testId, super.key});

  @override
  State<ShareTestScreen> createState() => _ShareTestScreenState();
}

class _ShareTestScreenState extends State<ShareTestScreen> {
  String? accessCode;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAccessCode();
  }

  Future<void> _loadAccessCode() async {
    try {
      final testRecord = await PocketBaseService.pb
          .collection('tests')
          .getOne(widget.testId);

      setState(() {
        accessCode = testRecord.data['access_code'] as String?;
        loading = false;
      });
    } catch (e) {
      setState(() {
        accessCode = null; // برای نمایش خطا
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // خط بالای مودال
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'کد ورود به آزمون',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'SB',
              color: Color(0xff1A237E),
            ),
          ),
          const SizedBox(height: 20),

          if (loading)
            const CircularProgressIndicator()
          else if (accessCode == null)
            const Text(
              'کد پیدا نشد یا خطا در بارگذاری!',
              style: TextStyle(color: Colors.red),
            )
          else ...[
            const Text(
              'دانش‌آموزان فقط این کد را وارد کنند:',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // کد بزرگ و زیبا
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xfff0f2ff),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xff1A237E), width: 3),
              ),
              child: Text(
                accessCode!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 12,
                  fontFamily: 'monospace',
                  color: Color(0xff1A237E),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // دکمه کپی
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: accessCode!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('کد کپی شد!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.copy, color: Colors.white, size: 28),
              label: const Text('کپی کد', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff1A237E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // دکمه اشتراک‌گذاری
            OutlinedButton.icon(
              onPressed: () {
                final message =
                    'کد ورود به آزمون:\n\n$accessCode\n\nدر اپ فرازمون وارد کنید!';
                Share.share(message);
              },
              icon: const Icon(Icons.share, color: Color(0xff1A237E), size: 26),
              label: const Text(
                'اشتراک‌گذاری کد',
                style: TextStyle(fontSize: 17),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xff1A237E),
                side: const BorderSide(color: Color(0xff1A237E), width: 2.5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
