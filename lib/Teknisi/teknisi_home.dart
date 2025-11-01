import 'dart:async';
import 'dart:io';
import 'package:e_service/Others/new_order_notification_service.dart';
import 'package:e_service/Others/notifikasi.dart';
import 'package:e_service/Others/session_manager.dart';
import 'package:e_service/api_services/api_service.dart';
import 'package:e_service/models/technician_order_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'teknisi_profil.dart';
import 'tasks_tab.dart';
import 'tracking_tab.dart';
import 'chat_tab.dart';
import 'history_tab.dart';

class TeknisiHomePage extends StatefulWidget {
  const TeknisiHomePage({super.key});

  @override
  State<TeknisiHomePage> createState() => _TeknisiHomePageState();
}

class _TeknisiHomePageState extends State<TeknisiHomePage>
    with WidgetsBindingObserver {
  int currentIndex = 0;
  List<TechnicianOrder> assignedOrders = [];
  List<dynamic> transaksiList = [];
  bool isLoading = true;

  // ========== AUTO-REFRESH VARIABLES ==========
  Timer? _refreshTimer;
  Set<String> _previousOrderIds = {};
  bool _isAutoRefreshEnabled = true;
  static const int refreshIntervalSeconds =
      30; // ✅ Ubah ke 30 detik (lebih hemat)
  // ============================================

  Future<void> _initializePreviousOrderIds() async {
    final prefs = await SharedPreferences.getInstance();
    final storedIds = prefs.getStringList('previous_order_ids') ?? [];
    setState(() {
      _previousOrderIds = storedIds.toSet();
    });
  }

  Future<void> _savePreviousOrderIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('previous_order_ids', _previousOrderIds.toList());
  }

  final TextEditingController damageDescriptionController =
      TextEditingController();
  final TextEditingController estimatedPriceController =
      TextEditingController();
  List<XFile> selectedMedia = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshData();
    _startAutoRefresh();
    _initializePreviousOrderIds();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAutoRefresh();
    damageDescriptionController.dispose();
    estimatedPriceController.dispose();
    super.dispose();
  }

  // Deteksi app lifecycle (pause ketika app di background)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App kembali aktif, resume auto-refresh
      if (_isAutoRefreshEnabled && _refreshTimer == null) {
        _startAutoRefresh();
        _refreshDataWithNewOrderDetection();
      }
    } else if (state == AppLifecycleState.paused) {
      // App di background, stop timer untuk hemat resource
      _stopAutoRefresh();
      // Background check akan tetap berjalan via WorkManager
    }
  }

  // ========== AUTO-REFRESH METHODS ==========

  void _startAutoRefresh() {
    _stopAutoRefresh(); // Pastikan tidak ada timer duplikat
    _refreshTimer = Timer.periodic(
      const Duration(seconds: refreshIntervalSeconds),
      (timer) {
        if (mounted && _isAutoRefreshEnabled) {
          _refreshDataWithNewOrderDetection();
        }
      },
    );
    print('🔄 Auto-refresh started (interval: ${refreshIntervalSeconds}s)');
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    print('⏸️ Auto-refresh stopped');
  }

  void _toggleAutoRefresh() {
    setState(() {
      _isAutoRefreshEnabled = !_isAutoRefreshEnabled;
      if (_isAutoRefreshEnabled) {
        _startAutoRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Auto-refresh diaktifkan'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        _stopAutoRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Auto-refresh dinonaktifkan'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Future<void> _refreshDataWithNewOrderDetection() async {
    if (!mounted) return;

    try {
      final technicianId = await SessionManager.getkry_kode();
      if (technicianId != null) {
        final fetchedOrders = await ApiService.getkry_kode(technicianId);

        if (mounted) {
          // Deteksi pesanan baru
          final newOrderIds = fetchedOrders.map((o) => o.orderId).toSet();
          final newOrders = newOrderIds.difference(_previousOrderIds);

          // Jika ada pesanan baru dan bukan load pertama kali
          if (newOrders.isNotEmpty && _previousOrderIds.isNotEmpty) {
            // ✅ Hanya tampilkan notifikasi IN-APP (SnackBar + Dialog)
            // Background notification sudah dihandle oleh WorkManager
            _showInAppNotification(newOrders.length, newOrders.toList());

            // Vibrate untuk alert
            HapticFeedback.vibrate();

            // Also send push notification for new orders
            await NewOrderNotificationService.sendNewOrderNotification(
              newOrders.length,
              newOrders.toList(),
            );
          }

          setState(() {
            assignedOrders = fetchedOrders;
            _previousOrderIds = newOrderIds;
          });

          // Simpan ke SharedPreferences
          await _savePreviousOrderIds();
        }
      } else {
        if (mounted) setState(() => assignedOrders = []);
      }
    } catch (e) {
      print("Error fetching orders in auto-refresh: $e");
      // Tidak tampilkan error di auto-refresh untuk menghindari spam
    }

    try {
      final fetchedTransaksi = await ApiService.getTransaksi();
      if (mounted) setState(() => transaksiList = fetchedTransaksi);
    } catch (e) {
      print("Error fetching transaksi in auto-refresh: $e");
    }
  }

  // ✅ Notifikasi IN-APP saja (tidak kirim push notification)
  void _showInAppNotification(int count, List<String> orderIds) {
    // Tampilkan SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '🎉 Ada $count pesanan baru!',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Lihat',
          textColor: Colors.white,
          onPressed: () {
            setState(() => currentIndex = 0); // Pindah ke Tasks tab
          },
        ),
      ),
    );

    // Optional: Tampilkan dialog jika ingin lebih mencolok
    if (currentIndex != 0) {
      // Hanya show dialog jika user tidak di tab Tasks
      _showNewOrderDialog(count);
    }
  }

  void _showNewOrderDialog(int count) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.assignment_turned_in,
                    color: Colors.green.shade700,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pesanan Baru!',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'Anda mendapat $count pesanan baru. Segera cek dan terima pesanan!',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Nanti',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => currentIndex = 0); // Pindah ke Tasks tab
                },
                icon: const Icon(Icons.visibility),
                label: const Text('Lihat Sekarang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // ==========================================

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final technicianId = await SessionManager.getkry_kode();
      if (technicianId != null) {
        final fetchedOrders = await ApiService.getkry_kode(technicianId);
        if (mounted) {
          setState(() {
            assignedOrders = fetchedOrders;
            // Update previous order IDs untuk deteksi pesanan baru
            _previousOrderIds = fetchedOrders.map((o) => o.orderId).toSet();
          });

          // Simpan ke SharedPreferences
          await _savePreviousOrderIds();
        }
      } else {
        if (mounted) setState(() => assignedOrders = []);
      }
    } catch (e) {
      print("Error fetching orders: $e");
      if (mounted) {
        setState(() => assignedOrders = []);
      }
    }

    try {
      final fetchedTransaksi = await ApiService.getTransaksi();
      if (mounted) setState(() => transaksiList = fetchedTransaksi);
    } catch (e) {
      print("Error fetching transaksi: $e");
      if (mounted) {
        setState(() => transaksiList = []);
      }
    }

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _updateOrderStatus(
    TechnicianOrder order,
    OrderStatus newStatus,
  ) async {
    print(
      '>>> Tombol ditekan. Memperbarui status dari [${order.status.name}] ke [${newStatus.name}]',
    );

    if (!_isValidStatusTransition(order.status, newStatus)) {
      print('!!! Transisi status TIDAK VALID. Aksi dibatalkan.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transisi status tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final oldStatus = order.status;
    final int orderIndex = assignedOrders.indexWhere(
      (o) => o.orderId == order.orderId,
    );

    if (orderIndex == -1) {
      print(
        '!!! FATAL: Order dengan ID ${order.orderId} tidak ditemukan dalam list state.',
      );
      return;
    }

    setState(() {
      assignedOrders[orderIndex] = order.copyWith(status: newStatus);
      print(
        '>>> setState dipanggil. Status order ${order.orderId} di state sekarang adalah: [${assignedOrders[orderIndex].status.name}]',
      );
    });

    try {
      await ApiService.updateTransaksiStatus(order.orderId, newStatus.name);
      print(
        '>>> API call berhasil. Status [${newStatus.name}] tersimpan di server.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status berhasil diperbarui ke ${newStatus.displayName}',
          ),
          backgroundColor: Colors.green,
        ),
      );
      // Refresh data agar pesanan yang selesai muncul di history_tab
      await _refreshData();
    } catch (e) {
      print('!!! API call GAGAL: $e. Mengembalikan status ke [$oldStatus].');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        assignedOrders[orderIndex] = order.copyWith(status: oldStatus);
      });
    }
  }

  bool _isValidStatusTransition(OrderStatus current, OrderStatus next) {
    switch (current) {
      case OrderStatus.waiting:
        return next == OrderStatus.accepted;
      case OrderStatus.accepted:
        return next == OrderStatus.enRoute;
      case OrderStatus.enRoute:
        return next == OrderStatus.arrived;
      case OrderStatus.arrived:
        return next == OrderStatus.completed ||
            next == OrderStatus.waitingApproval;
      case OrderStatus.waitingApproval:
        return next == OrderStatus.pickingParts;
      case OrderStatus.pickingParts:
        return next == OrderStatus.repairing;
      case OrderStatus.repairing:
        return next == OrderStatus.completed;
      default:
        return false;
    }
  }

  Future<void> _openMaps(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka maps')));
    }
  }

  void _showDamageForm(TechnicianOrder order) {
    damageDescriptionController.clear();
    estimatedPriceController.clear();
    selectedMedia.clear();

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
                          'Temuan Kerusakan - ${order.orderId}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: damageDescriptionController,
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
                          controller: estimatedPriceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
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
                                final pickedFiles =
                                    await picker.pickMultiImage();
                                setModalState(
                                  () => selectedMedia.addAll(pickedFiles),
                                );
                              },
                              icon: const Icon(Icons.photo_camera),
                              label: const Text('Upload Media'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${selectedMedia.length} file dipilih',
                              ),
                            ),
                          ],
                        ),
                        if (selectedMedia.isNotEmpty)
                          Container(
                            height: 100,
                            margin: const EdgeInsets.only(top: 8),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: selectedMedia.length,
                              itemBuilder:
                                  (context, index) => Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Image.file(
                                      File(selectedMedia[index].path),
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
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Batal'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await _saveDamageAndUpdateStatus(order);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Simpan'),
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

  Future<void> _saveDamageAndUpdateStatus(TechnicianOrder order) async {
    final desc = damageDescriptionController.text.trim();
    final estStr = estimatedPriceController.text.trim().replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final est = num.tryParse(estStr);

    if (desc.isEmpty || est == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi deskripsi dan estimasi harga dengan benar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updatedOrderWithDamage = order.copyWith(
      damageDescription: desc,
      estimatedPrice: (est is num) ? est.toDouble() : null,
      damagePhotos: selectedMedia.map((f) => f.path).toList(),
    );

    final int orderIndex = assignedOrders.indexWhere(
      (o) => o.orderId == order.orderId,
    );
    if (orderIndex != -1) {
      setState(() {
        assignedOrders[orderIndex] = updatedOrderWithDamage;
      });
    }

    try {
      await ApiService.updateTransaksiTemuan(order.orderId, desc, est);
      await _updateOrderStatus(
        updatedOrderWithDamage,
        OrderStatus.waitingApproval,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal simpan temuan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateTransaksiStatus(
    dynamic transaksi,
    String newStatus,
  ) async {
    final String transKode = transaksi['trans_kode'];
    final int index = transaksiList.indexWhere(
      (t) => t['trans_kode'] == transKode,
    );
    if (index == -1) return;

    final oldStatus = transaksiList[index]['trans_status'];
    setState(() => transaksiList[index]['trans_status'] = newStatus);

    try {
      await ApiService.updateTransaksiStatus(transKode, newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status transaksi diperbarui ke $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal update status transaksi: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => transaksiList[index]['trans_status'] = oldStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeOrders =
        assignedOrders
            .where((order) => order.status != OrderStatus.completed)
            .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        title: Text(
          'Dashboard Teknisi',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Debug Button
          IconButton(
            icon: Icon(Icons.bug_report, color: Colors.white),
            onPressed: () async {
              final kryKode = await SessionManager.getkry_kode();
              final session = await SessionManager.getUserSession();

              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text('🐛 Debug Info'),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'kry_kode: ${kryKode ?? "NULL"}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    kryKode != null ? Colors.green : Colors.red,
                              ),
                            ),
                            Divider(),
                            Text('Role: ${session['role'] ?? "NULL"}'),
                            Text('Name: ${session['name'] ?? "NULL"}'),
                            Text('ID: ${session['id'] ?? "NULL"}'),
                            Divider(),
                            Text('Orders: ${assignedOrders.length}'),
                            Text(
                              'Active: ${assignedOrders.where((o) => o.status != OrderStatus.completed).length}',
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await NewOrderNotificationService.testNotification();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Test notification sent!'),
                              ),
                            );
                          },
                          child: Text('Test Notif'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _refreshData();
                          },
                          child: Text('Refresh'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Close'),
                        ),
                      ],
                    ),
              );
            },
            tooltip: 'Debug',
          ),
          // Toggle Auto-Refresh Button
          IconButton(
            icon: Icon(
              _isAutoRefreshEnabled ? Icons.sync : Icons.sync_disabled,
              color: Colors.white,
            ),
            onPressed: _toggleAutoRefresh,
            tooltip:
                _isAutoRefreshEnabled
                    ? 'Nonaktifkan Auto-Refresh'
                    : 'Aktifkan Auto-Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationPage(),
                  ),
                ),
          ),
        ],
      ),
      body: IndexedStack(
        index: currentIndex,
        children: [
          TasksTab(
            assignedOrders: activeOrders,
            isLoading: isLoading,
            onRefresh: _refreshData,
            onUpdateStatus: _updateOrderStatus,
            onShowDamageForm: _showDamageForm,
            onOpenMaps: _openMaps,
            isAutoRefreshEnabled: _isAutoRefreshEnabled,
          ),
          TrackingTab(
            customerAddress:
                activeOrders.isNotEmpty
                    ? activeOrders.first.customerAddress
                    : '',
          ),
          const ChatTab(),
          HistoryTab(
            transaksiList: transaksiList,
            isLoading: isLoading,
            onRefresh: _refreshData,
            onUpdateTransaksiStatus: _updateTransaksiStatus,
          ),
          const TeknisiProfilPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        backgroundColor: const Color(0xFF1976D2),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: [
          BottomNavigationBarItem(
            icon: Badge(
              label: Text(activeOrders.length.toString()),
              child: const Icon(Icons.assignment),
            ),
            label: 'Tugas',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.navigation),
            label: 'Pelacakan',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Obrolan',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
