import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'api_services.dart';

class ProductApiService {
  final String baseUrl;
  final ApiService api;
  ProductApiService({required this.baseUrl, required this.api});

  /// Gửi ảnh lên Python API và nhận JSON product
  Future<Map<String, dynamic>?> sendImage(String imagePath) async {
    final uri = Uri.parse('$baseUrl/product/detect');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = json.decode(respStr);
        return data; // JSON product
      } else {
        print('API Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error sending image: $e');
      return null;
    }
  }

  Future<List<dynamic>?> getAllCategories() async {
    try {
      final response = await api.get('/categories');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        debugPrint('API response123: ${data}');

        return data; // JSON product
      } else {
        debugPrint('API Error: ${response.data['message']}');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting categories: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> body) async {
    try {
      final resp = await api.post('/products', data: body);

      debugPrint("📩 API Response: ${resp.data}");

      final ok =
          resp.statusCode == 201 &&
          resp.data is Map &&
          resp.data['statusCode'] == 200;

      if (ok) {
        return resp.data as Map<String, dynamic>;
      }

      throw Exception(resp.data['message'] ?? "Unknown API error");
    } catch (e, stack) {
      debugPrint("❌ createProduct error: $e");
      debugPrint("STACK: $stack");

      throw Exception("Không thể tạo sản phẩm. Lỗi: $e");
    }
  }
}
