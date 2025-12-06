import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatTab extends StatelessWidget {
  const ChatTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Komunikasi / Obrolan',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hubungi pelanggan atau admin',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          // Chat feature removed as per requirements
          const SizedBox.shrink(),
        ],
      ),
    );
  }
}
