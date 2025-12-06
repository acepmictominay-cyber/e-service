import 'package:azza_service/models/knowledge_model.dart';
import 'package:azza_service/api_services/api_service.dart';
import 'package:azza_service/Others/session_manager.dart';
import 'package:azza_service/services/query_detection.dart';

class KnowledgeService {
  // ============================================================
  // GET ALL KNOWLEDGE
  // ============================================================
  static Future<List<KnowledgeItem>> getAllKnowledge() async {
    return _getDefaultKnowledge();
  }

  // ============================================================
  // GET DEFAULT KNOWLEDGE
  // ============================================================
  static List<KnowledgeItem> _getDefaultKnowledge() {
    final now = DateTime.now();

    return [
      KnowledgeItem(
        id: 'product_laptop_service',
        title: 'Harga Service Laptop',
        content:
            'Service laptop mulai dari Rp 50.000 untuk diagnosis, Rp 150.000 untuk perbaikan hardware ringan, hingga Rp 500.000 untuk perbaikan berat.',
        category: 'Harga Service',
        createdAt: now,
        updatedAt: now,
      ),
      KnowledgeItem(
        id: 'product_pc_service',
        title: 'Harga Service PC/Komputer',
        content:
            'Service PC mulai dari Rp 75.000 untuk cleaning, Rp 200.000 untuk upgrade komponen, hingga Rp 750.000 untuk perbaikan motherboard.',
        category: 'Harga Service',
        createdAt: now,
        updatedAt: now,
      ),
      KnowledgeItem(
        id: 'product_printer_service',
        title: 'Harga Service Printer',
        content:
            'Service printer Epson/Canon/HP mulai dari Rp 100.000 untuk perbaikan mekanik, Rp 150.000 untuk penggantian cartridge, hingga Rp 300.000 untuk perbaikan head printer.',
        category: 'Harga Service',
        createdAt: now,
        updatedAt: now,
      ),
      KnowledgeItem(
        id: 'product_cleaning_service',
        title: 'Harga Service Cleaning',
        content:
            'Service cleaning laptop/PC mulai dari Rp 50.000 untuk cleaning ringan, Rp 100.000 untuk deep cleaning dengan disassembly.',
        category: 'Harga Service',
        createdAt: now,
        updatedAt: now,
      ),

      // PRODUK
      KnowledgeItem(
        id: 'product_mouse_available',
        title: 'Ketersediaan Mouse',
        content:
            'Mouse gaming dan office tersedia dalam berbagai merk: Logitech, Razer, SteelSeries, HP, Dell. Harga mulai dari Rp 50.000 hingga Rp 500.000.',
        category: 'Produk',
        createdAt: now,
        updatedAt: now,
      ),
      KnowledgeItem(
        id: 'product_laptop_available',
        title: 'Ketersediaan Laptop',
        content:
            'Laptop berbagai merk tersedia: ASUS, Lenovo, HP, Dell, MSI. Mulai dari laptop entry-level Rp 3.000.000 hingga gaming laptop Rp 15.000.000.',
        category: 'Produk',
        createdAt: now,
        updatedAt: now,
      ),

      // LAYANAN
      KnowledgeItem(
        id: 'service_warranty',
        title: 'Garansi Service',
        content:
            'Semua service diberikan garansi 30 hari untuk perbaikan hardware, 7 hari untuk software.',
        category: 'Layanan',
        createdAt: now,
        updatedAt: now,
      ),
      KnowledgeItem(
        id: 'service_pickup_delivery',
        title: 'Pickup & Delivery',
        content:
            'Tersedia layanan pickup dan delivery area Jabodetabek. Biaya mulai Rp 25.000.',
        category: 'Layanan',
        createdAt: now,
        updatedAt: now,
      ),

      // ESTIMASI
      KnowledgeItem(
        id: 'service_estimation',
        title: 'Estimasi Lama Pengerjaan Service',
        content:
            'Estimasi lama pengerjaan 2-3 minggu tergantung kerusakan dan ketersediaan spare part.',
        category: 'Layanan',
        createdAt: now,
        updatedAt: now,
      ),

      KnowledgeItem(
        id: 'service_status_check',
        title: 'Cara Cek Status Service',
        content:
            'Buka halaman Service, masukkan kode antrean. Estimasi 2-3 minggu tergantung kerusakan.',
        category: 'Panduan',
        createdAt: now,
        updatedAt: now,
      ),

      // LOKASI
      KnowledgeItem(
        id: 'store_location',
        title: 'Lokasi Toko',
        content:
            'Ruko Kranggan Permai, Jl. Alternatif Cibubur No.27, Jatisampurna, Bekasi.',
        category: 'Lokasi',
        createdAt: now,
        updatedAt: now,
      ),

      // FAQ
      KnowledgeItem(
        id: 'faq_payment',
        title: 'Metode Pembayaran',
        content: 'Transfer bank, GoPay, OVO, Dana, kartu kredit, dan Midtrans.',
        category: 'FAQ',
        createdAt: now,
        updatedAt: now,
      ),

      // FAQ APLIKASI
      KnowledgeItem(
        id: 'faq_app_navigation',
        title: 'Cara Navigasi Aplikasi',
        content:
            'Aplikasi memiliki 4 menu utama:\n• Service: Untuk perbaikan laptop/PC/printer\n• Beli: Untuk membeli produk seperti mouse, keyboard\n• History: Riwayat service dan pembelian\n• Profile: Pengaturan akun dan kontak CS\n\nUntuk navigasi mudah, gunakan menu bawah aplikasi.',
        category: 'FAQ Aplikasi',
        createdAt: now,
        updatedAt: now,
      ),

      KnowledgeItem(
        id: 'faq_customer_support',
        title: 'Layanan Customer Support',
        content:
            'Customer Support kami siap membantu Anda 24/7:\n\n📞 Telepon: 0812-3456-7890\n💬 WhatsApp: 0812-3456-7890\n📧 Email: support@azza-service.com\n🏪 Toko: Ruko Kranggan Permai No.27, Cibubur\n\nJam operasional CS: Senin-Sabtu 08:00-17:00 WIB',
        category: 'Customer Support',
        createdAt: now,
        updatedAt: now,
      ),

      KnowledgeItem(
        id: 'faq_emergency_service',
        title: 'Layanan Emergency/Darurat',
        content:
            'Untuk keadaan darurat atau perbaikan urgent:\n\n🚨 Emergency Hotline: 0812-3456-7890\n⏰ Response Time: 2-4 jam untuk area Jabodetabek\n💰 Biaya Emergency: +50% dari harga normal\n\nKami prioritaskan service emergency untuk:\n• Komputer tidak bisa booting\n• Hard drive rusak dengan data penting\n• Perangkat mati total',
        category: 'Emergency Service',
        createdAt: now,
        updatedAt: now,
      ),

      KnowledgeItem(
        id: 'faq_warranty_extend',
        title: 'Perpanjangan Garansi',
        content:
            'Program perpanjangan garansi AzzaService:\n\n🔧 Extended Warranty Service:\n• 6 bulan: +20% dari harga service\n• 1 tahun: +35% dari harga service\n• 2 tahun: +50% dari harga service\n\n📋 Syarat dan Ketentuan:\n• Berlaku untuk service perbaikan hardware\n• Tidak termasuk kerusakan akibat misuse\n• Klaim garansi harus dengan nota service asli',
        category: 'Garansi',
        createdAt: now,
        updatedAt: now,
      ),

      KnowledgeItem(
        id: 'faq_data_backup',
        title: 'Layanan Backup Data',
        content:
            'Layanan backup dan recovery data profesional:\n\n💾 Backup Service:\n• External HDD: Rp 150.000\n• Cloud Backup (Google Drive): Rp 100.000\n• NAS Setup: Rp 300.000\n\n🔄 Data Recovery:\n• HDD Recovery: Mulai Rp 500.000\n• SSD Recovery: Mulai Rp 750.000\n• RAID Recovery: Mulai Rp 1.500.000\n\n⚠️ Important: Selalu backup data penting sebelum service!',
        category: 'Data Management',
        createdAt: now,
        updatedAt: now,
      ),

      KnowledgeItem(
        id: 'faq_remote_support',
        title: 'Remote Support / Support Jarak Jauh',
        content:
            'Layanan remote support untuk troubleshooting:\n\n🖥️ Remote Desktop Support:\n• Diagnosa masalah: Rp 50.000/jam\n• Troubleshooting software: Rp 75.000/jam\n• Setup aplikasi: Rp 100.000/jam\n\n📱 Remote Support via:\n• TeamViewer\n• AnyDesk\n• Microsoft Quick Assist\n\n⏱️ Jam operasional remote support: 09:00-17:00 WIB',
        category: 'Remote Support',
        createdAt: now,
        updatedAt: now,
      ),

      KnowledgeItem(
        id: 'faq_preventive_maintenance',
        title: 'Preventive Maintenance / Pemeliharaan Berkala',
        content:
            'Paket preventive maintenance untuk menjaga performa device:\n\n🛠️ Basic Cleaning Package:\n• Pembersihan debu dan ventilasi\n• Update driver dan software\n• Check kesehatan hardware\n• Harga: Rp 150.000\n\n🔧 Premium Maintenance Package:\n• Semua fitur Basic + thermal paste\n• Hardware diagnostic lengkap\n• Performance optimization\n• Harga: Rp 300.000\n\n📅 Recommended: Service setiap 6 bulan',
        category: 'Preventive Maintenance',
        createdAt: now,
        updatedAt: now,
      ),

      KnowledgeItem(
        id: 'faq_bulk_service',
        title: 'Layanan Service Massal/Kantor',
        content:
            'Solusi service untuk perusahaan dan instansi:\n\n🏢 Corporate Service Package:\n• Diskon hingga 30% untuk 5+ device\n• On-site service di lokasi\n• SLA guarantee 24-48 jam\n• Dedicated technical support\n\n📊 Volume Pricing:\n• 5-10 device: 20% discount\n• 11-25 device: 25% discount\n• 26+ device: 30% discount\n\n📞 Contact: business@azza-service.com',
        category: 'Corporate Service',
        createdAt: now,
        updatedAt: now,
      ),

      KnowledgeItem(
        id: 'faq_pickup_delivery_zones',
        title: 'Area Coverage Pickup & Delivery',
        content:
            'Area layanan pickup & delivery AzzaService:\n\n✅ FULL COVERAGE AREA:\n• Jakarta Pusat, Selatan, Barat, Utara, Timur\n• Depok, Bogor, Tangerang, Bekasi\n• Cibubur, Cibinong, Citayam\n\n⚠️ LIMITED AREA (biaya tambahan):\n• Karawang, Cikarang (Rp 50.000 extra)\n• Serpong, BSD (Rp 25.000 extra)\n\n❌ OUT OF AREA:\n• Di luar Jabodetabek - koordinasi khusus\n\n🚚 Free delivery untuk service > Rp 500.000',
        category: 'Area Coverage',
        createdAt: now,
        updatedAt: now,
      ),

      KnowledgeItem(
        id: 'faq_payment_methods',
        title: 'Metode Pembayaran Lengkap',
        content:
            'Berbagai metode pembayaran di AzzaService:\n\n💳 CREDIT/DEBIT CARD:\n• Visa, Mastercard, JCB\n• Cicilan 0% hingga 12 bulan\n\n📱 E-WALLET:\n• GoPay, OVO, Dana, LinkAja\n• ShopeePay, Tokopedia\n\n🏦 TRANSFER BANK:\n• BCA, Mandiri, BNI, BRI\n• CIMB Niaga, Permata\n\n💰 CASH ON DELIVERY:\n• Area Jabodetabek\n• Biaya admin Rp 5.000\n\n📋 PEMBAYARAN CICILAN:\n• Indodana, Kredivo, Akulaku\n• Minimum Rp 500.000',
        category: 'Payment Methods',
        createdAt: now,
        updatedAt: now,
      ),

      KnowledgeItem(
        id: 'faq_technical_consultation',
        title: 'Konsultasi Teknis Gratis',
        content:
            'Layanan konsultasi teknis gratis untuk customer:\n\n💬 FREE CONSULTATION:\n• Troubleshooting masalah umum\n• Rekomendasi upgrade hardware\n• Tips optimasi performa\n• Panduan penggunaan software\n\n⏰ Available via:\n• Chat bot (24/7)\n• WhatsApp (08:00-17:00)\n• Telepon (08:00-17:00)\n\n📞 Premium Consultation:\n• 1-on-1 technical session: Rp 150.000/jam\n• Home visit consultation: Rp 250.000\n• System audit lengkap: Rp 500.000',
        category: 'Technical Consultation',
        createdAt: now,
        updatedAt: now,
      ),

      KnowledgeItem(
        id: 'faq_app_register',
        title: 'Cara Daftar Akun',
        content:
            '1. Buka aplikasi\n2. Klik "Daftar" di halaman login\n3. Isi nama lengkap, email, nomor HP\n4. Buat password\n5. Klik "Daftar"\n6. Verifikasi email jika diperlukan',
        category: 'FAQ Aplikasi',
        createdAt: now,
        updatedAt: now,
      ),

      KnowledgeItem(
        id: 'faq_app_login',
        title: 'Cara Login ke Aplikasi',
        content:
            '1. Buka aplikasi\n2. Masukkan email dan password\n3. Klik "Login"\n4. Jika lupa password, klik "Lupa Password"',
        category: 'FAQ Aplikasi',
        createdAt: now,
        updatedAt: now,
      ),

      KnowledgeItem(
        id: 'faq_app_reset_password',
        title: 'Cara Reset Password',
        content:
            '1. Di halaman login, klik "Lupa Password"\n2. Masukkan email yang terdaftar\n3. Klik "Kirim"\n4. Cek email untuk link reset password\n5. Ikuti instruksi di email',
        category: 'FAQ Aplikasi',
        createdAt: now,
        updatedAt: now,
      ),

      KnowledgeItem(
        id: 'faq_app_profile',
        title: 'Cara Update Profile',
        content:
            '1. Klik menu "Profile"\n2. Klik ikon edit (pensil)\n3. Update data nama, alamat, nomor HP\n4. Klik "Simpan"\n5. Data akan tersimpan otomatis',
        category: 'FAQ Aplikasi',
        createdAt: now,
        updatedAt: now,
      ),

      KnowledgeItem(
        id: 'faq_app_notification',
        title: 'Cara Mengatur Notifikasi',
        content:
            'Notifikasi otomatis aktif untuk:\n• Update status service\n• Konfirmasi pembayaran\n• Promo dan diskon\n• Pengingat appointment\n\nUntuk mengatur: Settings > Notifikasi',
        category: 'FAQ Aplikasi',
        createdAt: now,
        updatedAt: now,
      ),

      KnowledgeItem(
        id: 'faq_app_crash',
        title: 'Aplikasi Sering Crash',
        content:
            'Solusi:\n1. Restart aplikasi\n2. Clear cache aplikasi\n3. Update ke versi terbaru\n4. Restart device\n5. Jika masih bermasalah, hubungi CS',
        category: 'FAQ Aplikasi',
        createdAt: now,
        updatedAt: now,
      ),

      KnowledgeItem(
        id: 'faq_app_update',
        title: 'Cara Update Aplikasi',
        content:
            'Update otomatis via Play Store/App Store:\n1. Buka Play Store/App Store\n2. Cari "AzzaService"\n3. Klik "Update" jika tersedia\n\nAtau aktifkan auto-update di pengaturan store.',
        category: 'FAQ Aplikasi',
        createdAt: now,
        updatedAt: now,
      ),

      KnowledgeItem(
        id: 'faq_app_offline',
        title: 'Bisa Pakai Aplikasi Offline?',
        content:
            'Fitur offline terbatas:\n• Bisa lihat riwayat yang sudah di-cache\n• Tidak bisa pesan service baru\n• Tidak bisa cek status real-time\n• Perlu koneksi internet untuk fitur utama',
        category: 'FAQ Aplikasi',
        createdAt: now,
        updatedAt: now,
      ),

      KnowledgeItem(
        id: 'faq_app_contact_cs',
        title: 'Cara Hubungi Customer Service',
        content:
            '1. Klik menu "Profile"\n2. Scroll ke bawah\n3. Klik "Hubungi CS"\n4. Pilih WhatsApp atau Telepon\n5. Jam operasional: Senin-Sabtu 09:00-18:00 WIB',
        category: 'FAQ Aplikasi',
        createdAt: now,
        updatedAt: now,
      ),

      // PANDUAN
      KnowledgeItem(
        id: 'guide_order_service',
        title: 'Cara Pemesanan Service',
        content:
            '1. Buka aplikasi\n2. Pilih menu Service\n3. Pilih perangkat\n4. Isi detail kerusakan\n5. Pilih jadwal\n6. Bayar\n7. Tunggu konfirmasi.',
        category: 'Panduan',
        createdAt: now,
        updatedAt: now,
      ),

      // OPERASIONAL
      KnowledgeItem(
        id: 'info_contact',
        title: 'Kontak & Jam Operasional',
        content:
            'Senin–Sabtu 08:00–17:00. WA: 08123456789. Email: info@azza-service.com',
        category: 'Operasional',
        createdAt: now,
        updatedAt: now,
      ),

      // SOP CUSTOMER SERVICE
      KnowledgeItem(
        id: 'sop_customer_review_request',
        title: 'Cara Meminta Review Customer',
        content:
            'Customer wajib dimintakan review untuk meningkatkan kualitas pelayanan. Cara mengomong: "Mohon waktunya sebentar kak, untuk meningkatkan kualitas pelayanan kami, mohon dibantu scan barcode dan berikan Bintang 5 nya ya kak, sama komentar positifnya ya kak." Jika sudah direview: "Terimakasih banyak atas review positifnya kak, sehat selalu hati-hati di jalan."',
        category: 'SOP Customer Service',
        createdAt: now,
        updatedAt: now,
      ),

      KnowledgeItem(
        id: 'sop_product_sales',
        title: 'Produk yang Dijual',
        content:
            'Penjualan Produk Semua Brand: Laptop, HP (Handphone), Printer, PC All in one, PC Built Up/rakitan, CCTV, Fingerprint, Monitor, Screen, Proyektor. Pengadaan Kantor melayani: SIP Lah, Sistem Kredit bekerjasama dengan Kredivo.',
        category: 'SOP Customer Service',
        createdAt: now,
        updatedAt: now,
      ),

      KnowledgeItem(
        id: 'sop_warranty_advan',
        title: 'Cek Garansi Advan (Zyrex)',
        content:
            'Garansi Advan dari Zyrex dicek berdasarkan invoice/nota pembelian. Garansi 1 tahun untuk produk, baterai 6 bulan. Jika tidak ada invoice maka diproses Out Off Warranty (OOW).',
        category: 'SOP Customer Service',
        createdAt: now,
        updatedAt: now,
      ),

      KnowledgeItem(
        id: 'sop_warranty_lenovo',
        title: 'Cek Garansi Lenovo',
        content:
            'Untuk cek garansi Lenovo: Buka web Lenovo part lookup, ketik Serial Number (SN) dan search. Klik Warranty Services. Pastikan Ship location Indonesia, jika produk selain Indonesia maka tidak bisa klaim garansi (proses OOW).',
        category: 'SOP Customer Service',
        createdAt: now,
        updatedAt: now,
      ),

      KnowledgeItem(
        id: 'sop_warranty_asus',
        title: 'Cek Garansi Asus',
        content:
            'Untuk cek garansi Asus: Buka web Asus (pengecekan garansi & dukungan garansi), masukan Serial Number (SN), kemudian search.',
        category: 'SOP Customer Service',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  // ============================================================
  // SEARCH KNOWLEDGE – DENGAN RANKING
  // ============================================================
  static Future<List<KnowledgeItem>> searchKnowledge(String query) async {
    if (query.isEmpty) return await getAllKnowledge();

    // Use consolidated query detection
    final detectionResult = QueryDetection.detectQueryType(query);
    final q = query.toLowerCase();

    // ===== GET DATA BERDASARKAN INTENT =====
    List<KnowledgeItem> allItems;

    switch (detectionResult.type) {
      case QueryType.faq:
        // Special handling for FAQ questions - return app FAQ items
        allItems = await getAllKnowledge();
        allItems =
            allItems.where((item) => item.category == 'FAQ Aplikasi').toList();
        break;

      case QueryType.orderingService:
        // Special handling for ordering service questions - return ordering guide
        final now = DateTime.now();
        allItems = [
          KnowledgeItem(
            id: 'guide_order_service',
            title: 'Cara Pemesanan Service',
            content:
                '1. Buka aplikasi\n2. Pilih menu Service\n3. Klik button Perbaikan\n4. Isi detail device dan detail kerusakan\n5. Tunggu persetujuan\n6. Pembayaran bisa di lakukan setelah diagnosa perbaikan.',
            category: 'Panduan',
            createdAt: now,
            updatedAt: now,
          )
        ];
        break;

      case QueryType.payment:
        // Special handling for payment questions
        final now = DateTime.now();
        allItems = [
          KnowledgeItem(
            id: 'payment_info',
            title: 'Informasi Pembayaran',
            content:
                'Informasi terkait pembayaran ada di dalam aplikasi, bisa di lihat di halaman service lalu masukan kode transaksi.',
            category: 'Pembayaran',
            createdAt: now,
            updatedAt: now,
          )
        ];
        break;

      case QueryType.yesNo:
        // Special handling for yes/no questions
        final now = DateTime.now();
        String answer = _getYesNoAnswer(q);
        allItems = [
          KnowledgeItem(
            id: 'yes_no_answer',
            title: 'Jawaban Ya/Tidak',
            content: answer,
            category: 'Informasi',
            createdAt: now,
            updatedAt: now,
          )
        ];
        break;

      case QueryType.operatingHours:
        // Special handling for operating hours queries
        final now = DateTime.now();
        allItems = [
          KnowledgeItem(
            id: 'operating_hours',
            title: 'Jam Operasional',
            content: '''Jam Oprasional kami Senin - Sabtu: Pukul 09.00–18.00
Minggu: Tutup
  ''',
            category: 'Operasional',
            createdAt: now,
            updatedAt: now,
          )
        ];
        break;

      case QueryType.complaint:
        // Special handling for complaints or additional questions
        final now = DateTime.now();
        allItems = [
          KnowledgeItem(
            id: 'complaint_response',
            title: 'Keluhan/Pertanyaan Tambahan',
            content:
                'Maaf ya, sebagai bot saya mungkin belum bisa menjawab semua pertanyaan Anda dengan sempurna. Untuk bantuan lebih lengkap, silakan hubungi Customer Service kami di halaman Profile atau tanyakan saja seputar service komputer dan produk yang kami tawarkan! 😊',
            category: 'Bantuan',
            createdAt: now,
            updatedAt: now,
          )
        ];
        break;

      case QueryType.location:
        // Special handling for location/address queries
        final now = DateTime.now();
        allItems = [
          KnowledgeItem(
            id: 'store_locations',
            title: 'Lokasi Toko',
            content: '''Kami beroperasi di:
  1. Ruko Kranggan Permai, Jl. Alternatif Cibubur No.Blok. RT16 No. 27, Jatisampurna, Kec. Jatisampurna, Kota Bks, Jawa Barat 17431

  2. Ruko Citraland Tegal, Blk. B No.11, Kraton, Kec. Tegal Bar., Kota Tegal, Jawa Tengah 52112''',
            category: 'Lokasi',
            createdAt: now,
            updatedAt: now,
          )
        ];
        break;

      case QueryType.serviceStatus:
        // Special handling for service status queries
        try {
          // Get customer ID from session
          final session = await SessionManager.getUserSession();
          final customerId = session['id'];

          if (customerId != null) {
            // Check customer orders
            final orders =
                await ApiService.getCustomerOrders(customerId.toString());

            if (orders.isNotEmpty) {
              // Find ongoing orders (not completed/cancelled)
              final ongoingOrders = orders.where((order) {
                final status =
                    order['trans_status']?.toString().toLowerCase() ?? '';
                return !['selesai', 'completed', 'cancelled', 'dibatalkan']
                    .contains(status);
              }).toList();

              if (ongoingOrders.isNotEmpty) {
                final now = DateTime.now();
                allItems = ongoingOrders.map((order) {
                  final orderCode =
                      order['trans_kode'] ?? order['order_code'] ?? 'Unknown';
                  final status = order['trans_status'] ?? 'Unknown';
                  final estimatedDays = order['estimasi_hari'] ?? '2-3 minggu';

                  String statusMessage;
                  final statusLower = status.toString().toLowerCase();
                  if (statusLower == 'pickingparts' ||
                      statusLower.contains('part')) {
                    statusMessage =
                        'Service Anda sedang dalam tahap pengambilan suku cadang. Estimasi selesai: $estimatedDays.';
                  } else if (statusLower == 'repairing') {
                    statusMessage =
                        'Service Anda sedang dalam tahap perbaikan. Estimasi selesai: $estimatedDays.';
                  } else {
                    statusMessage =
                        'Service Anda sedang diproses. Estimasi selesai: $estimatedDays.';
                  }

                  return KnowledgeItem(
                    id: 'service_status_$orderCode',
                    title: 'Status Service - Order $orderCode',
                    content: statusMessage,
                    category: 'Service Status',
                    createdAt: now,
                    updatedAt: now,
                  );
                }).toList();
              } else {
                // No ongoing orders
                final now = DateTime.now();
                allItems = [
                  KnowledgeItem(
                    id: 'service_status_none',
                    title: 'Status Service',
                    content:
                        'Anda tidak memiliki service yang sedang dikerjakan. Semua pesanan Anda telah selesai.',
                    category: 'Service Status',
                    createdAt: now,
                    updatedAt: now,
                  )
                ];
              }
            } else {
              // No orders at all
              final now = DateTime.now();
              allItems = [
                KnowledgeItem(
                  id: 'service_status_no_orders',
                  title: 'Status Service',
                  content:
                      'Anda belum memiliki riwayat service apapun. Pesan service sekarang untuk mendapatkan informasi status service.',
                  category: 'Service Status',
                  createdAt: now,
                  updatedAt: now,
                )
              ];
            }
          } else {
            // Not logged in
            final now = DateTime.now();
            allItems = [
              KnowledgeItem(
                id: 'service_status_login_required',
                title: 'Status Service',
                content:
                    'Silakan login terlebih dahulu untuk melihat status service Anda.',
                category: 'Service Status',
                createdAt: now,
                updatedAt: now,
              )
            ];
          }
        } catch (e) {
          allItems = await getAllKnowledge();
        }
        break;

      case QueryType.service:
        // Use static knowledge for other service queries
        allItems = await getAllKnowledge();
        break;

      case QueryType.product:
        // For product queries, prioritize static knowledge first, then try API
        allItems = await getAllKnowledge();

        // Filter to only product-related items
        allItems = allItems
            .where((item) =>
                item.category.toLowerCase().contains('produk') ||
                item.title.toLowerCase().contains('laptop') ||
                item.title.toLowerCase().contains('mouse') ||
                item.title.toLowerCase().contains('keyboard') ||
                item.title.toLowerCase().contains('printer'))
            .toList();

        // Try to get fresh product data from API for additional context
        try {
          final products = await ApiService.getProduk();
          if (products.isNotEmpty && products.length < 10) {
            // Only if reasonable number of products
            final now = DateTime.now();
            final apiItems = products
                .map((product) {
                  final nama =
                      product['nama_produk'] ?? product['name'] ?? 'Produk';
                  final harga = product['harga'] ?? product['price'] ?? 0;
                  final deskripsi = product['deskripsi'] ??
                      product['description'] ??
                      'Produk berkualitas tinggi';
                  final brand = product['brand'] ?? product['merk'] ?? '';

                  // Skip malformed products
                  if (nama.toString().isEmpty || harga == 0) return null;

                  return KnowledgeItem(
                    id: product['kode_barang'] ??
                        product['id_produk'] ??
                        product['id'] ??
                        'api_prod_${products.indexOf(product)}',
                    title: nama.toString(),
                    content:
                        '$deskripsi. Harga: Rp ${harga.toString()}. ${brand.isNotEmpty ? 'Brand: $brand.' : ''}',
                    category: 'Produk',
                    createdAt: now,
                    updatedAt: now,
                  );
                })
                .where((item) => item != null)
                .cast<KnowledgeItem>()
                .toList();

            // Add API items to the list if they're valid
            allItems.addAll(apiItems);
          }
        } catch (e) {
          // API failed, but we already have static knowledge
          print('Product API failed, using static knowledge: $e');
        }
        break;

      case QueryType.capabilities:
        // Special handling for capabilities questions
        final now = DateTime.now();
        allItems = [
          KnowledgeItem(
            id: 'ai_capabilities',
            title: 'Apa yang Bisa NanyaAzza Bantu?',
            content:
                '''Sebagai NanyaAzza, AI asisten E-Service, saya bisa membantu Anda dengan berbagai hal:

🛠️ **Service & Perbaikan:**
• Informasi harga service laptop, PC, printer
• Panduan cara pemesanan service
• Estimasi waktu pengerjaan
• Informasi garansi dan status service

💻 **Produk & Beli:**
• Informasi produk laptop, mouse, keyboard
• Harga dan spesifikasi produk
• Rekomendasi produk
• Ketersediaan stok

💰 **Pembayaran:**
• Metode pembayaran yang tersedia
• Informasi biaya service
• Panduan pembayaran

📍 **Lokasi & Kontak:**
• Alamat toko dan lokasi
• Jam operasional
• Informasi kontak

❓ **Bantuan Umum:**
• Panduan menggunakan aplikasi
• FAQ dan troubleshooting
• Informasi umum tentang layanan

💬 **Percakapan:**
• Menjawab pertanyaan seputar produk dan layanan
• Memberikan rekomendasi
• Membantu navigasi aplikasi

Untuk bantuan lebih spesifik, silakan tanyakan langsung apa yang Anda butuhkan!''',
            category: 'Bantuan',
            createdAt: now,
            updatedAt: now,
          )
        ];
        break;

      case QueryType.general:
        // Check if query has no recognized keywords - treat as general inquiry
        final hasAnyKeywords =
            QueryDetection.serviceKeywords.any((k) => q.contains(k)) ||
                QueryDetection.productKeywords.any((k) => q.contains(k)) ||
                q.contains('harga') ||
                q.contains('beli') ||
                q.contains('produk') ||
                q.contains('price') ||
                q.contains('service') ||
                q.contains('servis') ||
                q.contains('perbaikan') ||
                q.contains('benerin') ||
                q.contains('laptop') ||
                q.contains('komputer') ||
                q.contains('pc') ||
                q.contains('mouse') ||
                q.contains('gimana') ||
                q.contains('gmana') ||
                q.contains('bagaimana') ||
                q.contains('cara');

        if (!hasAnyKeywords) {
          // No keywords detected - treat as general/random inquiry
          final now = DateTime.now();
          allItems = [
            KnowledgeItem(
              id: 'general_inquiry',
              title: 'Pertanyaan Umum',
              content:
                  'Wah, pertanyaan yang menarik! 😊 Sebagai NanyaAzza, saya di sini untuk membantu Anda dengan segala hal tentang service komputer, produk elektronik, dan informasi aplikasi AzzaService. Ada yang bisa saya bantu seputar laptop, PC, printer, atau produk lainnya?',
              category: 'Bantuan',
              createdAt: now,
              updatedAt: now,
            )
          ];
        } else {
          // Use static knowledge for other queries
          allItems = await getAllKnowledge();
        }
        break;
    }

    // ===== FILTER AWAL BERDASARKAN INTENT =====
    List<KnowledgeItem> filtered = allItems;

    // Skip filtering for special cases that return specific data
    final specialCases = [
      QueryType.faq,
      QueryType.orderingService,
      QueryType.payment,
      QueryType.yesNo,
      QueryType.operatingHours,
      QueryType.complaint,
      QueryType.location,
      QueryType.serviceStatus,
      QueryType.capabilities
    ];

    if (!specialCases.contains(detectionResult.type)) {
      if (detectionResult.type == QueryType.service) {
        filtered = filtered.where((item) {
          final c = item.category.toLowerCase();
          return c.contains('service') ||
              c.contains('harga service') ||
              item.title.toLowerCase().contains('service');
        }).toList();
      }

      if (detectionResult.type == QueryType.product) {
        filtered = filtered.where((item) {
          return item.category.toLowerCase().contains('produk') ||
              item.title.toLowerCase().contains('laptop');
        }).toList();
      }
    }

    // ===== RANKING SCORE =====
    final List<_SearchResult> ranked = [];
    for (var item in filtered) {
      double score = 0;
      final text =
          "${item.title} ${item.content} ${item.category}".toLowerCase();

      // Kata cocok langsung
      if (text.contains(q)) score += 30;

      // Intent kuat
      if (q.contains('harga') && item.title.toLowerCase().contains('harga')) {
        score += 50;
      }

      if (q.contains('laptop') && item.title.toLowerCase().contains('laptop')) {
        score += 40;
      }

      // Brand matching - high priority for specific brand queries
      if (q.contains('lenovo') && text.contains('lenovo')) {
        score += 60;
      }
      if (q.contains('asus') && text.contains('asus')) {
        score += 60;
      }
      if (q.contains('hp') && text.contains('hp')) {
        score += 60;
      }
      if (q.contains('dell') && text.contains('dell')) {
        score += 60;
      }
      if (q.contains('msi') && text.contains('msi')) {
        score += 60;
      }

      // Fuzzy / similarity sederhana
      score += _similarity(q, text) * 20;

      ranked.add(_SearchResult(item: item, score: score));
    }

    // Urutkan berdasarkan skor tertinggi
    ranked.sort((a, b) => b.score.compareTo(a.score));

    return ranked.map((e) => e.item).toList();
  }

  // ===== similarity sederhana =====
  static double _similarity(String a, String b) {
    if (a == b) return 1.0;
    if (b.contains(a)) return 0.8;
    return 0.0;
  }

  // ===== get yes/no answer =====
  static String _getYesNoAnswer(String question) {
    final q = question.toLowerCase();

    // Questions about pickup/delivery
    if (q.contains('pickup') ||
        q.contains('antar') ||
        q.contains('kirim') ||
        q.contains('delivery')) {
      return 'Ya, tersedia layanan pickup & delivery area Jabodetabek dengan biaya mulai Rp 25.000.';
    }

    // Questions about warranty
    if (q.contains('garansi') || q.contains('jaminan')) {
      return 'Ya, semua service diberikan garansi 30 hari untuk perbaikan hardware, 7 hari untuk software.';
    }

    // Questions about payment methods
    if (q.contains('bayar') ||
        q.contains('pembayaran') ||
        q.contains('cod') ||
        q.contains('transfer')) {
      return 'Ya, menerima berbagai metode pembayaran: transfer bank, GoPay, OVO, Dana, kartu kredit, dan Midtrans.';
    }

    // Questions about availability
    if (q.contains('ada') || q.contains('tersedia') || q.contains('stok')) {
      return 'Ya, produk tersedia dalam berbagai merk dan spesifikasi. Silakan cek halaman Beli untuk ketersediaan terkini.';
    }

    // Questions about service availability
    if (q.contains('service') ||
        q.contains('perbaikan') ||
        q.contains('repair')) {
      // Check for unsupported services (vehicles, transportation, etc.)
      final unsupportedServiceKeywords = [
        'motor',
        'mobil',
        'kendaraan',
        'sepeda motor',
        'mobil',
        'truck',
        'truk',
        'bus',
        'kapal',
        'perahu',
        'helikopter',
        'pesawat',
        'kereta',
        'becak',
        'sepeda',
        'skuter',
        'vespa',
        'honda',
        'yamaha',
        'suzuki',
        'kawasaki',
        'mesin',
        'ban',
        'oli',
        'bensin',
        'solar',
        'transmisi',
        'rem',
        'kopling',
        'ac',
        'knalpot',
        'karburator',
        'piston',
        'roda',
        'velg',
        'shockbreaker'
      ];

      final containsUnsupported =
          unsupportedServiceKeywords.any((keyword) => q.contains(keyword));

      if (containsUnsupported) {
        return 'Maaf, kami tidak menyediakan layanan service untuk kendaraan bermotor, alat transportasi, atau mesin-mesin kendaraan. Kami fokus pada service perangkat komputer seperti laptop, PC, printer, dan perangkat elektronik lainnya.';
      } else {
        return 'Ya, kami menyediakan berbagai layanan service: laptop, PC, printer, dan cleaning perangkat komputer.';
      }
    }

    // Questions about operating hours
    if (q.contains('buka') || q.contains('operasional') || q.contains('jam')) {
      return 'Ya, kami buka Senin-Sabtu pukul 09.00-18.00 WIB, Minggu tutup.';
    }

    // Default yes answer for general questions
    return 'Ya, informasi lebih lengkap dapat dilihat di menu terkait atau hubungi CS di halaman Profile.';
  }

  // ============================================================
  // EXPORT KNOWLEDGE KE AI CONTEXT
  // ============================================================
  static Future<String> getKnowledgeAsContext() async {
    final allItems = await getAllKnowledge();
    if (allItems.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('INFORMASI TAMBAHAN DARI KNOWLEDGE BASE:\n');

    for (final item in allItems) {
      buffer.writeln('JUDUL: ${item.title}');
      buffer.writeln('KATEGORI: ${item.category}');
      buffer.writeln('KONTEN: ${item.content}');
      buffer.writeln('---');
    }

    return buffer.toString();
  }
}

class _SearchResult {
  final KnowledgeItem item;
  final double score;
  _SearchResult({required this.item, required this.score});
}
