import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserRepository {
  static const String usersKey = "users";
  static const String currentUserKey = "current_user";

  static Future<List<User>> _getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(usersKey);

    if (data == null) return [];

    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((e) => User.fromJson(e)).toList();
  }

  static Future<void> _saveUsers(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = users.map((e) => e.toJson()).toList();
    await prefs.setString(usersKey, jsonEncode(jsonList));
  }

  static Future<String?> loginOrRegister(String phone, String password) async {
    final users = await _getUsers();

    // Check existing user
    final existingUser =
        users.where((u) => u.phone == phone).cast<User?>().firstOrNull;

    // Check password if user exists
    if (existingUser != null) {
      if (existingUser.password == password) {
        await _setCurrentUser(phone);
        return "login_ok";
      } else {
        return "wrong_password";
      }
    }

    // Register new user
    final newUser = User(phone: phone, password: password);
    users.add(newUser);
    await _saveUsers(users);
    await _setCurrentUser(phone);
    return "registered";
  }

  // save current user
  static Future<void> _setCurrentUser(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(currentUserKey, phone);
  }

  // get current user
  static Future<String?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(currentUserKey);
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(currentUserKey);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(currentUserKey) != null;
  }
}

extension IterableExt<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
