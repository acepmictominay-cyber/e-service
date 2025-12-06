import 'dart:math';
import 'package:azza_service/services/context_manager.dart';

class ConversationEnhancer {
  // Topic-specific conversation starters and transitions
  static const Map<String, List<String>> _topicSpecificTransitions = {
    'service': [
      'Tentang service, ',
      'Untuk perbaikan, ',
      'Mengenai servis, ',
      'Soal perbaikan, ',
      'Baiklah, untuk service ',
      'Mengenai benerin, ',
      'Untuk repair, ',
    ],
    'product': [
      'Untuk produk, ',
      'Tentang laptop, ',
      'Mengenai beli, ',
      'Soal produk, ',
      'Baiklah, untuk pembelian ',
      'Tentang mouse, ',
      'Mengenai printer, ',
    ],
    'price': [
      'Soal harga, ',
      'Tentang biaya, ',
      'Mengenai tarif, ',
      'Untuk harga, ',
      'Baiklah, mengenai biaya ',
      'Tentang cost, ',
      'Mengenai payment, ',
    ],
    'location': [
      'Tentang lokasi, ',
      'Mengenai alamat, ',
      'Untuk toko, ',
      'Soal tempat, ',
      'Baiklah, mengenai lokasi ',
      'Tentang address, ',
      'Mengenai store, ',
    ],
    'payment': [
      'Tentang pembayaran, ',
      'Mengenai bayar, ',
      'Untuk payment, ',
      'Soal transfer, ',
      'Baiklah, mengenai metode bayar ',
    ],
    'warranty': [
      'Tentang garansi, ',
      'Mengenai jaminan, ',
      'Untuk warranty, ',
      'Soal garansi service, ',
      'Baiklah, mengenai garansi ',
    ],
    'general': [
      'Baiklah, ',
      'Oh, ',
      'Tentu, ',
      'Mengerti, ',
      'Oke, ',
      'Baik, ',
      'Silakan, ',
    ],
  };

  // Generic casual transitions for fallback
  static const List<String> _casualTransitions = [
    'Baiklah, ',
    'Oh, ',
    'Tentu, ',
    'Mengerti, ',
    'Oke, ',
    'Baik, ',
    'Silakan, ',
    'Boleh, ',
  ];

  static const List<String> _politeClosings = [
    ' Ada yang lain yang bisa saya bantu?',
    ' Butuh informasi lain?',
    ' Ada pertanyaan lainnya?',
    ' Perlu bantuan dengan hal lain?',
    ' Ada yang ingin ditanyakan lagi?',
  ];

  static const List<String> _enthusiasticResponses = [
    'Dengan senang hati saya bantu! ',
    'Tentu saja, saya siap membantu! ',
    'Baik, mari saya bantu! ',
    'Saya di sini untuk membantu Anda! ',
  ];

  static const List<String> _smallTalkResponses = [
    'Bagaimana kabar Anda hari ini?',
    'Semoga hari Anda menyenangkan!',
    'Ada yang bisa saya bantu lainnya?',
    'Jangan ragu untuk bertanya lagi ya!',
    'Saya selalu siap membantu Anda!',
  ];

  // Contextual follow-up suggestions based on topic
  static const Map<String, List<String>> _topicFollowUps = {
    'service': [
      'Apakah Anda ingin tahu estimasi waktu pengerjaan?',
      'Perlu informasi tentang garansi service?',
      'Ingin tahu cara tracking status service?',
      'Apakah ada gejala kerusakan spesifik yang ingin dijelaskan?',
    ],
    'product': [
      'Apakah Anda tertarik dengan spesifikasi lengkapnya?',
      'Ingin tahu harga dan ketersediaan stok?',
      'Perlu rekomendasi produk lainnya?',
      'Apakah ada fitur khusus yang Anda cari?',
    ],
    'location': [
      'Apakah Anda ingin tahu jam operasional?',
      'Perlu informasi kontak untuk reservasi?',
      'Ingin tahu cara menuju lokasi?',
      'Apakah ada layanan pickup & delivery?',
    ],
    'price': [
      'Apakah Anda ingin tahu metode pembayaran?',
      'Perlu informasi promo atau diskon?',
      'Ingin bandingkan dengan produk lain?',
      'Apakah ada paket service yang lebih hemat?',
    ],
    'general': [
      'Ada yang lain yang bisa saya bantu?',
      'Apakah ada pertanyaan lainnya?',
      'Perlu informasi tambahan?',
      'Ada topik lain yang ingin dibahas?',
    ],
  };

