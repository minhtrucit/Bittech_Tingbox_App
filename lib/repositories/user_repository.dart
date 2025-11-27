import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserRepository {
  static const String _keyUser = 'current_user';
  static const String keyToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';

  // Save user object (json) + token
  static Future<void> saveUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUser, jsonEncode(user.toJson()));
      await prefs.setString(keyUserId, user.id.toString());
      if (user.token != null) {
        await prefs.setString(keyToken, user.token!);
      }

      await prefs.setString(keyRefreshToken, user.refreshToken);
    } catch (e, st) {
      // log error, but don't throw to UI (optionally rethrow)
      debugPrint('UserRepository.saveUser error: $e\n$st');
      rethrow;
    }
  }

  static Future<User?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyUser);
      if (raw == null) return null;
      final Map<String, dynamic> json = jsonDecode(raw);
      return User.fromJson(json);
    } catch (e, st) {
      debugPrint('UserRepository.getUser error: $e\n$st');
      return null;
    }
  }

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(keyToken);
    } catch (e, st) {
      debugPrint('UserRepository.getToken error: $e\n$st');
      return null;
    }
  }

  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(keyToken);
      await prefs.remove('sepay_url');
    } catch (e, st) {
      debugPrint('UserRepository.clear error: $e\n$st');
    }
  }

  static Future<bool> isLoggedIn() async {
    final t = await getToken();
    return t != null && t.isNotEmpty;
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyToken, token);
  }

  static Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyRefreshToken, token);
  }
}
