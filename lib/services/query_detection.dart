enum QueryType {
  faq,
  orderingService,
  capabilities,
  general,
  payment,
  yesNo,
  operatingHours,
  complaint,
  location,
  serviceStatus,
  service,
  product,
}

class QueryDetection {
  static const List<String> serviceKeywords = [
    'service',
    'perbaikan',
    'repair',
    'maintenance',
    'servis'
  ];

  static const List<String> productKeywords = [
    'produk',
    'product',
    'beli',
    'buy',
    'laptop',
    'pc',
    'printer',
    'mouse',
    'keyboard',
    'monitor',
    'speaker',
    'lenovo',
    'asus',
    'hp',
    'dell',
    'msi',
    'logitech',
    'razer',
    'steelseries'
  ];

  static QueryResult detectQueryType(String query) {
    final q = query.toLowerCase().trim();
    final entities = <String, dynamic>{};

    // Enhanced entity extraction first
    _extractEntities(q, entities);

    // Priority-based detection (most specific to general)

    // Complaint/Problem detection - highest priority
    if (_isComplaint(q)) {
      return QueryResult(QueryType.complaint, entities);
    }

    // Service status detection - high priority
    if (_isServiceStatusQuery(q)) {
      return QueryResult(QueryType.serviceStatus, entities);
    }

    // Ordering service detection
    if (_isOrderingServiceQuery(q)) {
      return QueryResult(QueryType.orderingService, entities);
    }

    // FAQ detection - app usage, registration, login, etc.
    if (_isFAQQuery(q)) {
      return QueryResult(QueryType.faq, entities);
    }

    // Capabilities detection - what can the bot do
    if (_isCapabilitiesQuery(q)) {
      return QueryResult(QueryType.capabilities, entities);
    }

    // Payment detection
    if (_isPaymentQuery(q)) {
      return QueryResult(QueryType.payment, entities);
    }

    // Product detection (moved up before yes/no)
    if (_isProductQuery(q)) {
      return QueryResult(QueryType.product, entities);
    }

    // Yes/No questions
    if (_isYesNoQuestion(q)) {
      return QueryResult(QueryType.yesNo, entities);
    }

    // Operating hours detection
    if (_isOperatingHoursQuery(q)) {
      return QueryResult(QueryType.operatingHours, entities);
    }

    // Location detection
    if (_isLocationQuery(q)) {
      return QueryResult(QueryType.location, entities);
    }

    // Service detection (general service questions)
    if (_isServiceQuery(q)) {
      return QueryResult(QueryType.service, entities);
    }

    // Default to general
    return QueryResult(QueryType.general, entities);
  }

  static bool _containsAny(String query, List<String> keywords) {
    return keywords.any((keyword) => query.contains(keyword));
  }

  static void _extractEntities(String query, Map<String, dynamic> entities) {
    final q = query.toLowerCase();

    // Product extraction
    if (q.contains('laptop') ||
        q.contains('komputer') ||
        q.contains('pc') ||
        q.contains('notebook')) {
      entities['product'] = 'laptop';
      entities['product_category'] = 'computer';

      // Extract brand for laptops
      if (q.contains('lenovo')) entities['brand'] = 'lenovo';
      if (q.contains('asus')) entities['brand'] = 'asus';
      if (q.contains('hp')) entities['brand'] = 'hp';
      if (q.contains('dell')) entities['brand'] = 'dell';
      if (q.contains('msi')) entities['brand'] = 'msi';
    } else if (q.contains('printer') ||
        q.contains('epson') ||
        q.contains('canon') ||
        q.contains('hp printer')) {
      entities['product'] = 'printer';
      entities['product_category'] = 'peripheral';
    } else if (q.contains('mouse') ||
        q.contains('keyboard') ||
        q.contains('monitor') ||
        q.contains('speaker')) {
      entities['product'] = 'peripheral';
      entities['product_category'] = 'accessory';
      if (q.contains('mouse')) entities['product'] = 'mouse';
      if (q.contains('keyboard')) entities['product'] = 'keyboard';

      // Extract brand for peripherals
      if (q.contains('logitech')) entities['brand'] = 'logitech';
      if (q.contains('razer')) entities['brand'] = 'razer';
      if (q.contains('steelseries')) entities['brand'] = 'steelseries';
    }

    // Service type extraction
    if (q.contains('cleaning') ||
        q.contains('bersih') ||
        q.contains('pembersihan')) {
      entities['service_type'] = 'cleaning';
    } else if (q.contains('perbaikan') ||
        q.contains('repair') ||
        q.contains('benerin') ||
        q.contains('rusak')) {
      entities['service_type'] = 'repair';
    } else if (q.contains('upgrade') ||
        q.contains('install') ||
        q.contains('pasang')) {
      entities['service_type'] = 'upgrade';
    }

    // Intent extraction
    if (_containsAny(
        q, ['harga', 'biaya', 'berapa', 'cost', 'price', 'tarif'])) {
      entities['intent'] = 'pricing';
    } else if (_containsAny(
        q, ['beli', 'pesan', 'purchase', 'order', 'checkout'])) {
      entities['intent'] = 'purchase';
    } else if (_containsAny(
        q, ['lokasi', 'alamat', 'dimana', 'where', 'tempat'])) {
      entities['intent'] = 'location';
    } else if (_containsAny(
        q, ['jam', 'waktu', 'operasional', 'buka', 'schedule'])) {
      entities['intent'] = 'schedule';
    } else if (_containsAny(
        q, ['bisa', 'dapat', 'mampu', 'available', 'tersedia'])) {
      entities['intent'] = 'availability';
    }

    // Urgency detection
    if (_containsAny(q, [
      'urgent',
      'segera',
      'cepat',
      'mendesak',
      'asap',
      'hari ini',
      'besok'
    ])) {
      entities['urgency'] = 'high';
    }

    // Sentiment detection
    if (_containsAny(
        q, ['bagus', 'baik', 'puas', 'senang', 'terima kasih', 'thanks'])) {
      entities['sentiment'] = 'positive';
    } else if (_containsAny(
        q, ['buruk', 'jelek', 'kecewa', 'marah', 'tidak puas', 'problem'])) {
      entities['sentiment'] = 'negative';
    }
  }

