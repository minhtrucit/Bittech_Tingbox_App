import 'dart:async';
import 'package:dio/dio.dart';

class ApiService {
  static ApiService? _instance;
  final Dio _dio;

  ApiService._internal({required String baseUrl})
      : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(milliseconds: 15000),
    receiveTimeout: const Duration(milliseconds: 15000),
    contentType: 'application/json',
  )) {
    _dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
  }

  static ApiService getInstance({required String baseUrl}) {
    _instance ??= ApiService._internal(baseUrl: baseUrl);
    return _instance!;
  }

  Dio get client => _dio;

  Future<Response> post(String path,
      {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) =>
      _dio.post(path, data: data, queryParameters: queryParameters, options: options);

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters, Options? options}) =>
      _dio.get(path, queryParameters: queryParameters, options: options);
}

