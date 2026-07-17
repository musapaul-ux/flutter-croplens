import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_exception.dart';
import 'secure_storage.dart';

/// Centralized HTTP client for talking to the CropLens backend.
///
/// - Attaches the JWT access token to every request.
/// - Transparently refreshes an expired access token once and retries the
///   original request, so screens never have to think about token expiry.
/// - Normalizes every failure into an [ApiException] with a clean message
///   the UI can show directly (matching the backend's { success, message, errors } shape).
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:5000/api',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.instance.getAccessToken();
          if (token != null && !options.path.contains('/auth/')) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException error, handler) async {
          final isUnauthorized = error.response?.statusCode == 401;
          final isRetry = error.requestOptions.extra['retried'] == true;

          if (isUnauthorized && !isRetry) {
            final refreshed = await _tryRefreshToken();
            if (refreshed) {
              final opts = error.requestOptions;
              opts.extra['retried'] = true;
              final newToken = await SecureStorage.instance.getAccessToken();
              opts.headers['Authorization'] = 'Bearer $newToken';
              try {
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await SecureStorage.instance.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
      final newAccessToken = response.data['data']['accessToken'] as String;
      await SecureStorage.instance.saveAccessToken(newAccessToken);
      return true;
    } catch (_) {
      await SecureStorage.instance.clearTokens();
      return false;
    }
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    try {
      final res = await _dio.get(path, queryParameters: query);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<Map<String, dynamic>> post(String path, {dynamic data}) async {
    try {
      final res = await _dio.post(path, data: data);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<Map<String, dynamic>> put(String path, {dynamic data}) async {
    try {
      final res = await _dio.put(path, data: data);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final res = await _dio.delete(path);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  /// Multipart upload helper for image uploads (profile picture, crop scans).
  /// Takes raw bytes rather than a file path so this works identically on
  /// Flutter Web (no real filesystem) and on mobile (Android/iOS).
  Future<Map<String, dynamic>> upload(
    String path, {
    required Uint8List fileBytes,
    required String fileName,
    required String fieldName,
    Map<String, dynamic>? extraFields,
  }) async {
    try {
      final formData = FormData.fromMap({
        ...?extraFields,
        fieldName: MultipartFile.fromBytes(fileBytes, filename: fileName),
      });
      final res = await _dio.post(path, data: formData);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString() ?? 'Something went wrong';
      final errorsRaw = data['errors'];
      final fieldErrors = <FieldError>[];
      if (errorsRaw is List) {
        for (final item in errorsRaw) {
          if (item is Map) {
            fieldErrors.add(FieldError(item['field']?.toString() ?? '', item['message']?.toString() ?? ''));
          }
        }
      }
      return ApiException(message, statusCode: e.response?.statusCode, fieldErrors: fieldErrors);
    }

    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
      return ApiException('The connection timed out. Please check your network and try again.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return ApiException('Could not connect to CropLens. Please check your network.');
    }
    return ApiException(e.message ?? 'An unexpected error occurred');
  }
}