  static bool _isComplaint(String query) {
    return _containsAny(query, [
      'keluhan',
      'komplain',
      'complaint',
      'masalah',
      'problem',
      'error',
      'rusak',
      'tidak puas',
      'kecewa',
      'buruk',
      'jelek',
      'lambat',
      'lama',
      'susah',
      'tidak bisa',
      'gagal',
      'bermasalah',
      'broken',
      'not working'
    ]);
  }

  static bool _isServiceStatusQuery(String query) {
    return _containsAny(query, [
      'status service',
      'cek status',
      'tracking',
      'progress',
      'sudah selesai',
      'estimasi',
      'lama pengerjaan',
      'kapan selesai',
      'bagaimana progress',
      'service saya',
      'order saya',
      'pesanan saya'
    ]);
  }

  static bool _isOrderingServiceQuery(String query) {
    return _containsAny(query, [
      'pesan service',
      'order service',
      'booking service',
      'jadwal service',
      'appointment',
      'reservasi',
      'cara pesan',
      'cara order',
      'booking',
      'jadwal',
      'schedule service',
      'make appointment'
    ]);
  }

  static bool _isFAQQuery(String query) {
    return _containsAny(query, [
      'cara',
      'gimana',
      'bagaimana',
      'how to',
      'panduan',
      'tutorial',
      'daftar',
      'register',
      'login',
      'masuk',
      'reset password',
      'lupa password',
      'update profile',
      'notifikasi',
      'crash',
      'update aplikasi',
      'offline',
      'download',
      'install app',
      'gunakan aplikasi',
      'fitur aplikasi'
    ]);
  }

  static bool _isCapabilitiesQuery(String query) {
    return _containsAny(query, [
      'apa yang bisa',
      'what can you do',
      'kemampuan',
      'bisa bantu apa',
      'fitur',
      'function',
      'capabilities',
      'help',
      'bantuan',
      'apa saja',
      'layanan apa',
      'service apa'
    ]);
  }

  static bool _isPaymentQuery(String query) {
    final hasProductKeywords = _containsAny(query, productKeywords);
    if (hasProductKeywords) {
      return false;
    }
    return _containsAny(query, [
      'bayar',
      'pembayaran',
      'payment',
      'transfer',
      'midtrans',
      'gopay',
      'ovo',
      'dana',
      'kartu kredit',
      'cod',
      'harga service',
      'biaya service',
      'berapa harganya',
      'cost',
      'harga',
      'biaya',
      'tarif'
    ]);
  }

  static bool _isOperatingHoursQuery(String query) {
    return _containsAny(query, [
      'jam operasional',
      'jam buka',
      'operating hours',
      'waktu buka',
      'schedule',
      'senin',
      'selasa',
      'rabu',
      'kamis',
      'jumat',
      'sabtu',
      'minggu',
      'hari apa',
      'kapan buka',
      'sampai jam berapa'
    ]);
  }

  static bool _isLocationQuery(String query) {
    return _containsAny(query, [
      'lokasi',
      'alamat',
      'address',
      'tempat',
      'dimana',
      'where',
      'toko',
      'store',
      'cabang',
      'branch',
      'office',
      'kantor'
    ]);
  }

  static bool _isProductQuery(String query) {
    return _containsAny(query, [
      'produk',
      'product',
      'beli',
      'buy',
      'laptop',
      'komputer',
      'pc',
      'printer',
      'mouse',
      'keyboard',
      'monitor',
      'speaker',
      'harga produk',
      'spesifikasi',
      'stok',
      'tersedia',
      'available',
      'stock'
    ]);
  }

  static bool _isServiceQuery(String query) {
    return _containsAny(query, [
      'service',
      'servis',
      'perbaikan',
      'repair',
      'maintenance',
      'benerin',
      'fix',
      'cleaning',
      'bersih',
      'upgrade',
      'install',
      'pasang'
    ]);
  }

  static bool _isYesNoQuestion(String query) {
    // Check for yes/no question patterns
    final yesNoIndicators = [
      'apakah',
      'apa',
      'benarkah',
      'betulkah',
      'sudah',
      'masih',
      'bisa',
      'boleh',
      'tersedia',
      'menerima',
      'apakah bisa'
    ];
    final questionWords = ['?', 'kah', 'kah?', 'ya?', 'tidak?', 'tidak kah'];

    // Must contain question indicator and yes/no keyword
    // But exclude if it contains product keywords (should be handled by product detection)
    final hasProductKeywords = _containsAny(query, productKeywords);
    if (hasProductKeywords) {
      return false; // Let product detection handle it
    }

    return questionWords.any((qw) => query.contains(qw)) &&
        yesNoIndicators.any((indicator) => query.contains(indicator));
  }
}

class QueryResult {
  final QueryType type;
  final Map<String, dynamic> entities;

  QueryResult(this.type, this.entities);
}
