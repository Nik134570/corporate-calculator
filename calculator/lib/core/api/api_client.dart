import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:calculator/core/storage/secure_storage.dart';

class ApiClient {
  late final Dio dio;
  final SecureStorage _storage;

  static String get baseUrl {
    if (kIsWeb) {
      final port = Uri.base.port;
      // port == 0 means default port (443 for HTTPS, 80 for HTTP)
      if (port != 0 && port != 80 && port != 443) {
        return 'http://localhost:3000/api/v1';
      }
      return '/api/v1';
    }
    return 'http://10.0.2.2:3000/api/v1';
  }

  ApiClient(this._storage) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    dio.interceptors.add(_TokenInterceptor(_storage, dio));
  }
}

class _TokenInterceptor extends Interceptor {
  final SecureStorage _storage;
  final Dio _dio;

  _TokenInterceptor(this._storage, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) {
        try {
          final response = await _dio.post(
            '/auth/refresh',
            data: {'refreshToken': refreshToken},
            options: Options(headers: {'Authorization': null}),
          );
          final newAccessToken = response.data['data']['accessToken'];
          final newRefreshToken = response.data['data']['refreshToken'];
          await _storage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryResponse = await _dio.fetch(opts);
          return handler.resolve(retryResponse);
        } catch (_) {
          await _storage.clearTokens();
        }
      }
    }
    handler.next(err);
  }
}
