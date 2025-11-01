import 'dart:async';
import 'dart:io';
import 'package:e_service/api_services/api_service.dart';
import 'package:e_service/models/technician_order_model.dart';
import 'package:e_service/Others/map_view_page.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class TasksTab extends StatefulWidget {
  final List<TechnicianOrder> assignedOrders;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final Future<void> Function(TechnicianOrder, OrderStatus) onUpdateStatus;
  final void Function(TechnicianOrder) onShowDamageForm;
  final Future<void> Function(String) onOpenMaps;
  final bool isAutoRefreshEnabled;

  const TasksTab({
    super.key,
    required this.assignedOrders,
    required this.isLoading,
    required this.onRefresh,
    required this.onUpdateStatus,
    required this.onShowDamageForm,
    required this.onOpenMaps,
    this.isAutoRefreshEnabled = true,
  });

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  Timer? _locationTimer;
  String? _currentTrackingTransKode;
  String? _currentTrackingKryKode;

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  void _startLocationTracking(String transKode, String kryKode) {
    _stopLocationTracking(); // Stop any existing tracking

    _currentTrackingTransKode = transKode;
    _currentTrackingKryKode = kryKode;

    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        await ApiService.updateDriverLocation(
          transKode,
          kryKode,
          position.latitude,
          position.longitude,
        );

        print('📍 Location sent: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        print('❌ Failed to send location: $e');
      }
    });
  }

  void _stopLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _currentTrackingTransKode = null;
    _currentTrackingKryKode = null;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: Column(
        children: [
          // ========== AUTO-REFRESH INDICATOR ==========
          if (widget.isAutoRefreshEnabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.green.shade200, width: 1),
                ),
              ),
              child: Row(
                children: [
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(seconds: 2),
                    builder: (context, double value, child) {
                      return Transform.rotate(
                        angle: value * 2 * 3.14159,
                        child: Icon(
                          Icons.sync,
                          size: 16,
                          color: Colors.green.shade700,
                        ),
                      );
                    },
                    onEnd: () {
                      // Trigger rebuild untuk animasi continuous
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Auto-refresh aktif • Memperbarui setiap 10 detik',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'LIVE',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // ============================================
          Expanded(
            child:
                widget.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : widget.assignedOrders.isEmpty
                    ? Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.6,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tidak ada pesanan aktif',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (widget.isAutoRefreshEnabled)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Menunggu pesanan baru...',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.assignedOrders.length,
                      itemBuilder: (context, index) {
                        final order = widget.assignedOrders[index];
                        return _buildOrderCard(context, order);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, TechnicianOrder order) {
    print(
      '--- UI RENDER: Membangun Card untuk Order [${order.orderId}] dengan Status [${order.status.name}]',
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan Order ID dan Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderId,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Tambahan: Kode Customer jika ada
                      if (order.cosKode != null)
                        Text(
                          'Kode: ${order.cosKode}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: order.status.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        order.status.icon,
                        size: 16,
                        color: order.status.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        order.status.displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: order.status.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Informasi Customer dan Perangkat dalam bentuk flat info rows
            _infoRow('Nama Customer', order.customerName),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    'Alamat:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => MapsWebViewPage(
                                address: order.customerAddress,
                              ),
                        ),
                      );
                    },
                    child: Text(
                      order.customerAddress,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),
            if (order.customerPhone != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      'No. Telepon:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final Uri launchUri = Uri(
                          scheme: 'tel',
                          path: order.customerPhone,
                        );
                        await launchUrl(launchUri);
                      },
                      child: Text(
                        order.customerPhone!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            _infoRow('Merek', order.deviceBrand ?? 'N/A'),
            const SizedBox(height: 4),
            _infoRow('Device', order.deviceType ?? 'N/A'),
            const SizedBox(height: 4),
            _infoRow('Serial Number', order.deviceSerial ?? 'N/A'),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    'Status Garansi:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getWarrantyColor(
                        order.warrantyStatus,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getWarrantyColor(order.warrantyStatus),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      order.warrantyStatus ?? 'Tidak Ada Garansi',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getWarrantyColor(order.warrantyStatus),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _infoRow(
              'Total',
              'Rp ${order.estimatedPrice?.toStringAsFixed(0) ?? '0'}',
            ),

            // Action Buttons
            if (order.status != OrderStatus.completed) ...[
              const SizedBox(height: 16),
              if (order.status == OrderStatus.arrived) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            () => widget.onUpdateStatus(
                              order,
                              OrderStatus.completed,
                            ),
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: const Text('Selesai'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => widget.onShowDamageForm(order),
                        icon: const Icon(Icons.report_problem, size: 16),
                        label: const Text('Temuan Kerusakan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final nextStatus = _getNextStatus(order.status);
                      if (nextStatus != null) {
                        if (nextStatus == OrderStatus.enRoute) {
                          // Start location tracking when status changes to enRoute
                          _startLocationTracking(
                            order.orderId,
                            'TECH001',
                          ); // TODO: Get actual kry_kode from session
                        } else if (order.status == OrderStatus.enRoute &&
                            nextStatus != OrderStatus.enRoute) {
                          // Stop location tracking when leaving enRoute status
                          _stopLocationTracking();
                        }
                        widget.onUpdateStatus(order, nextStatus);
                      }
                    },
                    icon: Icon(_getButtonIcon(order.status), size: 16),
                    label: Text(_getButtonLabel(order.status)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getButtonColor(order.status),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // Popup khusus Transaksi untuk "Temuan Kerusakan"
  void _showTransaksiDamageForm(BuildContext context, dynamic transaksi) {
    final TextEditingController descCtrl = TextEditingController();
    final TextEditingController estCtrl = TextEditingController();
    final List<XFile> media = [];
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 16,
                    right: 16,
                    top: 16,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Temuan Kerusakan - ${transaksi['trans_kode'] ?? ''}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: descCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Deskripsi Kerusakan',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: estCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Estimasi Harga (Rp)',
                            prefixText: 'Rp ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                final picker = ImagePicker();
                                final picked = await picker.pickMultiImage();
                                setModalState(() => media.addAll(picked));
                              },
                              icon: const Icon(Icons.photo_camera),
                              label: const Text('Upload Media'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('${media.length} file dipilih'),
                            ),
                          ],
                        ),
                        if (media.isNotEmpty)
                          Container(
                            height: 100,
                            margin: const EdgeInsets.only(top: 8),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: media.length,
                              itemBuilder:
                                  (context, index) => Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Image.file(
                                      File(media[index].path),
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed:
                                    isSaving
                                        ? null
                                        : () => Navigator.pop(context),
                                child: const Text('Batal'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    isSaving
                                        ? null
                                        : () async {
                                          final kode =
                                              (transaksi['trans_kode'] ?? '')
                                                  .toString();
                                          final ket = descCtrl.text.trim();
                                          final totalStr = estCtrl.text
                                              .trim()
                                              .replaceAll(
                                                RegExp(r'[^0-9]'),
                                                '',
                                              );
                                          final total = num.tryParse(totalStr);

                                          if (kode.isEmpty) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'trans_kode tidak ditemukan',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return;
                                          }
                                          if (ket.isEmpty || total == null) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Isi deskripsi dan estimasi harga dengan benar',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return;
                                          }

                                          setModalState(() => isSaving = true);
                                          try {
                                            await ApiService.updateTransaksiTemuan(
                                              kode,
                                              ket,
                                              total,
                                              alsoSetStatus: 'waitingapproval',
                                            );

                                            // Mutasi lokal agar kartu langsung update
                                            transaksi['ket_keluhan'] = ket;
                                            transaksi['trans_total'] = total;
                                            transaksi['trans_status'] =
                                                'waitingapproval';

                                            if (context.mounted) {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Temuan disimpan',
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            }

                                            // Rebuild data dari server (opsional tapi disarankan)
                                            await widget.onRefresh();
                                          } catch (e) {
                                            setModalState(
                                              () => isSaving = false,
                                            );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Gagal simpan temuan: $e',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                                child:
                                    isSaving
                                        ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                        : const Text('Simpan'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  // ====== Helpers for Order (TechnicianOrder) ======

  OrderStatus? _getNextStatus(OrderStatus current) {
    switch (current) {
      case OrderStatus.waiting:
        return OrderStatus.accepted;
      case OrderStatus.accepted:
        return OrderStatus.enRoute;
      case OrderStatus.enRoute:
        return OrderStatus.arrived;
      case OrderStatus.arrived:
        return null;
      case OrderStatus.waitingApproval:
        return OrderStatus.pickingParts;
      case OrderStatus.pickingParts:
        return OrderStatus.repairing;
      case OrderStatus.repairing:
        return OrderStatus.completed;
      default:
        return null;
    }
  }

  String _getButtonLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.waiting:
        return 'Menerima Pesanan';
      case OrderStatus.accepted:
        return 'Dalam Perjalanan';
      case OrderStatus.enRoute:
        return 'Tiba';
      case OrderStatus.arrived:
        return 'Pilih Aksi';
      case OrderStatus.waitingApproval:
        return 'Ambil Suku Cadang';
      case OrderStatus.pickingParts:
        return 'Memperbaiki';
      case OrderStatus.repairing:
        return 'Selesai';
      default:
        return '';
    }
  }

  IconData _getButtonIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.waiting:
        return Icons.assignment_turned_in;
      case OrderStatus.accepted:
        return Icons.directions_car;
      case OrderStatus.enRoute:
        return Icons.location_on;
      case OrderStatus.arrived:
        return Icons.hourglass_empty;
      case OrderStatus.waitingApproval:
        return Icons.build;
      case OrderStatus.pickingParts:
        return Icons.settings;
      case OrderStatus.repairing:
        return Icons.check_circle;
      default:
        return Icons.check;
    }
  }

  Color _getButtonColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.waiting:
        return Colors.green;
      case OrderStatus.accepted:
        return Colors.blue;
      case OrderStatus.enRoute:
        return Colors.orange;
      case OrderStatus.arrived:
        return Colors.purple;
      case OrderStatus.waitingApproval:
        return Colors.indigo;
      case OrderStatus.pickingParts:
        return Colors.teal;
      case OrderStatus.repairing:
        return Colors.red;
      default:
        return const Color(0xFF1976D2);
    }
  }

  // ====== Helpers for Transaksi (String status) ======

  String _getTransaksiButtonLabel(String status) {
    switch (status.toLowerCase()) {
      case 'waiting':
      case 'pending':
        return 'Menerima Pesanan';
      case 'accepted':
        return 'Dalam Perjalanan';
      case 'enroute':
        return 'Tiba';
      case 'arrived':
        return 'Menunggu Persetujuan';
      case 'waitingapproval':
        return 'Ambil Suku Cadang';
      case 'pickingparts':
        return 'Memperbaiki';
      case 'repairing':
        return 'Selesai';
      default:
        return 'Tandai Selesai';
    }
  }

  String? _getNextTransaksiStatus(String current) {
    switch (current.toLowerCase()) {
      case 'waiting':
      case 'pending':
        return 'accepted';
      case 'accepted':
        return 'enroute';
      case 'enroute':
        return 'arrived';
      case 'arrived':
        return null;
      case 'waitingapproval':
        return 'pickingparts';
      case 'pickingparts':
        return 'repairing';
      case 'repairing':
        return 'completed';
      default:
        return null;
    }
  }

  IconData _getTransaksiButtonIcon(String status) {
    switch (status.toLowerCase()) {
      case 'waiting':
      case 'pending':
        return Icons.assignment_turned_in;
      case 'accepted':
        return Icons.directions_car;
      case 'enroute':
        return Icons.location_on;
      case 'arrived':
        return Icons.hourglass_empty;
      case 'waitingapproval':
        return Icons.build;
      case 'pickingparts':
        return Icons.settings;
      case 'repairing':
        return Icons.check_circle;
      default:
        return Icons.check;
    }
  }

  Color _getTransaksiButtonColor(String status) {
    switch (status.toLowerCase()) {
      case 'waiting':
      case 'pending':
        return Colors.green;
      case 'accepted':
        return Colors.blue;
      case 'enroute':
        return Colors.orange;
      case 'arrived':
        return Colors.purple;
      case 'waitingapproval':
        return Colors.indigo;
      case 'pickingparts':
        return Colors.teal;
      case 'repairing':
        return Colors.red;
      default:
        return const Color(0xFF1976D2);
    }
  }

  // ====== Common UI helpers ======

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

  // Helper function untuk warna status garansi
  Color _getWarrantyColor(String? warrantyStatus) {
    if (warrantyStatus == null) return Colors.grey;

    switch (warrantyStatus.toLowerCase()) {
      case 'aktif':
      case 'active':
        return Colors.green;
      case 'expired':
      case 'kadaluarsa':
        return Colors.red;
      case 'hampir expired':
      case 'near expiry':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
