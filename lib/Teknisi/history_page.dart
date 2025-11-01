import 'package:e_service/api_services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'history_tab.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<dynamic> transaksiList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => isLoading = true);
    try {
      final fetchedTransaksi = await ApiService.getTransaksi();
      if (mounted) setState(() => transaksiList = fetchedTransaksi);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data transaksi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _updateTransaksiStatus(
    dynamic transaksi,
    String newStatus,
  ) async {
    final String transKode = transaksi['trans_kode'];
    final int index = transaksiList.indexWhere(
      (t) => t['trans_kode'] == transKode,
    );
    if (index == -1) return;

    final oldStatus = transaksiList[index]['trans_status'];
    setState(() => transaksiList[index]['trans_status'] = newStatus);

    try {
      await ApiService.updateTransaksiStatus(transKode, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status transaksi diperbarui ke $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update status transaksi: $e')),
        );
      }
      setState(() => transaksiList[index]['trans_status'] = oldStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        title: Text(
          'Riwayat Pekerjaan',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: HistoryTab(
        transaksiList: transaksiList,
        isLoading: isLoading,
        onRefresh: _refreshData,
        onUpdateTransaksiStatus: _updateTransaksiStatus,
      ),
    );
  }
}
