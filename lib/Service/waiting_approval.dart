import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'tracking_driver.dart';
import '../api_services/api_service.dart';
import '../Others/session_manager.dart';

class WaitingApprovalPage extends StatefulWidget {
  final String? transKode;
  final int? jumlahItem;

  const WaitingApprovalPage({super.key, this.transKode, this.jumlahItem});

  @override
  State<WaitingApprovalPage> createState() => _WaitingApprovalPageState();
}

class _WaitingApprovalPageState extends State<WaitingApprovalPage> {
  bool isApproved = false;
  bool isLoading = true;
  String transKode = '';
  Map<String, dynamic>? orderData;
  List<Map<String, String>> parsedItems = [];
  Timer? _statusCheckTimer;

  @override
  void initState() {
    super.initState();
    if (widget.transKode != null && widget.transKode!.isNotEmpty) {
      transKode = widget.transKode!;
      _loadOrderDetails();
      _startStatusCheck();
    } else {
      _fetchLatestTransKode();
    }
  }

  Future<void> _fetchLatestTransKode() async {
    try {
      String? cosKode = await SessionManager.getCustomerId();
      if (cosKode == null) {
        setState(() => isLoading = false);
        return;
      }

      // Gunakan method yang sudah ada di ApiService
      final allOrders = await ApiService.getOrderList();

      // Filter berdasarkan customer
      final customerOrders =
          allOrders.where((o) => o['cos_kode']?.toString() == cosKode).toList();

      if (customerOrders.isNotEmpty) {
        final pendingOnly =
            customerOrders
                .where(
                  (o) =>
                      o['trans_status']?.toString().toLowerCase() == 'pending',
                )
                .toList();

        if (pendingOnly.isNotEmpty) {
          pendingOnly.sort((a, b) {
            String dateA =
                (a['created_at'] ?? a['trans_tanggal'] ?? '').toString();
            String dateB =
                (b['created_at'] ?? b['trans_tanggal'] ?? '').toString();
            return dateB.compareTo(dateA);
          });

          transKode = pendingOnly.first['trans_kode']?.toString() ?? '';
        }
      }

      if (transKode.isNotEmpty) {
        _loadOrderDetails();
        _startStatusCheck();
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching latest trans_kode: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadOrderDetails() async {
    if (transKode.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final result = await ApiService.getOrderListByTransKode(transKode);

      Map<String, dynamic>? data;

      // Handle response - API returns List
      if (result is List && result.isNotEmpty) {
        if (result.first is Map<String, dynamic>) {
          data = Map<String, dynamic>.from(result.first);
        }
      }

      if (data != null) {
        setState(() {
          orderData = data;
          parsedItems = _parseCommaSeparatedData(data!);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error loading order details: $e');
      setState(() => isLoading = false);
    }
  }

  // Ganti separator dari koma ke |||
  List<Map<String, String>> _parseCommaSeparatedData(
    Map<String, dynamic> data,
  ) {
    const String separator = '|||';

    List<String> mereks = (data['merek']?.toString() ?? '').split(separator);
    List<String> devices = (data['device']?.toString() ?? '').split(separator);
    List<String> statuses = (data['status_garansi']?.toString() ?? '').split(
      separator,
    );
    List<String> seris = (data['seri']?.toString() ?? '').split(separator);
    List<String> keluhans = (data['ket_keluhan']?.toString() ?? '').split(
      separator,
    );
    List<String> emails = (data['email']?.toString() ?? '').split(separator);

    int itemCount = [
      mereks.length,
      devices.length,
      statuses.length,
      seris.length,
    ].reduce((a, b) => a > b ? a : b);

    // Jika semua field kosong atau hanya 1 item dengan value kosong, return empty
    if (itemCount == 1 && mereks[0].trim().isEmpty) {
      return [];
    }

    List<Map<String, String>> items = [];
    for (int i = 0; i < itemCount; i++) {
      items.add({
        'merek': i < mereks.length ? mereks[i].trim() : '-',
        'device': i < devices.length ? devices[i].trim() : '-',
        'status_garansi': i < statuses.length ? statuses[i].trim() : '-',
        'seri': i < seris.length ? seris[i].trim() : '-',
        'ket_keluhan': i < keluhans.length ? keluhans[i].trim() : '-',
        'email': i < emails.length ? emails[i].trim() : '',
      });
    }

    return items;
  }

  void _startStatusCheck() {
    if (transKode.isEmpty) return;

    _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (
      timer,
    ) async {
      try {
        final result = await ApiService.getOrderListByTransKode(transKode);

        String status = 'pending';

        // Handle response - API returns List
        if (result is List && result.isNotEmpty) {
          final firstItem = result.first;
          if (firstItem is Map) {
            status =
                firstItem['trans_status']?.toString().toLowerCase() ??
                'pending';
          }
        }

        if (status == 'confirm' || status == 'confirmed') {
          setState(() => isApproved = true);
          _statusCheckTimer?.cancel();

          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => TrackingPage(queueCode: transKode),
              ),
            );
          });
        }
      } catch (e) {
        print('Error checking status: $e');
      }
    });
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  void _copyTransKode() {
    Clipboard.setData(ClipboardData(text: transKode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trans Kode berhasil disalin')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        title: Text(
          "Menunggu Persetujuan",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
          ),
        ),
        elevation: 0,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).shadowColor.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon Status
                        Icon(
                          isApproved
                              ? Icons.check_circle
                              : Icons.hourglass_empty,
                          size: 80,
                          color: isApproved ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(height: 20),

                        // Title
                        Text(
                          isApproved
                              ? "Pesanan Disetujui!"
                              : "Menunggu Persetujuan Admin",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Trans Kode Section
                        if (!isApproved && transKode.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Trans Kode',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white70
                                            : Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  transKode,
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${parsedItems.length} item',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white70
                                            : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _copyTransKode,
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('Salin Trans Kode'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 24,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Status Message
                        Text(
                          isApproved
                              ? "Sedang mengarahkan ke halaman tracking..."
                              : "Pesanan Anda sedang dalam proses persetujuan.\nMohon tunggu sebentar.",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // Detail Items
                        if (parsedItems.isNotEmpty && !isApproved)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Detail Pesanan',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : Colors.black87,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'PENDING',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // List Items
                                ...parsedItems.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  Map<String, String> item = entry.value;

                                  return Container(
                                    margin: EdgeInsets.only(
                                      bottom:
                                          index < parsedItems.length - 1
                                              ? 12
                                              : 0,
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Header Item
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Barang ${index + 1}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      Theme.of(
                                                                context,
                                                              ).brightness ==
                                                              Brightness.dark
                                                          ? Colors.white
                                                          : Theme.of(
                                                            context,
                                                          ).colorScheme.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),

                                        // Details
                                        _buildItemDetail(
                                          'Merek',
                                          item['merek'] ?? '-',
                                        ),
                                        _buildItemDetail(
                                          'Device',
                                          item['device'] ?? '-',
                                        ),
                                        _buildItemDetail(
                                          'Seri',
                                          item['seri'] ?? '-',
                                        ),
                                        _buildItemDetail(
                                          'Status',
                                          item['status_garansi'] ?? '-',
                                        ),
                                        _buildItemDetail(
                                          'Keluhan',
                                          item['ket_keluhan'] ?? '-',
                                        ),
                                        if (item['email']?.isNotEmpty == true)
                                          _buildItemDetail(
                                            'Email',
                                            item['email'] ?? '-',
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),

                        // Info jika tidak ada data
                        if (parsedItems.isEmpty && !isApproved && !isLoading)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.amber[700],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Detail pesanan sedang dimuat...',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.amber[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildItemDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.white60
                        : Colors.black45,
              ),
            ),
          ),
          Text(
            ': ',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white60
                      : Colors.black45,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
