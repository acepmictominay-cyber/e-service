import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PoinInfoPage extends StatefulWidget {
  const PoinInfoPage({super.key});

  @override
  State<PoinInfoPage> createState() => _PoinInfoPageState();
}

class _PoinInfoPageState extends State<PoinInfoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          'Apa Itu Poin Service',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: AssetImage('assets/image/banner/points.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Apa Itu Poin Service',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '''
🏅 Apa Itu Poin Service?

Poin Service adalah sistem penghargaan yang kamu dapatkan setiap kali menggunakan layanan di aplikasi E-Service.
Setiap transaksi yang kamu lakukan akan memberikan poin, dan poin tersebut bisa kamu kumpulkan untuk mendapatkan berbagai keuntungan menarik.

💡 Cara Mendapatkan Poin

Kamu bisa memperoleh Poin Service dengan beberapa cara, seperti:

Melakukan pemesanan layanan dan menyelesaikannya.

Memberikan rating atau ulasan positif setelah servis selesai.

Mengundang teman untuk bergabung dan menggunakan aplikasi.

Mengikuti promo atau event tertentu dari E-Service.

🎁 Manfaat Poin Service

Poin yang kamu kumpulkan bisa kamu tukarkan dengan:

Potongan harga (diskon) untuk servis berikutnya.

Voucher promo atau bonus layanan.

Hadiah menarik sesuai periode promo yang berlaku.
''',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black87,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
