import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/statistic.dart';
import 'api_services.dart';

class StatisticServices {
  final ApiService api;
  StatisticServices({required this.api});

  Future<Statistic> getStatisticByDateRange({
    required String startDate,
    required String endDate,
    required int configId,
    int page = 1,
  }) async {
    try {
      final response = await api.get(
        '/statistics',
        queryParameters: {
          'configId': configId,
          'startDate': startDate,
          'endDate': endDate,
          'page': page,
        },
      );

      if (response.statusCode == 200) {
        debugPrint("📊 Statistic Data: ${response.data['data']}");
        return Statistic.fromJson(response.data['data']);
      }

      throw Exception('Failed to load statistics');
    } catch (e) {
      debugPrint("❌ Error getting statistics: $e");
      rethrow;
    }
  }

  // Helper method to format DateTime to string for API
  String formatDateForApi(DateTime date) {
    return DateFormat('yyyy-M-dd').format(date);
  }

  // Convenience method using DateTimeRange
  Future<Statistic> getStatisticByDateTimeRange({
    required DateTimeRange dateRange,
    required int configId,
  }) async {
    return getStatisticByDateRange(
      startDate: formatDateForApi(dateRange.start),
      endDate: formatDateForApi(dateRange.end),
      configId: configId,
    );
  }

  Future<Map<String, dynamic>> createCashBook({
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await api.post('/cashbooks', data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ Cash book created successfully: ${response.data}");
        return {
          'status': 'success',
          'message': response.data['message'] ?? 'Tạo sổ quỹ thành công',
          'data': response.data['data'],
        };
      }

      return {
        'status': 'error',
        'message': response.data['message'] ?? 'Tạo sổ quỹ thất bại',
      };
    } on DioException catch (err) {
      // Xử lý các lỗi HTTP như 409 (Conflict), 400 (Bad Request), etc.
      debugPrint(
        "❌ DioException creating cash book: ${err.response?.statusCode}",
      );
      debugPrint("❌ Error data: ${err.response?.data}");

      return {
        'status': 'error',
        'message': err.response?.data['message'] ?? 'Tạo sổ quỹ thất bại',
        'statusCode': err.response?.statusCode,
      };
    } catch (e) {
      debugPrint("❌ Unexpected error creating cash book: $e");
      return {'status': 'error', 'message': 'Đã xảy ra lỗi không mong muốn'};
    }
  }

  Future<Map<String, dynamic>> getConfigBankAccountId({
    required int configId,
  }) async {
    try {
      final response = await api.get(
        '/config-bank-accounts',
        queryParameters: {'configId': configId},
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Config data: ${response.data}");
        return response.data['data'][0];
      }

      throw Exception('Failed to load config data');
    } catch (e) {
      debugPrint("❌ Error getting config data: $e");
      rethrow;
    }
  }

  Future<int> getCashBookIdByDate(String date) async {
    try {
      // API: cashbooks/date/2025-11-27
      final response = await api.get('/cashbooks/date/$date');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        // Handle if data is list or object
        if (data is List && data.isNotEmpty) {
          return data[0]['id'];
        } else if (data is Map) {
          return data['id'];
        }
      }
      throw Exception('Cashbook not found for date $date');
    } catch (e) {
      debugPrint("❌ Error getting cashbook id: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createPayment({
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await api.post('/payments', data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ Payment created successfully: ${response.data}");
        return {
          'status': 'success',
          'message': response.data['message'] ?? 'Tạo phiếu chi thành công',
          'data': response.data['data'],
        };
      }

      return {
        'status': 'error',
        'message': response.data['message'] ?? 'Tạo phiếu chi thất bại',
      };
    } on DioException catch (err) {
      debugPrint(
        "❌ DioException creating payment: ${err.response?.statusCode}",
      );
      debugPrint("❌ Error data: ${err.response?.data}");
      return {
        'status': 'error',
        'message': err.response?.data['message'] ?? 'Tạo phiếu chi thất bại',
        'statusCode': err.response?.statusCode,
      };
    } catch (e) {
      debugPrint("❌ Unexpected error creating payment: $e");
      return {'status': 'error', 'message': 'Đã xảy ra lỗi không mong muốn'};
    }
  }

  Future<Map<String, dynamic>> createReceipt({
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await api.post('/receipts', data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ Receipt created successfully: ${response.data}");
        return {
          'status': 'success',
          'message': response.data['message'] ?? 'Tạo phiếu thu thành công',
          'data': response.data['data'],
        };
      }

      return {
        'status': 'error',
        'message': response.data['message'] ?? 'Tạo phiếu thu thất bại',
      };
    } on DioException catch (err) {
      debugPrint(
        "❌ DioException creating payment: ${err.response?.statusCode}",
      );
      debugPrint("❌ Error data: ${err.response?.data}");
      return {
        'status': 'error',
        'message': err.response?.data['message'] ?? 'Tạo phiếu thu thất bại',
        'statusCode': err.response?.statusCode,
      };
    } catch (e) {
      debugPrint("❌ Unexpected error creating payment: $e");
      return {'status': 'error', 'message': 'Đã xảy ra lỗi không mong muốn'};
    }
  }
}
