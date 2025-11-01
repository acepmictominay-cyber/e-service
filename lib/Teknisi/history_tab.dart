import 'package:e_service/api_services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryTab extends StatelessWidget {
  final List<dynamic> transaksiList;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final Future<void> Function(dynamic, String) onUpdateTransaksiStatus;

  const HistoryTab({
    super.key,
    required this.transaksiList,
    required this.isLoading,
    required this.onRefresh,
    required this.onUpdateTransaksiStatus,
  });

  @override
  Widget build(BuildContext context) {
    // Filter transaksi that are completed
    final filteredTransaksi = transaksiList.where((transaksi) {
      final status = transaksi['trans_status']?.toString().toLowerCase() ?? '';
      return status == 'completed' || status == 'selesai' || status == 'finished';
    }).toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredTransaksi.isEmpty
          ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada data transaksi',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
          : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredTransaksi.length,
            itemBuilder: (context, index) {
              final transaksi = filteredTransaksi[index];
              return _buildTransaksiCard(context, transaksi);
            },
          ),
    );
  }

  Widget _buildTransaksiCard(BuildContext context, dynamic transaksi) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction ID and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  transaksi['trans_kode'] ?? 'N/A',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(transaksi['trans_status'] ?? '').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    transaksi['trans_status'] ?? 'N/A',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _getStatusColor(transaksi['trans_status'] ?? ''),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Transaction Details
            _infoRow('Tanggal', transaksi['trans_tanggal'] ?? 'N/A'),
            const SizedBox(height: 8),
            _infoRow('Total', 'Rp ${transaksi['trans_total']?.toString() ?? '0'}'),
            const SizedBox(height: 8),
            _infoRow('Metode Pembayaran', transaksi['trans_metode'] ?? 'N/A'),

            // Customer Info if available
            if (transaksi['cos_nama'] != null) ...[
              const SizedBox(height: 8),
              _infoRow('Pelanggan', transaksi['cos_nama']),
            ],

            // Service Type if available
            if (transaksi['service_type'] != null) ...[
              const SizedBox(height: 8),
              _infoRow('Jenis Layanan', transaksi['service_type']),
            ],


          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Text(value, style: GoogleFonts.poppins(fontSize: 14))),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'paid':
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
