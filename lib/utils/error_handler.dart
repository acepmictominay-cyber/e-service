import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'error_utils.dart';

/// Advanced error handling utility with configurable logging
class ErrorHandler {
  static bool _enableDetailedLogs = kDebugMode;
  static bool _sanitizeSensitiveData = true;
  static String _logPrefix = '🚨 [ErrorHandler]';

  /// Configure error handling behavior
  static void configure({
    bool enableDetailedLogs = true,
    bool sanitizeSensitiveData = true,
    String logPrefix = '🚨 [ErrorHandler]',
  }) {
    _enableDetailedLogs = enableDetailedLogs;
    _sanitizeSensitiveData = sanitizeSensitiveData;
    _logPrefix = logPrefix;
  }

  /// Handle API errors with controlled logging
  static String handleApiError(
    dynamic error, {
    String? context,
    bool showToUser = true,
    String? customUserMessage,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final contextInfo = context != null ? '[$context]' : '';

    // Log detailed error for debugging
    if (_enableDetailedLogs) {
      developer.log(
        '$_logPrefix$contextInfo API Error at $timestamp',
        error: error,
        stackTrace: StackTrace.current,
        name: 'API_ERROR',
        level: 900, // Error level
      );
    }

    // Sanitize error message if enabled
    String sanitizedError = error.toString();
    if (_sanitizeSensitiveData) {
      sanitizedError = ErrorUtils.sanitizeServerMessage(sanitizedError);
    }

    // Create user-friendly message
    String userMessage;
    if (customUserMessage != null) {
      userMessage = customUserMessage;
    } else if (showToUser) {
      userMessage = ErrorUtils.getUserFriendlyErrorMessage(sanitizedError);
    } else {
      userMessage = 'Terjadi kesalahan sistem';
    }

    // Log user message if different from raw error
    if (_enableDetailedLogs && userMessage != sanitizedError) {
      developer.log(
        '$_logPrefix$contextInfo User Message: $userMessage',
        name: 'USER_ERROR_MESSAGE',
        level: 800, // Warning level
      );
    }

    return userMessage;
  }

  /// Handle UI errors with controlled logging
  static String handleUiError(
    dynamic error, {
    String? context,
    String? customUserMessage,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final contextInfo = context != null ? '[$context]' : '';

    // Log detailed error for debugging
    if (_enableDetailedLogs) {
      developer.log(
        '$_logPrefix$contextInfo UI Error at $timestamp',
        error: error,
        stackTrace: StackTrace.current,
        name: 'UI_ERROR',
        level: 900,
      );
    }

    // Sanitize error message if enabled
    String sanitizedError = error.toString();
    if (_sanitizeSensitiveData) {
      sanitizedError = ErrorUtils.sanitizeServerMessage(sanitizedError);
    }

    // Create user-friendly message
    String userMessage = customUserMessage ??
        ErrorUtils.getUserFriendlyErrorMessage(sanitizedError);

    // Log user message
    if (_enableDetailedLogs) {
      developer.log(
        '$_logPrefix$contextInfo Displayed Message: $userMessage',
        name: 'UI_ERROR_MESSAGE',
        level: 700, // Info level
      );
    }

    return userMessage;
  }

  /// Handle payment errors with extra security
  static String handlePaymentError(
    dynamic error, {
    String? context,
    bool maskSensitiveInfo = true,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final contextInfo = context != null ? '[$context]' : '';

    // Extra sensitive data masking for payment errors
    String errorStr = error.toString();
    if (maskSensitiveInfo) {
      // Mask credit card numbers, tokens, etc.
      errorStr = errorStr.replaceAll(
          RegExp(r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b'),
          '[CARD_MASKED]');
      errorStr = errorStr.replaceAll(RegExp(r'\b\d{16}\b'), '[CARD_MASKED]');
      errorStr = errorStr.replaceAll(
          RegExp(r'token[_-]?[a-zA-Z0-9]{10,}'), '[TOKEN_MASKED]');
    }

    // Log with payment-specific level
    if (_enableDetailedLogs) {
      developer.log(
        '$_logPrefix$contextInfo Payment Error at $timestamp',
        error: errorStr,
        stackTrace: StackTrace.current,
        name: 'PAYMENT_ERROR',
        level: 1000, // Critical level
      );
    }

    // Always sanitize payment errors
    String sanitizedError = _sanitizeSensitiveData
        ? ErrorUtils.sanitizeServerMessage(errorStr)
        : errorStr;

    String userMessage = ErrorUtils.getUserFriendlyErrorMessage(sanitizedError);

    return userMessage;
  }

  /// Log custom events with controlled format
  static void logEvent(
    String event, {
    dynamic data,
    String? context,
    int level = 600, // Default info level
  }) {
    if (!_enableDetailedLogs) return;

    final timestamp = DateTime.now().toIso8601String();
    final contextInfo = context != null ? '[$context]' : '';

    developer.log(
      '$_logPrefix$contextInfo $event at $timestamp',
      error: data,
      name: 'CUSTOM_EVENT',
      level: level,
    );
  }

  /// Get formatted log entry for external logging systems
  static Map<String, dynamic> formatLogEntry({
    required String type,
    required dynamic error,
    String? context,
    String? userMessage,
    StackTrace? stackTrace,
  }) {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'type': type,
      'context': context,
      'error': _sanitizeSensitiveData
          ? ErrorUtils.sanitizeServerMessage(error.toString())
          : error.toString(),
      'userMessage': userMessage,
      'stackTrace': stackTrace?.toString(),
      'platform': 'flutter',
      'version': '1.0.0', // You can make this dynamic
    };
  }
}
