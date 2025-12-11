import 'package:azza_service/Beli/shop.dart';
import 'package:azza_service/Chat/chat_page.dart';
import 'package:azza_service/Home/home.dart';
import 'package:azza_service/Others/custom_dialog.dart';
import 'package:azza_service/Others/notifikasi.dart';
import 'package:azza_service/Others/session_manager.dart';
import 'package:azza_service/Profile/profile.dart';
import 'package:azza_service/Promo/promo.dart';
import 'package:azza_service/Service/perbaikan_service.dart';
import 'package:azza_service/Service/waiting_approval.dart';
import 'package:azza_service/api_services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tracking_driver.dart';

class ServicePage extends StatefulWidget {
  const ServicePage({super.key});

  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  int currentIndex = 0; // Tab aktif: Service
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _handleSearch(String kode) async {
    if (kode.isEmpty) {
      CustomDialog.show(
        context: context,
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.warning, color: Colors.orange, size: 24),
        ),
        title: 'Peringatan',
        content: const Text('Masukkan kode transaksi terlebih dahulu'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
      return;
    }

    try {
      // Get current user ID
      final userSession = await SessionManager.getUserSession();
      final currentUserId = userSession['id'] as String?;

      if (currentUserId == null) {
        CustomDialog.show(
          context: context,
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error, color: Colors.red, size: 24),
          ),
          title: 'Error',
          content: const Text('Sesi login tidak valid'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
        return;
      }


      // Get all orders to search by cos_kode or trans_kode
      final allOrders = await ApiService.getOrderList();

      dynamic order;

      // First, try to find by cos_kode where trans_status is one of the allowed statuses
      final allowedStatuses = [
        'itemsubmitted',
        'waitingapproval',
        'waitingorder',
        'repairing',
        'completed',
      ];
      final cosKodeOrder = allOrders.firstWhere(
        (o) =>
            o['cos_kode']?.toString() == kode &&
            allowedStatuses.contains(
              o['trans_status']?.toString().toLowerCase(),
            ),
        orElse: () => null,
      );

      if (cosKodeOrder != null) {
        order = cosKodeOrder;
      } else {
        // If not found, search by trans_kode
        final transKodeOrders = allOrders
            .where((o) => o['trans_kode']?.toString() == kode)
            .toList();
        if (transKodeOrders.isNotEmpty) {
          order = transKodeOrders.first;
        } else {
          // If still not found, try to search in transaksi table for pickup orders
          try {
            final transaksiData = await ApiService.getTransaksiByKode(kode);
            if (transaksiData.isNotEmpty &&
                transaksiData['cos_kode'] == currentUserId) {
              // Create a mock order object for pickup
              order = {
                'cos_kode': transaksiData['cos_kode'],
                'trans_status':
                    transaksiData['trans_status']?.toString().toLowerCase() ??
                        'waiting',
                'trans_kode': kode,
              };
            } else {
              if (mounted) {
                CustomDialog.show(
                  context: context,
                  icon: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.error, color: Colors.red, size: 24),
                  ),
                  title: 'Error',
                  content: const Text('Transaksi tidak ditemukan'),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                );
              }
              return;
            }
          } catch (e) {
            if (mounted) {
              CustomDialog.show(
                context: context,
                icon: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error, color: Colors.red, size: 24),
                ),
                title: 'Error',
                content: const Text('Transaksi tidak ditemukan'),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              );
            }
            return;
          }
        }
      }

      final status = order['trans_status']?.toString().toLowerCase() ?? '';
      final orderCosKode = order['cos_kode']?.toString();
      if (orderCosKode != currentUserId) {
        if (mounted) {
          CustomDialog.show(
            context: context,
            icon: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error, color: Colors.red, size: 24),
            ),
            title: 'Akses Ditolak',
            content: const Text('Anda tidak memiliki akses ke transaksi ini'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        }
        return;
      }

      final transKode = order['trans_kode']?.toString() ?? kode;

      if (status == 'pending') {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WaitingApprovalPage(transKode: transKode),
            ),
          );
        }
      } else if (status != 'completed') {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TrackingPage(queueCode: transKode),
            ),
          );
        }
      } else {
        if (mounted) {
          CustomDialog.show(
            context: context,
            icon: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning, color: Colors.orange, size: 24),
            ),
            title: 'Status Tidak Valid',
            content: const Text('Status transaksi tidak valid'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomDialog.show(
          context: context,
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error, color: Colors.red, size: 24),
          ),
          title: 'Error',
          content: const Text('Transaksi tidak ditemukan'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Image.asset('assets/image/logo.png', width: 95, height: 30),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy, color: Colors.white),
            tooltip: 'AI Assistant',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatPage()),
              );
            },
          ),
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
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          onSubmitted: (value) => _handleSearch(value.trim()),
                          decoration: InputDecoration(
                            hintText: 'Masukkan Kode Transaksi',
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            _handleSearch(searchController.text.trim()),
                        icon: Icon(
                          Icons.search,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black54,
                        ),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Service Image
                AspectRatio(
                  aspectRatio: 17 / 11, // Maintain aspect ratio
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: const DecorationImage(
                        image: AssetImage('assets/image/service_image.jpeg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Info Text Section
                Text(
                  'Tidak sempat datang ke tempat servis?',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tenang, kami menyediakan layanan Home Delivery\nuntuk perbaikan di rumah Anda.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Pesan Sekarang',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_downward, size: 18),
                  ],
                ),
                const SizedBox(height: 20),

                // Service Options Card
                Card(
                  color: const Color(0xFF0041c3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PerbaikanServicePage(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.build,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Perbaikan',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Perbaikan (upgrade/ganti part)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20), // Bottom padding
              ],
            ),
          ),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 1) {
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
          } else {
            setState(() {
              currentIndex = index;
            });
          }
        },
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedItemColor: Colors.white,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.build_circle, size: 24),
            label: 'Service',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined, size: 24),
            label: 'Beli',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 24),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/image/promo.png',
              width: 24,
              height: 24,
              color: Colors.white70,
            ),
            activeIcon: Image.asset(
              'assets/image/promo.png',
              width: 24,
              height: 24,
              color: Colors.white,
            ),
            label: 'Promo',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 24),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
