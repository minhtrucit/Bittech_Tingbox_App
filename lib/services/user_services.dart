import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'api_services.dart';

class UserService {
  final ApiService api;
  UserService({required this.api});

  Future<User?> getUser({required String userId}) async {
    try {
      final resp = await api.get('/users/$userId');

      debugPrint("📩 API Response: ${resp.data}");

      final ok = resp.statusCode == 200;

      if (!ok) {
        debugPrint("❌ UserService: API Error: ${resp.data['message']}");
        throw Exception(resp.data['message'] ?? "Lỗi API không xác định");
      }

      debugPrint("✅ UserService: Parsing User JSON...");
      final userData = resp.data['data'];
      if (userData == null) {
        throw Exception("API returned no data field");
      }
      final user = User.fromJson(userData);
      debugPrint("✅ UserService: User parsed successfully: ${user.userName}");
      return user;
    } catch (e, st) {
      debugPrint("❌ Get User error: $e");
      debugPrint("STACK: $st");

      throw Exception("Không thể lấy thông tin user. Lỗi: $e");
    }
  }

  Future<User?> updateAvatar({
    required String userId,
    required String filePath,
  }) async {
    try {
      debugPrint("🚀 UserService: Updating avatar for user $userId");

      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(filePath),
      });

      final resp = await api.put('/users/$userId', data: formData);

      debugPrint("📩 API Response: ${resp.data}");

      final ok = resp.statusCode == 200 || resp.statusCode == 201;

      if (!ok) {
        debugPrint("❌ UserService: API Error: ${resp.data['message']}");
        throw Exception(resp.data['message'] ?? "Lỗi API không xác định");
      }

      final userData = resp.data['data'];
      if (userData == null) {
        throw Exception("API returned no data field");
      }
      final user = User.fromJson(userData);
      debugPrint("✅ UserService: Avatar updated successfully");
      return user;
    } catch (e, st) {
      debugPrint("❌ Update Avatar error: $e");
      debugPrint("STACK: $st");
      throw Exception("Không thể cập nhật ảnh đại diện. Lỗi: $e");
    }
  }
}
