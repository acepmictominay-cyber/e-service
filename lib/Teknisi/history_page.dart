import 'package:azza_service/api_services/api_service.dart';
import 'package:azza_service/Others/session_manager.dart';
import 'package:azza_service/utils/error_utils.dart';
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
      final kryKode = await SessionManager.getkry_kode();
      if (kryKode != null) {
        final fetchedTransaksi = await ApiService.getOrderListByKryKode(kryKode);
        if (mounted) setState(() => transaksiList = fetchedTransaksi);
      } else {
        if (mounted) setState(() => transaksiList = []);
      }
    } catch (e) {
      if (mounted) {
        ErrorUtils.showErrorSnackBar(context, e, customMessage: 'Gagal memuat data transaksi');
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

    final oldStatus = transaksiList[index]['status'];
    setState(() => transaksiList[index]['status'] = newStatus);

    try {
      await ApiService.updateOrderListStatus(transKode, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status transaksi diperbarui ke $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorUtils.showErrorSnackBar(context, e, customMessage: 'Gagal memperbarui status transaksi');
      }
      setState(() => transaksiList[index]['status'] = oldStatus);
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
