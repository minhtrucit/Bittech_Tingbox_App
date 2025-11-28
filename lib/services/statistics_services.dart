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
  }) async {
    try {
      final response = await api.get(
        '/statistics',
        queryParameters: {
          'configId': configId,
          'limit': 5,
          'startDate': startDate,
          'endDate': endDate,
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
}
