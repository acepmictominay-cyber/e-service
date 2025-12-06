import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Import your existing files
import 'package:azza_service/Beli/shop.dart';
import 'package:azza_service/Home/Home.dart';
import 'package:azza_service/Others/session_manager.dart';
import 'package:azza_service/Promo/promo.dart';
import 'package:azza_service/Service/Service.dart';
import 'package:azza_service/Service/tracking_driver.dart';
import 'package:azza_service/api_services/api_service.dart';
import 'package:azza_service/api_services/payment_service.dart';

class RiwayatPage extends StatefulWidget {
  final bool shouldRefresh;

  const RiwayatPage({super.key, this.shouldRefresh = false});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage>
    with SingleTickerProviderStateMixin {
  // Helper method for adaptive colors (white in dark mode, blue in light mode)
  Color _getAdaptiveColor(Color lightColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : lightColor;
  }

  // Navigation
  int currentIndex = 4;

  // Tab Controller for Service/Purchase toggle
  late TabController _mainTabController;
  int _selectedMainTab = 0; // 0 = Service, 1 = Purchase

  // Selected status filter
  String? _selectedServiceStatus;
  String? _selectedPurchaseStatus;

  // Transaction data
  List<Map<String, dynamic>> serviceTransactions = [];
  List<Map<String, dynamic>> purchaseTransactions = [];

  bool isLoading = true;

  // Status definitions
  final List<String> serviceStatuses = [
    'pending',
    'approved',
    'in_progress',
    'on_the_way',
    'completed',
  ];
  final List<String> purchaseStatuses = [
    'pending',
    'paid',
    'diproses',
    'dikirim',
    'selesai',
    'pending_shipping_payment',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _mainTabController.addListener(() {
      if (!_mainTabController.indexIsChanging) {
        setState(() {
          _selectedMainTab = _mainTabController.index;
        });
      }
    });

    _loadTransactionHistory();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  // ============ DATA LOADING ============

  Future<void> _loadTransactionHistory() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final session = await SessionManager.getUserSession();
      final userCosKode = session['id']?.toString();
      if (userCosKode == null || userCosKode.isEmpty) {
        _setEmptyState();
        return;
      }

      // Fetch service transactions
      final serviceData = await ApiService.getOrderList();

      // Fetch purchase transactions
      final purchaseData = await ApiService.getCustomerOrders(userCosKode);

      if (!mounted) return;

      // Process service transactions
      final tempService = <Map<String, dynamic>>[];
      for (final transaksi in serviceData) {
        final transCosKode = transaksi['cos_kode']?.toString();
        if (transCosKode == userCosKode) {
          tempService.add(Map<String, dynamic>.from(transaksi));
        }
      }

      // Process purchase transactions
      final tempPurchase = <Map<String, dynamic>>[];
      for (final orderData in purchaseData) {
        final order = orderData['order'];
        if (order == null) continue;

        final orderCode = order['order_code']?.toString();
        if (orderCode == null || orderCode.isEmpty) continue;

        tempPurchase.add({
          'order_code': orderCode,
          'total_payment': order['total_payment'] ?? order['total_price'] ?? 0,
          'created_at': order['created_at'],
          'payment_status':
              order['payment_status']?.toString().toLowerCase() ?? 'pending',
          'delivery_status':
              order['delivery_status']?.toString().toLowerCase() ?? 'menunggu',
          'payment_method': order['payment_method'] ?? 'N/A',
          'expedition_type': order['expedition_type'] ?? 'N/A',
          'items': orderData['items'] ?? [],
        });
      }

      // Sort by date (newest first)
      tempService.sort(
        (a, b) => _compareDate(b['trans_tanggal'], a['trans_tanggal']),
      );
      tempPurchase.sort(
        (a, b) => _compareDate(b['created_at'], a['created_at']),
      );

      setState(() {
        serviceTransactions = tempService;
        purchaseTransactions = tempPurchase;
        isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Error loading transactions: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) _setEmptyState();
    }
  }

  void _setEmptyState() {
    setState(() {
      serviceTransactions = [];
      purchaseTransactions = [];
      isLoading = false;
    });
  }

  int _compareDate(String? a, String? b) {
    final dateA = DateTime.tryParse(a ?? '') ?? DateTime(1900);
    final dateB = DateTime.tryParse(b ?? '') ?? DateTime(1900);
    return dateA.compareTo(dateB);
  }

  // ============ HELPER METHODS ============

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatCurrency(dynamic amount) {
    try {
      final number = double.tryParse(amount?.toString() ?? '0') ?? 0;
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      return formatter.format(number);
    } catch (e) {
      return 'Rp 0';
    }
  }

  String _getStatusLabel(String status) {
    final labels = {
      'pending': 'Menunggu',
      'approved': 'Disetujui',
      'in_progress': 'Diproses',
      'on_the_way': 'Dalam Perjalanan',
      'completed': 'Selesai',
      'paid': 'Dibayar',
      'diproses': 'Diproses',
      'dikirim': 'Dikirim',
      'selesai': 'Selesai',
      'menunggu': 'Menunggu',
      'pending_shipping_payment': 'Menunggu Pembayaran Ongkir',
      'cancelled': 'Dibatalkan',
    };
    return labels[status.toLowerCase()] ?? status;
  }

  Color _getStatusColor(String status) {
    final colors = {
      'pending': Colors.orange,
      'approved': Colors.blue,
      'in_progress': Colors.indigo,
      'on_the_way': Colors.purple,
      'completed': Colors.green,
      'paid': Colors.green,
      'diproses': Colors.blue,
      'dikirim': Colors.purple,
      'selesai': Colors.green,
      'menunggu': Colors.orange,
      'pending_shipping_payment': Colors.orange,
      'cancelled': Colors.red,
    };
    return colors[status.toLowerCase()] ?? Colors.grey;
  }

  IconData _getStatusIcon(String status) {
    final icons = {
      'pending': Icons.hourglass_empty,
      'approved': Icons.thumb_up_outlined,
      'in_progress': Icons.engineering,
      'on_the_way': Icons.local_shipping,
      'completed': Icons.check_circle,
      'paid': Icons.payment,
      'diproses': Icons.inventory,
      'dikirim': Icons.local_shipping,
      'selesai': Icons.check_circle,
      'menunggu': Icons.hourglass_empty,
      'pending_shipping_payment': Icons.payment,
      'cancelled': Icons.cancel,
    };
    return icons[status.toLowerCase()] ?? Icons.help_outline;
  }

  // ============ COUNT METHODS ============

  int _getServiceCountByStatus(String status) {
    return serviceTransactions.where((t) {
      final transStatus = t['trans_status']?.toString().toLowerCase() ?? '';
      return transStatus == status.toLowerCase();
    }).length;
  }

  int _getPurchaseCountByStatus(String status) {
    return purchaseTransactions.where((t) {
      final paymentStatus = t['payment_status']?.toString().toLowerCase() ?? '';
      final deliveryStatus =
          t['delivery_status']?.toString().toLowerCase() ?? '';
      final paymentMethod = t['payment_method']?.toString().toLowerCase() ?? '';

      if (status == 'pending') {
        return paymentStatus == 'pending' &&
            paymentMethod != 'pending_shipping_payment';
      } else if (status == 'paid') {
        return paymentStatus == 'paid' && deliveryStatus != 'selesai';
      } else if (status == 'diproses') {
        return deliveryStatus == 'diproses';
      } else if (status == 'dikirim') {
        return deliveryStatus == 'dikirim';
      } else if (status == 'selesai') {
        return deliveryStatus == 'selesai';
      } else if (status == 'pending_shipping_payment') {
        return paymentMethod == 'pending_shipping_payment';
      } else if (status == 'cancelled') {
        return paymentStatus == 'cancelled' || deliveryStatus == 'cancelled';
      }
      return false;
    }).length;
  }

  List<Map<String, dynamic>> _getFilteredServiceTransactions() {
    if (_selectedServiceStatus == null) return [];
    return serviceTransactions.where((t) {
      final status = t['trans_status']?.toString().toLowerCase() ?? '';
      return status == _selectedServiceStatus!.toLowerCase();
    }).toList();
  }

  List<Map<String, dynamic>> _getFilteredPurchaseTransactions() {
    if (_selectedPurchaseStatus == null) return [];
    return purchaseTransactions.where((t) {
      final paymentStatus = t['payment_status']?.toString().toLowerCase() ?? '';
      final deliveryStatus =
          t['delivery_status']?.toString().toLowerCase() ?? '';
      final paymentMethod = t['payment_method']?.toString().toLowerCase() ?? '';

      if (_selectedPurchaseStatus == 'pending') {
        return paymentStatus == 'pending' &&
            paymentMethod != 'pending_shipping_payment';
      } else if (_selectedPurchaseStatus == 'paid') {
        return paymentStatus == 'paid' && deliveryStatus != 'selesai';
      } else if (_selectedPurchaseStatus == 'diproses') {
        return deliveryStatus == 'diproses';
      } else if (_selectedPurchaseStatus == 'dikirim') {
        return deliveryStatus == 'dikirim';
      } else if (_selectedPurchaseStatus == 'selesai') {
        return deliveryStatus == 'selesai';
      } else if (_selectedPurchaseStatus == 'pending_shipping_payment') {
        return paymentMethod == 'pending_shipping_payment';
      } else if (_selectedPurchaseStatus == 'cancelled') {
        return paymentStatus == 'cancelled' || deliveryStatus == 'cancelled';
      }
      return false;
    }).toList();
  }

  // ============ BUILD METHODS ============

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: isLoading ? _buildLoading() : _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      title: Text(
        'Riwayat Transaksi',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _getAdaptiveColor(Colors.white),
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            Icons.refresh,
            color: _getAdaptiveColor(Colors.white),
          ),
          onPressed: _loadTransactionHistory,
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Center(
      child: CircularProgressIndicator(
        color: _getAdaptiveColor(Color(0xFF0041c3)),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Custom Tab Bar dengan background yang kontras
        _buildCustomTabBar(),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _mainTabController,
            children: [_buildServiceTab(), _buildPurchaseTab()],
          ),
        ),
      ],
    );
  }

  // ============ CUSTOM TAB BAR ============

  Widget _buildCustomTabBar() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  // Service Tab
                  Expanded(
                    child: _buildTabItem(
                      index: 0,
                      icon: Icons.build_circle,
                      label: 'Service',
                      count: serviceTransactions.length,
                      isSelected: _selectedMainTab == 0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Purchase Tab
                  Expanded(
                    child: _buildTabItem(
                      index: 1,
                      icon: Icons.shopping_bag,
                      label: 'Pembelian',
                      count: purchaseTransactions.length,
                      isSelected: _selectedMainTab == 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required String label,
    required int count,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        _mainTabController.animateTo(index);
        setState(() {
          _selectedMainTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? _getAdaptiveColor(Color(0xFF0041c3))
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: _getAdaptiveColor(
                        Color(0xFF0041c3),
                      ).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color:
                  isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            // Count Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Theme.of(
                          context,
                        ).colorScheme.onPrimary.withOpacity(0.25)
                        : _getAdaptiveColor(
                          Color(0xFF0041c3),
                        ).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : _getAdaptiveColor(Color(0xFF0041c3)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ SERVICE TAB ============

  Widget _buildServiceTab() {
    if (serviceTransactions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.build_circle_outlined,
        title: 'Belum Ada Riwayat Service',
        subtitle: 'Transaksi service Anda akan muncul di sini',
      );
    }

    return Column(
      children: [
        // Status Grid
        _buildStatusGrid(isService: true),

        // Transaction List
        Expanded(
          child:
              _selectedServiceStatus == null
                  ? _buildSelectStatusHint()
                  : _buildServiceList(),
        ),
      ],
    );
  }

  Widget _buildServiceList() {
    final filtered = _getFilteredServiceTransactions();

    if (filtered.isEmpty) {
      return _buildEmptyState(
        icon: _getStatusIcon(_selectedServiceStatus!),
        title: 'Tidak Ada Pesanan',
        subtitle:
            'Tidak ada pesanan dengan status "${_getStatusLabel(_selectedServiceStatus!)}"',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransactionHistory,
      color: const Color(0xFF0041c3),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) => _buildServiceCard(filtered[index]),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> transaction) {
    final kode = transaction['trans_kode'] ?? '-';
    final status =
        transaction['trans_status']?.toString().toLowerCase() ?? 'pending';
    final tanggal = _formatDate(transaction['trans_tanggal']);
    final total = _formatCurrency(transaction['trans_total']);
    final keluhan = transaction['ket_keluhan'] ?? '-';

    final isTrackable = [
      'pending',
      'approved',
      'in_progress',
      'on_the_way',
    ].contains(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap:
              isTrackable
                  ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrackingPage(queueCode: kode),
                    ),
                  )
                  : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getAdaptiveColor(
                                Color(0xFF0041c3),
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.build,
                              size: 18,
                              color: _getAdaptiveColor(Color(0xFF0041c3)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '#$kode',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _getAdaptiveColor(Color(0xFF0041c3)),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(status),
                  ],
                ),

                const SizedBox(height: 14),

                // Divider
                Container(height: 1, color: Theme.of(context).dividerColor),

                const SizedBox(height: 14),

                // Info Row
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(Icons.calendar_today, tanggal),
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      color: Theme.of(context).dividerColor,
                    ),
                    Expanded(child: _buildInfoItem(Icons.payments, total)),
                  ],
                ),

                const SizedBox(height: 12),

                // Keluhan
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          keluhan,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tracking Button
                if (isTrackable) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getAdaptiveColor(Color(0xFF0041c3)),
                          _getAdaptiveColor(Color(0xFF0052E0)),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lacak Pesanan',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============ PURCHASE TAB ============

  Widget _buildPurchaseTab() {
    if (purchaseTransactions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'Belum Ada Riwayat Pembelian',
        subtitle: 'Transaksi pembelian Anda akan muncul di sini',
      );
    }

    return Column(
      children: [
        // Status Grid
        _buildStatusGrid(isService: false),

        // Transaction List
        Expanded(
          child:
              _selectedPurchaseStatus == null
                  ? _buildSelectStatusHint()
                  : _buildPurchaseList(),
        ),
      ],
    );
  }

  Widget _buildPurchaseList() {
    final filtered = _getFilteredPurchaseTransactions();

    if (filtered.isEmpty) {
      return _buildEmptyState(
        icon: _getStatusIcon(_selectedPurchaseStatus!),
        title: 'Tidak Ada Pesanan',
        subtitle:
            'Tidak ada pesanan dengan status "${_getStatusLabel(_selectedPurchaseStatus!)}"',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransactionHistory,
      color: _getAdaptiveColor(Color(0xFF0041c3)),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) => _buildPurchaseCard(filtered[index]),
      ),
    );
  }

  Widget _buildPurchaseCard(Map<String, dynamic> transaction) {
    final orderCode = transaction['order_code'] ?? '-';
    final paymentStatus = transaction['payment_status'] ?? 'pending';
    final deliveryStatus = transaction['delivery_status'] ?? 'menunggu';
    final tanggal = _formatDate(transaction['created_at']);
    final total = _formatCurrency(transaction['total_payment']);
    final items = transaction['items'] as List? ?? [];
    final paymentMethod = transaction['payment_method'] ?? 'N/A';
    final isPendingShippingPayment =
        paymentMethod.toLowerCase() == 'pending_shipping_payment';

    // Get product summary
    String productSummary = 'Tidak ada produk';
    if (items.isNotEmpty) {
      final firstItem = items[0];
      final name = firstItem['nama_produk'] ?? firstItem['name'] ?? 'Produk';
      final qty = firstItem['quantity'] ?? 1;
      if (items.length == 1) {
        productSummary = '$name (${qty}x)';
      } else {
        productSummary = '$name (${qty}x) +${items.length - 1} lainnya';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.shopping_bag,
                          size: 18,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '#$orderCode',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getAdaptiveColor(Color(0xFF0041c3)),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(
                  paymentStatus == 'cancelled'
                      ? 'cancelled'
                      : deliveryStatus == 'cancelled'
                      ? 'cancelled'
                      : isPendingShippingPayment
                      ? 'pending_shipping_payment'
                      : deliveryStatus,
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Divider
            Container(height: 1, color: Theme.of(context).dividerColor),

            const SizedBox(height: 14),

            // Product Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getAdaptiveColor(Color(0xFF0041c3)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _getAdaptiveColor(Color(0xFF0041c3)).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 18,
                    color: _getAdaptiveColor(Color(0xFF0041c3)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      productSummary,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Info Row
            Row(
              children: [
                Expanded(child: _buildInfoItem(Icons.calendar_today, tanggal)),
                Container(
                  width: 1,
                  height: 20,
                  color: Theme.of(context).dividerColor,
                ),
                Expanded(child: _buildInfoItem(Icons.payments, total)),
              ],
            ),

            const SizedBox(height: 14),

            // Status Row
            Row(
              children: [
                Expanded(
                  child: _buildMiniStatus(
                    icon: Icons.payment,
                    label: 'Pembayaran',
                    status: paymentStatus,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMiniStatus(
                    icon: Icons.local_shipping,
                    label: 'Pengiriman',
                    status: deliveryStatus,
                  ),
                ),
              ],
            ),

            // Resume Payment Button for pending shipping payments
            if (isPendingShippingPayment) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0041c3),
                      const Color(0xFF0052E0),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
                  onPressed: () => _resumeShippingPayment(context, transaction),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.payment,
                        size: 18,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Lanjutkan Pembayaran Ongkir',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Cancel Order Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.5),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextButton(
                  onPressed: () => _cancelOrder(context, transaction),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cancel,
                        size: 18,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Batalkan Pesanan',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============ REUSABLE WIDGETS ============

  Widget _buildStatusGrid({required bool isService}) {
    final statuses = isService ? serviceStatuses : purchaseStatuses;
    final selectedStatus =
        isService ? _selectedServiceStatus : _selectedPurchaseStatus;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _getAdaptiveColor(
                      Color(0xFF0041c3),
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.filter_list,
                    size: 16,
                    color: _getAdaptiveColor(Color(0xFF0041c3)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Filter Status',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (selectedStatus != null) ...[
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isService) {
                          _selectedServiceStatus = null;
                        } else {
                          _selectedPurchaseStatus = null;
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.error.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.close,
                            size: 14,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Reset',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              children:
                  statuses.asMap().entries.map((entry) {
                    final index = entry.key;
                    final status = entry.value;
                    final count =
                        isService
                            ? _getServiceCountByStatus(status)
                            : _getPurchaseCountByStatus(status);
                    final isSelected = selectedStatus == status;

                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < statuses.length - 1 ? 10 : 0,
                      ),
                      child: _buildStatusFilterChip(
                        status: status,
                        count: count,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            if (isService) {
                              _selectedServiceStatus =
                                  isSelected ? null : status;
                            } else {
                              _selectedPurchaseStatus =
                                  isSelected ? null : status;
                            }
                          });
                        },
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip({
    required String status,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = _getStatusColor(status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : Theme.of(context).colorScheme.outline,
              width: isSelected ? 2 : 1,
            ),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? Colors.white.withOpacity(0.2)
                          : color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(status),
                  size: 20,
                  color: isSelected ? Colors.white : color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                count.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : color,
                ),
              ),
              Text(
                _getStatusLabel(status),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color:
                      isSelected
                          ? Theme.of(
                            context,
                          ).colorScheme.onPrimary.withOpacity(0.9)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(status), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            _getStatusLabel(status),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatus({
    required IconData icon,
    required String label,
    required String status,
  }) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _getStatusLabel(status),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectStatusHint() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _getAdaptiveColor(Color(0xFF0041c3)).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.touch_app,
                size: 48,
                color: _getAdaptiveColor(Color(0xFF0041c3)).withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Pilih Status',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap salah satu status di atas\nuntuk melihat daftar pesanan',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 52,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============ RESUME PAYMENT ============

  void _resumeShippingPayment(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) async {
    final orderCode = transaction['order_code'] ?? '';
    final totalPayment = transaction['total_payment'] ?? 0;

    if (orderCode.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Order code tidak valid')));
      return;
    }

    try {
      // Get customer ID from session (since orders are already filtered by logged-in user)
      final session = await SessionManager.getUserSession();
      final customerId = session['id']?.toString();

      if (customerId == null || customerId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session user tidak ditemukan')),
        );
        return;
      }

      // Get customer data for payment
      final customerData = await ApiService.getCostomerById(customerId);
      final customerName = customerData['cos_nama'] ?? 'Customer';
      final customerEmail = 'test@example.com'; // Use fixed email for testing
      final customerPhone = customerData['cos_hp'] ?? '08123456789';

      // Start Midtrans payment directly
      await PaymentService.startMidtransPayment(
        context: context,
        orderId: orderCode,
        amount: totalPayment.toInt(),
        customerId: customerId,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        itemDetails: [
          {
            'id': 'SHIPPING_RESUME',
            'price': totalPayment.toInt(),
            'quantity': 1,
            'name': 'Pembayaran Ongkir (Resume)',
          },
        ],
        onTransactionFinished: (result) async {
          if (PaymentService.isTransactionSuccess(result)) {
            // Update payment status
            await ApiService.updatePaymentStatus(
              orderCode: orderCode,
              paymentStatus: 'paid',
            );

            // Navigate back to refresh the list
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            _loadTransactionHistory();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pembayaran ongkir berhasil!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Pembayaran gagal: ${PaymentService.getStatusMessage(result)}',
                ),
              ),
            );
          }
        },
      );
    } catch (e, stackTrace) {
      debugPrint('Error resuming shipping payment: $e');
      debugPrint('Stack trace: $stackTrace');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ============ CANCEL ORDER ============

  void _cancelOrder(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) async {
    final orderCode = transaction['order_code'] ?? '';

    if (orderCode.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Order code tidak valid')));
      return;
    }

    // Show confirmation dialog
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Batalkan Pesanan'),
            content: const Text(
              'Apakah Anda yakin ingin membatalkan pesanan ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Tidak'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Ya, Batalkan'),
              ),
            ],
          ),
    );

    if (shouldCancel != true) return;

    try {
      // Update payment status to cancelled
      await ApiService.updatePaymentStatus(
        orderCode: orderCode,
        paymentStatus: 'cancelled',
      );

      // Update delivery status to cancelled as well
      await ApiService.updateDeliveryStatus(
        orderCode: orderCode,
        deliveryStatus: 'cancelled',
      );

      // Refresh the list
      _loadTransactionHistory();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan berhasil dibatalkan')),
      );
    } catch (e, stackTrace) {
      debugPrint('Error cancelling order: $e');
      debugPrint('Stack trace: $stackTrace');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membatalkan pesanan: $e')));
    }
  }

  // ============ BOTTOM NAVIGATION ============

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == currentIndex) {
            _loadTransactionHistory();
            return;
          }

          Widget? page;
          switch (index) {
            case 0:
              page = const ServicePage();
              break;
            case 1:
              page = const MarketplacePage();
              break;
            case 2:
              page = const HomePage();
              break;
            case 3:
              page = const TukarPoinPage();
              break;
            case 4:
              return;
          }

          if (page != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => page!),
            );
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.build_circle_outlined),
            label: 'Service',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Beli',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon:
                currentIndex == 3
                    ? Image.asset(
                      'assets/image/promo.png',
                      width: 24,
                      height: 24,
                    )
                    : Opacity(
                      opacity: 0.6,
                      child: Image.asset(
                        'assets/image/promo.png',
                        width: 24,
                        height: 24,
                      ),
                    ),
            label: 'Promo',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
        ],
      ),
    );
  }
}
