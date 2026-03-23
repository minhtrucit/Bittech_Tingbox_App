import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ting_box/models/order.dart';
import '../models/statistic_order.dart';
import 'api_services.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

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
    } on DioException catch (e) {
      debugPrint("❌ Create Order DioError: ${e.response?.data}");
      String message = "Lỗi hệ thống (HTTP ${e.response?.statusCode})";
      if (e.response?.data is Map) {
        message =
            e.response?.data['message'] ?? e.response?.data['error'] ?? message;
      } else if (e.message != null && e.message!.isNotEmpty) {
        message = e.message!;
      }
      throw Exception(message);
    } catch (e, st) {
      debugPrint("❌ Create Order error: $e");
      debugPrint("STACK: $st");

      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  Future<StatisticOrder> getStatisticsOverview() async {
    try {
      final resp = await api.get('/orders/statistics/overview');

      debugPrint("📌 API RAW DATA: ${resp.data}");

      if (resp.statusCode == 200) {
        debugPrint("📌 DATA PARSED: ${resp.data['data']}");

        return StatisticOrder.fromJson(resp.data['data']);
      }

      throw Exception('Failed to load dashboard statistic');
    } catch (e) {
      debugPrint("❌ ERROR: $e");
      throw Exception('Error: $e');
    }
  }

  Future<OrderListResponse> getAllOrdersbyUserId({
    required int userId,
    int? page,
    int limit = 10,
    int? paymentStatus,
    String? searchQuery,
    int? tableId,
  }) async {
    try {
      final queryParams = {
        if (page != null) 'page': page,
        'limit': limit,
        if (paymentStatus != null) 'paymentStatus': paymentStatus,
        if (tableId != null) 'tableId': tableId,
        if (searchQuery != null && searchQuery.isNotEmpty)
          'search': searchQuery,
      };

      final resp = await api.get('/orders', queryParameters: queryParams);

      debugPrint("📌 API RAW DATA: ${resp.data}");

      if (resp.statusCode == 200) {
        return OrderListResponse.fromJson(resp.data);
      }

      throw Exception('Failed to load orders');
    } catch (e) {
      debugPrint("❌ ERROR: $e");
      throw Exception('Error: $e');
    }
  }

  Future<Order> getOrdersbyOrderId({required int orderId}) async {
    try {
      final resp = await api.get('/orders/$orderId');

      debugPrint("📌 API RAW DATA: ${resp.data}");

      if (resp.statusCode == 200) {
        return Order.fromJson(resp.data['data']);
      }

      throw Exception('Failed to load orders');
    } catch (e) {
      debugPrint("❌ ERROR: $e");
      throw Exception('Error: $e');
    }
  }

  Future<Order> updateStatusOrdersbyOrderId({
    required int orderId,
    required String paymentStatus,
  }) async {
    try {
      final resp = await api.put(
        '/orders/$orderId',
        data: {'paymentStatus': paymentStatus},
      );

      debugPrint("📌 Update Status Order: ${resp.data}");

      if (resp.statusCode == 200) {
        return Order.fromJson(resp.data['data']);
      }

      throw Exception('Failed to update status order: ${resp.data['message']}');
    } catch (e) {
      debugPrint("❌ ERROR: $e");
      throw Exception('Error: $e');
    }
  }

  Future<Order> putOrder({
    required int orderId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final resp = await api.put('/orders/$orderId', data: data);

      debugPrint("📌 Put Order response: ${resp.data}");

      if (resp.statusCode == 200) {
        return Order.fromJson(resp.data['data']);
      }

      throw Exception('Failed to update order: ${resp.data['message']}');
    } catch (e) {
      debugPrint("❌ ERROR: $e");
      throw Exception('Error: $e');
    }
  }

  Future<String> addItemsToOrder({
    required int orderId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final resp =
          await api.post('/orders/$orderId/items', data: {'items': items});

      debugPrint("📌 Add Items to Order response: ${resp.data}");

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return resp.data['message'] ?? 'Thêm món thành công';
      }

      throw Exception('Failed to add items: ${resp.data['message']}');
    } catch (e) {
      debugPrint("❌ ERROR: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> handleSePayWebHook({
    required dynamic body,
  }) async {
    try {
      final dio = Dio();
      dio.options.headers['Authorization'] =
          'Apikey ${dotenv.get('SEPAY_API_KEY')}';

      debugPrint("📤 Xử lý webhook SePay Body: ${body.toString()}");
      final resp = await dio.post(
        'https://sepay.bittechx.cloud/sepay/webhook',
        data: body,
      );

      debugPrint(
        "📩 API Response Xử lý webhook SePay thành công: ${resp.data}",
      );

      final ok = (resp.statusCode == 200 || resp.data['statusCode'] == 201);

      if (!ok) {
        throw Exception(resp.data['message'] ?? "Lỗi API không xác định");
      }

      return resp.data;
    } on DioException catch (err) {
      debugPrint("❌ Xử lý webhook SePay thất bại: ${err.message}");

      throw Exception(
        "Không thể xử lý webhook SePay dio exception. Lỗi: ${err.message}",
      );
    } catch (e) {
      debugPrint("❌ Xử lý webhook SePay thất bại: ${e.toString()}");

      throw Exception("Không thể xử lý webhook SePay. Lỗi: ${e.toString()}");
    }
  }

  Future<Map<String, dynamic>> generateOrderQRCode({
    required String orderId,
  }) async {
    try {
      debugPrint("📤 Generate QR code for order: $orderId");

      final resp = await api.post('/orders/$orderId/regenerate-qr');

      debugPrint("📩 API Generate QR code for order Response: ${resp.data}");

      final ok = resp.statusCode == 201;

      if (!ok) {
        throw Exception(resp.data['message'] ?? "Lỗi API không xác định");
      }

      return resp.data['data'];
    } catch (e, st) {
      debugPrint("❌ Generate QR code for order error: $e");
      debugPrint("STACK: $st");

      throw Exception("Không thể generate QR code for order. Lỗi: $e");
    }
  }
}
