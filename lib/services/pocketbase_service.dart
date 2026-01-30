// lib/services/pocketbase_service.dart
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

class PocketBaseService {
  static final PocketBase pb = PocketBase(
    'https://far-pocket1-ju2jlgxzvh.liara.run',
  );

  static Future<void> testConnection() async {
    try {
      await pb.health.check();
      debugPrint('✅ اتصال به PocketBase موفق بود');
    } catch (e) {
      debugPrint('❌ خطا در اتصال به PocketBase: $e');
      rethrow;
    }
  }

  static Future<void> loginAdmin(String email, String password) async {
    try {
      await pb.admins.authWithPassword(email, password);
      debugPrint('ورود ادمین موفق');
    } catch (e) {
      debugPrint('خطا در ورود ادمین: $e');
      rethrow;
    }
  }

  static void logoutAdmin() {
    pb.authStore.clear();
  }

  static bool isAdminLoggedIn() {
    return pb.authStore.isValid && pb.authStore.model != null;
  }

  static String? getAdminToken() {
    return pb.authStore.token;
  }
}
