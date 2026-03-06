import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../repositories/user_repository.dart';

class ApiService {
  static final Map<String, ApiService> _instances = {};
  final Dio _dio;

  String? _accessToken;
  String? _refreshToken;

  bool _isRefreshing = false;
  final List<void Function(String?, DioException?)> _tokenQueue = [];

  ApiService._internal({required String baseUrl})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(milliseconds: 15000),
          receiveTimeout: const Duration(milliseconds: 15000),
          contentType: 'application/json',
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );

    _dio.interceptors.add(
      LogInterceptor(responseBody: true, requestBody: true),
    );
  }

  static ApiService getInstance({required String baseUrl}) {
    if (!_instances.containsKey(baseUrl)) {
      _instances[baseUrl] = ApiService._internal(baseUrl: baseUrl);
    }
    return _instances[baseUrl]!;
  }

  // ----------------------
  // SET TOKEN
  // ----------------------
  void setTokens({required String accessToken, required String refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  // ----------------------
  // ON REQUEST: Add token vào header
  // ----------------------
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_accessToken != null) {
      options.headers["Authorization"] = "Bearer $_accessToken";
      debugPrint('[ApiService] Adding Authorization header: $_accessToken');
    }

    return handler.next(options);
  }

  // ----------------------
  // ON ERROR: Handle 401 → Refresh token
  // ----------------------
  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      RequestOptions requestOptions = err.requestOptions;

      // Nếu đang refresh → đưa request vào queue chờ
      if (_isRefreshing) {
        final completer = Completer<Response>();

        _tokenQueue.add((newToken, error) async {
          if (error != null) {
            completer.completeError(error);
          } else if (newToken != null) {
            requestOptions.headers["Authorization"] = "Bearer $newToken";
            try {
              final retryResponse = await _dio.fetch(requestOptions);
              completer.complete(retryResponse);
            } catch (e) {
              completer.completeError(e);
            }
          }
        });

        return handler.resolve(await completer.future);
      }

      _isRefreshing = true;

      try {
        final newAccessToken = await _performRefreshToken();

        // RUN QUEUE request (with success)
        for (var callback in _tokenQueue) {
          callback(newAccessToken, null);
        }
        _tokenQueue.clear();

        // Retry request gốc
        requestOptions.headers["Authorization"] = "Bearer $newAccessToken";
        final response = await _dio.fetch(requestOptions);

        return handler.resolve(response);
      } catch (e) {
        debugPrint('[ApiService] Refresh failed, rejecting queue: $e');

        // Reject all queued requests
        for (var callback in _tokenQueue) {
          callback(null, err); // Re-use the original 401 error
        }
        _tokenQueue.clear();

        return handler.reject(err);
      } finally {
        _isRefreshing = false;
      }
    }

    return handler.next(err);
  }

  // ----------------------
  // GỌI API REFRESH TOKEN
  // ----------------------
  Future<String> _performRefreshToken() async {
    if (_refreshToken == null) throw Exception("Missing refresh token");

    debugPrint('[ApiService] Refreshing token...');

    final response = await _dio.post(
      "/auth/refresh",
      data: {"refreshToken": _refreshToken},
    );

    final data = response.data["data"];
    if (data == null) throw Exception("Invalid refresh response");

    final newAccessToken = data["expenseManagerAccessToken"];
    final newRefreshToken = data["expenseManagerRefreshToken"];

    // LƯU VÀO SharedPreferences
    await UserRepository.saveToken(newAccessToken);
    await UserRepository.saveRefreshToken(newRefreshToken);

    // cập nhật biến memory
    _accessToken = newAccessToken;
    _refreshToken = newRefreshToken;

    return newAccessToken;
  }

  // ----------------------
  // REQUEST WRAPPER
  // ----------------------
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _dio.post(
    path,
    data: data,
    queryParameters: queryParameters,
    options: options,
  );

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _dio.get(path, queryParameters: queryParameters, options: options);

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _dio.put(
    path,
    data: data,
    queryParameters: queryParameters,
    options: options,
  );
}
