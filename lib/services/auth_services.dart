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
      // Let Dio handle the timeout (configured in ApiService as 15s)
      final resp = await api.post('/auth/login', data: {
        'phone': phone,
        'password': password,
      });
      debugPrint(
        'API Response status: ${resp.statusCode} - ${resp.data['statusCode']}',
      );

      // Check for success status codes
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        // Some APIs wrap success in a body statusCode
        final bodyStatusCode = resp.data['statusCode'];
        if (bodyStatusCode != null && bodyStatusCode != 200 && bodyStatusCode != 201) {
           return {
            'success': false,
            'message': resp.data['message']?.toString() ?? 'Lỗi đăng nhập ($bodyStatusCode)',
          };
        }

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
        // Handle non-success response codes that didn't throw DioException
        String message = 'Lỗi máy chủ (${resp.statusCode})';
        if (resp.data is Map && resp.data['message'] != null) {
          message = resp.data['message'].toString();
        }
        return {'success': false, 'message': message};
      }
    } on DioException catch (e) {
      debugPrint('Login DioError: ${e.type} - ${e.message}');
      String message = 'Lỗi kết nối đến máy chủ';
      
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        message = 'Kết nối máy chủ quá hạn (Timeout). Vui lòng kiểm tra mạng.';
      } else if (e.response?.data is Map && e.response?.data['message'] != null) {
        message = e.response?.data['message'].toString() ?? 'Lỗi đăng nhập';
      } else if (e.message != null) {
        message = e.message!;
      }

      return {
        'success': false,
        'message': message,
        'error': e.toString(),
      };
    } catch (e, st) {
      debugPrint('Login unexpected error: $e\n$st');
      return {
        'success': false,
        'message': 'Đã có lỗi xảy ra. Vui lòng thử lại sau.',
        'error': e.toString(),
      };
    }
  }

  Future<bool> logout() async {
    try {
      final rs = await api.post('/auth/logout');
      if (rs.data['status'] == 'success') {
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
