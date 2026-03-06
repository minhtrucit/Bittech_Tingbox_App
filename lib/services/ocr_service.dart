import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'api_services.dart';

class OcrService {
  static OcrService? _instance;

  OcrService._internal();

  static OcrService getInstance() {
    _instance ??= OcrService._internal();
    return _instance!;
  }

  Future<Map<String, dynamic>> detectOCR(String imagePath) async {
    final apiService = ApiService.getInstance(
      baseUrl: dotenv.get('OCR_API_URL'),
    );
    try {
      final formData = FormData.fromMap({
        'files': [
          await MultipartFile.fromFile(
            imagePath,
            filename: imagePath.split('/').last,
          ),
        ],
        'type': 'menu',
      });

      final response = await apiService.post(
        '/api/vlm-detect',
        data: formData,
        options: Options(
          headers: {'x-api-key': dotenv.get('OCR_API_KEY')},
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      if (response.statusCode == 202) {
        final data = response.data;
        debugPrint('API response: $data');

        return data;
      } else {
        debugPrint('API Error: ${response.data['message']}');
        throw Exception('Lỗi API: ${response.data['message']}');
      }
    } catch (e) {
      debugPrint('Error detecting OCR: $e');
      throw Exception('Lỗi khi detect OCR: $e');
    }
  }

  Future<Map<String, dynamic>> detectVLMDirect(String imagePath) async {
    final apiService = ApiService.getInstance(
      baseUrl: 'http://192.168.1.241:8080',
    );
    try {
      final formData = FormData.fromMap({
        'files': [
          await MultipartFile.fromFile(
            imagePath,
            filename: imagePath.split('/').last,
          ),
        ],
        'type': 'menu',
      });

      final response = await apiService.post(
        '/api/vlm-detect',
        data: formData,
        options: Options(
          headers: {'x-api-key': dotenv.get('OCR_API_KEY')},
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        debugPrint('VLM Direct API response: $data');
        return data; // Kết quả trả về ngay
      } else {
        debugPrint('VLM Direct API Error: ${response.data['message']}');
        throw Exception('Lỗi VLM Direct: ${response.data['message']}');
      }
    } catch (e) {
      debugPrint('Error in detectVLMDirect: $e');
      throw Exception('Lỗi khi gọi VLM Direct: $e');
    }
  }
}
