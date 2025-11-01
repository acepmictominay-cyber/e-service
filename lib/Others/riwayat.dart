import 'package:e_service/Beli/shop.dart';
import 'package:e_service/Home/Home.dart';
import 'package:e_service/Others/notifikasi.dart';
import 'package:e_service/Promo/promo.dart';
import 'package:e_service/Service/Service.dart';
import 'package:e_service/api_services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  int currentIndex =
      4; // Assuming Riwayat is added to nav, but for now set to Profile index
  List<Map<String, dynamic>> orderHistory = [];
  List<dynamic> completedTransactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompletedTransactions();
  }



  Future<void> _loadCompletedTransactions() async {
    setState(() => isLoading = true);
    try {
      final allTransactions = await ApiService.getTransaksi();
      final filteredTransactions = <dynamic>[];
      for (final transaksi in allTransactions) {
        final status = transaksi['trans_status']?.toString().toLowerCase() ?? '';
        if (status == 'completed' || status == 'selesai' || status == 'finished') {
          filteredTransactions.add(transaksi);
        }
      }
      setState(() {
        completedTransactions = filteredTransactions;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        completedTransactions = [];
        isLoading = false;
      });
      // Error loading completed transactions
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: Image.asset('assets/image/logo.png', width: 95, height: 30),
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCompletedTransactions,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : completedTransactions.isEmpty
              ? Center(
                child: Text(
                  'Belum ada riwayat transaksi yang selesai.',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              )
              : ListView.builder(
                itemCount: completedTransactions.length,
                itemBuilder: (context, index) {
                  final transaksi = completedTransactions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transaksi: ${transaksi['trans_kode'] ?? 'N/A'}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _infoRow(
                            'Tanggal',
                            transaksi['trans_tanggal'] ?? 'N/A',
                            'Total',
                            'Rp ${transaksi['trans_total']?.toString() ?? '0'}',
                          ),
                          const SizedBox(height: 8),
                          _infoRow(
                            'Metode Pembayaran',
                            transaksi['trans_metode'] ?? 'N/A',
                            'Status',
                            transaksi['trans_status'] ?? 'N/A',
                          ),
                          if (transaksi['cos_nama'] != null) ...[
                            const SizedBox(height: 8),
                            _infoRow(
                              'Pelanggan',
                              transaksi['cos_nama'],
                              'Keluhan',
                              transaksi['ket_keluhan'] ?? 'Tidak ada keluhan',
                            ),
                          ],
                          if (transaksi['service_type'] != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Jenis Layanan: ${transaksi['service_type']}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ServicePage()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MarketplacePage()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TukarPoinPage()),
            );
          } else if (index == 4) {
            // Stay on Riwayat
            setState(() {
              currentIndex = index;
            });
          }
        },
        backgroundColor: Colors.blue,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.build_circle_outlined),
            label: 'Service',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Beli',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon:
                currentIndex == 3
                    ? Image.asset(
                      'assets/image/promo.png',
                      width: 24,
                      height: 24,
                    )
                    : Opacity(
                      opacity: 0.6,
                      child: Image.asset(
                        'assets/image/promo.png',
                        width: 24,
                        height: 24,
                      ),
                    ),
            label: 'Promo',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label1, String value1, String label2, String value2) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label1,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value1,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label2,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value2,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
