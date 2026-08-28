/// Endpoint paths only — hostnames/base URL live in AppConfig, headers
/// live in DioClient. Keep this file as the one place new endpoints get
/// added as the API surface grows.
class ApiEndpoints {
  ApiEndpoints._();

  static const String deviceRegister = '/api/v1/devices/register';
}