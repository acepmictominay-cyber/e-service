import 'dart:async';
import 'package:azza_service/models/technician_order_model.dart';
import 'package:azza_service/Others/map_view_page.dart';
import 'package:azza_service/Others/session_manager.dart';
import 'package:azza_service/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _startLocationTracking(String orderId) async {
    final kryKode = await SessionManager.getkry_kode();
    if (kryKode == null || kryKode.isEmpty) {
      return;
    }

    await LocationService.instance.startTracking(
      transKode: orderId,
      kryKode: kryKode,
    );
  }

  void _stopLocationTracking() {
    LocationService.instance.stopTracking();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: Column(
        children: [
          // Auto-refresh indicator
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
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Auto-refresh aktif • Memperbarui setiap 30 detik',
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

            // Informasi Customer dan Perangkat
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
                        color: const Color(0xFF0041c3),
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
                          color: const Color(0xFF0041c3),
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

            // ===== ACTION BUTTONS SECTION =====
            if (order.status != OrderStatus.completed &&
                order.status != OrderStatus.jobDone) ...[
              const SizedBox(height: 16),

              // Status: ARRIVED - Show Selesai and Tindakan buttons
              if (order.status == OrderStatus.arrived) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showCompletionDialog(context, order),
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
                        icon: const Icon(Icons.build, size: 16),
                        label: const Text('Tindakan'),
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

                // Status: WAITING APPROVAL atau APPROVED
              ] else if (order.status == OrderStatus.waitingApproval ||
                  order.status == OrderStatus.approved) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        order.status == OrderStatus.approved
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          order.status == OrderStatus.approved
                              ? Colors.green.shade300
                              : Colors.orange.shade300,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status header
                      Row(
                        children: [
                          Icon(
                            order.status == OrderStatus.approved
                                ? Icons.check_circle
                                : Icons.hourglass_empty,
                            color:
                                order.status == OrderStatus.approved
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.status == OrderStatus.approved
                                  ? 'Persetujuan admin diterima. Silakan ambil suku cadang.'
                                  : 'Menunggu persetujuan admin untuk pengambilan suku cadang',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color:
                                    order.status == OrderStatus.approved
                                        ? Colors.green.shade700
                                        : Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Approval Status Badge
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              order.status == OrderStatus.approved
                                  ? Colors.green.shade100
                                  : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color:
                                order.status == OrderStatus.approved
                                    ? Colors.green.shade400
                                    : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              order.status == OrderStatus.approved
                                  ? Icons.verified
                                  : Icons.pending,
                              size: 16,
                              color:
                                  order.status == OrderStatus.approved
                                      ? Colors.green.shade700
                                      : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              order.status == OrderStatus.approved
                                  ? 'Disetujui oleh Admin'
                                  : 'Belum Disetujui',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color:
                                    order.status == OrderStatus.approved
                                        ? Colors.green.shade700
                                        : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Catatan jika ada
                      if (order.approvalNotes != null &&
                          order.approvalNotes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Catatan:',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.approvalNotes!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Action Buttons
                      Row(
                        children: [
                          // Button Ambil Suku Cadang (enabled hanya jika status = approved)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  order.status == OrderStatus.approved
                                      ? () async {
                                        // Start tracking untuk ambil suku cadang
                                        await _startLocationTracking(
                                          order.orderId,
                                        );
                                        widget.onUpdateStatus(
                                          order,
                                          OrderStatus.pickingParts,
                                        );

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Memulai pengambilan suku cadang',
                                            ),
                                            backgroundColor: Colors.purple,
                                          ),
                                        );
                                      }
                                      : null, // Disabled jika status masih waitingApproval
                              icon: Icon(
                                order.status == OrderStatus.approved
                                    ? Icons.build
                                    : Icons.lock,
                                size: 16,
                              ),
                              label: Text(
                                order.status == OrderStatus.approved
                                    ? 'Ambil Suku Cadang'
                                    : 'Menunggu Approval',
                                style: const TextStyle(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade300,
                                disabledForegroundColor: Colors.grey.shade600,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Info tambahan jika belum disetujui
                      if (order.status == OrderStatus.waitingApproval) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Admin akan memeriksa kebutuhan suku cadang dan mengubah status menjadi "approved" jika disetujui',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Status: PICKING PARTS - Show progress and Selesai button
              ] else if (order.status == OrderStatus.pickingParts) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_shipping,
                        color: Colors.purple.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sedang dalam perjalanan mengambil suku cadang',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.purple.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              backgroundColor: Colors.purple.shade100,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.purple.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCompletionDialog(context, order),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Selesai Mengambil Part'),
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

                // Status: REPAIRING - Show progress and Selesai button
              ] else if (order.status == OrderStatus.repairing) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.engineering,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sedang melakukan perbaikan',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              backgroundColor: Colors.red.shade100,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.red.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCompletionDialog(context, order),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Selesai Perbaikan'),
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

                // Other statuses (waiting, accepted, enRoute)
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final nextStatus = _getNextStatus(order.status);

                      if (nextStatus != null) {
                        if (nextStatus == OrderStatus.enRoute) {
                          await _startLocationTracking(order.orderId);
                        } else if (order.status == OrderStatus.enRoute &&
                            nextStatus != OrderStatus.enRoute) {
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

  // Helper functions
  OrderStatus? _getNextStatus(OrderStatus current) {
    switch (current) {
      case OrderStatus.waiting:
        return OrderStatus.accepted;
      case OrderStatus.waitingOrder:
        return OrderStatus.accepted;
      case OrderStatus.accepted:
        return OrderStatus.enRoute;
      case OrderStatus.enRoute:
        return OrderStatus.arrived;
      case OrderStatus.arrived:
        return null; // Handled by specific buttons
      case OrderStatus.waitingApproval:
        return null; // Handled by specific buttons
      case OrderStatus.pickingParts:
        return null; // Handled by Selesai button
      case OrderStatus.repairing:
        return null; // Handled by Selesai Perbaikan button
      default:
        return null;
    }
  }

  String _getButtonLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.waiting:
        return 'Menerima Pesanan';
      case OrderStatus.waitingOrder:
        return 'Menerima Pesanan';
      case OrderStatus.accepted:
        return 'Dalam Perjalanan';
      case OrderStatus.enRoute:
        return 'Tiba';
      case OrderStatus.arrived:
        return 'Pilih Aksi';
      case OrderStatus.waitingApproval:
        return 'Menunggu Approval';
      case OrderStatus.pickingParts:
        return 'Sedang Ambil Suku Cadang';
      case OrderStatus.repairing:
        return 'Sedang Perbaikan';
      default:
        return '';
    }
  }

  IconData _getButtonIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.waiting:
        return Icons.assignment_turned_in;
      case OrderStatus.waitingOrder:
        return Icons.assignment_turned_in;
      case OrderStatus.accepted:
        return Icons.directions_car;
      case OrderStatus.enRoute:
        return Icons.location_on;
      case OrderStatus.arrived:
        return Icons.touch_app;
      case OrderStatus.waitingApproval:
        return Icons.hourglass_empty;
      case OrderStatus.pickingParts:
        return Icons.local_shipping;
      case OrderStatus.repairing:
        return Icons.engineering;
      default:
        return Icons.check;
    }
  }

  Color _getButtonColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.waiting:
        return Colors.green;
      case OrderStatus.waitingOrder:
        return Colors.green;
      case OrderStatus.accepted:
        return const Color(0xFF0041c3);
      case OrderStatus.enRoute:
        return Colors.orange;
      case OrderStatus.arrived:
        return Colors.purple;
      case OrderStatus.waitingApproval:
        return Colors.amber;
      case OrderStatus.pickingParts:
        return Colors.indigo;
      case OrderStatus.repairing:
        return Colors.red;
      default:
        return const Color(0xFF1976D2);
    }
  }

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

  // ===== PERBAIKAN: Ganti nama method dan logika =====
  void _showCompletionDialog(BuildContext context, TechnicianOrder order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'Konfirmasi Penyelesaian',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                order.status == OrderStatus.pickingParts
                    ? 'Apakah suku cadang sudah diambil?'
                    : order.status == OrderStatus.repairing
                        ? 'Apakah perbaikan sudah selesai dikerjakan?'
                        : 'Apakah pekerjaan sudah selesai dikerjakan?',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _stopLocationTracking();
                      // UPDATE STATUS BERDASARKAN STATUS SAAT INI
                      final nextStatus = order.status == OrderStatus.pickingParts
                          ? OrderStatus.repairing
                          : OrderStatus.completed;
                      widget.onUpdateStatus(order, nextStatus);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Ya, Selesai',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
