import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:azza_service/config/api_config.dart';
import 'package:azza_service/api_services/xendit_payment_service.dart';

/// Dialog untuk memilih metode pembayaran Xendit
class XenditPaymentMethodDialog extends StatelessWidget {
  final Function(dynamic) onMethodSelected;

  const XenditPaymentMethodDialog({
    super.key,
    required this.onMethodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Pilih Metode Pembayaran',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            _buildSectionHeader('QR Code'),
            _buildPaymentOption(
              context,
              XenditPaymentMethodType.qris,
              Icons.qr_code_2,
              'Scan QR Code',
              'Pembayaran instan dengan QRIS',
              available: false,
            ),
            _buildSectionHeader('Virtual Account'),
            ...ApiConfig.xenditSupportedBanks
                .map((bank) => _buildBankOption(
                      context,
                      bank,
                    ))
                .toList(),
            _buildSectionHeader('E-Wallet'),
            ...ApiConfig.xenditSupportedEWallets
                .map((ewallet) => _buildEWalletOption(
                      context,
                      ewallet,
                    ))
                .toList(),
            _buildSectionHeader('Kartu'),
            _buildPaymentOption(
              context,
              XenditPaymentMethodType.creditCard,
              Icons.credit_card,
              'Kartu Kredit/Debit',
              'Visa, Mastercard, JCB',
              available: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext context,
    XenditPaymentMethodType method,
    IconData icon,
    String title,
    String subtitle, {
    bool available = true,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: available
                ? Colors.blue.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: available ? Colors.blue : Colors.grey),
        ),
        title: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
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
        subtitle: Text(subtitle),
        trailing: available
            ? const Icon(Icons.arrow_forward_ios, size: 16)
            : const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
        onTap: available
            ? () {
                Navigator.of(context).pop();
                onMethodSelected(method);
              }
            : () {
                // Show coming soon message
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Coming Soon'),
                    content: Text('$title akan segera tersedia'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
      ),
    );
  }

  Widget _buildBankOption(BuildContext context, String bankCode) {
    // All banks are coming soon except we keep them visible but disabled
    final bool available = false;

    IconData bankIcon;
    switch (bankCode) {
      case 'BCA':
        bankIcon = Icons.account_balance;
        break;
      case 'BNI':
        bankIcon = Icons.account_balance;
        break;
      case 'BRI':
        bankIcon = Icons.account_balance;
        break;
      case 'MANDIRI':
        bankIcon = Icons.account_balance;
        break;
      default:
        bankIcon = Icons.account_balance;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: available
                ? Colors.blue.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(bankIcon, color: available ? Colors.blue : Colors.grey),
        ),
        title: Row(
          children: [
            Text(
              _getBankName(bankCode),
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
        subtitle: const Text('Virtual Account'),
        trailing: available
            ? const Icon(Icons.arrow_forward_ios, size: 16)
            : const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
        onTap: available
            ? () {
                Navigator.of(context).pop();
                onMethodSelected({
                  'type': 'VA',
                  'bank_code': bankCode,
                });
              }
            : () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Coming Soon'),
                    content: Text(
                        '${_getBankName(bankCode)} Virtual Account akan segera tersedia'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
      ),
    );
  }

  Widget _buildEWalletOption(BuildContext context, String ewalletType) {
    // Only OVO is available, all others are coming soon
    final bool available = ewalletType.toUpperCase() == 'OVO';

    IconData walletIcon;
    switch (ewalletType.toUpperCase()) {
      case 'OVO':
        walletIcon = Icons.wallet;
        break;
      case 'DANA':
        walletIcon = Icons.wallet;
        break;
      case 'SHOPEEPAY':
        walletIcon = Icons.shopping_bag;
        break;
      case 'LINKAJA':
        walletIcon = Icons.link;
        break;
      default:
        walletIcon = Icons.wallet;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: available
                ? Colors.blue.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(walletIcon, color: available ? Colors.blue : Colors.grey),
        ),
        title: Row(
          children: [
            Text(
              _getEWalletName(ewalletType),
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
                Navigator.of(context).pop();
                onMethodSelected({
                  'type': 'EWALLET',
                  'ewallet_type': ewalletType.toUpperCase(),
                });
              }
            : () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Coming Soon'),
                    content: Text(
                        '${_getEWalletName(ewalletType)} akan segera tersedia'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
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
      default:
        return code;
    }
  }

  String _getEWalletName(String code) {
    switch (code.toUpperCase()) {
      case 'OVO':
        return 'OVO';
      case 'DANA':
        return 'DANA';
      case 'SHOPEEPAY':
        return 'ShopeePay';
      case 'LINKAJA':
        return 'LinkAja';
      default:
        return code;
    }
  }
}

/// Widget untuk menampilkan QRIS
class QrisDisplayWidget extends StatelessWidget {
  final String qrisString;
  final String orderId;
  final int amount;

  const QrisDisplayWidget({
    super.key,
    required this.qrisString,
    required this.orderId,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Scan QRIS',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // QR Code Image
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Image.network(
              'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=$qrisString',
              width: 250,
              height: 250,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 250,
                  height: 250,
                  color: Colors.grey[200],
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_2, size: 80, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('QR Code'),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Amount
          Text(
            XenditPaymentService.formatIdr(amount),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),

          const SizedBox(height: 8),

          // Order ID
          Text(
            'Order: $orderId',
            style: TextStyle(color: Colors.grey[600]),
          ),

          const SizedBox(height: 16),

          // Instructions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Scan QRIS menggunakan aplikasi pembayaran pilihan Anda',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}

/// Widget untuk menampilkan Virtual Account
class VirtualAccountDisplayWidget extends StatelessWidget {
  final String vaNumber;
  final String bankCode;
  final int amount;
  final String orderId;

  const VirtualAccountDisplayWidget({
    super.key,
    required this.vaNumber,
    required this.bankCode,
    required this.amount,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Virtual Account',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bank Name
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getBankName(bankCode),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // VA Number
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Nomor Virtual Account',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  _formatVaNumber(vaNumber),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Amount
          Text(
            XenditPaymentService.formatIdr(amount),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),

          const SizedBox(height: 8),

          // Order ID
          Text(
            'Order: $orderId',
            style: TextStyle(color: Colors.grey[600]),
          ),

          const SizedBox(height: 16),

          // Instructions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cara Pembayaran:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                SizedBox(height: 4),
                Text(
                  '1. Buka aplikasi mobile banking\n'
                  '2. Pilih Transfer → Virtual Account\n'
                  '3. Masukkan nomor VA di atas\n'
                  '4. Konfirmasi dan selesaikan pembayaran',
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
      ],
    );
  }

  String _getBankName(String code) {
    switch (code) {
      case 'BCA':
        return 'Bank Central Asia';
      case 'BNI':
        return 'Bank Negara Indonesia';
      case 'BRI':
        return 'Bank Rakyat Indonesia';
      case 'MANDIRI':
        return 'Bank Mandiri';
      case 'BSI':
        return 'Bank Syaria Indonesia';
      case 'BTPN':
        return 'Bank BTPN';
      case 'CIMB':
        return 'Bank CIMB Niaga';
      default:
        return code;
    }
  }

  String _formatVaNumber(String va) {
    // Format VA number with spaces every 4 digits
    final cleaned = va.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(cleaned[i]);
    }
    return buffer.toString();
  }
}

/// Widget untuk menampilkan E-Wallet payment
class EWalletDisplayWidget extends StatelessWidget {
  final String checkoutUrl;
  final String deeplinkUrl;
  final String ewalletType;
  final int amount;
  final String orderId;

  const EWalletDisplayWidget({
    super.key,
    required this.checkoutUrl,
    required this.deeplinkUrl,
    required this.ewalletType,
    required this.amount,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Pembayaran $_ewalletName',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // E-Wallet Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getEWalletColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getEWalletIcon(),
              size: 64,
              color: _getEWalletColor(),
            ),
          ),

          const SizedBox(height: 24),

          // Amount
          Text(
            XenditPaymentService.formatIdr(amount),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),

          const SizedBox(height: 8),

          // Order ID
          Text(
            'Order: $orderId',
            style: TextStyle(color: Colors.grey[600]),
          ),

          const SizedBox(height: 16),

          // Instructions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cara Pembayaran:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                SizedBox(height: 4),
                Text(
                  '1. Klik tombol di bawah untuk membuka aplikasi\n'
                  '2. Konfirmasi pembayaran di aplikasi\n'
                  '3. Tunggu konfirmasi pembayaran berhasil',
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            // Buka URL checkout atau deep link OVO
            try {
              String? urlToOpen;
              if (checkoutUrl.isNotEmpty) {
                urlToOpen = checkoutUrl;
              } else if (deeplinkUrl.isNotEmpty) {
                urlToOpen = deeplinkUrl;
              } else {
                // Use fallback deep links
                urlToOpen = _getEWalletFallbackUrl(ewalletType);
              }

              if (urlToOpen != null && urlToOpen.isNotEmpty) {
                final uri = Uri.parse(urlToOpen);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  // Show manual instructions if can't open
                  if (context.mounted) {
                    _showManualInstructions(context, ewalletType);
                  }
                }
              } else {
                // Show manual instructions
                if (context.mounted) {
                  _showManualInstructions(context, ewalletType);
                }
              }

              // Tutup dialog dan kembali
              Navigator.of(context).pop();
            } catch (e) {
              // Jika gagal, tetap tutup dialog
              Navigator.of(context).pop();
            }
          },
          icon: const Icon(Icons.open_in_new),
          label: const Text('Buka Aplikasi'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getEWalletColor(),
          ),
        ),
      ],
    );
  }

  String get _ewalletName {
    switch (ewalletType.toUpperCase()) {
      case 'OVO':
        return 'OVO';
      case 'DANA':
        return 'DANA';
      case 'SHOPEEPAY':
        return 'ShopeePay';
      case 'LINKAJA':
        return 'LinkAja';
      default:
        return ewalletType;
    }
  }

  IconData _getEWalletIcon() {
    switch (ewalletType.toUpperCase()) {
      case 'OVO':
        return Icons.wallet;
      case 'DANA':
        return Icons.account_balance_wallet;
      case 'SHOPEEPAY':
        return Icons.shopping_bag;
      case 'LINKAJA':
        return Icons.link;
      default:
        return Icons.wallet;
    }
  }

  Color _getEWalletColor() {
    switch (ewalletType.toUpperCase()) {
      case 'OVO':
        return Colors.purple;
      case 'DANA':
        return Colors.blue;
      case 'SHOPEEPAY':
        return Colors.orange;
      case 'LINKAJA':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  /// Get fallback URL for e-wallet when API doesn't return one
  String _getEWalletFallbackUrl(String ewalletType) {
    switch (ewalletType.toUpperCase()) {
      case 'OVO':
        return 'ovo://payment';
      case 'DANA':
        return 'dana://';
      case 'SHOPEEPAY':
        return 'shopeepay://';
      case 'LINKAJA':
        return 'linkaja://';
      case 'GOJEK':
        return 'gojek://';
      default:
        return '';
    }
  }

  /// Show manual instructions when app deep link fails
  void _showManualInstructions(BuildContext context, String ewalletType) {
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
        ],
      ),
    );
  }
}
