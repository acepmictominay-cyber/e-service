import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:azza_service/config/api_config.dart';

/// Base API service with comprehensive error handling, timeouts, and retries
class BaseApiService {
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);

  static String get baseUrl => ApiConfig.apiBaseUrl;

  /// Generic HTTP GET request with error handling
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    Duration? timeout,
    bool retryOnFailure = true,
  }) async {
    return _makeRequest(
      () => http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _buildHeaders(headers),
      ),
      timeout: timeout,
      retryOnFailure: retryOnFailure,
    );
  }

  /// Generic HTTP POST request with error handling
  static Future<Map<String, dynamic>> post(
    String endpoint,
    dynamic body, {
    Map<String, String>? headers,
    Duration? timeout,
    bool retryOnFailure = true,
  }) async {
    return _makeRequest(
      () => http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _buildHeaders(headers),
        body: json.encode(body),
      ),
      timeout: timeout,
      retryOnFailure: retryOnFailure,
    );
  }

  /// Generic HTTP PUT request with error handling
  static Future<Map<String, dynamic>> put(
    String endpoint,
    dynamic body, {
    Map<String, String>? headers,
    Duration? timeout,
    bool retryOnFailure = true,
  }) async {
    return _makeRequest(
      () => http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _buildHeaders(headers),
        body: json.encode(body),
      ),
      timeout: timeout,
      retryOnFailure: retryOnFailure,
    );
  }

  /// Generic HTTP DELETE request with error handling
  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
    Duration? timeout,
    bool retryOnFailure = true,
  }) async {
    return _makeRequest(
      () => http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _buildHeaders(headers),
      ),
      timeout: timeout,
      retryOnFailure: retryOnFailure,
    );
  }

  /// Multipart file upload
  static Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    File file,
    String fieldName, {
    Map<String, String>? headers,
    Map<String, String>? fields,
    Duration? timeout,
  }) async {
    return _makeRequest(
      () async {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl$endpoint'),
        );

        request.headers.addAll(_buildHeaders(headers));
        request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));

        if (fields != null) {
          request.fields.addAll(fields);
        }

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        return response;
      },
      timeout: timeout,
      retryOnFailure: false, // Don't retry file uploads
    );
  }

  /// Core request execution with retry logic
  static Future<Map<String, dynamic>> _makeRequest(
    Future<http.Response> Function() request, {
    Duration? timeout,
    bool retryOnFailure = true,
  }) async {
    int attempts = 0;
    final effectiveTimeout = timeout ?? _defaultTimeout;

    while (attempts < (retryOnFailure ? _maxRetries : 1)) {
      attempts++;

      try {
        final response = await request().timeout(effectiveTimeout);

        // Parse response
        final responseData = _parseResponse(response);

        // Check for API-level errors
        if (responseData.containsKey('success') && responseData['success'] == false) {
          throw ApiException(
            message: responseData['message'] ?? 'API request failed',
            statusCode: response.statusCode,
            data: responseData,
          );
        }

        return responseData;
      } on TimeoutException {
        if (attempts >= _maxRetries || !retryOnFailure) {
          throw ApiException(
            message: 'Request timeout after ${effectiveTimeout.inSeconds} seconds',
            statusCode: 408,
          );
        }
        await Future.delayed(_retryDelay * attempts);
      } on SocketException {
        if (attempts >= _maxRetries || !retryOnFailure) {
          throw ApiException(
            message: 'Network connection failed. Please check your internet connection.',
            statusCode: 0,
          );
        }
        await Future.delayed(_retryDelay * attempts);
      } on FormatException {
        throw ApiException(
          message: 'Invalid response format from server',
          statusCode: 0,
        );
      } catch (e) {
        if (e is ApiException) rethrow;

        // Handle HTTP status codes
        if (e is http.ClientException) {
          throw ApiException(
            message: 'Network request failed',
            statusCode: 0,
          );
        }

        throw ApiException(
          message: 'Unexpected error: $e',
          statusCode: 0,
        );
      }
    }

    throw ApiException(
      message: 'Request failed after $_maxRetries attempts',
      statusCode: 0,
    );
  }

  /// Parse HTTP response
  static Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      final contentType = response.headers['content-type'] ?? '';

      if (contentType.contains('application/json')) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else if (decoded is List) {
          return {'data': decoded, 'success': true};
        } else {
          return {'data': decoded, 'success': true};
        }
      } else {
        // Handle non-JSON responses
        return {
          'success': response.statusCode >= 200 && response.statusCode < 300,
          'data': response.body,
          'raw_response': response.body,
        };
      }
    } catch (e) {
      throw ApiException(
        message: 'Failed to parse response: $e',
        statusCode: response.statusCode,
      );
    }
  }

  /// Build request headers
  static Map<String, String> _buildHeaders(Map<String, String>? customHeaders) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic>? data;

  ApiException({
    required this.message,
    required this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

/// Utility class for safe API calls with error handling
class ApiHelper {
  static Future<T?> safeApiCall<T>(
    Future<T> Function() apiCall, {
    String? errorMessage,
    Duration? timeout,
  }) async {
    try {
      return await apiCall().timeout(timeout ?? const Duration(seconds: 30));
    } catch (e) {
      if (e is ApiException) {
        rethrow; // Re-throw API exceptions as-is
      }

      throw ApiException(
        message: errorMessage ?? 'Operation failed: $e',
        statusCode: 0,
      );
    }
  }

  /// Extract data from API response with fallback
  static T extractData<T>(
    Map<String, dynamic> response,
    String key, {
    T? defaultValue,
  }) {
    try {
      final data = response['data'];
      if (data is Map<String, dynamic> && data.containsKey(key)) {
        return data[key] as T;
      } else if (response.containsKey(key)) {
        return response[key] as T;
      }
      return defaultValue as T;
    } catch (e) {
      if (defaultValue != null) return defaultValue;
      throw ApiException(
        message: 'Failed to extract $key from response',
        statusCode: 0,
      );
    }
  }

  /// Extract list from API response
  static List<T> extractList<T>(
    Map<String, dynamic> response, {
    String key = 'data',
  }) {
    try {
      final data = response[key];
      if (data is List) {
        return data.cast<T>();
      } else if (data is Map && data.containsKey('data') && data['data'] is List) {
        return (data['data'] as List).cast<T>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
