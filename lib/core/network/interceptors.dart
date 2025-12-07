import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constant/api_urls.dart'; // Pastikan path ini sesuai dengan file ApiConstants kamu

class DioInterceptor extends Interceptor {
  final Logger _logger;
  final SharedPreferences _sharedPreferences;
  final Dio _dio;
  Future<String?>? _refreshFuture;

  DioInterceptor(this._logger, this._sharedPreferences, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 1. Log Request Keluar
    _logger.i('--> ${options.method.toUpperCase()} ${options.uri}');
    _logger.t('Headers: ${options.headers}');
    _logger.t('Body: ${options.data}');

    // 2. Ambil Token dari Shared Preferences
    final token = _sharedPreferences.getString(ApiConstants.tokenKey);

    // 3. Jika token ada, sisipkan ke Header Authorization
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Lanjut ke request server
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 1. Log Response Sukses
    _logger.d('<-- ${response.statusCode} ${response.requestOptions.uri}');
    _logger.t('Data: ${response.data}');

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 1. Log Error
    _logger.e('<-- ${err.response?.statusCode} ${err.requestOptions.uri}');
    _logger.e('Message: ${err.message}');
    _logger.e('Error Data: ${err.response?.data}');
    if (_shouldAttemptRefresh(err)) {
      await _handleTokenRefresh(err, handler);
    } else {
      super.onError(err, handler);
    }
  }

  bool _shouldAttemptRefresh(DioException err) {
    final statusCode = err.response?.statusCode;
    final path = err.requestOptions.path;
    final hasRetried = err.requestOptions.extra['__retry'] == true;

    final isRefreshEndpoint = path.contains('/auth/refresh');
    final isLoginEndpoint = path.contains('/auth/login');

    return statusCode == 401 &&
        !isRefreshEndpoint &&
        !isLoginEndpoint &&
        !hasRetried;
  }

  Future<void> _handleTokenRefresh(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      final newToken = await _refreshToken();

      if (newToken == null || newToken.isEmpty) {
        return handler.next(err);
      }

      final opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer $newToken';
      opts.extra['__retry'] = true;

      final response = await _dio.fetch(opts);
      handler.resolve(response);
    } catch (e) {
      handler.next(err);
    }
  }

  Future<String?> _refreshToken() {
    final existing = _refreshFuture;
    if (existing != null) return existing;

    final refreshToken = _sharedPreferences.getString(
      ApiConstants.refreshTokenKey,
    );
    if (refreshToken == null || refreshToken.isEmpty) {
      return Future.value(null);
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    final future = (() async {
      try {
        final response = await dio.post(
          '/auth/refresh',
          data: {'refreshToken': refreshToken},
        );

        final raw = response.data;
        final data = raw is Map<String, dynamic> ? raw : null;
        final tokenData = data?['data'] as Map<String, dynamic>?;
        final access = tokenData?['accessToken'] as String?;
        final newRefresh = tokenData?['refreshToken'] as String?;

        if (access != null && access.isNotEmpty) {
          await _sharedPreferences.setString(ApiConstants.tokenKey, access);
          if (newRefresh != null && newRefresh.isNotEmpty) {
            await _sharedPreferences.setString(
              ApiConstants.refreshTokenKey,
              newRefresh,
            );
          }
          _logger.i('Token refreshed successfully');
          return access;
        }
      } catch (e) {
        _logger.e('Refresh token failed: $e');
      } finally {
        _refreshFuture = null;
      }
      return null;
    })();

    _refreshFuture = future;
    return future;
  }
}
