import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'api_services.dart';

class OrderService {
  final ApiService api;
  OrderService({required this.api});

  Future<Map<String, dynamic>> createOrder({
    required Map<String, dynamic> body,
  }) async {
    try {

      debugPrint("📤 Uploading product: $body");

      final resp = await api.post('/orders', data: body);

      debugPrint("📩 API Response: ${resp.data}");

      final ok = resp.statusCode == 201;

      if (!ok) {
        throw Exception(resp.data['message'] ?? "Lỗi API không xác định");
      }

      return resp.data;
    } catch (e, st) {
      debugPrint("❌ Create Order error: $e");
      debugPrint("STACK: $st");

      throw Exception("Không thể tạo đơn hàng. Lỗi: $e");
    }
  }

}
