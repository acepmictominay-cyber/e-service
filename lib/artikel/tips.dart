import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TipsPage extends StatefulWidget {
  const TipsPage({super.key});

  @override
  State<TipsPage> createState() => _TipsPageState();
}

class _TipsPageState extends State<TipsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tips Perawatan Laptop',
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
                  image: AssetImage('assets/image/banner/tips.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tips Perawatan Laptop',
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
Tips dan Trik Merawat Laptop Ringan Agar Tidak Cepat Rusak

1. Jangan Membebani Laptop Anda Terlalu Berat
Salah satu cara paling sederhana untuk menjaga laptop tetap ringan adalah dengan tidak membebani laptop Anda terlalu berat. Jika Anda menjalankan banyak program berat atau membuka banyak tab browser sekaligus, laptop Anda akan bekerja lebih keras dan lebih panas. Hal ini dapat mengakibatkan kelebihan panas yang berpotensi merusak komponen dalam laptop Anda. Pastikan untuk menutup program yang tidak Anda gunakan dan mengelola aplikasi dengan bijak.

2. Gunakan Laptop pada Permukaan yang Rata dan Ventilasi yang Baik
Laptop yang digunakan pada permukaan yang datar dan keras akan membantu menjaga sirkulasi udara yang baik di sekitar laptop. Hindari meletakkan laptop Anda pada permukaan yang empuk seperti kasur atau bantal yang dapat menghalangi ventilasi udara, karena ini dapat menyebabkan laptop menjadi panas berlebihan. Gunakan alas laptop yang keras atau bantuan pendingin laptop jika diperlukan.

3. Bersihkan Laptop secara Berkala
Debu dan kotoran dapat mengumpul di dalam laptop dan mengganggu kinerja serta menyebabkan panas berlebihan. Bersihkan laptop secara berkala dengan menggunakan kompresor udara atau alat pembersih khusus untuk elektronik. Pastikan laptop dimatikan saat membersihkannya.

4. Hindari Guncangan dan Benturan
Guncangan dan benturan dapat merusak komponen dalam laptop Anda. Selalu pastikan laptop Anda ditempatkan dengan aman dan tidak terpapar risiko fisik yang berlebihan. Gunakan tas laptop yang dirancang khusus untuk melindunginya saat Anda bepergian.

5. Lakukan Update dan Backup Data Secara Teratur
Selalu perbarui sistem operasi dan perangkat lunak Anda secara berkala untuk menjaga keamanan dan kinerja laptop. Selain itu, lakukan backup data Anda secara teratur. Jika terjadi masalah atau kerusakan pada laptop, Anda akan memiliki cadangan data yang aman.

6. Hindari Paparan Suhu yang Ekstrem
Suhu yang ekstrem, baik terlalu panas maupun terlalu dingin, dapat merusak komponen dalam laptop. Hindari menggunakan laptop di tempat yang terlalu panas atau terlalu dingin. Selain itu, jangan biarkan laptop terkena sinar matahari langsung atau suhu ekstrem.

7. Gunakan Perangkat Lunak Antivirus dan Anti-Malware
Instal perangkat lunak antivirus dan anti-malware yang andal untuk melindungi laptop Anda dari serangan virus dan malware yang dapat merusak sistem Anda.

8. Matikan Laptop dengan Benar
Selalu matikan laptop Anda dengan benar daripada hanya mengaturnya ke mode sleep atau hibernate. Ini akan membantu menghindari masalah dengan sistem operasi dan perangkat keras.

Dengan mengikuti tips dan trik di atas, Anda dapat menjaga laptop Anda agar tetap ringan dan tidak cepat rusak. Merawat laptop dengan baik adalah investasi untuk menjaga kinerja laptop Anda dalam jangka panjang, sehingga Anda dapat terus menggunakannya dengan efisien dan tanpa masalah.
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
