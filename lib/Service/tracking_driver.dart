import 'package:azza_service/Beli/shop.dart';
import 'package:azza_service/Home/home.dart';
import 'package:azza_service/Others/notifikasi.dart';
import 'package:azza_service/Profile/profile.dart';
import 'package:azza_service/Promo/promo.dart';
import 'package:azza_service/Service/service.dart';
import 'package:azza_service/Service/detail_service_midtrans.dart';
import 'package:azza_service/api_services/api_service.dart';
import 'package:azza_service/api_services/xendit_payment_service.dart';
import 'package:azza_service/utils/error_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class TrackingPage extends StatefulWidget {
  final String? queueCode; // trans_kode

  const TrackingPage({super.key, this.queueCode});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage>
    with TickerProviderStateMixin {
  int currentIndex = 0;

  Timer? _statusPollingTimer;

  // Payment loading state
  final bool _isPaymentProcessing = false;

  // Payment method selection
  String? _selectedPaymentMethod;

  // E-wallet selection
  String? selectedEwallet;

  // Payment proof
  File? _paymentProofImage;
  final ImagePicker _picker = ImagePicker();

  // Bank account details
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

  // Timeline state
  List<_TimelineItem> _timeline = [];
  String _currentStatus = 'waiting';
  DateTime? _createdAt;
  DateTime? _updatedAt;
  double? _totalCost; // Untuk menyimpan total biaya dari tindakan

  // Service type inference
  String _inferredServiceType = 'delivery'; // 'delivery' or 'pickup'
  bool _hasConfirmedType = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
    _startStatusPolling();
    // Show confirmation dialog for pickup after initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_inferredServiceType == 'pickup' && !_hasConfirmedType) {
        _showServiceTypeConfirmationDialog();
      }
    });
  }

  @override
  void dispose() {
    _statusPollingTimer?.cancel();
    super.dispose();
  }

  // ========================= Polling =========================

  void _startStatusPolling() {
    _statusPollingTimer?.cancel();
    _statusPollingTimer = Timer.periodic(const Duration(seconds: 15), (
      timer,
    ) async {
      await _refreshStatus();
    });
  }

  // Ambil trans_status dari transaksi dan subtotal tindakan
  Future<void> _refreshStatus() async {
    if (widget.queueCode == null || widget.queueCode!.isEmpty) return;
    try {
      final detail = await ApiService.getOrderDetail(widget.queueCode!);
      if (detail == null) return;

      String status =
          (detail['trans_status'] ?? 'waiting').toString().toLowerCase().trim();
      status = _normalizeStatus(status);

      final createdAtStr =
          (detail['created_at'] ?? detail['trans_tgl'] ?? detail['createdAt'])
              ?.toString();
      final updatedAtStr =
          (detail['updated_at'] ?? detail['updatedAt'] ?? createdAtStr)
              ?.toString();
      final createdAt = DateTime.tryParse(createdAtStr ?? '');
      final updatedAt = DateTime.tryParse(updatedAtStr ?? '');

      // Infer service type: delivery if kry_kode exists (technician assigned), else pickup
      final kryKode = detail['kry_kode']?.toString();
      _inferredServiceType =
          (kryKode != null && kryKode.isNotEmpty) ? 'delivery' : 'pickup';

      // Ambil subtotal dari tindakan (tidak digunakan lagi)
      try {
        await ApiService.getTindakanByTransKode(
          widget.queueCode!,
        );
        // Subtotal calculation removed as it's not used
      } catch (e) {
        log('Error getting tindakan: $e');
      }

      // Ambil trans_total dari detail
      final transTotal =
          double.tryParse(detail['trans_total']?.toString() ?? '0') ?? 0.0;

      if (mounted) {
        setState(() {
          _currentStatus = status;
          _createdAt =
              createdAt ?? DateTime.now().subtract(const Duration(hours: 2));
          _updatedAt = updatedAt ?? DateTime.now();
          _totalCost = transTotal; // Set total cost dari trans_total
          _timeline = _buildTimelineFromCurrentStatus(
            _currentStatus,
            _createdAt!,
            _updatedAt!,
          );
        });
      }
    } catch (e) {
      log('Error refreshing status: $e');
    }
  }

  // ========================= Timeline builder =========================

  final List<String> _orderedStatuses = const [
    'waiting',
    'accepted',
    'enroute',
    'arrived',
    'waitingapproval',
    'approved',
    'waitingOrder',
    'pickingparts',
    'repairing',
    'menunggu_verifikasi',
    'completed',
  ];

  final Map<String, List<String>> _statusByType = const {
    'delivery': [
      'waiting',
      'accepted',
      'enroute',
      'arrived',
      'waitingapproval',
      'approved',
      'waitingOrder',
      'pickingparts',
      'repairing',
      'menunggu_verifikasi',
      'completed',
    ],
    'pickup': [
      'itemSubmitted', // Pengecekan
      'waitingapproval',
      'waitingOrder',
      'repairing',
      'menunggu_verifikasi',
      'completed',
    ],
  };

  String _normalizeStatus(String s) {
    final ss = s.replaceAll(' ', '').replaceAll('_', '');
    switch (ss) {
      case 'pending':
        return 'waiting';
      case 'enroute':
      case 'enrute':
      case 'enrouted':
      case 'en_route':
        return 'enroute';
      case 'waitingapproval':
      case 'waitingapprovalstatus':
        return 'waitingapproval';
      case 'approved':
        return 'approved';
      case 'waitingorder':
        return 'waitingOrder';
      case 'pickingparts':
      case 'pickingpart':
      case 'picking_parts':
        return 'pickingparts';
      case 'itemsubmitted':
      case 'item_submitted':
        return 'itemSubmitted';
      case 'menunggu_verifikasi':
        return 'menunggu_verifikasi';
      default:
        return ss;
    }
  }

  _StatusMeta _statusMeta(String statusKey, [String serviceType = 'delivery']) {
    switch (statusKey.toLowerCase()) {
      case 'waiting':
        return _StatusMeta(
          'Pesanan Dibuat',
          'Pesanan dibuat dan menunggu konfirmasi teknisi.',
        );
      case 'accepted':
        return _StatusMeta(
          'Teknisi Ditugaskan',
          'Teknisi sudah ditugaskan. Pesanan akan diproses.',
        );
      case 'enroute':
        return serviceType == 'pickup'
            ? _StatusMeta(
                'Menunggu Teknisi',
                'Barang Anda sedang dipersiapkan untuk diperiksa teknisi.',
              )
            : _StatusMeta(
                'Teknisi Mengajukan Part',
                'Teknisi dalam perjalanan menuju lokasi Anda.',
              );
      case 'arrived':
        return serviceType == 'pickup'
            ? _StatusMeta(
                'Barang Diterima',
                'Barang Anda telah diterima dan sedang diperiksa teknisi.',
              )
            : _StatusMeta(
                'Sampai Lokasi',
                'Teknisi telah tiba di lokasi Anda.',
              );
      case 'itemsubmitted':
        return _StatusMeta(
          'Barang Diterima & Dicek',
          'Barang Anda telah diterima dan sedang dalam proses pengecekan.',
        );
      case 'waitingapproval':
        return _StatusMeta(
          'Mengkonfirmasi Ketersediaan Part',
          'Temuan kerusakan menunggu persetujuan biaya untuk perbaikan.',
        );
      case 'approved':
        return _StatusMeta(
          'Part Tersedia',
          'Admin telah menyetujui tindakan perbaikan.',
        );
      case 'waitingorder':
        return serviceType == 'pickup'
            ? _StatusMeta(
                'Menunggu Transaksi User',
                'User Harus Melakukan Transaksi untuk ke tahap perbaikan',
              )
            : _StatusMeta(
                'Sedang dalam Pengajuan Part',
                'Pesanan sedang dalam pengajuan part.',
              );
      case 'pickingparts':
        return _StatusMeta(
          'Teknisi Dalam Perjalanan Mambawa Part',
          'Pesanan sedang dalam pengajuan part.',
        );
      case 'repairing':
        return _StatusMeta(
          'Sedang Dikerjakan',
          'Perbaikan perangkat Anda sedang diproses.',
        );
      case 'menunggu_verifikasi':
        return _StatusMeta(
          'Menunggu Verifikasi',
          'Bukti pembayaran sedang diverifikasi oleh tim kami.',
        );
      case 'completed':
        return _StatusMeta(
          'Selesai',
          'Layanan selesai. Terima kasih telah menggunakan layanan kami.',
        );
      default:
        return _StatusMeta(
          'Status Tidak Dikenal',
          'Sedang memuat informasi status.',
        );
    }
  }

  List<DateTime?> _distributeTimes({
    required int activeIndex,
    required DateTime start,
    required DateTime end,
    required int total,
  }) {
    if (activeIndex <= 0) {
      return List.generate(total, (i) => i == 0 ? start : null);
    }
    if (!end.isAfter(start)) {
      return List.generate(total, (i) {
        if (i > activeIndex) return null;
        return start.add(Duration(minutes: 5 * i));
      });
    }
    final steps = activeIndex;
    final interval = end.difference(start) ~/ (steps);
    return List.generate(total, (i) {
      if (i > activeIndex) return null;
      return start.add(interval * i);
    });
  }

  List<_TimelineItem> _buildTimelineFromCurrentStatus(
    String currentStatus,
    DateTime createdAt,
    DateTime updatedAt,
  ) {
    final orderedStatuses =
        _statusByType[_inferredServiceType] ?? _orderedStatuses;
    final total = orderedStatuses.length;
    final activeIndex = orderedStatuses.indexOf(currentStatus);
    final validActiveIndex = activeIndex >= 0 ? activeIndex : 0;

    final times = _distributeTimes(
      activeIndex: validActiveIndex,
      start: createdAt,
      end: updatedAt,
      total: total,
    );

    final List<_TimelineItem> items = [];

    if (currentStatus == 'completed') {
      for (int i = 0; i <= validActiveIndex; i++) {
        final s = orderedStatuses[i];
        final meta = _statusMeta(s, _inferredServiceType);
        items.add(
          _TimelineItem(
            time: times[i],
            title: meta.title,
            description: meta.description,
            state: StepState.done,
          ),
        );
      }
    } else if (currentStatus == 'waiting') {
      final currentMeta = _statusMeta('waiting', _inferredServiceType);
      items.add(
        _TimelineItem(
          time: times[0],
          title: currentMeta.title,
          description: currentMeta.description,
          state: StepState.progress,
        ),
      );

      if (validActiveIndex + 1 < total) {
        final nextMeta = _statusMeta(orderedStatuses[1], _inferredServiceType);
        items.add(
          _TimelineItem(
            time: times[1],
            title: nextMeta.title,
            description: nextMeta.description,
            state: StepState.progress,
          ),
        );
      }
    } else {
      for (int i = 0; i < validActiveIndex; i++) {
        final s = orderedStatuses[i];
        final meta = _statusMeta(s, _inferredServiceType);
        items.add(
          _TimelineItem(
            time: times[i],
            title: meta.title,
            description: meta.description,
            state: StepState.done,
          ),
        );
      }

      final currentMeta = _statusMeta(
        orderedStatuses[validActiveIndex],
        _inferredServiceType,
      );
      items.add(
        _TimelineItem(
          time: times[validActiveIndex],
          title: currentMeta.title,
          description: currentMeta.description,
          state: StepState.done,
        ),
      );

      if (validActiveIndex + 1 < total) {
        final nextStatus = orderedStatuses[validActiveIndex + 1];
        final nextMeta = _statusMeta(nextStatus, _inferredServiceType);
        items.add(
          _TimelineItem(
            time: times[validActiveIndex + 1],
            title: nextMeta.title,
            description: nextMeta.description,
            state: StepState.progress,
          ),
        );
      }
    }

    return items;
  }

  String _fmt(DateTime? dt) =>
      dt == null ? '—' : DateFormat('dd-MM-yyyy HH:mm').format(dt);

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'waiting':
        return Icons.hourglass_empty;
      case 'accepted':
        return Icons.check_circle;
      case 'enroute':
        return Icons.directions_car;
      case 'arrived':
        return Icons.location_on;
      case 'waitingapproval':
        return Icons.hourglass_empty;
      case 'approved':
        return Icons.verified;
      case 'waitingorder':
        return Icons.shopping_cart;
      case 'pickingparts':
        return Icons.local_shipping;
      case 'repairing':
        return Icons.engineering;
      case 'menunggu_verifikasi':
        return Icons.hourglass_empty;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  void _showQrisPayment(
    BuildContext context,
    double amount, {
    bool isCancel = false,
  }) {
    Navigator.pop(context); // Close method selection dialog

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 24,
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color:
                    Theme.of(context).colorScheme.shadow.withValues(alpha: 25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header integrated with container
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF0041c3),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFF0041c3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 76),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.qr_code_2,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pembayaran QRIS',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Scan & Bayar Cepat',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // QR Code Container with enhanced design
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade50,
                            Colors.blue.shade100,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .shadow
                                      .withValues(alpha: 25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                'assets/image/my_qris.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade100,
                                    child: const Icon(
                                      Icons.qr_code_2,
                                      size: 80,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade600,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.blue.shade300,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.payments,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Instructions with better design
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade50,
                            Colors.indigo.shade50,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.smartphone,
                              color: Colors.blue.shade600,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cara Pembayaran',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Buka aplikasi e-wallet Anda dan scan QR code di atas',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Actions with enhanced design
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Theme.of(context).colorScheme.outline),
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Batal',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF0041c3),
                              Color(0xFF0066FF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF0041c3,
                              ).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showPaymentProofDialog(
                              context,
                              amount,
                              'QRIS',
                              isCancel: isCancel,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Upload Bukti',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
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
    );
  }

  void _showPaymentProofDialog(
    BuildContext context,
    double amount,
    String paymentMethod, {
    bool isCancel = false,
  }) {
    _paymentProofImage = null; // Reset image

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: MediaQuery.of(context).viewInsets.bottom > 0 ? 10 : 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .shadow
                        .withValues(alpha: 25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header integrated with container
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.orange.shade100,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.secondary,
                                Theme.of(context)
                                    .colorScheme
                                    .secondary
                                    .withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondary
                                    .withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.receipt_long,
                            color: Theme.of(context).colorScheme.onSecondary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Upload Bukti Pembayaran',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                                ),
                              ),
                              Text(
                                'Verifikasi Pembayaran',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer
                                      .withOpacity(0.8),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Payment info card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Theme.of(context)
                                      .colorScheme
                                      .tertiaryContainer,
                                  Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .tertiaryContainer,
                                    borderRadius: BorderRadius.circular(
                                      10,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.payments,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onTertiaryContainer,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Metode: $paymentMethod',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onTertiaryContainer,
                                        ),
                                      ),
                                      Text(
                                        'Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onTertiaryContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Instructions
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerLow,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Upload foto bukti pembayaran yang jelas dan terbaca',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Image upload area with enhanced design
                          if (_paymentProofImage != null)
                            Container(
                              width: double.infinity,
                              height: 160,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      0.1,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(
                                  _paymentProofImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerLow,
                                    Theme.of(context)
                                        .colorScheme
                                        .surfaceContainer,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .shadow
                                        .withValues(alpha: 25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .shadow
                                              .withOpacity(0.2),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.cloud_upload,
                                      size: 24,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Belum ada bukti pembayaran",
                                    style: GoogleFonts.poppins(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Upload button with enhanced design
                          Container(
                            width: double.infinity,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () => _showImageSourceDialog(
                                context,
                                setState,
                              ),
                              icon: const Icon(
                                Icons.camera_alt,
                                size: 18,
                              ),
                              label: Text(
                                _paymentProofImage != null
                                    ? "Ganti Foto"
                                    : "Pilih Foto",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    10,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Format info
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .tertiaryContainer,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onTertiaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Format: JPG, PNG • Maksimal 5MB",
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onTertiaryContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // Actions with enhanced design
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainer,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    10,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Batal',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: _paymentProofImage != null
                                  ? LinearGradient(
                                      colors: [
                                        Theme.of(context).colorScheme.primary,
                                        Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.8),
                                      ],
                                    )
                                  : LinearGradient(
                                      colors: [
                                        Theme.of(context)
                                            .colorScheme
                                            .surfaceContainer,
                                        Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _paymentProofImage != null
                                  ? [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: ElevatedButton(
                              onPressed: _paymentProofImage != null
                                  ? () {
                                      Navigator.pop(context);
                                      _confirmManualPayment(
                                        context,
                                        amount,
                                        paymentMethod,
                                        isCancel: isCancel,
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                disabledBackgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    10,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Konfirmasi',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _paymentProofImage != null
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                ),
                              ),
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
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, StateSetter setState) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _paymentProofImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ErrorUtils.showErrorSnackBar(context, e,
          customMessage: 'Gagal memilih gambar');
    }
  }

  void _showImageSourceDialog(BuildContext context, StateSetter setState) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, setState);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, setState);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmManualPayment(
    BuildContext context,
    double amount,
    String method, {
    bool isCancel = false,
  }) {
    // Show verification pending dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_empty,
                color: Colors.orange,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isCancel
                  ? 'Pembayaran Cancel Diterima!'
                  : 'Bukti Pembayaran Diterima!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          isCancel
              ? 'Biaya cancel sebesar Rp ${NumberFormat('#,###', 'id_ID').format(amount)} dengan metode $method telah diterima. Order akan dibatalkan setelah verifikasi.'
              : 'Bukti pembayaran sebesar Rp ${NumberFormat('#,###', 'id_ID').format(amount)} dengan metode $method telah diterima. Status akan berubah menjadi "Menunggu Verifikasi" dan akan diverifikasi dalam 1x24 jam.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: 120,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                if (isCancel) {
                  // For cancel, go back to previous screen
                  Navigator.pop(context);
                } else {
                  // Update status to "menunggu_verifikasi"
                  _updateStatusToVerificationPending();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateStatusToVerificationPending() {
    if (mounted) {
      setState(() {
        _currentStatus = 'menunggu_verifikasi';
        _updatedAt = DateTime.now();
        _timeline = _buildTimelineFromCurrentStatus(
          _currentStatus,
          _createdAt!,
          _updatedAt!,
        );
      });
    }
  }

  List<_TimelineItem> _getCompletedStatuses() {
    return _timeline.where((item) => item.state == StepState.done).toList();
  }

  // ===== MODAL PEMBAYARAN DP =====
  void _showPaymentModal() {
    final TextEditingController dpAmountController = TextEditingController();

    // Hitung DP minimal (30% dari total)
    final double minDp = _totalCost != null ? _totalCost! * 0.3 : 0.0;

    String? selectedPaymentMethod =
        _selectedPaymentMethod; // Initialize with current value

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8)
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              children: [
                // Handle bar with glow effect
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(25),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                        left: 20,
                        right: 20,
                        top: 20,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with icon
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context).colorScheme.secondary,
                                        Theme.of(context)
                                            .colorScheme
                                            .secondary
                                            .withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary
                                            .withOpacity(
                                              0.3,
                                            ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.payment,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pembayaran DP',
                                        style: GoogleFonts.poppins(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                      Text(
                                        'Down Payment Service',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Amount Summary Cards
                            Row(
                              children: [
                                Expanded(
                                  child: _buildAmountCard(
                                    'Total Biaya',
                                    _totalCost != null && _totalCost! > 0
                                        ? 'Rp ${NumberFormat('#,###', 'id_ID').format(_totalCost)}'
                                        : 'Rp 0',
                                    Theme.of(context).colorScheme.primary,
                                    Icons.receipt_long,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildAmountCard(
                                    'DP Minimal',
                                    _totalCost != null && _totalCost! > 0
                                        ? 'Rp ${NumberFormat('#,###', 'id_ID').format(minDp)}'
                                        : 'Rp 0',
                                    Theme.of(context).colorScheme.secondary,
                                    Icons.account_balance_wallet,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Payment Methods Section
                            Text(
                              'Pilih Metode Pembayaran',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // QRIS - Available
                            _buildModernPaymentOption(
                              "QRIS",
                              "Scan QR code untuk pembayaran cepat",
                              Icons.qr_code_2,
                              Theme.of(context).colorScheme.primary,
                              selectedPaymentMethod == "QRIS",
                              () => setModalState(
                                () => selectedPaymentMethod = "QRIS",
                              ),
                              available: true,
                            ),

                            const SizedBox(height: 12),

                            // Transfer Bank - Available
                            _buildModernPaymentOption(
                              "Transfer Bank",
                              "Transfer ke rekening bank",
                              Icons.account_balance,
                              Theme.of(context).colorScheme.primary,
                              selectedPaymentMethod == "Bank Transfer",
                              () => setModalState(
                                () => selectedPaymentMethod = "Bank Transfer",
                              ),
                              available: true,
                            ),

                            const SizedBox(height: 12),

                            // E-wallet - Available
                            _buildModernPaymentOption(
                              "E-wallet",
                              "GoPay, OVO, Dana, LinkAja",
                              Icons.account_balance_wallet,
                              Theme.of(context).colorScheme.primary,
                              selectedPaymentMethod == "E-wallet",
                              () => setModalState(
                                () => selectedPaymentMethod = "E-wallet",
                              ),
                              available: true,
                            ),

                            const SizedBox(height: 24),

                            // Amount Input Section
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLow,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nominal DP',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Masukkan jumlah DP yang ingin dibayar (minimal 30%)',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .shadow
                                              .withOpacity(
                                                0.1,
                                              ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      controller: dpAmountController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        TextInputFormatter.withFunction((
                                          oldValue,
                                          newValue,
                                        ) {
                                          if (newValue.text.isEmpty) {
                                            return newValue;
                                          }
                                          final int? inputValue =
                                              int.tryParse(newValue.text);
                                          if (inputValue != null &&
                                              _totalCost != null &&
                                              inputValue >= _totalCost!) {
                                            return oldValue;
                                          }
                                          return newValue;
                                        }),
                                      ],
                                      decoration: InputDecoration(
                                        hintText: '0',
                                        hintStyle: GoogleFonts.poppins(
                                          fontSize: 18,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                        prefixText: 'Rp ',
                                        prefixStyle: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 16,
                                        ),
                                      ),
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Pay Button
                            Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (mounted) {
                                    setState(
                                      () => _selectedPaymentMethod =
                                          selectedPaymentMethod,
                                    );
                                  }

                                  if (selectedPaymentMethod == null) {
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Mohon pilih metode pembayaran',
                                          style: GoogleFonts.poppins(),
                                        ),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final dpAmount = double.tryParse(
                                    dpAmountController.text
                                        .replaceAll(',', '')
                                        .replaceAll('.', ''),
                                  );

                                  if (dpAmount == null || dpAmount <= 0) {
                                    _showErrorDialog(
                                      'Input Tidak Valid',
                                      'Masukkan nominal DP yang valid untuk melanjutkan pembayaran.',
                                      Colors.red,
                                    );
                                    return;
                                  }

                                  if (dpAmount < minDp) {
                                    _showMinDpDialog(minDp);
                                    return;
                                  }

                                  Navigator.pop(context);

                                  final paymentAmount = dpAmount;
                                  if (selectedPaymentMethod == "QRIS") {
                                    _showQrisPayment(
                                      context,
                                      paymentAmount,
                                    );
                                  }
                                },
                                icon: const Icon(Icons.payment, size: 24),
                                label: Text(
                                  'Bayar Sekarang',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Security note
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.security,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Pembayaran aman & terenkripsi dengan teknologi terkini',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAmountCard(
    String title,
    String amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPaymentOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool isSelected,
    VoidCallback? onTap, {
    required bool available,
  }) {
    return InkWell(
      onTap: available ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: available
              ? (isSelected ? color.withValues(alpha: 25) : Colors.white)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: available
                ? (isSelected ? color : Colors.grey[200]!)
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: available && isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    available ? color.withValues(alpha: 25) : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: available ? color : Colors.grey[500],
                size: 24,
              ),
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
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: available ? Colors.black87 : Colors.grey[500],
                        ),
                      ),
                      if (!available) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Coming Soon',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: available ? Colors.grey[600] : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            if (available && isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 25),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, color: color, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: 120,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMinDpDialog(double minDp) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 25),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange[700],
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'DP Kurang dari Minimal',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pembayaran DP minimal adalah 30% dari total biaya perbaikan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                children: [
                  Text(
                    'DP Minimal',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${NumberFormat('#,###', 'id_ID').format(minDp)}',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange[900],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: 120,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: Text(
                'Mengerti',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show Xendit payment method dialog
  void _showXenditPaymentDialog(
      BuildContext context, double amount, String paymentType,
      {bool isCancel = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8)
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ListView(
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              paymentType == 'VA'
                                  ? Icons.account_balance
                                  : Icons.wallet,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  paymentType == 'VA'
                                      ? 'Transfer Bank'
                                      : 'E-Wallet',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Pilih metode pembayaran',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Amount
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.payments,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Pembayaran',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                  ),
                                  Text(
                                    'Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Bank options
                      if (paymentType == 'VA') ...[
                        Text(
                          'Pilih Bank',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildBankOption(context, 'BCA', amount, isCancel),
                        _buildBankOption(context, 'BNI', amount, isCancel),
                        _buildBankOption(context, 'BRI', amount, isCancel),
                        _buildBankOption(context, 'MANDIRI', amount, isCancel),
                      ],

                      // E-wallet options
                      if (paymentType == 'EWALLET') ...[
                        Text(
                          'Pilih E-Wallet',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildEWalletOption(context, 'OVO', amount, isCancel),
                        _buildEWalletOption(context, 'DANA', amount, isCancel),
                        _buildEWalletOption(
                            context, 'SHOPEEPAY', amount, isCancel),
                        _buildEWalletOption(
                            context, 'LINKAJA', amount, isCancel),
                      ],

                      const SizedBox(height: 24),

                      // Cancel button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Batal', style: GoogleFonts.poppins()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankOption(
      BuildContext context, String bankCode, double amount, bool isCancel) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.account_balance, color: Colors.blue[700]),
        ),
        title: Text(_getBankName(bankCode),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        subtitle:
            Text('Virtual Account', style: GoogleFonts.poppins(fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          Navigator.pop(context);
          await _createVirtualAccount(context, bankCode, amount, isCancel);
        },
      ),
    );
  }

  Widget _buildEWalletOption(
      BuildContext context, String ewalletType, double amount, bool isCancel) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getEWalletColor(ewalletType).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_getEWalletIcon(ewalletType),
              color: _getEWalletColor(ewalletType)),
        ),
        title: Text(_getEWalletName(ewalletType),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        subtitle: Text('E-Wallet', style: GoogleFonts.poppins(fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          Navigator.pop(context);
          await _createEWalletPayment(context, ewalletType, amount, isCancel);
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
      case 'CIMB':
        return 'Bank CIMB Niaga';
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
      default:
        return code;
    }
  }

  IconData _getEWalletIcon(String code) {
    switch (code) {
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

  Color _getEWalletColor(String code) {
    switch (code) {
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

  Future<void> _createVirtualAccount(BuildContext context, String bankCode,
      double amount, bool isCancel) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      final orderCode = isCancel
          ? 'CANCEL_${DateTime.now().millisecondsSinceEpoch}'
          : widget.queueCode ??
              'ORDER_${DateTime.now().millisecondsSinceEpoch}';

      // Call Xendit VA API
      final result = await XenditPaymentService.createVirtualAccount(
        orderId: orderCode,
        amount: amount.toInt(),
        customerName: 'Customer',
        customerId: '1',
        bankCode: bankCode,
      );

      // Hide loading
      if (context.mounted) Navigator.pop(context);

      if (result['success'] == true) {
        // Show VA dialog
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Virtual Account ${_getBankName(bankCode)}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text('Nomor VA',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 8),
                        SelectableText(
                          result['va_number'] ?? '',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Tutup'),
                ),
              ],
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(result['message'] ?? 'Gagal membuat Virtual Account'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createEWalletPayment(BuildContext context, String ewalletType,
      double amount, bool isCancel) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      final orderCode = isCancel
          ? 'CANCEL_${DateTime.now().millisecondsSinceEpoch}'
          : widget.queueCode ??
              'ORDER_${DateTime.now().millisecondsSinceEpoch}';

      // Call Xendit E-wallet API
      final result = await XenditPaymentService.createEWalletPayment(
        orderId: orderCode,
        amount: amount.toInt(),
        customerPhone: '081234567890',
        customerId: '1',
        ewalletType: ewalletType,
      );

      // Hide loading
      if (context.mounted) Navigator.pop(context);

      if (result['success'] == true) {
        final checkoutUrl = result['checkout_url'] ?? '';
        final deeplinkUrl = result['deeplink_url'] ?? '';

        // Show e-wallet dialog
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Pembayaran ${_getEWalletName(ewalletType)}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getEWalletIcon(ewalletType),
                      size: 64, color: _getEWalletColor(ewalletType)),
                  const SizedBox(height: 16),
                  Text('Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue)),
                  const SizedBox(height: 16),
                  Text(
                      'Klik tombol di bawah untuk membuka aplikasi ${_getEWalletName(ewalletType)}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Tutup'),
                ),
                if (checkoutUrl.isNotEmpty || deeplinkUrl.isNotEmpty)
                  ElevatedButton(
                    onPressed: () {
                      // Open e-wallet app
                      Navigator.pop(context);
                    },
                    child: Text('Buka Aplikasi'),
                  ),
              ],
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Gagal membuat payment'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processFullPayment() async {
    final fullAmount = _totalCost ?? 0.0;
    if (fullAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Total biaya tidak valid',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Show modern payment method selection for full payment
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8)
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),

              Flexible(
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2196F3),
                                    Color(0xFF1976D2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.payments,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pembayaran Penuh',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Full Payment Service',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Amount display
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                                Theme.of(context).colorScheme.tertiaryContainer,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Theme.of(context).colorScheme.secondary),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.receipt_long,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Pembayaran',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondaryContainer,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Rp ${NumberFormat('#,###', 'id_ID').format(fullAmount)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Payment Methods
                        Text(
                          'Pilih Metode Pembayaran',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // QRIS - Available
                        _buildModernPaymentOption(
                          "QRIS",
                          "Scan QR code untuk pembayaran cepat",
                          Icons.qr_code_2,
                          Theme.of(context).colorScheme.primary,
                          false,
                          () {
                            Navigator.pop(context);
                            _showQrisPayment(context, fullAmount);
                          },
                          available: true,
                        ),

                        const SizedBox(height: 10),

                        // Transfer Bank - Available - show Xendit dialog
                        _buildModernPaymentOption(
                          "Transfer Bank",
                          "Transfer ke rekening bank",
                          Icons.account_balance,
                          Theme.of(context).colorScheme.primary,
                          false,
                          () {
                            Navigator.pop(context);
                            _showXenditPaymentDialog(context, fullAmount, 'VA');
                          },
                          available: true,
                        ),

                        const SizedBox(height: 10),

                        // E-wallet - Available - show Xendit dialog
                        _buildModernPaymentOption(
                          "E-wallet",
                          "GoPay, OVO, Dana, LinkAja",
                          Icons.account_balance_wallet,
                          Theme.of(context).colorScheme.primary,
                          false,
                          () {
                            Navigator.pop(context);
                            _showXenditPaymentDialog(
                                context, fullAmount, 'EWALLET');
                          },
                          available: true,
                        ),

                        const SizedBox(height: 16),

                        // Security note
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Theme.of(context).colorScheme.primary),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.security,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Pembayaran aman & terenkripsi',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCancelModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD32F2F), Color(0xFFF44336)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(25),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.error,
                                  Theme.of(context)
                                      .colorScheme
                                      .error
                                      .withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .error
                                      .withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.cancel,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Batalkan Order',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  'Cancel Order',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Cancel fee display
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.errorContainer,
                              Theme.of(context)
                                  .colorScheme
                                  .errorContainer
                                  .withOpacity(0.8)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Theme.of(context).colorScheme.error),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Biaya Pembatalan',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Rp 50.000',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
                                    ),
                                  ),
                                  Text(
                                    'Biaya jasa pengecekan yang telah dilakukan',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer
                                          .withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Pay and Cancel Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.error,
                              Theme.of(context)
                                  .colorScheme
                                  .error
                                  .withOpacity(0.8)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .error
                                  .withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _processCancelPayment();
                          },
                          icon: const Icon(Icons.payment, size: 24),
                          label: Text(
                            'Bayar & Batalkan Order',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Warning note
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Theme.of(context).colorScheme.tertiary),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onTertiaryContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tindakan ini tidak dapat dibatalkan',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onTertiaryContainer,
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
          ],
        ),
      ),
    );
  }

  Future<void> _processCancelPayment() async {
    const cancelAmount = 50000; // Rp 50.000

    // Show modern payment method selection for cancel
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.error,
                Theme.of(context).colorScheme.error.withOpacity(0.8)
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),

              Flexible(
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.error,
                                    Theme.of(context)
                                        .colorScheme
                                        .error
                                        .withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .error
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.cancel,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Biaya Pembatalan',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Cancel Order Fee',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Cancel fee display
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.errorContainer,
                                Theme.of(context)
                                    .colorScheme
                                    .errorContainer
                                    .withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Theme.of(context).colorScheme.error),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Biaya Cancel Order',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onErrorContainer,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Rp ${NumberFormat('#,###', 'id_ID').format(cancelAmount)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onErrorContainer,
                                      ),
                                    ),
                                    Text(
                                      'Biaya jasa pengecekan yang telah dilakukan',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onErrorContainer
                                            .withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Payment Methods
                        Text(
                          'Pilih Metode Pembayaran',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // QRIS - Available
                        _buildModernPaymentOption(
                          "QRIS",
                          "Scan QR code untuk pembayaran cepat",
                          Icons.qr_code_2,
                          Theme.of(context).colorScheme.primary,
                          false,
                          () {
                            Navigator.pop(context);
                            _showQrisPayment(
                              context,
                              cancelAmount.toDouble(),
                              isCancel: true,
                            );
                          },
                          available: true,
                        ),

                        const SizedBox(height: 10),

                        // Transfer Bank - Available
                        _buildModernPaymentOption(
                          "Transfer Bank",
                          "Transfer ke rekening bank",
                          Icons.account_balance,
                          Theme.of(context).colorScheme.primary,
                          false,
                          () {
                            Navigator.pop(context);
                            _showXenditPaymentDialog(
                                context, cancelAmount.toDouble(), 'VA',
                                isCancel: true);
                          },
                          available: true,
                        ),

                        const SizedBox(height: 10),

                        // E-wallet - Available
                        _buildModernPaymentOption(
                          "E-wallet",
                          "GoPay, OVO, Dana, LinkAja",
                          Icons.account_balance_wallet,
                          Theme.of(context).colorScheme.primary,
                          false,
                          () {
                            Navigator.pop(context);
                            _showXenditPaymentDialog(
                                context, cancelAmount.toDouble(), 'EWALLET',
                                isCancel: true);
                          },
                          available: true,
                        ),

                        const SizedBox(height: 16),

                        // Warning note
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Theme.of(context).colorScheme.tertiary),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onTertiaryContainer,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Pembayaran ini akan membatalkan order Anda',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onTertiaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showServiceTypeConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing without choice
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Konfirmasi Jenis Service',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Berdasarkan data order, ini terdeteksi sebagai service pickup (tidak ada teknisi yang ditugaskan). Apakah benar?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _inferredServiceType = 'pickup';
              _hasConfirmedType = true;
              Navigator.pop(context);
              setState(() {}); // Refresh UI
            },
            child: Text(
              'Ya, Pickup',
              style: GoogleFonts.poppins(color: Colors.blue),
            ),
          ),
          TextButton(
            onPressed: () {
              _inferredServiceType = 'delivery';
              _hasConfirmedType = true;
              Navigator.pop(context);
              setState(() {}); // Refresh UI
            },
            child: Text(
              'Tidak, Delivery',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // ========================= UI =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Image.asset('assets/image/logo.png', width: 95, height: 30),
        actions: [
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
      bottomNavigationBar: _bottomNavBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Status Order (${_inferredServiceType == 'delivery' ? 'Delivery' : 'Pickup'})',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),

            if (_inferredServiceType == 'pickup') ...[
              const SizedBox(height: 8),
            ],

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(_currentStatus),
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _statusMeta(
                            _currentStatus,
                            _inferredServiceType,
                          ).description,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (_getCompletedStatuses().isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.shadow.withValues(alpha: 25),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status yang Sudah Selesai',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._getCompletedStatuses().map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                  Text(
                                    _fmt(item.time),
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Button Bayar DP (muncul saat status approved atau waitingOrder)
            if (_currentStatus == 'approved' ||
                _currentStatus == 'waitingOrder') ...[
              const SizedBox(height: 16),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              _isPaymentProcessing ? null : _showPaymentModal,
                          icon: const Icon(Icons.payment, size: 20),
                          label: Text(
                            'Bayar DP',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isPaymentProcessing
                                ? Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                : Theme.of(context).colorScheme.tertiary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onTertiary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isPaymentProcessing
                              ? null
                              : () => _processFullPayment(),
                          icon: const Icon(Icons.payment, size: 20),
                          label: Text(
                            'Bayar Keseluruhan',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isPaymentProcessing
                                ? Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                : Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isPaymentProcessing ? null : _showCancelModal,
                      icon: const Icon(Icons.cancel, size: 20),
                      label: Text(
                        'Cancel Order (Biaya Rp 50.000)',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isPaymentProcessing
                            ? Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                            : Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Button Lanjutkan Pembayaran (muncul saat completed)
            if (_currentStatus == 'completed') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailServiceMidtransPage(
                          serviceType: 'repair',
                          nama: 'Customer',
                          status: _currentStatus,
                          jumlahBarang: 1,
                          items: const [],
                          alamat: 'Alamat Customer',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Lanjutkan Pembayaran',
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bottomNavBar() {
    return BottomNavigationBar(
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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          );
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor:
          Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
      unselectedItemColor:
          Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
      showUnselectedLabels: true,
      selectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
      unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.build_circle_outlined),
          label: 'Service',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart_outlined),
          label: 'Beli',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.percent_outlined),
          label: 'Promo',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}

// ========================= Types util =========================

enum StepState { done, progress, pending }

class _TimelineItem {
  final DateTime? time;
  final String title;
  final String description;
  final StepState state;

  _TimelineItem({
    required this.time,
    required this.title,
    required this.description,
    required this.state,
  });
}

class _StatusMeta {
  final String title;
  final String description;
  _StatusMeta(this.title, this.description);
}
