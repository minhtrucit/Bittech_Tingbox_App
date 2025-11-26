import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:ting_box/models/config_model.dart';

import 'api_services.dart';

class ConfigService {
  final ApiService api;

  ConfigService({required this.api});

  Future<ConfigModel?> getConfig(int userId) async {
    try {
      final response = await api.get(
        '',
       
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.data);
        if (data['status'] == 'success' && data['data'] != null) {
          return ConfigModel.fromJson(data['data']);
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
      final response = await api.post(
        '',
        data: jsonEncode(config.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.data);
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
