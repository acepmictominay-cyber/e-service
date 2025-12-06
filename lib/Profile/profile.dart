import 'package:azza_service/Auth/auth_service.dart';
import 'package:azza_service/Auth/login.dart';
import 'package:azza_service/Beli/shop.dart';
import 'package:azza_service/Chat/chat_page.dart';
import 'package:azza_service/Home/Home.dart';
import 'package:azza_service/Others/notifikasi.dart';
import 'package:azza_service/Others/notification_service.dart';
import 'package:azza_service/Others/session_manager.dart';
import 'package:azza_service/providers/theme_provider.dart';
import 'package:azza_service/Others/tier_utils.dart';
import 'package:azza_service/Others/user_point_data.dart';
import 'package:azza_service/Profile/edit_profile.dart';
import 'package:azza_service/Profile/scan_qr.dart';
import 'package:azza_service/Profile/show_qr_detail.dart';
import 'package:azza_service/Promo/promo.dart';
import 'package:azza_service/Service/Service.dart';
import 'package:azza_service/api_services/api_service.dart';
import 'package:azza_service/config/api_config.dart';
import 'package:azza_service/models/voucher_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class LoadingWrapper extends StatelessWidget {
  final bool isLoading;
  final Widget shimmer;
  final Widget child;

  const LoadingWrapper({
    super.key,
    required this.isLoading,
    required this.shimmer,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return isLoading ? shimmer : child;
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int currentIndex = 4;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  int voucherCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadVoucherCount();
    UserPointData.loadUserPoints();
  }

  Future<void> _loadUserData() async {
    final session = await SessionManager.getUserSession();
    final id = session['id'];
    if (id != null) {
      try {
        final data = await ApiService.getCostomerById(id);
        setState(() {
          userData = data;
          isLoading = false;
        });
      } catch (e) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadVoucherCount() async {
    final session = await SessionManager.getUserSession();
    final id = session['id'];
    if (id != null) {
      try {
        final vouchers = await ApiService.getUserVouchers(id);
        final userVouchers =
            vouchers.map((json) => UserVoucher.fromJson(json)).toList();
        setState(() {
          voucherCount = userVouchers.where((uv) => uv.used == 'no').length;
        });
      } catch (e) {
        debugPrint('Error loading voucher count: $e');
      }
    }
  }

  Future<void> _logout() async {
    // Hapus semua data lokal
    await SessionManager.clearSession();
    await NotificationService.clearNotifications();
    UserPointData.userPoints.value = 0;

    // Sign out dari Google jika diperlukan
    try {
      await AuthService().signOut();
    } catch (e) {
      // Handle error gracefully, tidak perlu throw
      debugPrint('Error signing out from Google: $e');
    }

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final nama = userData?['cos_nama'] ?? '-';
    final id =
        userData?['id_costomer'] != null
            ? 'Id ${userData!['id_costomer']}'
            : '-';
    final nohp = userData?['cos_hp'] ?? '-';
    final displayNohp = nohp.startsWith('62') ? '0${nohp.substring(2)}' : nohp;
    final tglLahir = userData?['cos_tgl_lahir'] ?? '-';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LoadingWrapper(
        isLoading: isLoading,
        shimmer: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 160,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).appBarTheme.backgroundColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 120,
              left: 16,
              right: 16,
              child: _buildShimmerProfileCard(context),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 300),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildShimmerBody(context),
              ),
            ),
          ],
        ),
        child: Stack(
          children: [
            // HEADER
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 160,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).appBarTheme.backgroundColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Image.asset('assets/image/logo.png', width: 95, height: 30),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.smart_toy, color: Colors.white),
                      tooltip: 'AI Assistant',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChatPage(),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                      ),
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
              ),
            ),

            // PROFILE CARD
            Positioned(
              top: 115,
              left: 16,
              right: 16,
              child: _buildProfileCard(context, nama, id),
            ),

            // BODY
            Padding(
              padding: const EdgeInsets.only(top: 340),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoTile(context, Icons.person, 'Nama', nama),
                    const SizedBox(height: 12),
                    _infoTile(
                      context,
                      Icons.calendar_month,
                      'Tanggal Lahir',
                      tglLahir,
                    ),
                    const SizedBox(height: 12),
                    _infoTile(
                      context,
                      Icons.phone,
                      'Nomor Telpon',
                      displayNohp,
                    ),
                    const SizedBox(height: 12),
                    _infoTile(
                      context,
                      Icons.card_giftcard,
                      'Jumlah Voucher',
                      '$voucherCount',
                    ),
                    const SizedBox(height: 12),
                    _themeToggleTile(context),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _qrBox(
                          context,
                          Icons.qr_code,
                          'Tunjukan QR',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const ShowQrCustomerData(),
                              ),
                            );
                          },
                        ),
                        _qrBox(
                          context,
                          Icons.qr_code_scanner,
                          'Scan QR',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ScanQrPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _contactTile(
                      context,
                      const Icon(Icons.support_agent, color: Colors.white),
                      '085942001720',
                      Icons.chat,
                      onTrailingTap: () async {
                        final wa = Uri.parse(
                          'https://wa.me/6285942001720?text=Halo%20Admin,%20saya%20user',
                        );
                        await launchUrl(
                          wa,
                          mode: LaunchMode.externalApplication,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _contactTile(
                      context,
                      const FaIcon(
                        FontAwesomeIcons.instagram,
                        color: Colors.purple,
                      ),
                      userData?['cos_instagram'] ??
                          'authorized_servicecenter.tegal',
                      Icons.chat,
                      onTrailingTap: () async {
                        final username =
                            userData?['cos_instagram'] ??
                            'authorized_servicecenter.tegal';
                        final url = Uri.parse(
                          'instagram://user?username=$username',
                        );
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      },
                    ),

                    const SizedBox(height: 30),
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text("Logout"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenSize.width * 0.25,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  // ==================== SUPPORTING WIDGETS ====================

  Widget _buildProfileCard(BuildContext context, String nama, String id) {
    return ValueListenableBuilder<int>(
      valueListenable: UserPointData.userPoints,
      builder: (context, points, _) {
        final tierInfo = getTierInfo(points);
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: tierInfo.decoration,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // 🔹 Foto profil user
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.black.withOpacity(0.2),
                    backgroundImage:
                        (userData?['cos_gambar'] != null &&
                                userData!['cos_gambar'].isNotEmpty)
                            ? NetworkImage(
                              "${ApiConfig.storageBaseUrl}${userData!['cos_gambar']}",
                            )
                            : null,
                    child:
                        (userData?['cos_gambar'] == null ||
                                userData!['cos_gambar'].isEmpty)
                            ? Icon(
                              Icons.person,
                              size: 50,
                              color: tierInfo.textColor.withOpacity(0.7),
                            )
                            : null,
                  ),

                  // 🔹 Tombol edit (pensil) di kanan atas
                  Positioned(
                    top: 0,
                    right: 0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    EditProfilePage(userData: userData ?? {}),
                          ),
                        );

                        // 🔹 Jika dari EditProfilePage ada data baru, refresh profil
                        if (result != null && result.isNotEmpty) {
                          await _loadUserData();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.edit,
                          color: tierInfo.textColor,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 🔹 Nama dan ID
              Text(
                nama,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: tierInfo.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                id,
                style: GoogleFonts.poppins(
                  color: tierInfo.textColor.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),

              // 🔹 Poin user
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Poin',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color: tierInfo.textColor.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$points',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: tierInfo.textColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Image.asset('assets/logo/point.png', width: 18, height: 18),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTierIcon(String label) {
    switch (label) {
      case 'Bronze':
        return const Icon(
          Icons.grade,
          color: Color(0xFFD2B48C), // light brown
          size: 16,
        );
      case 'Silver':
        return const Icon(
          Icons.star,
          color: Color(0xFFC0C0C0), // silver
          size: 16,
        );
      case 'Gold':
        return const Icon(
          Icons.workspace_premium,
          color: Color(0xFFFFD700), // gold
          size: 16,
        );
      case 'Diamond':
        return const Icon(Icons.diamond, color: Colors.white, size: 16);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _qrBox(
    BuildContext context,
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color:
                      isDark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 60,
              color: Theme.of(context).iconTheme.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color:
                isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactTile(
    BuildContext context,
    Widget leadingIcon,
    String title,
    IconData trailingIcon, {
    Color color = const Color(0xFF0041c3),
    VoidCallback? onTrailingTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color:
                isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          leadingIcon,
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onTrailingTap,
            child: Icon(trailingIcon, color: color),
          ),
        ],
      ),
    );
  }

  Widget _themeToggleTile(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Theme.of(context).dividerColor, width: 1),
            boxShadow: [
              BoxShadow(
                color:
                    isDark
                        ? Colors.black.withOpacity(0.2)
                        : Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.brightness_6, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mode Tema',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              DropdownButton<ThemeMode>(
                value: themeProvider.themeMode,
                onChanged: (ThemeMode? newMode) {
                  if (newMode != null) {
                    themeProvider.setThemeMode(newMode);
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('Otomatis'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text('Terang'),
                  ),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Gelap')),
                ],
                underline: const SizedBox.shrink(),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context).iconTheme.color,
                ),
                dropdownColor: Theme.of(context).cardColor,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  BottomNavigationBar _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index != currentIndex) {
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
          }
        }
      },
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      selectedItemColor: Colors.white,
      selectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
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
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }

  // shimmer placeholders
  Widget _buildShimmerBody(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        _buildShimmerInfoTile(context),
        const SizedBox(height: 12),
        _buildShimmerInfoTile(context),
        const SizedBox(height: 12),
        _buildShimmerInfoTile(context),
        const SizedBox(height: 12),
        _buildShimmerInfoTile(context),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [_buildShimmerQRBox(context), _buildShimmerQRBox(context)],
        ),
        const SizedBox(height: 24),
        _buildShimmerInfoTile(context),
        const SizedBox(height: 12),
        _buildShimmerInfoTile(context),
      ],
    );
  }

  Widget _buildShimmerProfileCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade600 : Colors.grey.shade100,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerInfoTile(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[700]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[600]! : Colors.grey[100]!,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[700] : Colors.grey[300],
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  Widget _buildShimmerQRBox(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[700]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[600]! : Colors.grey[100]!,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[700] : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
