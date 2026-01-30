// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_home.dart';
import 'screens/user/user_home.dart';

import 'services/pocketbase_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await PocketBaseService.testConnection();
    debugPrint('✅ PocketBase آماده است');
  } catch (e) {
    debugPrint('⚠️ مشکل در اتصال به PocketBase: $e');
  }

  runApp(
    ChangeNotifierProvider(create: (_) => ThemeService(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          title: 'فرآزمون',
          debugShowCheckedModeBanner: false,
          themeMode: themeService.themeMode,

          // تم روشن
          theme: ThemeData(
            brightness: Brightness.light,
            fontFamily: 'dana',
            primaryColor: const Color(0xff1A237E),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color.fromARGB(255, 223, 235, 250),
            cardColor: Colors.white,
            dialogBackgroundColor: Colors.white,
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Colors.white,
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.black87),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff1A237E),
                foregroundColor: Colors.white,
              ),
            ),
          ),

          // تم تیره — کامل و زیبا
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: 'dana',
            primaryColor: const Color(0xff3F51B5),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xff121212), // بک‌گراند اصلی
            cardColor: const Color(0xff1E1E1E), // کارت‌ها و کانتینرها
            dialogBackgroundColor: const Color(0xff1E1E1E), // دیالوگ‌ها
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Color(0xff1E1E1E),
              modalBackgroundColor: Color(0xff1E1E1E),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xff1A1A1A),
              foregroundColor: Colors.white,
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.white70),
              titleLarge: TextStyle(color: Colors.white),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xff2C2C2C), // پس‌زمینه TextField تیره
              hintStyle: const TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.grey, width: 0.5),
              ),
              labelStyle: const TextStyle(color: Colors.white70),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff3F51B5),
                foregroundColor: Colors.white,
              ),
            ),
            drawerTheme: const DrawerThemeData(
              backgroundColor: Color(0xff1E1E1E),
            ),
            popupMenuTheme: const PopupMenuThemeData(color: Color(0xff1E1E1E)),
            colorScheme: ColorScheme.dark(
              primary: const Color(0xff3F51B5),
              secondary: Colors.greenAccent,
              surface: const Color(0xff1E1E1E),
              background: const Color(0xff121212),
            ),
          ),

          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('fa', 'IR')],

          initialRoute: '/',
          routes: {
            '/': (context) => const Directionality(
              textDirection: TextDirection.rtl,
              child: SplashScreen(),
            ),
            '/login': (context) => const Directionality(
              textDirection: TextDirection.rtl,
              child: LoginScreen(),
            ),
            '/admin': (context) => const Directionality(
              textDirection: TextDirection.rtl,
              child: AdminHome(),
            ),
            '/user': (context) => const Directionality(
              textDirection: TextDirection.rtl,
              child: UserHome(),
            ),
          },

          onUnknownRoute: (settings) => MaterialPageRoute(
            builder: (context) => const Directionality(
              textDirection: TextDirection.rtl,
              child: LoginScreen(),
            ),
          ),
        );
      },
    );
  }
}
