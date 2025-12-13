import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'api_services.dart';

class AuthService {
  static AuthService? _instance;
  final ApiService api;

  AuthService._internal({required this.api});

  static AuthService getInstance({required ApiService api}) {
    _instance ??= AuthService._internal(api: api);
    return _instance!;
  }

  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final resp = await api
          .post('/auth/login', data: {'phone': phone, 'password': password})
          .timeout(const Duration(seconds: 15));
      debugPrint(
        'API Response status: ${resp.statusCode} - ${resp.data['statusCode']}',
      );

      if (resp.statusCode == 201 && resp.data['statusCode'] == 200) {
        final data = resp.data['data'] ?? {};
        debugPrint('Data JSON: $data');

        final userJson = Map<String, dynamic>.from(data['user'] ?? {});
        // Gán token từ API
        userJson['expenseManagerAccessToken'] =
            data['expenseManagerAccessToken'];
        userJson['expenseManagerRefreshToken'] =
            data['expenseManagerRefreshToken'];
        userJson['qrCode'] = data['qrCode'];

        final user = User.fromJson(userJson);
        debugPrint('Parsed User: ${user.toJson()}');
        api.setTokens(
          accessToken: user.token!,
          refreshToken: user.refreshToken,
        );
        debugPrint('Access token set in ApiService: ${user.token}');
        debugPrint('Refresh token set in ApiService: ${user.refreshToken}');
        return {'success': true, 'message': 'login_ok', 'user': user};
      } else {
        final msg = resp.data ?? 'Server returned ${resp.statusCode}';
        return {'success': false, 'message': msg};
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'],
        'error': e.message,
      };
    } catch (e, st) {
      debugPrint('Login unexpected error: $e\n$st');
      return {
        'success': false,
        'message': 'Unexpected error',
        'error': e.toString(),
      };
    }
  }

  Future<bool> logout() async {
    try {
      final rs = await api.post('/auth/logout');
      if (rs.data['success']) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint(
        'AuthService.logout: server logout failed but continue locally: $e',
      );
      return false;
    }
  }
}
