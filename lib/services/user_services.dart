import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'api_services.dart';

class UserService {
  final ApiService api;
  UserService({required this.api});

  Future<User> getUser({
    required String userId,
  }) async {
    try {
      final resp = await api.get('/users/$userId');

      debugPrint("📩 API Response: ${resp.data}");

      final ok = resp.statusCode == 200;

      if (!ok) {
        throw Exception(resp.data['message'] ?? "Lỗi API không xác định");
      }

      return User.fromJson(resp.data);
    } catch (e, st) {
      debugPrint("❌ Create Order error: $e");
      debugPrint("STACK: $st");

      throw Exception("Không thể tạo đơn hàng. Lỗi: $e");
    }
  }

  
}
