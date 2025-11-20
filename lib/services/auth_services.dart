import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';
import 'api_services.dart';

class AuthService {
  static AuthService? _instance;
  final ApiService api;

  AuthService._internal({required this.api});

  static AuthService getInstance({required ApiService api}) {
    _instance ??= AuthService._internal(api: api);
    return _instance!;
  }

  /// Trả về Map {success: bool, message: String, user?: User}
  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final resp = await api.post('/auth/login', data: {
        'phone': phone,
        'password': password,
      });

      // success code 200
      if (resp.statusCode == 200) {
        final data = resp.data is String ? jsonDecode(resp.data) : resp.data;
        // Giả sử API trả { "id": "...", "phone":"...","token":"...", "name":"..." }
        final user = User.fromJson(Map<String, dynamic>.from(data));
        await UserRepository.saveUser(user);
        return {'success': true, 'message': 'login_ok', 'user': user};
      } else {
        return {'success': false, 'message': 'Server returned ${resp.statusCode}', 'data': resp.data};
      }
    } on DioException catch (e) {
      // Dio error: có thể network / server / response data lỗi
      final msg = _dioErrorMessage(e);
      print('AuthService.login DioError: $msg');
      return {'success': false, 'message': msg, 'error': e};
    } catch (e, st) {
      print('AuthService.login error: $e\n$st');
      return {'success': false, 'message': 'Unexpected error', 'error': e.toString()};
    }
  }

  Future<void> logout() async {
    try {
      // Optionally call API to invalidate token
      final token = await UserRepository.getToken();
      if (token != null && token.isNotEmpty) {
        try {
          await api.client.post('/auth/logout', options: Options(headers: {'Authorization': 'Bearer $token'}));
        } catch (e) {
          print('AuthService.logout: server logout failed but continue locally: $e');
        }
      }
    } catch (e, st) {
      print('AuthService.logout error: $e\n$st');
      rethrow;
    }
  }

  String _dioErrorMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) return 'Connection timeout';
    if (e.type == DioExceptionType.receiveTimeout) return 'Receive timeout';
    if (e.type == DioExceptionType.badResponse) {
      return 'Server error: ${e.response?.statusCode} - ${e.response?.data}';
    }
    if (e.type == DioExceptionType.cancel) return 'Request cancelled';
    return 'Network error: ${e.message}';
  }
}
