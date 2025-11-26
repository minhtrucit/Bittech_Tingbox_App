import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../repositories/user_repository.dart';

class ApiService {
  static ApiService? _instance;
  final Dio _dio;

  String? _accessToken;
  String? _refreshToken;

  bool _isRefreshing = false;
  final List<Function(String)> _tokenQueue = [];

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
    _instance ??= ApiService._internal(baseUrl: baseUrl);
    return _instance!;
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

        _tokenQueue.add((newToken) async {
          requestOptions.headers["Authorization"] = "Bearer $newToken";
          final retryResponse = await _dio.fetch(requestOptions);
          completer.complete(retryResponse);
        });

        return handler.resolve(await completer.future);
      }

      _isRefreshing = true;

      try {
        final newAccessToken = await _performRefreshToken();

        // update vào memory
        _accessToken = newAccessToken;

        // RUN QUEUE request
        for (var callback in _tokenQueue) {
          callback(newAccessToken);
        }
        _tokenQueue.clear();

        // Retry request gốc
        requestOptions.headers["Authorization"] = "Bearer $newAccessToken";
        final response = await _dio.fetch(requestOptions);

        return handler.resolve(response);
      } catch (e) {
        // refresh thất bại → logout user
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
