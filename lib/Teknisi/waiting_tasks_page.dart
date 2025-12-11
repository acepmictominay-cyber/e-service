import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:azza_service/models/technician_order_model.dart';
import 'package:azza_service/api_services/api_service.dart';
import 'package:azza_service/Others/session_manager.dart';

class WaitingTasksPage extends StatefulWidget {
  final bool isAutoRefreshEnabled;

  const WaitingTasksPage({
    super.key,
    this.isAutoRefreshEnabled = true,
  });

  @override
  State<WaitingTasksPage> createState() => _WaitingTasksPageState();
}

class _WaitingTasksPageState extends State<WaitingTasksPage> {
  List<TechnicianOrder> _waitingOrders = [];
  bool _isLoadingOrders = false;

  @override
  void initState() {
    super.initState();
    _fetchWaitingOrders();
  }

  Future<void> _fetchWaitingOrders() async {
    setState(() => _isLoadingOrders = true);

    try {
      final kryKode = await SessionManager.getkry_kode();
      if (kryKode == null) {
        if (mounted) setState(() => _waitingOrders = []);
        return;
      }

      final allOrdersRaw = await ApiService.getOrderListByKryKode(kryKode);
      final allOrders = allOrdersRaw.map((item) => TechnicianOrder.fromMap(item as Map<String, dynamic>)).toList();
      final fetchedWaitingOrders = allOrders
          .where((order) => order.status == OrderStatus.waitingOrder)
          .toList();

      if (mounted) setState(() => _waitingOrders = fetchedWaitingOrders);
    } catch (e) {
      if (mounted) setState(() => _waitingOrders = []);
    } finally {
      if (mounted) setState(() => _isLoadingOrders = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchWaitingOrders,
        child: Column(
          children: [
            // Header Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade600, Colors.orange.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.inbox,
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
                              'Waiting Task Pool',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Order yang menunggu untuk diambil',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_waitingOrders.length}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.isAutoRefreshEnabled) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.sync,
                          size: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Auto-refresh aktif',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Filter Chips
            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            //   child: SingleChildScrollView(
            //     scrollDirection: Axis.horizontal,
            //     child: Row(
            //       children: [
            //         _buildFilterChip('Semua', true, _waitingOrders.length),
            //         const SizedBox(width: 8),
            //         _buildFilterChip('Hari Ini', false, _getTodayCount(_waitingOrders)),
            //         const SizedBox(width: 8),
            //         _buildFilterChip('Kemarin', false, _getYesterdayCount(_waitingOrders)),
            //         const SizedBox(width: 8),
            //         _buildFilterChip('Minggu Ini', false, _getThisWeekCount(_waitingOrders)),
            //       ],
            //     ),
            //   ),
            // ),

            // List of Waiting Orders
            Expanded(
              child: _isLoadingOrders
                  ? const Center(child: CircularProgressIndicator())
                  : _waitingOrders.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _waitingOrders.length,
                          itemBuilder: (context, index) {
                            final order = _waitingOrders[index];
                            return _buildWaitingOrderCard(context, order);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildFilterChip(String label, bool isSelected, int count) {
  //   return FilterChip(
  //     label: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Flexible(
  //           child: Text(
  //             label,
  //             overflow: TextOverflow.ellipsis,
  //             maxLines: 1,
  //           ),
  //         ),
  //         if (count > 0) ...[
  //           const SizedBox(width: 4),
  //           Container(
  //             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
  //             decoration: BoxDecoration(
  //               color: isSelected ? Colors.white : Colors.orange.shade100,
  //               borderRadius: BorderRadius.circular(10),
  //             ),
  //             child: Text(
  //               '$count',
  //               style: GoogleFonts.poppins(
  //                 fontSize: 11,
  //                 fontWeight: FontWeight.bold,
  //                 color: isSelected ? Colors.orange : Colors.orange.shade700,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ],
  //     ),
  //     selected: isSelected,
  //     onSelected: (bool value) {
  //       // Handle filter logic
  //     },
  //     selectedColor: Colors.orange.shade500,
  //     backgroundColor: Colors.grey.shade200,
  //     labelStyle: GoogleFonts.poppins(
  //       color: isSelected ? Colors.white : Colors.grey.shade700,
  //       fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
  //     ),
  //   );
  // }


  Widget _buildWaitingOrderCard(BuildContext context, TechnicianOrder order) {
    final daysSinceCreated = order.createdAt != null
        ? DateTime.now().difference(order.createdAt!).inDays
        : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showOrderDetails(context, order),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Order ID and Time Badge
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
                        if (order.createdAt != null)
                          Text(
                            _formatDateTime(order.createdAt!),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Priority/Time indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(daysSinceCreated).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getPriorityColor(daysSinceCreated),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getPriorityIcon(daysSinceCreated),
                          size: 14,
                          color: _getPriorityColor(daysSinceCreated),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getPriorityLabel(daysSinceCreated),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: _getPriorityColor(daysSinceCreated),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 20),

              // Customer Info
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.customerName,
                      style: GoogleFonts.poppins(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Customer Phone
              if (order.customerPhone != null) ...[
                Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.customerPhone!,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],

              // Address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.customerAddress,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Device Info
              if (order.deviceType != null || order.deviceBrand != null) ...[
                Row(
                  children: [
                    Icon(Icons.devices_outlined, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${order.deviceBrand ?? ''} ${order.deviceType ?? ''}'.trim(),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],

              // Device Serial
              // if (order.deviceSerial != null) ...[
              //   Row(
              //     children: [
              //       Icon(Icons.tag_outlined, size: 16, color: Colors.grey.shade600),
              //       const SizedBox(width: 8),
              //       Expanded(
              //         child: Text(
              //           'SN: ${order.deviceSerial}',
              //           style: GoogleFonts.poppins(
              //             fontSize: 13,
              //             color: Colors.grey.shade700,
              //           ),
              //           overflow: TextOverflow.ellipsis,
              //         ),
              //       ),
              //     ],
              //   ),
              //   const SizedBox(height: 6),
              // ],

              // // Warranty Status
              // if (order.warrantyStatus != null) ...[
              //   Row(
              //     children: [
              //       Icon(Icons.verified_outlined, size: 16, color: Colors.grey.shade600),
              //       const SizedBox(width: 8),
              //       Expanded(
              //         child: Text(
              //           'Garansi: ${order.warrantyStatus}',
              //           style: GoogleFonts.poppins(
              //             fontSize: 13,
              //             color: Colors.grey.shade700,
              //           ),
              //           overflow: TextOverflow.ellipsis,
              //         ),
              //       ),
              //     ],
              //   ),
              //   const SizedBox(height: 6),
              // ],

              // // Estimated Price
              // if (order.estimatedPrice != null) ...[
              //   Row(
              //     children: [
              //       Icon(Icons.attach_money_outlined, size: 16, color: Colors.grey.shade600),
              //       const SizedBox(width: 8),
              //       Expanded(
              //         child: Text(
              //           'Total: Rp ${order.estimatedPrice!.toStringAsFixed(0)}',
              //           style: GoogleFonts.poppins(
              //             fontSize: 13,
              //             color: Colors.grey.shade700,
              //             fontWeight: FontWeight.w500,
              //           ),
              //           overflow: TextOverflow.ellipsis,
              //         ),
              //       ),
              //     ],
              //   ),
              // ],

            ],
          ),
        ),
      ),
    );
  }


  void _showOrderDetails(BuildContext context, TechnicianOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Header
                Text(
                  'Detail Order',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.orderId,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                
                const Divider(height: 24),
                
                // Customer Section
                _buildDetailSection(
                  'Informasi Customer',
                  [
                    _buildDetailRow('Nama', order.customerName),
                    _buildDetailRow('Alamat', order.customerAddress),
                    if (order.customerPhone != null)
                      _buildDetailRow('Telepon', order.customerPhone!),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Device Section
                _buildDetailSection(
                  'Informasi Perangkat',
                  [
                    if (order.deviceBrand != null)
                      _buildDetailRow('Merek', order.deviceBrand!),
                    if (order.deviceType != null)
                      _buildDetailRow('Tipe', order.deviceType!),
                    if (order.deviceSerial != null)
                      _buildDetailRow('Serial Number', order.deviceSerial!),
                    if (order.warrantyStatus != null)
                      _buildDetailRow('Garansi', order.warrantyStatus!),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Price Section
                if (order.estimatedPrice != null)
                  _buildDetailSection(
                    'Total Biaya',
                    [
                      _buildDetailRow(
                        'Total',
                        'Rp ${order.estimatedPrice!.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                
                const SizedBox(height: 24),

                // Close Button
                Center(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Tutup'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(int days) {
    if (days == 0) return Colors.green;
    if (days == 1) return Colors.orange;
    return Colors.red;
  }

  IconData _getPriorityIcon(int days) {
    if (days == 0) return Icons.schedule;
    if (days == 1) return Icons.warning_amber;
    return Icons.priority_high;
  }

  String _getPriorityLabel(int days) {
    if (days == 0) return 'Hari Ini';
    if (days == 1) return 'Kemarin';
    return '$days hari';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else {
      return '${difference.inDays} hari yang lalu';
    }
  }

  int _getTodayCount(List<TechnicianOrder> orders) {
    final now = DateTime.now();
    return orders.where((order) {
      if (order.createdAt == null) return false;
      return order.createdAt!.day == now.day &&
          order.createdAt!.month == now.month &&
          order.createdAt!.year == now.year;
    }).length;
  }

  int _getYesterdayCount(List<TechnicianOrder> orders) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return orders.where((order) {
      if (order.createdAt == null) return false;
      return order.createdAt!.day == yesterday.day &&
          order.createdAt!.month == yesterday.month &&
          order.createdAt!.year == yesterday.year;
    }).length;
  }

  int _getThisWeekCount(List<TechnicianOrder> orders) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return orders.where((order) {
      if (order.createdAt == null) return false;
      return order.createdAt!.isAfter(startOfWeek);
    }).length;
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
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
                'Tidak Ada Waiting Task',
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
        ),
      ),
    );
  }
}
