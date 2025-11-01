import 'package:e_service/Auth/login.dart';
import 'package:e_service/Others/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'history_page.dart';

class TeknisiProfilPage extends StatefulWidget {
  const TeknisiProfilPage({super.key});

  @override
  State<TeknisiProfilPage> createState() => _TeknisiProfilPageState();
}

class _TeknisiProfilPageState extends State<TeknisiProfilPage> {
  bool isOnDuty = true;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final session = await SessionManager.getUserSession();
    setState(() {
      userData = {
        'id': session['id'],
        'name': session['name'],
        'poin': session['poin'],
        'role': session['role'],
      };
      isLoading = false;
    });
  }

  Future<void> _toggleDutyStatus() async {
    setState(() {
      isOnDuty = !isOnDuty;
    });

    // In real app, this would update the server
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isOnDuty ? 'Status: On Duty' : 'Status: Off Duty'),
        backgroundColor: isOnDuty ? Colors.green : Colors.orange,
      ),
    );
  }

  Future<void> _logout() async {
    await SessionManager.clearSession();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nama = userData?['name'] ?? 'Teknisi';
    final id = userData?['id'] ?? '-';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        title: Text(
          'Profil Teknisi',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            nama,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: $id',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Duty Status Toggle
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Status Duty',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isOnDuty
                                        ? 'Sedang Bertugas'
                                        : 'Tidak Bertugas',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              Switch(
                                value: isOnDuty,
                                onChanged: (value) => _toggleDutyStatus(),
                                activeColor: const Color(0xFF1976D2),
                                activeTrackColor: const Color(
                                  0xFF1976D2,
                                ).withOpacity(0.3),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isOnDuty
                                      ? Colors.green.shade50
                                      : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    isOnDuty
                                        ? Colors.green.shade200
                                        : Colors.orange.shade200,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOnDuty
                                      ? Icons.check_circle
                                      : Icons.pause_circle,
                                  color:
                                      isOnDuty ? Colors.green : Colors.orange,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isOnDuty ? 'ON DUTY' : 'OFF DUTY',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isOnDuty
                                            ? Colors.green.shade800
                                            : Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Menu Options
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
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
                          _buildMenuItem(
                            icon: Icons.history,
                            title: 'Riwayat Pekerjaan',
                            subtitle:
                                'Lihat semua pekerjaan yang telah selesai',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HistoryPage(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          _buildMenuItem(
                            icon: Icons.settings,
                            title: 'Pengaturan',
                            subtitle: 'Konfigurasi aplikasi',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Fitur pengaturan akan segera hadir',
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          _buildMenuItem(
                            icon: Icons.help_outline,
                            title: 'Bantuan',
                            subtitle: 'Panduan dan dukungan',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Fitur bantuan akan segera hadir',
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          _buildMenuItem(
                            icon: Icons.info_outline,
                            title: 'Tentang Aplikasi',
                            subtitle: 'Versi dan informasi aplikasi',
                            onTap: () {
                              showAboutDialog(
                                context: context,
                                applicationName: 'E-Service',
                                applicationVersion: '1.0.0',
                                applicationLegalese: '© 2024 E-Service Team',
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Keluar Aplikasi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF1976D2), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
