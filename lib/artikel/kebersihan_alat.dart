import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KebersihanAlatPage extends StatefulWidget {
  const KebersihanAlatPage({super.key});

  @override
  State<KebersihanAlatPage> createState() => _KebersihanAlatPageState();
}

class _KebersihanAlatPageState extends State<KebersihanAlatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pentingnya Menjaga Kebersihan Alat Elektronik',
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
                  image: AssetImage('assets/image/banner/kebersihan.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pentingnya Menjaga Kebersihan Alat Elektronik',
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
Perangkat elektronik seperti HP, laptop, AC, komputer, dan vacuum cleaner adalah bagian penting dari kehidupan sehari-hari.
Namun, banyak orang lupa bahwa alat elektronik juga perlu dibersihkan secara rutin agar tetap awet, aman, dan bekerja dengan baik.

💡 1. Menjaga Performa Tetap Optimal

Debu dan kotoran yang menumpuk di dalam perangkat dapat:

Menghambat sirkulasi udara.

Menyebabkan perangkat cepat panas (overheating).

Membuat kinerja perangkat jadi lambat.

🧠 Contoh: Laptop atau PC yang tidak pernah dibersihkan biasanya cepat panas dan kipasnya berisik karena debu menumpuk di dalamnya.

⚙️ 2. Mencegah Kerusakan Komponen

Kotoran yang masuk ke celah-celah perangkat bisa merusak:

Kipas pendingin

Port USB / charger

Tombol keyboard atau remote

Sensor dan kamera

Dengan membersihkan secara rutin, kamu bisa mencegah kerusakan dini dan menghemat biaya servis.

⚡ 3. Menghindari Risiko Konsleting

Debu yang menumpuk dan lembap bisa menjadi penghantar listrik, berpotensi menyebabkan:

Konsleting

Kerusakan sirkuit

Bahkan kebakaran kecil pada perangkat elektronik

Itulah sebabnya penting memastikan perangkat dalam kondisi kering dan bersih.

🌿 4. Menjaga Kesehatan dan Kebersihan Lingkungan

Perangkat seperti AC, kipas angin, atau vacuum cleaner yang kotor bisa menyebarkan:

Debu

Bakteri

Jamur
ke udara rumah atau kantor.

Membersihkan secara teratur membantu menjaga udara tetap bersih dan mencegah alergi atau sesak napas.

🧴 5. Meningkatkan Umur Pakai dan Nilai Jual

Perangkat yang dirawat dan selalu bersih akan:

Tahan lebih lama

Tetap terlihat seperti baru

Lebih mudah dijual kembali dengan harga tinggi

🧽 Tips Membersihkan Alat Elektronik

Matikan dan cabut listrik sebelum dibersihkan.

Gunakan lap microfiber agar tidak menggores permukaan.

Hindari penggunaan air langsung. Gunakan cairan pembersih khusus.

Bersihkan ventilasi udara, kipas, dan port dengan kuas kecil atau blower.
''',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
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
