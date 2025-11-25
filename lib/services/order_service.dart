import 'package:flutter/foundation.dart';
import 'package:ting_box/models/order.dart';
import '../models/statistic.dart';
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

  Future<Statistic> getStatisticsOverview() async {
    try {
      final resp = await api.get('/orders/statistics/overview');

      debugPrint("📌 API RAW DATA: ${resp.data}");

      if (resp.statusCode == 200) {
        debugPrint("📌 DATA PARSED: ${resp.data['data']}");

        return Statistic.fromJson(resp.data['data']);
      }

      throw Exception('Failed to load dashboard statistic');
    } catch (e) {
      debugPrint("❌ ERROR: $e");
      throw Exception('Error: $e');
    }
  }

  Future<List<Order>> getAllOrders() async {
    try {
      final resp = await api.get('/orders');

      debugPrint("📌 API RAW DATA: ${resp.data}");

      if (resp.statusCode == 200) {
        debugPrint("📌 DATA PARSED: ${resp.data['data']}");

        final List<dynamic> data = resp.data['data'] as List<dynamic>;
        return data
            .map((e) => Order.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Failed to load orders');
    } catch (e) {
      debugPrint("❌ ERROR: $e");
      throw Exception('Error: $e');
    }
  }
}
