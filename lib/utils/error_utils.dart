/// Utility class for handling and displaying errors safely
import 'package:flutter/material.dart';

class ErrorUtils {
  /// Convert any error to a user-friendly message
  static String getUserFriendlyErrorMessage(dynamic error) {
    if (error == null) return 'Terjadi kesalahan yang tidak diketahui';

    final errorString = error.toString().toLowerCase();

    // Network-related errors
    if (errorString.contains('socketexception') ||
        errorString.contains('connection') ||
        errorString.contains('network') ||
        errorString.contains('timeout')) {
      return 'Koneksi internet bermasalah. Periksa koneksi Anda dan coba lagi.';
    }

    // Server errors
    if (errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504')) {
      return 'Server sedang mengalami masalah. Silakan coba lagi nanti.';
    }

    // Authentication errors
    if (errorString.contains('401') ||
        errorString.contains('403') ||
        errorString.contains('unauthorized')) {
      return 'Sesi Anda telah berakhir. Silakan login kembali.';
    }

    // Validation errors - remove any field names that might be exposed
    if (errorString.contains('validation') ||
        errorString.contains('invalid') ||
        errorString.contains('required')) {
      return 'Data yang dimasukkan tidak valid. Periksa kembali dan coba lagi.';
    }

    // Database or field-related errors - sanitize any exposed field names
    final sanitizedError = _sanitizeErrorMessage(errorString);
    if (sanitizedError != errorString) {
      return 'Terjadi kesalahan saat memproses data. Silakan coba lagi.';
    }

    // Generic fallback
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  /// Remove sensitive information from error messages
  static String _sanitizeErrorMessage(String error) {
    // Remove database field names (cos_*, trans_*, etc.)
    error = error.replaceAll(RegExp(r'\b(cos|trans|kry|tdkn|user)_[a-z_]+\b'), '[field]');

    // Remove server URLs
    error = error.replaceAll(RegExp(r'https?://[^\s]+'), '[server]');

    // Remove file paths
    error = error.replaceAll(RegExp(r'/[^\s]+\.[a-zA-Z]{2,4}'), '[file]');

    return error;
  }

  /// Show a safe error snackbar
  static void showErrorSnackBar(BuildContext context, dynamic error, {String? customMessage}) {
    final message = customMessage ?? getUserFriendlyErrorMessage(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Sanitize server response messages to remove sensitive information
  static String sanitizeServerMessage(String message) {
    if (message.isEmpty) return message;

    // Remove database field names
    message = message.replaceAll(RegExp(r'\b(cos|trans|kry|tdkn|user)_[a-z_]+\b'), '[field]');

    // Remove server URLs
    message = message.replaceAll(RegExp(r'https?://[^\s]+'), '[server]');

    // Remove file paths
    message = message.replaceAll(RegExp(r'/[^\s]+\.[a-zA-Z]{2,4}'), '[file]');

    // Remove SQL-related terms
    message = message.replaceAll(RegExp(r'\b(sql|query|database|table|column)\b', caseSensitive: false), '[system]');

    return message;
  }

  /// Show a success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}