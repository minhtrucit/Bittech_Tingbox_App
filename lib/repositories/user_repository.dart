import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserRepository {
  static const String _keyUser = 'current_user';
  static const String keyToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyConfigId = 'config_id';
  static const String keyUserId = 'user_id';
  static const String keyQrCode = 'qr_code';
  static const String keyLastPhone = 'last_phone';
  static const String _keyLastUser = 'last_user';

  // Save user object (json) + token
  static Future<void> saveUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = jsonEncode(user.toJson());
      await prefs.setString(_keyUser, userData);
      // Also save as last user (persists after logout)
      await prefs.setString(_keyLastUser, userData);
      await prefs.setString(keyUserId, user.id.toString());
      if (user.token != null) {
        await prefs.setString(keyToken, user.token!);
      }

      await prefs.setString(keyRefreshToken, user.refreshToken);
      if (user.qrCode != null) {
        await prefs.setString(keyQrCode, user.qrCode!);
      }
      await prefs.setString(keyLastPhone, user.phone);
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

  static Future<User?> getLastUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyLastUser);
      if (raw == null) return null;
      final Map<String, dynamic> json = jsonDecode(raw);
      return User.fromJson(json);
    } catch (e, st) {
      debugPrint('UserRepository.getLastUser error: $e\n$st');
      return null;
    }
  }

  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(keyToken);
      await prefs.remove(keyRefreshToken);
      await prefs.remove(_keyUser);
      await prefs.remove(keyUserId);
      await prefs.remove(keyQrCode);
      await prefs.remove('sepay_url');
      debugPrint(
        '[UserRepository] Logged out: User session cleared, but last_user preserved.',
      );
    } catch (e, st) {
      debugPrint('UserRepository.logout error: $e\n$st');
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

  static Future<void> saveConfigId(String configId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyConfigId, configId);
  }

  static Future<String?> getConfigId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(keyConfigId);
    } catch (e, st) {
      debugPrint('UserRepository.getConfigId error: $e\n$st');
      return null;
    }
  }

  static Future<String?> getQrCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(keyQrCode);
    } catch (e, st) {
      debugPrint('UserRepository.getQrCode error: $e\n$st');
      return null;
    }
  }

  static Future<String?> getLastPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyLastPhone);
  }
}
