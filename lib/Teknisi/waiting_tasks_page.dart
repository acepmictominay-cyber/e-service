import 'dart:async';
import 'package:azza_service/api_services/api_service.dart';
import 'package:azza_service/models/technician_order_model.dart';
import 'package:azza_service/Others/session_manager.dart';
import 'package:azza_service/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class WaitingTasksPage extends StatefulWidget {
  final bool isAutoRefreshEnabled;
  final Future<void> Function(TechnicianOrder, OrderStatus)? onUpdateStatus;
  final void Function(TechnicianOrder)? onShowDamageForm;
  final Future<void> Function(String)? onOpenMaps;

  const WaitingTasksPage({
    super.key,
    this.isAutoRefreshEnabled = true,
    this.onUpdateStatus,
    this.onShowDamageForm,
    this.onOpenMaps,
  });

  @override
  State<WaitingTasksPage> createState() => _WaitingTasksPageState();
}

class _WaitingTasksPageState extends State<WaitingTasksPage> {
  List<TechnicianOrder> _availableOrders = [];
  List<TechnicianOrder> _myOrders = [];
  List<TechnicianOrder> _otherOrders = [];
  bool _isLoadingOrders = false;
  String? _technicianId;
  DateTime? _lastFetchTime;
  static const _cacheDuration = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _fetchAvailableOrders();
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool get _isCacheFresh =>
      _lastFetchTime != null &&
      DateTime.now().difference(_lastFetchTime!) < _cacheDuration;

  Future<void> _fetchAvailableOrders({bool forceRefresh = false}) async {
    if (!mounted) return;
    if (!forceRefresh && _isCacheFresh && _availableOrders.isNotEmpty) {
      return;
    }

    final wasFirstLoad = _availableOrders.isEmpty;
    if (wasFirstLoad) {
      setState(() => _isLoadingOrders = true);
    }

    try {
      _technicianId = await SessionManager.getkry_kode();
      final allOrders =
          await ApiService.getTeknisiTransaksi(_technicianId ?? '');

      if (!mounted) return;

      var available = allOrders
          .where((order) =>
              order.status != OrderStatus.completed &&
              order.status != OrderStatus.jobDone)
          .toList()
        ..sort((a, b) {
          final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });

      available = available.take(5).toList();

      final mine = available
          .where((order) => order.kryKode == _technicianId)
          .toList();

      final other = available
          .where((order) =>
              order.kryKode == null || order.kryKode != _technicianId)
          .toList();

      setState(() {
        _availableOrders = available;
        _myOrders = mine;
        _otherOrders = other;
        _isLoadingOrders = false;
        _lastFetchTime = DateTime.now();
      });
    } catch (e) {
      if (mounted && wasFirstLoad) {
        setState(() => _isLoadingOrders = false);
      }
    }
  }

  Future<void> _updateOrderStatus(
      TechnicianOrder order, OrderStatus newStatus) async {
    if (!mounted) return;

    try {
      await ApiService.updateTransaksiStatus(order.orderId, newStatus.name);

      if (newStatus == OrderStatus.pickingParts) {
        final kryKode = await SessionManager.getkry_kode();
        if (kryKode != null) {
          await LocationService.instance.startTracking(
            transKode: order.orderId,
            kryKode: kryKode,
          );
        }
      } else if (newStatus == OrderStatus.completed ||
          newStatus == OrderStatus.arrived ||
          newStatus == OrderStatus.repairing) {
        await LocationService.instance.stopTracking();
      }

      String message = 'Status berhasil diperbarui ke ${newStatus.displayName}';
      if (newStatus == OrderStatus.waitingApproval) {
        message = 'Tindakan disimpan, menunggu persetujuan admin';
      } else if (newStatus == OrderStatus.pickingParts) {
        message = 'Mulai mengambil suku cadang';
      } else if (newStatus == OrderStatus.repairing) {
        message = 'Mulai melakukan perbaikan';
      } else if (newStatus == OrderStatus.completed) {
        message = 'Pekerjaan selesai! Order telah diselesaikan!';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: newStatus == OrderStatus.waitingApproval
                ? Colors.orange
                : Colors.green,
          ),
        );
      }

