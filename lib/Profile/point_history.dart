import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../api_services/api_service.dart';
import '../Others/session_manager.dart';

class PointHistoryPage extends StatefulWidget {
  const PointHistoryPage({super.key});

  @override
  State<PointHistoryPage> createState() => _PointHistoryPageState();
}

class _PointHistoryPageState extends State<PointHistoryPage> {
  List<dynamic> pointTransactions = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPointTransactions();
  }

  Future<void> _loadPointTransactions() async {
    try {
      final session = await SessionManager.getUserSession();
      final customerId = session['id']?.toString();

      if (customerId == null) {
        setState(() {
          errorMessage = 'User tidak ditemukan';
          isLoading = false;
        });
        return;
      }

      final transactions = await ApiService.getPointTransactions(customerId);

      setState(() {
        pointTransactions = transactions;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat riwayat poin: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0041c3),
        title: Text(
          "Riwayat Poin",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPointTransactions,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : pointTransactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada transaksi poin',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPointTransactions,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: pointTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = pointTransactions[index];
                          return _buildTransactionCard(transaction);
                        },
                      ),
                    ),
    );
  }

  Widget _buildTransactionCard(dynamic transaction) {
    final type = transaction['type'] ?? 'unknown';
    final amount = transaction['amount'] ?? 0;
    final description = transaction['description'] ?? 'Transaksi poin';
    final date = transaction['created_at'] ?? transaction['date'];

    DateTime? transactionDate;
    try {
      if (date != null) {
        transactionDate = DateTime.parse(date.toString());
      }
    } catch (e) {
      // Invalid date format
    }

    final isPositive = type == 'earned' || type == 'credit' || amount > 0;
    final absAmount = amount.abs();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPositive
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPositive ? Icons.add : Icons.remove,
              color: isPositive ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                if (transactionDate != null)
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(transactionDate),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                isPositive ? '+' : '-',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ),
              Text(
                NumberFormat('#,###', 'id_ID').format(absAmount),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 4),
              Image.asset('assets/image/coin.png', width: 16, height: 16),
            ],
          ),
        ],
      ),
    );
  }
}