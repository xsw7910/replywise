// Placeholder for the HTTP client that will wrap Dio / http.
// Backend integration is deferred — this file establishes the location.

import '../config/app_config.dart';

class ApiClient {
  ApiClient() : baseUrl = AppConfig.backendBaseUrl;

  final String baseUrl;

  // TODO(network): add Dio/http client, interceptors, auth headers.
}
