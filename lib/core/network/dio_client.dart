




import 'package:dio/dio.dart';

import '../config/app_config.dart';

/// Single shared Dio instance for the whole app.
///
/// Anything that talks to the backend (device registration today, photo
/// sync / auth / whatever comes next) should go through
/// `DioClient.instance`, not create its own `Dio()`. That way timeouts,
/// base URL, default headers, logging, and retry behavior are defined
/// once and stay consistent everywhere.
class DioClient {
  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // We want to inspect 4xx/5xx ourselves (e.g. treat 422 as
        // "handled, don't retry") rather than have Dio throw for every
        // non-2xx status.
        validateStatus: (_) => true,
      ),
    );

    _dio.interceptors.add(_RetryOnConnectionErrorInterceptor(_dio));

    if (!AppConfig.isProd) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
        ),
      );
    }
  }

  static final DioClient _instance = DioClient._internal();
  static DioClient get instance => _instance;

  late final Dio _dio;
  Dio get dio => _dio;
}

/// Retries a request once, after a short delay, if it failed for a
/// transient network reason (timeout, connection error, no route) —
/// NOT for 4xx/5xx application errors, which are handled by the caller.
///
/// This is a single-retry-on-connection-blip helper, not a substitute
/// for the offline queue in DeviceRegistrationService: if the device is
/// genuinely offline, this retry will fail too and the caller's own
/// catch/queue logic takes over.
class _RetryOnConnectionErrorInterceptor extends Interceptor {
  _RetryOnConnectionErrorInterceptor(this._dio);

  final Dio _dio;

  static const _retryableTypes = {
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
  };

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final alreadyRetried = err.requestOptions.extra['__retried'] == true;

    if (!alreadyRetried && _retryableTypes.contains(err.type)) {
      err.requestOptions.extra['__retried'] = true;
      await Future<void>.delayed(const Duration(seconds: 2));

      try {
        final response = await _dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } catch (_) {
        // Fall through to the original error below.
      }
    }

    handler.next(err);
  }
}