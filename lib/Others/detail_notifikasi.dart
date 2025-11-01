import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'notification_service.dart';

class NotificationDetailPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final DateTime? timestamp;

  const NotificationDetailPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: color,
        title: Text(
          "Detail Notifikasi",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(icon, size: 80, color: color),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            if (timestamp != null) ...[
              Text(
                'Waktu: ${TimeFormatter.formatRelativeTime(timestamp!)}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black45,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Notifikasi ini muncul saat Anda berhasil login ke aplikasi.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
            const Spacer(),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text("Kembali"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
