import 'dart:io';

import 'package:dio/dio.dart';
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
      final response = await request.send().timeout(
        const Duration(seconds: 60),
      );

      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(respStr);
      } else {
        debugPrint('API Error: ${response.statusCode} - $respStr');
        try {
          final data = json.decode(respStr);
          return data; // Return the error response so the UI can handle it
        } catch (e) {
          return {
            'status': 'error',
            'message': 'Lỗi server (${response.statusCode})',
          };
        }
      }
    } catch (e) {
      debugPrint('Error sending image: $e');
      rethrow;
    }
  }

  Future<List<dynamic>?> getAllCategories() async {
    try {
      final response = await api.get('/categories');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        debugPrint('API response Get Categories: $data');

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

  Future<Map<String, dynamic>> createProduct({
    required Map<String, dynamic> body,
    required List<File> images,
  }) async {
    try {
      // Prepare FormData
      final formData = FormData.fromMap({
        ...body,
        "images": [
          for (final f in images)
            await MultipartFile.fromFile(
              f.path,
              filename: f.path.split('/').last,
            ),
        ],
      });

      debugPrint("📤 Uploading product: $body");
      debugPrint("📤 Uploading images count: ${images.length}");

      final resp = await api.post('/products', data: formData);

      debugPrint("📩 API Response: ${resp.data}");

      final ok = resp.statusCode == 201;

      if (!ok) {
        throw Exception(resp.data['message'] ?? "Lỗi API không xác định");
      }

      return resp.data as Map<String, dynamic>;
    } catch (e, st) {
      debugPrint("❌ createProduct error: $e");
      debugPrint("STACK: $st");

      throw Exception("Không thể tạo sản phẩm. Lỗi: $e");
    }
  }

  Future<Map<String, dynamic>> getAllProducts() async {
    try {
      final response = await api.get('/products');

      if (response.statusCode == 200) {
        final data = response.data;
        debugPrint('API response: $data');

        return data;
      } else {
        debugPrint('API Error: ${response.data['message']}');
        throw Exception('Lỗi API: ${response.data['message']}');
      }
    } catch (e) {
      debugPrint('Error getting products: $e');
      throw Exception('Lỗi khi lấy sản phẩm: $e');
    }
  }

  Future<Map<String, dynamic>> updateProduct({
    required int productId,
    required Map<String, dynamic> body,
    List<File>? newImages,
  }) async {
    try {
      // Prepare FormData
      final Map<String, dynamic> formDataMap = {...body};

      // Add new images if provided
      if (newImages != null && newImages.isNotEmpty) {
        formDataMap["images"] = [
          for (final f in newImages)
            await MultipartFile.fromFile(
              f.path,
              filename: f.path.split('/').last,
            ),
        ];
      }

      final formData = FormData.fromMap(formDataMap);

      debugPrint("📤 Updating product ID: $productId");
      debugPrint("📤 Update data: $body");
      debugPrint("📤 New images count: ${newImages?.length ?? 0}");

      final resp = await api.put('/products/$productId', data: formData);

      debugPrint("📩 API Update Product Response: ${resp.data}");

      final ok = resp.statusCode == 200;

      if (!ok) {
        throw Exception(resp.data['message'] ?? "Lỗi API không xác định");
      }

      return resp.data as Map<String, dynamic>;
    } catch (e, st) {
      debugPrint("❌ updateProduct error: $e");
      debugPrint("STACK: $st");

      throw Exception("Không thể cập nhật sản phẩm. Lỗi: $e");
    }
  }

  Future<void> updateEmbedding({
    required int productId,
    required List<String> imageUrls,
  }) async {
    final uri = Uri.parse('$baseUrl/product/update_embedding');
    debugPrint("🌐 Full URL: $uri");
    debugPrint("🌐 Base URL: $baseUrl");
    final request = http.MultipartRequest('POST', uri);

    request.fields['product_id'] = productId.toString();
    for (final url in imageUrls) {
      request.files.add(await http.MultipartFile.fromPath('image_files', url));
    }

    try {
      debugPrint(
        "📤 Updating embedding for product: $productId, images count: ${imageUrls.length}",
      );

      final response = await request.send().timeout(
        const Duration(seconds: 60),
      );

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = json.decode(respStr);
        debugPrint("📩 Update Embedding API Response: $data");
        debugPrint("✅ Update embedding success");
      } else {
        final respStr = await response.stream.bytesToString();
        debugPrint("API Error: ${response.statusCode} - $respStr");
        throw Exception("Lỗi API: ${response.statusCode}");
      }
    } catch (e, st) {
      debugPrint("❌ updateEmbedding error: $e");
      debugPrint("STACK: $st");

      throw Exception("Không thể cập nhật embedding. Lỗi: $e");
    }
  }

  Future<void> deleteProduct(int productId) async {
    try {
      debugPrint("🚀 ProductApiService: Deleting product $productId");
      final response = await api.put(
        '/products/$productId',
        data: {"isActive": false},
      );

      if (response.statusCode == 200) {
        debugPrint("✅ ProductApiService: Delete success");
      } else {
        debugPrint("❌ ProductApiService: Delete failed: ${response.data}");
        throw Exception(response.data['message'] ?? "Lỗi API không xác định");
      }
    } catch (e, st) {
      debugPrint("❌ deleteProduct error: $e");
      debugPrint("STACK: $st");
      throw Exception("Không thể xóa sản phẩm. Lỗi: $e");
    }
  }
}