      await _fetchAvailableOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui status pesanan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showActionSheet(BuildContext context, TechnicianOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ActionForm(order: order, onSaved: () async {
        Navigator.pop(context);
        await _updateOrderStatus(order, OrderStatus.processing);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final my = _myOrders;
    final other = _otherOrders;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _fetchAvailableOrders(forceRefresh: true),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isLoadingOrders && _availableOrders.isEmpty)
              ...List.generate(3, (_) => _buildSkeletonCard())
            else ...[
              if (_isLoadingOrders) const LinearProgressIndicator(minHeight: 3),
              const SizedBox(height: 12),
              Text(
                'Daftar Order Offline',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              if (_availableOrders.isEmpty && !_isLoadingOrders)
                _buildEmptyState()
              else ...[
                if (my.isNotEmpty) ...[
                  _buildSectionHeader('Order Saya', Icons.person, const Color(0xFF0041c3)),
                  const SizedBox(height: 12),
                  ...my.map((order) => _buildOrderCard(context, order)),
                  const SizedBox(height: 20),
                ],
                if (other.isNotEmpty) ...[
                  _buildSectionHeader('Order Lain (Offline)', Icons.inbox, Colors.orange),
                  const SizedBox(height: 12),
                  ...other.map((order) => _buildOrderCard(context, order)),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.orange.shade300,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tidak Ada Order Tersedia',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Semua order sudah diambil atau sedang dikerjakan',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.isAutoRefreshEnabled) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.orange.shade300,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Memantau order baru...',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, TechnicianOrder order) {
    // Popup tindakan hanya untuk order yang boleh dikerjakan.
    // Status menunggu persetujuan admin & menunggu order part tidak memunculkan popup.
    final bool canOpenActionSheet =
        order.status != OrderStatus.waitingApproval &&
        order.status != OrderStatus.waitingOrder;

    return GestureDetector(
      onTap: canOpenActionSheet ? () => _showActionSheet(context, order) : null,
      child: Card(
        key: ValueKey(order.orderId),
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(
                           order.cosKode ?? '-',
                           style: GoogleFonts.poppins(
                             fontSize: 16,
                             fontWeight: FontWeight.bold,
                           ),
                           overflow: TextOverflow.ellipsis,
                         ),
                        if (order.createdAt != null)
                          Text(
                            '${order.createdAt!.day.toString().padLeft(2, '0')}/${order.createdAt!.month.toString().padLeft(2, '0')}/${order.createdAt!.year}',
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
              _buildInfoRow('Customer', order.customerName),
              const SizedBox(height: 4),
              _buildInfoRow('Alamat', order.customerAddress, isLink: true, onTap: () async {
                if (widget.onOpenMaps != null) {
                  await widget.onOpenMaps!(order.customerAddress);
                } else {
                  final encodedAddress = Uri.encodeComponent(order.customerAddress);
                  final url = Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                }
              }),
              const SizedBox(height: 4),
              if (order.customerPhone != null) ...[
                _buildInfoRow('Telepon', order.customerPhone!, isLink: true, onTap: () async {
                  final Uri launchUri = Uri(scheme: 'tel', path: order.customerPhone!);
                  if (await canLaunchUrl(launchUri)) {
                    await launchUrl(launchUri);
                  }
                }),
                const SizedBox(height: 4),
              ],
              _buildInfoRow('Device', '${order.deviceBrand ?? ''} ${order.deviceType ?? ''}'.trim()),
              const SizedBox(height: 4),
              _buildInfoRow('SN', order.deviceSerial ?? ''),
              const SizedBox(height: 4),
              _buildInfoRow('Total', 'Rp ${order.estimatedPrice?.toStringAsFixed(0) ?? '0'}'),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {VoidCallback? onTap, bool isLink = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isLink ? const Color(0xFF0041c3) : Colors.grey.shade700,
                decoration: isLink ? TextDecoration.underline : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmer(
      {required double width, required double height, double borderRadius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmer(width: 120, height: 18),
                      const SizedBox(height: 8),
                      _buildShimmer(width: 80, height: 14),
                    ],
                  ),
                ),
                _buildShimmer(width: 110, height: 28, borderRadius: 12),
              ],
            ),
            const SizedBox(height: 16),
            _buildShimmer(width: double.infinity, height: 16),
            const SizedBox(height: 8),
            _buildShimmer(width: double.infinity - 32, height: 16),
            const SizedBox(height: 8),
            _buildShimmer(width: double.infinity - 64, height: 16),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ActionForm extends StatefulWidget {
  final TechnicianOrder order;
  final VoidCallback onSaved;

  const _ActionForm({required this.order, required this.onSaved});

  @override
  State<_ActionForm> createState() => _ActionFormState();
}

class _ActionFormState extends State<_ActionForm> {
  final List<String> standardActions = [
    'Memperbaiki Part',
    'Mengganti Part',
  ];
  String? selectedAction;
  bool isCustom = false;
  final List<String> estimasiOptions = [
    '2-3 hari',
    '5-7 hari',
    '7-10 hari',
  ];
  String? selectedEstimasi;
  final TextEditingController customActionController = TextEditingController();
  final TextEditingController detailController = TextEditingController();
  final TextEditingController qtyController = TextEditingController(text: '1');
  bool isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tindakan - ${widget.order.orderId}',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedAction,
              decoration: InputDecoration(
                labelText: 'Pilih Tindakan',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                ...standardActions.map(
                  (action) => DropdownMenuItem(
                    value: action,
                    child: Text(action),
                  ),
                ),
                const DropdownMenuItem(
                  value: 'custom',
                  child: Text('Custom'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedAction = value;
                  isCustom = value == 'custom';
                  if (!isCustom) {
                    customActionController.text = value ?? '';
                  } else {
                    customActionController.clear();
                  }
                });
              },
            ),
            if (isCustom) ...[
              const SizedBox(height: 12),
              TextField(
                controller: customActionController,
                decoration: InputDecoration(
                  labelText: 'Tindakan Custom',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: detailController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Keterangan Detail',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedEstimasi,
              decoration: InputDecoration(
                labelText: 'Estimasi',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: estimasiOptions
                  .map(
                    (estimasi) => DropdownMenuItem(
                      value: estimasi,
                      child: Text(estimasi),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => selectedEstimasi = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Jumlah Tindakan',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (selectedAction == null || selectedAction!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pilih tindakan terlebih dahulu'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final actionName = isCustom
                          ? customActionController.text.trim()
                          : selectedAction!;
                      final detail = detailController.text.trim();
                      final qty = int.tryParse(qtyController.text.trim()) ?? 1;

                      if (actionName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Isi nama tindakan'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() => isSaving = true);

                      try {
                        await ApiService.createTindakan({
                          'trans_kode': widget.order.orderId,
                          'kry_kode': widget.order.kryKode,
                          'nama_tindakan': actionName,
                          'keterangan': detail,
                          'jumlah': qty,
                        });

                        await ApiService.updateTransaksiStatus(
                          widget.order.orderId,
                          'Diproses',
                        );

                        if (!mounted) return;
                        widget.onSaved();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal simpan tindakan: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        if (mounted) {
                          setState(() => isSaving = false);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0041c3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Simpan',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
