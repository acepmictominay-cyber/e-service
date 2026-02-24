import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../config/api_config.dart';
import '../api_services/xendit_payment_service.dart';
import 'riwayat.dart';

/// Halaman utama untuk pembayaran Xendit
/// Menangani semua metode pembayaran: QRIS, VA, E-Wallet, Kartu Kredit
class XenditPaymentPage extends StatefulWidget {
  final String orderId;
  final int amount;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final List<Map<String, dynamic>> items;
  final String paymentType; // 'product' atau 'service'
  final Function(String orderId, String status)? onPaymentComplete;

  const XenditPaymentPage({
    super.key,
    required this.orderId,
    required this.amount,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.items,
    this.paymentType = 'product',
    this.onPaymentComplete,
  });

  @override
  State<XenditPaymentPage> createState() => _XenditPaymentPageState();
}

class _XenditPaymentPageState extends State<XenditPaymentPage> {
  String? _selectedMethod;
  Map<String, dynamic>? _paymentData;
  bool _isLoading = false;
  String? _error;
  Timer? _statusPollingTimer;
  String? _selectedBank;
  String? _selectedEWallet;

  @override
  void dispose() {
    _statusPollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran Xendit'),
        backgroundColor: const Color(0xFF0A1473),
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_paymentData != null) {
      return _buildPaymentInstruction();
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memproses pembayaran...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _paymentData = null;
                  _selectedMethod = null;
                });
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return _buildMethodSelection();
  }

  Widget _buildMethodSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Summary
          _buildOrderSummary(),
          const SizedBox(height: 24),

          // Payment Methods
          const Text(
            'Pilih Metode Pembayaran',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // QRIS - Coming Soon
          _buildMethodCard(
            icon: Icons.qr_code_2,
            title: 'QRIS',
            subtitle: 'Scan QR Code dengan aplikasi apapun',
            color: const Color(0xFF0A1473),
            method: 'QRIS',
            available: false,
          ),

          const SizedBox(height: 12),

          // Virtual Account - Coming Soon
          _buildMethodCard(
            icon: Icons.account_balance,
            title: 'Virtual Account',
            subtitle: 'Transfer melalui ATM atau Mobile Banking',
            color: Colors.blue,
            method: 'VA',
            available: false,
          ),

          const SizedBox(height: 12),

          // E-Wallet - Available (OVO only)
          _buildMethodCard(
            icon: Icons.wallet,
            title: 'E-Wallet',
            subtitle: 'OVO, DANA, ShopeePay, LinkAja, Gojek',
            color: Colors.purple,
            method: 'EWALLET',
            available: true,
          ),

          const SizedBox(height: 12),

          // Credit Card - Coming Soon
          _buildMethodCard(
            icon: Icons.credit_card,
            title: 'Kartu Kredit/Debit',
            subtitle: 'Visa, Mastercard, JCB',
            color: Colors.orange,
            method: 'INVOICE',
            available: false,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Pesanan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kode Pesanan'),
                Text(widget.orderId,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Pembayaran'),
                Text(
                  formatter.format(widget.amount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A1473),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String method,
    bool available = true,
  }) {
    final isSelected = _selectedMethod == method;

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: available
            ? () => _onMethodSelected(method)
            : () => _showComingSoonDialog(title),
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: available ? 1.0 : 0.6,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!available) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Coming Soon',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  available ? Icons.arrow_forward_ios : Icons.lock_outline,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoonDialog(String methodName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.schedule, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Coming Soon'),
          ],
        ),
        content: Text('$methodName akan segera tersedia'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _onMethodSelected(String method) async {
    if (method == 'VA') {
      _showBankSelection();
    } else if (method == 'EWALLET') {
      _showEWalletSelection();
    } else if (method == 'INVOICE') {
      // Invoice can handle credit card payment
      _startPayment(method);
    } else {
      _startPayment(method);
    }
  }

  void _showBankSelection() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Bank',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: ApiConfig.xenditSupportedBanks.length,
                itemBuilder: (context, index) {
                  final bank = ApiConfig.xenditSupportedBanks[index];
                  return ListTile(
                    leading: const Icon(Icons.account_balance),
                    title: Row(
                      children: [
                        Text(_getBankName(bank)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Coming Soon',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: const Text('Virtual Account'),
                    trailing: const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Coming Soon'),
                          content: Text('${_getBankName(bank)} Virtual Account akan segera tersedia'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEWalletSelection() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih E-Wallet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: ApiConfig.xenditSupportedEWallets.length,
                itemBuilder: (context, index) {
                  final ewallet = ApiConfig.xenditSupportedEWallets[index];
                  final bool available = ewallet.toUpperCase() == 'OVO';
                  
                  return ListTile(
                    leading: Icon(_getEWalletIcon(ewallet),
                        color: _getEWalletColor(ewallet)),
                    title: Row(
                      children: [
                        Text(
                          _getEWalletName(ewallet),
                          style: TextStyle(
                            color: available ? null : Colors.grey,
                          ),
                        ),
                        if (!available) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Coming Soon',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: const Text('E-Wallet'),
                    trailing: available 
                        ? const Icon(Icons.arrow_forward_ios, size: 16)
                        : const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                    onTap: available
                        ? () {
                            Navigator.pop(context);
                            setState(() {
                              _selectedEWallet = ewallet;
                              _selectedMethod = 'EWALLET';
                            });
                            _startPayment('EWALLET');
                          }
                        : () {
                            Navigator.pop(context);
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Coming Soon'),
                                content: Text('${_getEWalletName(ewallet)} akan segera tersedia'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getBankName(String code) {
    switch (code) {
      case 'BCA':
        return 'Bank Central Asia (BCA)';
      case 'BNI':
        return 'Bank Negara Indonesia (BNI)';
      case 'BRI':
        return 'Bank Rakyat Indonesia (BRI)';
      case 'MANDIRI':
        return 'Bank Mandiri';
      case 'BSI':
        return 'Bank Syaria Indonesia (BSI)';
      case 'BTPN':
        return 'Bank BTPN';
      case 'CIMB':
        return 'Bank CIMB Niaga';
      case 'BTN':
        return 'Bank Tabungan Negara (BTN)';
      case 'BJB':
        return 'Bank Jawa Barat (BJB)';
      case 'DANAMON':
        return 'Bank Danamon';
      default:
        return code;
    }
  }

  String _getEWalletName(String code) {
    switch (code) {
      case 'OVO':
        return 'OVO';
      case 'DANA':
        return 'DANA';
      case 'SHOPEEPAY':
        return 'ShopeePay';
      case 'LINKAJA':
        return 'LinkAja';
      case 'GOJEK':
        return 'Gojek';
      default:
        return code;
    }
  }

  IconData _getEWalletIcon(String code) {
    switch (code.toUpperCase()) {
      case 'OVO':
        return Icons.wallet;
      case 'DANA':
        return Icons.account_balance_wallet;
      case 'SHOPEEPAY':
        return Icons.shopping_bag;
      case 'LINKAJA':
        return Icons.link;
      case 'GOJEK':
        return Icons.local_taxi;
      default:
        return Icons.wallet;
    }
  }

  Color _getEWalletColor(String code) {
    switch (code.toUpperCase()) {
      case 'OVO':
        return Colors.purple;
      case 'DANA':
        return Colors.blue;
      case 'SHOPEEPAY':
        return Colors.orange;
      case 'LINKAJA':
        return Colors.red;
      case 'GOJEK':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Future<void> _startPayment(String method) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Map<String, dynamic> result;

      switch (method) {
        case 'QRIS':
          result = await XenditPaymentService.createQrisPayment(
            orderId: widget.orderId,
            amount: widget.amount,
            customerId: widget.customerId,
            paymentType: widget.paymentType,
          );
          break;

        case 'VA':
          result = await XenditPaymentService.createVirtualAccount(
            orderId: widget.orderId,
            amount: widget.amount,
            customerName: widget.customerName,
            customerId: widget.customerId,
            bankCode: _selectedBank ?? 'BCA',
            paymentType: widget.paymentType,
          );
          break;

        case 'EWALLET':
          result = await XenditPaymentService.createEWalletPayment(
            orderId: widget.orderId,
            amount: widget.amount,
            customerPhone: widget.customerPhone,
            customerId: widget.customerId,
            ewalletType: _selectedEWallet ?? 'OVO',
            paymentType: widget.paymentType,
          );
          break;

        case 'INVOICE':
        default:
          result = await XenditPaymentService.createInvoice(
            orderId: widget.orderId,
            amount: widget.amount,
            customerEmail: widget.customerEmail,
            customerName: widget.customerName,
            items: widget.items,
            paymentType: widget.paymentType,
          );
          break;
      }

      if (result['success'] == true) {
        setState(() {
          _paymentData = result;
          _isLoading = false;
        });

        // Start polling for status if needed
        if (method == 'EWALLET' || method == 'INVOICE') {
          _startStatusPolling();
        }
      } else {
        // Tampilkan pesan error detail dari backend
        final errorMessage = result['message'] ?? 'Gagal membuat pembayaran';
        final rawError = result['raw_error'] ?? '';
        final response = result['response'] ?? '';

        setState(() {
          _error = '$errorMessage\n\nDetail: $rawError $response';
          _isLoading = false;
        });

        // Debug log untuk development
        debugPrint('[XenditPayment] Error: $errorMessage');
        debugPrint('[XenditPayment] Raw Error: $rawError');
        debugPrint('[XenditPayment] Response: $response');
      }
    } catch (e) {
      // Tangani exception dari service
      debugPrint('[XenditPayment] Exception: $e');

      String errorMsg = e.toString();
      // Hilangkan prefix "Exception: " jika ada
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(11);
      }

      setState(() {
        _error = 'Terjadi kesalahan:\n$errorMsg';
        _isLoading = false;
      });
    }
  }

  void _startStatusPolling() {
    _statusPollingTimer?.cancel();
    _statusPollingTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final statusData =
            await XenditPaymentService.checkPaymentStatus(widget.orderId);
        final status = statusData['status']?.toString().toLowerCase() ?? '';

        if (status == 'success' ||
            status == 'completed' ||
            status == 'paid' ||
            status == 'settlement') {
          timer.cancel();
          if (mounted) {
            _onPaymentSuccess();
          }
        } else if (status == 'failed' ||
            status == 'expired' ||
            status == 'cancelled') {
          timer.cancel();
          if (mounted) {
            setState(() {
              _error =
                  'Pembayaran ${status == 'expired' ? 'kedaluarsa' : 'gagal'}';
            });
          }
        }
      } catch (e) {
        // Ignore polling errors
      }
    });
  }

  Widget _buildPaymentInstruction() {
    if (_selectedMethod == 'QRIS') {
      return _buildQrisInstruction();
    } else if (_selectedMethod == 'VA') {
      return _buildVAInstruction();
    } else if (_selectedMethod == 'EWALLET') {
      return _buildEWalletInstruction();
    } else {
      return _buildInvoiceInstruction();
    }
  }

  Widget _buildQrisInstruction() {
    final qrisString = _paymentData?['qris_string'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Scan QRIS',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                ),
              ],
            ),
            child: QrImageView(
              data: qrisString,
              version: QrVersions.auto,
              size: 250,
            ),
          ),

          const SizedBox(height: 24),

          // Amount
          Text(
            XenditPaymentService.formatIdr(widget.amount),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A1473),
            ),
          ),

          const SizedBox(height: 16),

          // Instructions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cara Pembayaran:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('1. Buka aplikasi mobile banking atau e-wallet'),
                  const Text('2. Pilih menu Scan QR'),
                  const Text('3. Pindai QR code di atas'),
                  const Text('4. Konfirmasi dan selesaikan pembayaran'),
                  const Text('5. Tunggu konfirmasi berhasil'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Check Status Button
          ElevatedButton.icon(
            onPressed: _checkPaymentStatus,
            icon: const Icon(Icons.refresh),
            label: const Text('Cek Status Pembayaran'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A1473),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVAInstruction() {
    final vaNumber = _paymentData?['va_number'] ?? '';
    final bankCode = _paymentData?['bank_code'] ?? _selectedBank ?? 'BCA';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Virtual Account ${_getBankName(bankCode)}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // VA Number
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Nomor Virtual Account',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  vaNumber,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Amount
          Text(
            XenditPaymentService.formatIdr(widget.amount),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A1473),
            ),
          ),

          const SizedBox(height: 16),

          // Instructions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cara Pembayaran:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('1. Buka aplikasi mobile banking'),
                  const Text('2. Pilih Transfer → Virtual Account'),
                  const Text('3. Masukkan nomor VA di atas'),
                  const Text('4. Masukkan jumlah pembayaran'),
                  const Text('5. Konfirmasi dan selesaikan pembayaran'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Check Status Button
          ElevatedButton.icon(
            onPressed: _checkPaymentStatus,
            icon: const Icon(Icons.refresh),
            label: const Text('Cek Status Pembayaran'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A1473),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEWalletInstruction() {
    final checkoutUrl = _paymentData?['checkout_url'] ?? '';
    final deeplinkUrl = _paymentData?['deeplink_url'] ?? '';
    final ewalletType = _selectedEWallet ?? 'OVO';
    final qrString = _paymentData?['qr_string'] ?? '';

    // Check if we have QR string for the payment
    final hasQrCode = qrString.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // E-Wallet Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getEWalletColor(ewalletType).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getEWalletIcon(ewalletType),
              size: 64,
              color: _getEWalletColor(ewalletType),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Pembayaran $ewalletType',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 24),

          // Amount
          Text(
            XenditPaymentService.formatIdr(widget.amount),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A1473),
            ),
          ),

          const SizedBox(height: 24),

          // Show QR Code if available
          if (hasQrCode) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Scan QR Code dengan Aplikasi $ewalletType',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  QrImageView(
                    data: qrString,
                    version: QrVersions.auto,
                    size: 200,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Buka aplikasi, pilih Bayar/Scan QR, lalu pindai kode di atas',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Instructions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cara Pembayaran:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (hasQrCode) ...[
                    Text('1. Buka aplikasi $ewalletType di HP Anda'),
                    Text('2. Pilih menu "Scan QR" atau "Bayar"'),
                    Text('3. Pindai QR code di atas'),
                    Text('4. Konfirmasi pembayaran dengan PIN/OTP'),
                  ] else ...[
                    Text('1. Klik tombol "Bayar dengan $ewalletType" di bawah'),
                    Text('2. Periksa notifikasi di aplikasi $ewalletType'),
                    Text('3. Konfirmasi pembayaran sesuai jumlah'),
                    Text('4. Selesaikan autentikasi (PIN/Fingerprint)'),
                  ],
                  Text('5. Tunggu konfirmasi berhasil'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Pay Button - Shows popup with instructions
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showOVOPaymentDialog(ewalletType),
              icon: Icon(_getEWalletIcon(ewalletType)),
              label: Text('Bayar dengan $ewalletType'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getEWalletColor(ewalletType),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Check Status Button
          OutlinedButton.icon(
            onPressed: _checkPaymentStatus,
            icon: const Icon(Icons.refresh),
            label: const Text('Cek Status Pembayaran'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  /// Show payment confirmation dialog for OVO/DANA/e-wallets
  void _showOVOPaymentDialog(String ewalletType) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getEWalletColor(ewalletType).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getEWalletIcon(ewalletType),
                  size: 48,
                  color: _getEWalletColor(ewalletType),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Bayar dengan $ewalletType',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Amount
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _getEWalletColor(ewalletType).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  XenditPaymentService.formatIdr(widget.amount),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _getEWalletColor(ewalletType),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notifications_active,
                            color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Periksa notifikasi di aplikasi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '1. Periksa notifikasi masuk di HP Anda\n'
                      '2. Buka aplikasi $ewalletType\n'
                      '3. Konfirmasi pembayaran ${XenditPaymentService.formatIdr(widget.amount)}\n'
                      '4. Masukkan PIN $ewalletType\n'
                      '5. Pembayaran berhasil',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _checkPaymentStatus();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getEWalletColor(ewalletType),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cek Status'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceInstruction() {
    final invoiceUrl = _paymentData?['invoice_url'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long,
            size: 80,
            color: Color(0xFF0A1473),
          ),

          const SizedBox(height: 16),

          const Text(
            'Invoice Dibuat',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            'Kode: ${widget.orderId}',
            style: TextStyle(color: Colors.grey[600]),
          ),

          const SizedBox(height: 24),

          // Amount
          Text(
            XenditPaymentService.formatIdr(widget.amount),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A1473),
            ),
          ),

          const SizedBox(height: 24),

          // Open Invoice Button
          ElevatedButton.icon(
            onPressed: () => _openUrl(invoiceUrl),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Buka Halaman Pembayaran'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A1473),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),

          const SizedBox(height: 16),

          // Check Status Button
          OutlinedButton.icon(
            onPressed: _checkPaymentStatus,
            icon: const Icon(Icons.refresh),
            label: const Text('Cek Status Pembayaran'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEWallet(String checkoutUrl, String deeplinkUrl) async {
    String urlToOpen = checkoutUrl.isNotEmpty ? checkoutUrl : deeplinkUrl;

    // If no URL from API, use fallback deep links based on e-wallet type
    if (urlToOpen.isEmpty) {
      urlToOpen = _getEWalletFallbackUrl(_selectedEWallet ?? 'OVO');
    }

    if (urlToOpen.isNotEmpty) {
      final success = await _openUrl(urlToOpen);

      // If still fails after using fallback, show manual instructions
      if (!success && mounted) {
        _showEWalletManualInstructions();
      }
    } else {
      // Show manual instructions if no URL available
      if (mounted) {
        _showEWalletManualInstructions();
      }
    }
  }

  /// Get fallback URL for e-wallet when API doesn't return one
  String _getEWalletFallbackUrl(String ewalletType) {
    switch (ewalletType.toUpperCase()) {
      case 'OVO':
        return 'ovo://payment'; // OVO deep link
      case 'DANA':
        return 'dana://'; // DANA deep link
      case 'SHOPEEPAY':
        return 'shopeepay://'; // ShopeePay deep link
      case 'LINKAJA':
        return 'linkaja://'; // LinkAja deep link
      case 'GOJEK':
        return 'gojek://'; // Gojek deep link
      default:
        return '';
    }
  }

  /// Show manual instructions when app deep link fails
  void _showEWalletManualInstructions() {
    final ewalletType = _selectedEWallet ?? 'OVO';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cara Pembayaran $ewalletType'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ikuti langkah berikut:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('1. Buka aplikasi $ewalletType di HP Anda'),
            Text('2. Pilih menu "Scan QR" atau "Bayar"'),
            Text('3. Scan QR code yang ditampilkan'),
            Text('4. Konfirmasi pembayaran dengan PIN/OTP'),
            const SizedBox(height: 12),
            const Text(
              'atau hubungi customer service jika butuh bantuan.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _checkPaymentStatus();
            },
            child: const Text('Cek Status Pembayaran'),
          ),
        ],
      ),
    );
  }

  Future<bool> _openUrl(String url) async {
    if (url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        // Use externalApplication to open in the e-wallet app
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Tidak dapat membuka aplikasi. Pastikan aplikasi e-wallet terinstal.')),
          );
        }
        return false;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      return false;
    }
  }

  Future<void> _checkPaymentStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final statusData =
          await XenditPaymentService.checkPaymentStatus(widget.orderId);
      final status = statusData['status']?.toString().toLowerCase() ?? '';

      if (XenditPaymentService.isPaymentSuccess(status)) {
        _onPaymentSuccess();
      } else if (XenditPaymentService.isPaymentFailed(status)) {
        setState(() {
          _error = 'Pembayaran gagal atau kedaluarsa';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        // Show dialog with option to go to riwayat
        if (mounted) {
          _showPendingPaymentDialog();
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cek status: $e')),
        );
      }
    }
  }

  /// Show dialog when payment is still pending, with option to go to riwayat
  void _showPendingPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.hourglass_empty, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Pembayaran Pending'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Pembayaran untuk pesanan ${widget.orderId} masih menunggu konfirmasi.'),
            const SizedBox(height: 12),
            const Text(
              'Silakan lakukan pembayaran sesuai metode yang dipilih.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cek status di Riwayat Pembelian',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to riwayat page - Pembelian tab
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const RiwayatPage(),
                ),
              );
            },
            icon: const Icon(Icons.history, size: 18),
            label: const Text('Lihat di Riwayat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A1473),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _onPaymentSuccess() {
    _statusPollingTimer?.cancel();

    // Show success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 8),
            Text('Pembayaran Berhasil'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kode Pesanan: ${widget.orderId}'),
            const SizedBox(height: 8),
            Text('Jumlah: ${XenditPaymentService.formatIdr(widget.amount)}'),
            const SizedBox(height: 8),
            Text('Metode: ${_getPaymentMethodName()}'),
            const SizedBox(height: 8),
            const Text(
              'Pembayaran Anda telah berhasil dikonfirmasi.',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              widget.onPaymentComplete?.call(widget.orderId, 'success');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A1473),
              foregroundColor: Colors.white,
            ),
            child: const Text('Lihat Invoice'),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodName() {
    switch (_selectedMethod) {
      case 'QRIS':
        return 'QRIS';
      case 'VA':
        return 'Virtual Account ${_getBankName(_selectedBank ?? 'BCA')}';
      case 'EWALLET':
        return _getEWalletName(_selectedEWallet ?? 'OVO');
      case 'INVOICE':
        return 'Kartu Kredit/Debit';
      default:
        return 'Xendit';
    }
  }
}