  static String enhanceResponse(
    String originalResponse, {
    String? topic,
    bool addFollowUp = true,
    bool makeCasual = false,
    bool addClosing = false,
  }) {
    String enhanced = originalResponse;

    // Skip casual enhancements for product queries to avoid confusion
    if (topic == 'product' || topic == 'produk') {
      makeCasual = false;
    }

    // Only add ONE type of enhancement to avoid duplicates
    bool enhancementAdded = false;

    // Add topic-specific or casual transition if requested (only if no other enhancement)
    if (makeCasual && !_isGreeting(originalResponse) && !enhancementAdded) {
      if (topic != null && _topicSpecificTransitions.containsKey(topic)) {
        // Use topic-specific transition
        final topicTransitions = _topicSpecificTransitions[topic]!;
        enhanced = _getRandomItem(topicTransitions) + enhanced.toLowerCase();
        enhancementAdded = true;
      } else {
        // Fallback to generic casual transition
        enhanced = _getRandomItem(_casualTransitions) + enhanced.toLowerCase();
        enhancementAdded = true;
      }
    }

    // Add enthusiastic opener for certain responses (only if no other enhancement)
    if (_shouldAddEnthusiasm(originalResponse) && !enhancementAdded) {
      enhanced = _getRandomItem(_enthusiasticResponses) + enhanced;
      enhancementAdded = true;
    }

    // Add follow-up suggestion based on topic (separate from conversational enhancements)
    if (addFollowUp && topic != null) {
      final followUps = _topicFollowUps[topic];
      if (followUps != null && followUps.isNotEmpty) {
        final followUp = _getRandomItem(followUps);
        enhanced += '\n\n💡 $followUp';
      }
    }

    // Add polite closing (separate from conversational enhancements)
    if (addClosing) {
      enhanced += _getRandomItem(_politeClosings);
    }

    return enhanced;
  }

  static String generateSmallTalk() {
    return _getRandomItem(_smallTalkResponses);
  }

  static String generateContextualGreeting() {
    // Disable conversation context for greetings to avoid confusion
    final now = DateTime.now();
    final hour = now.hour;

    // Enhanced time-based greetings with more flexible ranges
    String timeGreeting;
    if (hour >= 5 && hour < 11) {
      timeGreeting = 'Selamat pagi';
    } else if (hour >= 11 && hour < 15) {
      timeGreeting = 'Selamat siang';
    } else if (hour >= 15 && hour < 18) {
      timeGreeting = 'Selamat sore';
    } else {
      timeGreeting = 'Selamat malam';
    }

    // Add some variation to make it more natural
    final variations = [
      '$timeGreeting! ',
      '$timeGreeting 😊 ',
      '$timeGreeting 👋 ',
      'Halo, $timeGreeting! ',
    ];

    return _getRandomItem(variations);
  }

  static String generateFollowUpQuestion(String topic) {
    final followUps = _topicFollowUps[topic];
    if (followUps != null && followUps.isNotEmpty) {
      return _getRandomItem(followUps);
    }
    return 'Ada yang lain yang bisa saya bantu?';
  }

  static String addEmpathy(String response, String userQuery) {
    final q = userQuery.toLowerCase();

    // Add empathy for complaints or issues
    if (q.contains('kok') ||
        q.contains('kenapa') ||
        q.contains('masalah') ||
        q.contains('error') ||
        q.contains('rusak') ||
        q.contains('bermasalah')) {
      return 'Saya mengerti kekhawatiran Anda. $response';
    }

    // Add encouragement for questions
    if (q.contains('gimana') || q.contains('bagaimana') || q.contains('cara')) {
      return 'Tidak masalah, saya akan jelaskan. $response';
    }

    return response;
  }

  static String makeResponseMorePersonal(String response, String userQuery) {
    final q = userQuery.toLowerCase();

    // Personalize based on query type
    if (q.contains('saya') || q.contains('aku')) {
      // User is talking about themselves
      if (response.contains('Anda') || response.contains('anda')) {
        return response; // Already personalized
      }
    }

    // Add personal touch for first-time interactions
    if (!ContextManager.isContextValid()) {
      return '$response Senang bisa membantu Anda!';
    }

    return response;
  }

  // Helper methods
  static T _getRandomItem<T>(List<T> items) {
    if (items.isEmpty) return items.first;
    final random = Random();
    return items[random.nextInt(items.length)];
  }

  static bool _isGreeting(String response) {
    final greetings = [
      'halo',
      'hai',
      'selamat',
      'hi',
      'hello',
      'hey',
      'selamat pagi',
      'selamat siang',
      'selamat sore',
      'selamat malam',
      'pagi',
      'siang',
      'sore',
      'malam',
      'assalamualaikum',
      'salam'
    ];
    return greetings.any((g) => response.toLowerCase().contains(g));
  }

  static bool _shouldAddEnthusiasm(String response) {
    // Add enthusiasm for helpful responses
    return response.contains('bisa') ||
        response.contains('saya bantu') ||
        response.contains('informasi') ||
        response.length < 100; // Short responses
  }
}
