// lib/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;

  String _fullText = 'FarAzmoon';
  String _visibleText = '';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    );

    _logoController.forward();

    // تایپ شدن متن
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_currentIndex < _fullText.length) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _visibleText += _fullText[_currentIndex];
          _currentIndex++;
        });
      } else {
        timer.cancel();
      }
    });

    // رفتن به صفحه لاگین بعد از ۴ ثانیه
    Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // گرادیان پس‌زمینه هماهنگ با تم
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

    // رنگ‌های گرادیان متن
    final textGradientColors = isDark
        ? const [
            Color.fromARGB(255, 0, 212, 255), // آبی روشن
            Color.fromARGB(255, 133, 221, 243),
          ]
        : const [
            Color.fromARGB(255, 17, 1, 194), // آبی تیره
            Color.fromARGB(255, 133, 221, 243),
          ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _logoAnimation,
                  child: FadeTransition(
                    opacity: _logoAnimation,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 150,
                      height: 150,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: textGradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    _visibleText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SB',
                      color: Colors.white, // برای ShaderMask حتماً سفید باشه
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
