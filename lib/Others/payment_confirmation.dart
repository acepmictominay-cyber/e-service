import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'struck_pesanan.dart';
import 'custom_dialog.dart';

class PaymentConfirmationPage extends StatefulWidget {
  final String orderCode;
  final String paymentMethod;
  final String? selectedBank;
  final double totalAmount;
  final Map<String, dynamic> produk;
  final int quantity;
  final Map<String, dynamic>? selectedAddress;

  const PaymentConfirmationPage({
    super.key,
    required this.orderCode,
    required this.paymentMethod,
    this.selectedBank,
    required this.totalAmount,
    required this.produk,
    required this.quantity,
    this.selectedAddress,
  });

  @override
  State<PaymentConfirmationPage> createState() =>
      _PaymentConfirmationPageState();
}

class _PaymentConfirmationPageState extends State<PaymentConfirmationPage> {
  bool _hasConfirmedTransfer = false;

  // Bank account details (you can move this to config later)
  final Map<String, Map<String, String>> bankDetails = {
    'BCA': {
      'accountNumber': '1234567890',
      'accountName': 'PT Azza Service Indonesia',
      'bankName': 'BCA',
    },
    'BRI': {
      'accountNumber': '0987654321',
      'accountName': 'PT Azza Service Indonesia',
      'bankName': 'BRI',
    },
    'Mandiri': {
      'accountNumber': '1122334455',
      'accountName': 'PT Azza Service Indonesia',
      'bankName': 'Mandiri',
    },
    'BNI': {
      'accountNumber': '5566778899',
      'accountName': 'PT Azza Service Indonesia',
      'bankName': 'BNI',
    },
    'CIMB Niaga': {
      'accountNumber': '9988776655',
      'accountName': 'PT Azza Service Indonesia',
      'bankName': 'CIMB Niaga',
    },
  };

  @override
  Widget build(BuildContext context) {
    final bankInfo =
        widget.selectedBank != null ? bankDetails[widget.selectedBank] : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0041c3),
        title: const Text(
          "Konfirmasi Pembayaran",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Detail Pesanan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildOrderDetail('Kode Pesanan', widget.orderCode),
                  _buildOrderDetail('Metode Pembayaran', widget.paymentMethod),
                  if (widget.selectedBank != null)
                    _buildOrderDetail('Bank Tujuan', widget.selectedBank!),
                  _buildOrderDetail(
                    'Total Pembayaran',
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(widget.totalAmount),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Bank Transfer Instructions
            if (widget.paymentMethod == "Transfer Bank" &&
                bankInfo != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance,
                          color: Colors.green[600],
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Informasi Transfer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Bank Account Details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        children: [
                          _buildBankDetail('Bank', bankInfo['bankName']!),
                          const Divider(),
                          _buildBankDetail(
                            'Nomor Rekening',
                            bankInfo['accountNumber']!,
                          ),
                          const Divider(),
                          _buildBankDetail(
                            'Atas Nama',
                            bankInfo['accountName']!,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Copy Account Number Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: bankInfo['accountNumber']!),
                          );
                          CustomDialog.show(
                            context: context,
                            icon: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 24,
                              ),
                            ),
                            title: 'Berhasil',
                            content: const Text(
                              'Nomor rekening berhasil disalin',
                            ),
                            actions: [
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          );
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Salin Nomor Rekening'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Transfer Instructions
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange[600],
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cara Transfer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInstruction(
                      1,
                      'Buka aplikasi banking atau m-banking Anda',
                    ),
                    _buildInstruction(2, 'Pilih menu transfer'),
                    _buildInstruction(
                      3,
                      'Masukkan nomor rekening tujuan di atas',
                    ),
                    _buildInstruction(
                      4,
                      'Masukkan nominal pembayaran yang sesuai',
                    ),
                    _buildInstruction(
                      5,
                      'Pastikan detail transfer sudah benar',
                    ),
                    _buildInstruction(6, 'Konfirmasi dan selesaikan transfer'),
                    _buildInstruction(
                      7,
                      'Simpan bukti transfer untuk referensi',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],

            // QRIS Instructions
            if (widget.paymentMethod == "QRIS") ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.qr_code_2,
                          color: Colors.purple[600],
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pembayaran QRIS',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // QR Code Placeholder
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_2,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'QR Code akan muncul di sini',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    _buildInstruction(
                      1,
                      'Buka aplikasi e-wallet (GoPay, OVO, Dana, dll)',
                    ),
                    _buildInstruction(2, 'Pilih menu scan QR atau bayar'),
                    _buildInstruction(3, 'Scan QR code di atas'),
                    _buildInstruction(4, 'Periksa detail pembayaran'),
                    _buildInstruction(5, 'Konfirmasi pembayaran'),
                    _buildInstruction(6, 'Simpan bukti pembayaran'),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],

            // E-wallet Instructions
            if (widget.paymentMethod == "E-wallet") ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: Colors.teal[600],
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pembayaran E-wallet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInstruction(1, 'Buka aplikasi e-wallet pilihan Anda'),
                    _buildInstruction(2, 'Pilih menu transfer atau bayar'),
                    _buildInstruction(
                      3,
                      'Cari merchant "PT Azza Service Indonesia"',
                    ),
                    _buildInstruction(4, 'Masukkan nominal pembayaran'),
                    _buildInstruction(5, 'Konfirmasi pembayaran'),
                    _buildInstruction(6, 'Simpan bukti pembayaran'),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],

            // Confirmation Checkbox
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Konfirmasi Pembayaran',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: _hasConfirmedTransfer,
                        onChanged: (value) {
                          setState(() {
                            _hasConfirmedTransfer = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFF0041c3),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Saya telah melakukan pembayaran sesuai dengan instruksi di atas',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _hasConfirmedTransfer
                        ? () {
                          // Navigate to success page
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => StruckPesananPage(
                                    serviceType: 'shop',
                                    nama:
                                        widget.selectedAddress?['nama'] ??
                                        'Customer',
                                    jumlahBarang: widget.quantity,
                                    items: [
                                      {
                                        'merek':
                                            widget.produk['nama_produk'] ??
                                            'Produk',
                                        'device':
                                            widget.produk['deskripsi'] ??
                                            'Deskripsi',
                                        'seri': 'Order: ${widget.orderCode}',
                                      },
                                    ],
                                    alamat:
                                        widget
                                            .selectedAddress?['detailAlamat'] ??
                                        'Atur alamat anda di sini',
                                    totalHarga: NumberFormat.currency(
                                      locale: 'id_ID',
                                      symbol: 'Rp ',
                                      decimalDigits: 0,
                                    ).format(widget.totalAmount),
                                  ),
                            ),
                          );
                        }
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _hasConfirmedTransfer
                          ? const Color(0xFF0041c3)
                          : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Konfirmasi Pembayaran Selesai',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Help Text
            Center(
              child: Text(
                'Butuh bantuan? Hubungi customer service kami',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (label == 'Nomor Rekening') ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    CustomDialog.show(
                      context: context,
                      icon: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 24,
                        ),
                      ),
                      title: 'Berhasil',
                      content: const Text('Nomor rekening berhasil disalin'),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                  icon: Icon(Icons.copy, size: 16, color: Colors.blue[600]),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction(int step, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
