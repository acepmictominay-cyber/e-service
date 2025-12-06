// File: lib/utils/transaction_debug.dart
// Gunakan ini untuk debug TransactionResult properties

class TransactionResult {
  final String status;

  TransactionResult({required this.status});

  @override
  String toString() {
    return 'TransactionResult(status: $status)';
  }
}

class TransactionDebugHelper {
  
  /// Print semua properti yang tersedia di TransactionResult
  static void printTransactionResult(TransactionResult result) {
    print('====== TRANSACTION RESULT DEBUG ======');
    
    try {
      print('status: ${result.status}');
    } catch (e) {
      print('status: ERROR - $e');
    }
    
    // Coba properti lain yang mungkin ada
    try {
      // Kadang TransactionResult punya toJson atau toString yang informatif
      print('toString: ${result.toString()}');
    } catch (e) {
      print('toString: ERROR - $e');
    }
    
    print('======================================');
  }
  
  /// Cek apakah transaksi sukses berdasarkan status yang tersedia
  static bool isSuccess(TransactionResult result) {
    final status = result.status.toLowerCase() ?? '';
    return status == 'capture' || 
           status == 'settlement' || 
           status == 'success';
  }
  
  /// Cek apakah transaksi dibatalkan
  static bool isCanceled(TransactionResult result) {
    final status = result.status.toLowerCase() ?? '';
    return status.isEmpty || 
           status == 'cancel' || 
           status == 'failure';
  }
}
