import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserRepository {
  static const String _keyUser = 'current_user';
  static const String _keyToken = 'auth_token';

  // Save user object (json) + token
  static Future<void> saveUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUser, jsonEncode(user.toJson()));
      if (user.token != null) {
        await prefs.setString(_keyToken, user.token!);
      }
    } catch (e, st) {
      // log error, but don't throw to UI (optionally rethrow)
      print('UserRepository.saveUser error: $e\n$st');
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
      print('UserRepository.getUser error: $e\n$st');
      return null;
    }
  }

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyToken);
    } catch (e, st) {
      print('UserRepository.getToken error: $e\n$st');
      return null;
    }
  }

  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUser);
      await prefs.remove(_keyToken);
    } catch (e, st) {
      print('UserRepository.clear error: $e\n$st');
    }
  }

  static Future<bool> isLoggedIn() async {
    final t = await getToken();
    return t != null && t.isNotEmpty;
  }
}
