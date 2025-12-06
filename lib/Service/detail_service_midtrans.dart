import 'package:azza_service/Service/Service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tracking_driver.dart';
import '../api_services/unified_payment_service.dart';
import '../api_services/payment_service.dart';
import '../Others/session_manager.dart';
import '../api_services/api_service.dart';

class DetailServiceMidtransPage extends StatefulWidget {
  final String serviceType;
  final String nama;
  final String? status;
  final int jumlahBarang;
  final List<Map<String, String?>> items;
  final String alamat;

  const DetailServiceMidtransPage({
    super.key,
    required this.serviceType,
    required this.nama,
    required this.status,
    required this.jumlahBarang,
    required this.items,
    required this.alamat,
  });

  @override
  State<DetailServiceMidtransPage> createState() =>
      _DetailServiceMidtransPageState();
}

class _DetailServiceMidtransPageState extends State<DetailServiceMidtransPage> {
  Map<String, dynamic>? selectedAddress;
  String? selectedPaymentMethod;
  int? selectedDiscount;

  static int _lastQueueNumber = 0;
  late String currentQueueCode;

  String _generateQueueCode(String serviceType) {
    _lastQueueNumber++;
    return "TTS${_lastQueueNumber.toString().padLeft(3, '0')}-$serviceType";
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Scale factor based on screen width (assuming base width 375 for iPhone 6/7/8)
    final double scale = screenWidth / 375.0;
    final double basePadding = 16 * scale;
    final double baseIconSize = 40 * scale;
    final double baseTextSize = 16 * scale;
    final double baseButtonHeight = 18 * scale;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF0041c3),
        elevation: 1,
        shadowColor: Colors.black12,
        titleTextStyle: const TextStyle(color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Ringkasan Pesanan"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: basePadding,
          right: basePadding,
          top: 8 * scale,
          bottom: 8 * scale + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          children: [
            _buildServiceItems(scale, basePadding, baseIconSize, baseTextSize),
            SizedBox(height: 16 * scale),
            _buildRingkasan(scale, basePadding, baseTextSize),
            SizedBox(height: 24 * scale),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12 * scale),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0041c3).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12 * scale),
                  ),
                  padding: EdgeInsets.symmetric(vertical: baseButtonHeight),
                ),
                onPressed: () => _startMidtransPayment(context),
                child: Text(
                  "Selesaikan Pesanan",
                  style: TextStyle(
                    fontSize: baseTextSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 24 * scale), // Add some bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildPengiriman() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${widget.jumlahBarang} Barang",
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 6),
          const Text(
            "Service Online",
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItems(
    double scale,
    double basePadding,
    double baseIconSize,
    double baseTextSize,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(basePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8 * scale),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0041c3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12 * scale),
                  ),
                  child: Icon(
                    widget.serviceType == 'cleaning'
                        ? Icons.cleaning_services
                        : Icons.build,
                    color: Colors.blue[700],
                    size: 24 * scale,
                  ),
                ),
                SizedBox(width: 12 * scale),
                Text(
                  "Layanan ${widget.serviceType == 'cleaning' ? 'Cleaning' : 'Perbaikan'}",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: baseTextSize,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16 * scale),
            ...widget.items.map((item) {
              return Container(
                margin: EdgeInsets.only(bottom: 12 * scale),
                padding: EdgeInsets.all(12 * scale),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12 * scale),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8 * scale),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8 * scale),
                      ),
                      child: Icon(
                        widget.serviceType == 'cleaning'
                            ? Icons.cleaning_services
                            : Icons.build,
                        color: Colors.blue[600],
                        size: 20 * scale,
                      ),
                    ),
                    SizedBox(width: 12 * scale),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${item['merek']} ${item['device']}",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15 * scale,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4 * scale),
                          _buildInfoRow("Status", item['status'] ?? '-', scale),
                          _buildInfoRow("Seri", item['seri'] ?? '-', scale),
                          if (widget.serviceType == 'repair' &&
                              item['part'] != null)
                            _buildInfoRow("Keluhan", item['part']!, scale),
                          SizedBox(height: 8 * scale),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8 * scale,
                              vertical: 4 * scale,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[600],
                              borderRadius: BorderRadius.circular(6 * scale),
                            ),
                            child: Text(
                              "1x   Rp 1",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13 * scale,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, double scale) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2 * scale),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 12 * scale,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12 * scale,
              color: Colors.black87,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRingkasan(
    double scale,
    double basePadding,
    double baseTextSize,
  ) {
    int subtotal = widget.jumlahBarang * 1;
    int biayaTeknisi = 0;
    int discountAmount = 0;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.all(14 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ringkasan Pesanan",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15 * scale),
          ),
          SizedBox(height: 10 * scale),
          _summaryRow("Biaya Pengecekan", "Rp 1", scale: scale),
          _summaryRow("Biaya Teknisi", "Rp 0", scale: scale),
          _summaryRow("Diskon", "Rp 0", scale: scale),
          const Divider(),
          _summaryRow(
            "Subtotal",
            "Rp 1",
            isTotal: true,
            color: const Color(0xFF0041c3),
            scale: scale,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? color,
    double scale = 1.0,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2 * scale),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13 * scale, color: Colors.black87),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: (isTotal ? 15 : 13) * scale,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _startMidtransPayment(BuildContext context) async {
    // Tampilkan loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 🔹 Dapatkan customerId dari session
      String? customerId = await SessionManager.getCustomerId();
      if (customerId == null) {
        // Close loading
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer ID tidak ditemukan. Silakan login ulang.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create service payment data
      final serviceData = UnifiedPaymentService.createServicePaymentData(
        serviceType: widget.serviceType,
        items: widget.items,
        amount: widget.jumlahBarang * 1,
      );

      await UnifiedPaymentService.startUnifiedPayment(
        context: context,
        paymentType: PaymentType.service,
        orderId: 'order_${DateTime.now().millisecondsSinceEpoch}',
        amount: widget.jumlahBarang * 1,
        customerId: customerId,
        customerName: widget.nama,
        customerEmail:
            '${widget.nama.replaceAll(' ', '').toLowerCase()}@example.com',
        customerPhone:
            selectedAddress != null
                ? selectedAddress!['hp'] ?? '08123456789'
                : '08123456789',
        itemDetails:
            widget.items
                .map(
                  (item) => {
                    'id': '34GM',
                    'price': 1,
                    'quantity': 1,
                    'name': 'Service ${item['merek']} ${item['device']}',
                  },
                )
                .toList(),
        serviceData: serviceData,
        onSuccess: (orderId) {
          // Close loading
          Navigator.of(context, rootNavigator: true).pop();
          _onPaymentSuccess();
        },
        onFailure: (errorMessage) {
          // Close loading
          Navigator.of(context, rootNavigator: true).pop();
          // Tampilkan pesan error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        },
      );
    } catch (e) {
      // Close loading jika masih ada
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _discountButton(int discount, String label) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedDiscount = discount;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              selectedDiscount == discount
                  ? const Color(0xFF0041c3)
                  : Colors.grey[300],
          foregroundColor:
              selectedDiscount == discount ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  void _showPaymentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Pilih Metode Pembayaran",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 20),
              _paymentItem(Icons.account_balance, "Transfer Bank BCA"),
              _paymentItem(Icons.account_balance_wallet, "Transfer Bank BRI"),
              _paymentItem(
                Icons.account_balance_rounded,
                "Transfer Bank Mandiri",
              ),
              _paymentItem(Icons.payment, "Midtrans Payment"),
              _paymentItem(Icons.payment, "Manual Payment"),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _paymentItem(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      onTap: () async {
        if (label == "Midtrans Payment") {
          // Close bottom sheet dulu
          Navigator.pop(context);

          // Tampilkan loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => const Center(child: CircularProgressIndicator()),
          );

          try {
            // 🔹 Dapatkan customerId dari session
            String? customerId = await SessionManager.getCustomerId();
            if (customerId == null) {
              // Close loading
              Navigator.of(context, rootNavigator: true).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Customer ID tidak ditemukan. Silakan login ulang.',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            // Create service payment data
            final serviceData = UnifiedPaymentService.createServicePaymentData(
              serviceType: widget.serviceType,
              items: widget.items,
              amount: widget.jumlahBarang * 1,
            );

            await UnifiedPaymentService.startUnifiedPayment(
              context: context,
              paymentType: PaymentType.service,
              orderId: 'order_${DateTime.now().millisecondsSinceEpoch}',
              amount: widget.jumlahBarang * 1,
              customerId: customerId,
              customerName: widget.nama,
              customerEmail:
                  '${widget.nama.replaceAll(' ', '').toLowerCase()}@example.com',
              customerPhone:
                  selectedAddress != null
                      ? selectedAddress!['hp'] ?? '08123456789'
                      : '08123456789',
              itemDetails:
                  widget.items
                      .map(
                        (item) => {
                          'id': '34GM',
                          'price': 1,
                          'quantity': 1,
                          'name': 'Service ${item['merek']} ${item['device']}',
                        },
                      )
                      .toList(),
              serviceData: serviceData,
              onSuccess: (orderId) {
                // Close loading
                Navigator.of(context, rootNavigator: true).pop();
                _onPaymentSuccess();
              },
              onFailure: (errorMessage) {
                // Close loading
                Navigator.of(context, rootNavigator: true).pop();
                // Tampilkan pesan error
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
            );
          } catch (e) {
            // Close loading jika masih ada
            if (Navigator.canPop(context)) {
              Navigator.of(context, rootNavigator: true).pop();
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
            );
          }
        } else {
          setState(() {
            selectedPaymentMethod = label;
          });
          Navigator.pop(context);
        }
      },
    );
  }

  // Dan update method _onPaymentSuccess:
  void _onPaymentSuccess() async {
    // Get customer ID from session
    String? customerId = await SessionManager.getCustomerId();
    if (customerId != null) {
      // Create payment record in backend
      try {
        await PaymentService.createPayment(
          customerId: customerId,
          amount: widget.jumlahBarang * 1,
          kodeBarang: null,
        );
        print('Payment record created successfully');
      } catch (e) {
        print('Failed to create payment record: $e');
        // Continue with order completion even if payment record fails
      }

      // Create transaction record in backend
      bool transactionCreated = false;
      try {
        int subtotal = widget.jumlahBarang * 1;
        String currentDate = DateTime.now().toIso8601String().substring(
          0,
          10,
        ); // YYYY-MM-DD format

        // Extract details from the first item (assuming single item per transaction)
        String merek =
            widget.items.isNotEmpty ? widget.items[0]['merek'] ?? '' : '';
        String device =
            widget.items.isNotEmpty ? widget.items[0]['device'] ?? '' : '';
        String seri =
            widget.items.isNotEmpty ? widget.items[0]['seri'] ?? '' : '';
        String ketKeluhan =
            (widget.serviceType == 'repair' &&
                    widget.items.isNotEmpty &&
                    widget.items[0]['part'] != null)
                ? widget.items[0]['part']!
                : '';
        String statusGaransi =
            widget.items.isNotEmpty
                ? widget.items[0]['status'] ?? 'Tidak Ada Garansi'
                : 'Tidak Ada Garansi'; // Assuming status indicates warranty

        final response = await ApiService.createTransaksi({
          'cos_kode': customerId,
          'kry_kode': 'KRY001', // Placeholder technician code, adjust as needed
          'trans_total': subtotal.toDouble(),
          'trans_discount': 0.0,
          'trans_tanggal': currentDate,
          'trans_status': 'Waiting',
          'merek': merek,
          'device': device,
          'seri': seri,
          'ket_keluhan': ketKeluhan,
          'status_garansi': statusGaransi,
        });

        // Check if the response indicates success
        if (response['success'] == true) {
          print('Transaction record created successfully');
          transactionCreated = true;
        } else {
          print(
            'Transaction creation failed: ${response['message'] ?? 'Unknown error'}',
          );
          transactionCreated = false;
        }
      } catch (e) {
        print('Failed to create transaction record: $e');
        transactionCreated = false;
      }

      // Check if transaction creation failed
      if (!transactionCreated) {
        // Show payment failed popup
        _showPaymentFailedPopup(context);
        return;
      }
    }

    // Set selected payment method
    setState(() {
      selectedPaymentMethod = "Lakukan Pembayaran";
    });

    // Complete order
    _completeOrder(context);
  }

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case "Transfer Bank BCA":
        return Icons.account_balance;
      case "Transfer Bank BRI":
        return Icons.account_balance_wallet;
      case "Transfer Bank Mandiri":
        return Icons.account_balance_rounded;
      default:
        return Icons.account_balance;
    }
  }

  void _completeOrder(BuildContext context) async {
    // Get customer ID from session
    String? customerId = await SessionManager.getCustomerId();
    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer ID tidak ditemukan. Silakan login ulang.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create transaction record in backend
    bool transactionCreated = false;
    try {
      int subtotal = widget.jumlahBarang * 1;
      String currentDate = DateTime.now().toIso8601String().substring(
        0,
        10,
      ); // YYYY-MM-DD format

      // Extract details from the first item (assuming single item per transaction)
      String merek =
          widget.items.isNotEmpty ? widget.items[0]['merek'] ?? '' : '';
      String device =
          widget.items.isNotEmpty ? widget.items[0]['device'] ?? '' : '';
      String seri =
          widget.items.isNotEmpty ? widget.items[0]['seri'] ?? '' : '';
      String ketKeluhan =
          (widget.serviceType == 'repair' &&
                  widget.items.isNotEmpty &&
                  widget.items[0]['part'] != null)
              ? widget.items[0]['part']!
              : '';
      String statusGaransi =
          widget.items.isNotEmpty
              ? widget.items[0]['status'] ?? 'Tidak Ada Garansi'
              : 'Tidak Ada Garansi'; // Assuming status indicates warranty

      final response = await ApiService.createTransaksi({
        'cos_kode': customerId,
        'kry_kode': 'KRY001', // Valid technician code
        'trans_total': subtotal.toDouble(),
        'trans_discount': 0.0,
        'trans_tanggal': currentDate,
        'trans_status': 'Waiting',
        'merek': merek,
        'device': device,
        'seri': seri,
        'ket_keluhan': ketKeluhan,
        'status_garansi': statusGaransi,
      });

      // Check if the response indicates success
      if (response['success'] == true) {
        print('Transaction record created successfully');
        transactionCreated = true;
      } else {
        print(
          'Transaction creation failed: ${response['message'] ?? 'Unknown error'}',
        );
        transactionCreated = false;
      }
    } catch (e) {
      print('Failed to create transaction record: $e');
      transactionCreated = false;
    }

    // Check if transaction creation failed
    if (!transactionCreated) {
      // Show payment failed popup
      _showPaymentFailedPopup(context);
      return;
    }

    // Buat kode antrean baru setiap pesanan selesai
    currentQueueCode = _generateQueueCode(widget.serviceType);

    // Simpan informasi pesanan ke SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('${currentQueueCode}_nama', widget.nama);
    await prefs.setString(
      '${currentQueueCode}_serviceType',
      widget.serviceType,
    );
    await prefs.setString(
      '${currentQueueCode}_device',
      widget.items.isNotEmpty
          ? widget.items[0]['device'] ?? 'Unknown'
          : 'Unknown',
    );
    await prefs.setString(
      '${currentQueueCode}_merek',
      widget.items.isNotEmpty
          ? widget.items[0]['merek'] ?? 'Unknown'
          : 'Unknown',
    );
    await prefs.setString(
      '${currentQueueCode}_seri',
      widget.items.isNotEmpty
          ? widget.items[0]['seri'] ?? 'Unknown'
          : 'Unknown',
    );
    await prefs.setString(
      '${currentQueueCode}_jamMulai',
      DateTime.now().toString(),
    );

    // Debug print untuk memastikan data tersimpan
    print('Data tersimpan untuk kode: $currentQueueCode');
    print('Nama: ${widget.nama}');
    print('Service Type: ${widget.serviceType}');
    print(
      'Device: ${widget.items.isNotEmpty ? widget.items[0]['device'] : 'Unknown'}',
    );
    print(
      'Merek: ${widget.items.isNotEmpty ? widget.items[0]['merek'] : 'Unknown'}',
    );
    print(
      'Seri: ${widget.items.isNotEmpty ? widget.items[0]['seri'] : 'Unknown'}',
    );

    _showSuccessPopup(context, currentQueueCode);
  }

  void _showSuccessPopup(BuildContext context, String queueCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 25,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0041c3),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Pesanan Berhasil",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Tim pick-up kami akan segera sampai,\n"
                            "mohon menunggu selama beberapa menit",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1976D2),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                queueCode, // tampilkan kode antrean dinamis
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Salin kode antrean untuk mengetahui\n"
                            "perkembangan service anda",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ServicePage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                "Kembali",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: queueCode),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Kode berhasil disalin"),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                "Salin Kode",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close dialog
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        TrackingPage(queueCode: queueCode),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            minimumSize: const Size(double.infinity, 45),
                          ),
                          child: const Text(
                            "Lacak Pesanan",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPaymentFailedPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 25,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Pembayaran Gagal",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Terjadi kesalahan saat memproses pembayaran.\n"
                            "Silakan coba lagi atau hubungi customer service.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ServicePage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            "Kembali",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Retry payment - go back to payment selection
                            _showPaymentOptions(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0041c3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            "Coba Lagi",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
