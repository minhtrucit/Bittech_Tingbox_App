import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:ting_box/models/config_model.dart';

import 'api_services.dart';

class ConfigService {
  final ApiService api;

  ConfigService({required this.api});

  Future<ConfigModel?> getConfig(String userId) async {
    try {
      final response = await api.get('configs/$userId');

      if (response.statusCode == 200) {
        final data =
            response.data is String ? jsonDecode(response.data) : response.data;

        if (data['status'] == 'success' && data != null) {
          if (data['data'] is List && (data['data'] as List).isNotEmpty) {
            final config = ConfigModel.fromJson(data['data'][0]);
            debugPrint('Config: ${config.toJson()}');
            return config;
          } else if (data['data'] is Map<String, dynamic>) {
            return ConfigModel.fromJson(data['data']);
          }
        }
      } else {
        debugPrint('Failed to load config: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading config: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> saveConfig(ConfigModel config) async {
    try {
      final response = await api.post('', data: jsonEncode(config.toJson()));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data =
            response.data is String ? jsonDecode(response.data) : response.data;
        return data;
      } else {
        debugPrint('Failed to save config: ${response.statusCode}');
        debugPrint('Body: ${response.data}');
        throw Exception(response.data['message'] ?? 'Failed to save config');
      }
    } catch (e) {
      debugPrint('Error saving config: ${e.toString()}');
      throw Exception(e.toString());
    }
  }
}
