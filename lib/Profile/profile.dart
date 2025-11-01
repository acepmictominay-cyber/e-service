import 'package:e_service/Auth/auth_service.dart';
import 'package:e_service/Auth/login.dart';
import 'package:e_service/Beli/shop.dart';
import 'package:e_service/Home/Home.dart';
import 'package:e_service/Others/notifikasi.dart';
import 'package:e_service/Others/notification_service.dart';
import 'package:e_service/Others/session_manager.dart';
import 'package:e_service/Others/tier_utils.dart';
import 'package:e_service/Others/user_point_data.dart';
import 'package:e_service/Profile/edit_profile.dart';
import 'package:e_service/Profile/scan_qr.dart';
import 'package:e_service/Profile/show_qr_addcoin.dart';
import 'package:e_service/Profile/show_qr_detail.dart';
import 'package:e_service/Promo/promo.dart';
import 'package:e_service/Service/Service.dart';
import 'package:e_service/api_services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
      }
    } else {
      setState(() => isLoading = false);
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
    final id = userData?['id_costomer'] != null ? 'Id ${userData!['id_costomer']}' : '-';
    final nohp = userData?['cos_hp'] ?? '-';
    final displayNohp = nohp.startsWith('62') ? '0${nohp.substring(2)}' : nohp;
    final tglLahir = userData?['cos_tgl_lahir'] ?? '-';

    return Scaffold(
      backgroundColor: Colors.white,
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
                decoration: const BoxDecoration(
                  color: Colors.blue,
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
              child: _buildShimmerProfileCard(),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 300),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildShimmerBody(),
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
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Image.asset('assets/image/logo.png', width: 95, height: 30),
                    const Spacer(),               
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationPage()),
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
                    _infoTile(Icons.person, 'Nama', nama),
                    const SizedBox(height: 12),
                    _infoTile(Icons.calendar_month, 'Tanggal Lahir', tglLahir),
                    const SizedBox(height: 12),
                    _infoTile(Icons.phone, 'Nomor Telpon', displayNohp),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _qrBox(
                          Icons.qr_code,
                          'Tunjukan QR',
                          onTap: () {
                            Navigator.push(context,
                              MaterialPageRoute(builder: (context) => const ShowQrCustomerData()));
                          },
                        ),
                        _qrBox(
                          Icons.qr_code_scanner,
                          'Scan QR',
                          onTap: () {
                            Navigator.push(context,
                              MaterialPageRoute(builder: (context) => const ScanQrPage()));
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _contactTile(
                      const Icon(Icons.support_agent, color: Colors.blue),
                      '085942001720',
                      Icons.chat,
                      onTrailingTap: () async {
                        final wa = Uri.parse('https://wa.me/6285942001720?text=Halo%20Admin,%20saya%20user');
                        await launchUrl(wa, mode: LaunchMode.externalApplication);
                      },
                    ),
                    const SizedBox(height: 12),
                    _contactTile(
                      const FaIcon(FontAwesomeIcons.instagram, color: Colors.purple),
                      userData?['cos_instagram'] ?? 'authorized_servicecenter.tegal',
                      Icons.chat,
                      onTrailingTap: () async {
                        final username = userData?['cos_instagram'] ?? 'authorized_servicecenter.tegal';
                        final url = Uri.parse('instagram://user?username=$username');
                        await launchUrl(url, mode: LaunchMode.externalApplication);
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
                  backgroundImage: (userData?['cos_gambar'] != null && userData!['cos_gambar'].isNotEmpty)
                      ? NetworkImage("http://192.168.1.6:8000/storage/${userData!['cos_gambar']}")
                      : null,
                  child: (userData?['cos_gambar'] == null || userData!['cos_gambar'].isEmpty)
                      ? Icon(Icons.person, size: 50, color: tierInfo.textColor.withOpacity(0.7))
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
                          builder: (context) => EditProfilePage(userData: userData ?? {}),
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

            // 🔹 Tier Label dan Poin berdampingan
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tier Label dengan Icon
                if (tierInfo.label.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        buildTierIcon(tierInfo.label),
                        const SizedBox(width: 6),
                        Text(
                          tierInfo.label,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: tierInfo.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                
                // Poin user
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                      Image.asset('assets/image/coin.png', width: 18, height: 18),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}


Widget _buildTierIcon(String label) {
  switch (label) {
    case 'Cuanners':
      return const Icon(
        Icons.stars_rounded,
        color: Colors.white,
        size: 16,
      );
    case 'Crazy Rich':
      return const Icon(
        Icons.diamond_rounded,
        color: Colors.white,
        size: 16,
      );
    case 'Sultan':
      return const FaIcon(
        FontAwesomeIcons.crown,
        color: Color(0xFFFFEB3B),
        size: 16,
      );
    default:
      return const SizedBox.shrink();
  }
}


  Widget _qrBox(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, size: 60, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

   Widget _contactTile(Widget leadingIcon, String title, IconData trailingIcon, {Color color = Colors.blue, VoidCallback? onTrailingTap}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              style: const TextStyle(fontSize: 14),
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

  BottomNavigationBar _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index != currentIndex) {
          if (index == 0) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const ServicePage()));
          } else if (index == 1) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const MarketplacePage()));
          } else if (index == 2) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => const HomePage()));
          } else if (index == 3) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const TukarPoinPage()));
          }
        }
      },
      backgroundColor: Colors.blue,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      showUnselectedLabels: true,
      selectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
      unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
      items: [
        const BottomNavigationBarItem(
            icon: Icon(Icons.build_circle_outlined), label: 'Service'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined), label: 'Beli'),
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: currentIndex == 3
              ? Image.asset('assets/image/promo.png', width: 24, height: 24)
              : Opacity(
                  opacity: 0.6,
                  child: Image.asset('assets/image/promo.png', width: 24, height: 24)),
          label: 'Promo',
        ),
        const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }

  // shimmer placeholders
  Widget _buildShimmerBody() {
    return Column(
      children: [
        const SizedBox(height: 24),
        _buildShimmerInfoTile(),
        const SizedBox(height: 12),
        _buildShimmerInfoTile(),
        const SizedBox(height: 12),
        _buildShimmerInfoTile(),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [_buildShimmerQRBox(), _buildShimmerQRBox()],
        ),
        const SizedBox(height: 24),
        _buildShimmerInfoTile(),
        const SizedBox(height: 12),
        _buildShimmerInfoTile(),
      ],
    );
  }

  Widget _buildShimmerProfileCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerInfoTile() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  Widget _buildShimmerQRBox() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
