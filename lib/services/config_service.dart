import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:ting_box/models/config_model.dart';
import 'package:ting_box/models/bank.dart';

import 'api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  final ApiService api;

  ConfigService({required this.api});

  static const String _keySepayUrl = 'sepay_url';
  static const String _keySepayApiKey = 'sepay_api_key';

  Future<List<Bank>> getBanks() async {
    try {
      final response = await api.get('banks');

      if (response.statusCode == 200) {
        final data =
            response.data is String ? jsonDecode(response.data) : response.data;
        debugPrint('Banks: ${data['data']}');
        if (data['status'] == 'success' && data['data'] != null) {
          return (data['data'] as List).map((e) => Bank.fromJson(e)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error loading banks: $e');
    }
    return [];
  }

  Future<void> saveSepayUrl(String url, String? sepayApiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySepayUrl, url);
      if (sepayApiKey != null) {
        await prefs.setString(_keySepayApiKey, sepayApiKey);
      }
    } catch (e) {
      debugPrint('Error saving sepay url: $e');
    }
  }

  Future<Map<String, dynamic>> getSepayInfoFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final url = prefs.getString(_keySepayUrl);
      final sepayApiKey = prefs.getString(_keySepayApiKey);
      return {'url': url, 'sepayApiKey': sepayApiKey};
    } catch (e) {
      debugPrint('Error getting sepay url from local: $e');
      return {'url': null, 'sepayApiKey': null};
    }
  }

  Future<Map<String, dynamic>> getSepayInfo(int configId) async {
    try {
      final response = await api.get('configs/url-sepay/?configId=$configId');
      if (response.statusCode == 200) {
        final data =
            response.data is String ? jsonDecode(response.data) : response.data;
        final url = data['data']['url'];
        final sepayApiKey = data['data']['sepayApiKey'];
        if (url != null) {
          await saveSepayUrl(url, sepayApiKey);
        }
        return data;
      }
      throw Exception('Error getting sepay info: ${response.data['message']}');
    } catch (e) {
      debugPrint('Error getting sepay info: $e');
      return {};
    }
  }

  Future<ConfigModel?> getConfig(String userId) async {
    try {
      final response = await api.get('config-users/user/$userId/configs');

      if (response.statusCode == 200) {
        final data =
            response.data is String ? jsonDecode(response.data) : response.data;

        if (data['status'] == 'success' && data != null) {
          if (data['data'] is List && (data['data'] as List).isNotEmpty) {
            final config = ConfigModel.fromJson(
              data['data'][0],
            ); // Lấy config đầu tiên
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

  Future<Map<String, dynamic>> createConfig(ConfigModel config) async {
    try {
      final response = await api.post('configs', data: config.toJson());

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data =
            response.data is String ? jsonDecode(response.data) : response.data;
        return data;
      } else {
        debugPrint('Failed to create config: ${response.statusCode}');
        debugPrint('Body: ${response.data}');
        throw Exception(response.data['message'] ?? 'Failed to create config');
      }
    } catch (e) {
      debugPrint('Error creating config: ${e.toString()}');
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> updateConfig(ConfigModel config) async {
    try {
      final response = await api.put(
        'configs/${config.id}',
        data: config.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data =
            response.data is String ? jsonDecode(response.data) : response.data;
        return data;
      } else {
        debugPrint('Failed to update config: ${response.statusCode}');
        debugPrint('Body: ${response.data}');
        throw Exception(response.data['message'] ?? 'Failed to update config');
      }
    } catch (e) {
      debugPrint('Error updating config: ${e.toString()}');
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> createOrUpdateBankAccount({
    required int configId,
    required int bankId,
    required String accountNumber,
    required String accountName,
    bool isDefault = true,
    bool isActive = true,
  }) async {
    try {
      final body = {
        'configId': configId,
        'bankId': bankId,
        'accountNumber': accountNumber,
        'accountName': accountName,
        'isDefault': isDefault ? 1 : 0,
        'isActive': isActive ? 1 : 0,
      };

      debugPrint('[ConfigService] Creating/Updating bank account: $body');

      final response = await api.post('config-bank-accounts', data: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data =
            response.data is String ? jsonDecode(response.data) : response.data;
        return data;
      } else {
        debugPrint(
          'Failed to create/update bank account: ${response.statusCode}',
        );
        debugPrint('Body: ${response.data}');
        throw Exception(
          response.data['message'] ?? 'Failed to create/update bank account',
        );
      }
    } catch (e) {
      debugPrint('Error creating/updating bank account: ${e.toString()}');
      throw Exception(e.toString());
    }
  }
}
