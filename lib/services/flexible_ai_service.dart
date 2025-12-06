import 'package:azza_service/services/knowledge_service.dart';
import 'package:azza_service/services/context_manager.dart';
import 'package:azza_service/services/query_detection.dart';
import 'package:azza_service/services/conversation_enhancer.dart';

class FlexibleAIResponse {
  final String response;
  final String confidence;
  final Map<String, dynamic> metadata;

  FlexibleAIResponse({
    required this.response,
    required this.confidence,
    this.metadata = const {},
  });
}

class FlexibleAIService {
  // Flexible query understanding with synonyms and variations
  static const Map<String, List<String>> _querySynonyms = {
    'service': ['servis', 'perbaikan', 'benerin', 'repair', 'fix', 'servicean'],
    'harga': ['biaya', 'price', 'cost', 'berapa', 'mahal', 'murah'],
    'beli': ['purchase', 'buy', 'order', 'pesan', 'checkout'],
    'produk': ['barang', 'item', 'product', 'goods', 'stuff'],
    'lokasi': ['alamat', 'tempat', 'address', 'location', 'dimana'],
    'jam': ['waktu', 'time', 'schedule', 'operasional'],
    'bisa': ['could', 'can', 'able', 'mampu', 'dapat'],
    'tolong': ['help', 'bantu', 'assist', 'aid'],
    'gimana': ['bagaimana', 'how', 'gimana caranya', 'cara'],
    'apa': ['what', 'yang mana', 'which'],
  };

  // Flexible query preprocessing
  static String _preprocessQuery(String query) {
    String processed = query.toLowerCase().trim();

    // Expand contractions and slang
    processed = processed
        .replaceAll('gak', 'tidak')
        .replaceAll('nggak', 'tidak')
        .replaceAll('gk', 'tidak')
        .replaceAll('ga', 'tidak')
        .replaceAll('mau', 'ingin')
        .replaceAll('pengenn', 'ingin')
        .replaceAll('kmrn', 'kemarin')
        .replaceAll('skrg', 'sekarang')
        .replaceAll('brp', 'berapa')
        .replaceAll('dr', 'dari')
        .replaceAll('ke', 'menuju')
        .replaceAll('jg', 'juga')
        .replaceAll('lg', 'lagi')
        .replaceAll('udh', 'sudah')
        .replaceAll('udah', 'sudah');

    return processed;
  }

  // Enhanced entity extraction with flexibility
  static Map<String, dynamic> _extractFlexibleEntities(String query) {
    final entities = <String, dynamic>{};
    final processedQuery = _preprocessQuery(query);

    // Product detection with synonyms
    final productKeywords = _querySynonyms['produk']!;
    if (productKeywords.any((keyword) => processedQuery.contains(keyword))) {
      // Check for specific product types
      if (processedQuery.contains('laptop') ||
          processedQuery.contains('komputer') ||
          processedQuery.contains('pc')) {
        entities['product'] = 'laptop';
        entities['product_category'] = 'computer';
      } else if (processedQuery.contains('printer') ||
          processedQuery.contains('epson') ||
          processedQuery.contains('canon')) {
        entities['product'] = 'printer';
        entities['product_category'] = 'peripheral';
      } else if (processedQuery.contains('mouse') ||
          processedQuery.contains('keyboard')) {
        entities['product'] = 'peripheral';
        entities['product_category'] = 'accessory';
      }
    }

    // Service type detection
    final serviceKeywords = _querySynonyms['service']!;
    if (serviceKeywords.any((keyword) => processedQuery.contains(keyword))) {
      if (processedQuery.contains('perbaikan') ||
          processedQuery.contains('repair') ||
          processedQuery.contains('benerin')) {
        entities['service_type'] = 'repair';
      } else if (processedQuery.contains('cleaning') ||
          processedQuery.contains('bersih')) {
        entities['service_type'] = 'cleaning';
      }
    }

    // Intent detection
    if (processedQuery.contains('harga') ||
        processedQuery.contains('biaya') ||
        processedQuery.contains('berapa')) {
      entities['intent'] = 'pricing';
    } else if (processedQuery.contains('beli') ||
        processedQuery.contains('pesan') ||
        processedQuery.contains('order')) {
      entities['intent'] = 'purchase';
    } else if (processedQuery.contains('lokasi') ||
        processedQuery.contains('alamat') ||
        processedQuery.contains('dimana')) {
      entities['intent'] = 'location';
    } else if (processedQuery.contains('jam') ||
        processedQuery.contains('waktu') ||
        processedQuery.contains('operasional')) {
      entities['intent'] = 'schedule';
    }

    return entities;
  }

  // Intelligent fallback with suggestions
  static Future<String> _generateIntelligentFallback(String query) async {
    final entities = _extractFlexibleEntities(query);
    final processedQuery = _preprocessQuery(query);

    // Try to find related knowledge even if direct match fails
    final allKnowledge = await KnowledgeService.getAllKnowledge();

    // Find knowledge items that might be related using fuzzy matching
    final relatedItems = allKnowledge.where((item) {
      final itemText =
          '${item.title} ${item.content} ${item.category}'.toLowerCase();
      final queryWords = processedQuery.split(' ');

      // Check if query contains keywords from knowledge items
      final directMatches = queryWords
          .where((word) => itemText.contains(word) && word.length > 2)
          .length;

      // Calculate relevance score
      final score = directMatches / queryWords.length;
      return score > 0.2; // At least 20% word match
    }).toList();

    if (relatedItems.isNotEmpty) {
      final bestMatch = relatedItems.first;
      return ConversationEnhancer.enhanceResponse(
        bestMatch.content,
        topic: bestMatch.category.toLowerCase(),
        addFollowUp: true,
        makeCasual: false,
      );
    }

    // Generate contextual suggestions based on detected entities and conversation history
    String suggestion = _generateContextualSuggestion(query, entities);

    // Add conversation context if available
    final conversationSummary = ContextManager.getConversationSummary();
    if (conversationSummary.isNotEmpty) {
      suggestion = '$conversationSummary\n\n$suggestion';
    }

    return ConversationEnhancer.enhanceResponse(
      'Saya akan membantu Anda dengan informasi yang tersedia. $suggestion',
      addFollowUp: true,
      makeCasual: true,
    );
  }

  static String _generateContextualSuggestion(
      String query, Map<String, dynamic> entities) {
    final processedQuery = _preprocessQuery(query);

    // Check for common customer service scenarios
    if (_containsAny(processedQuery,
        ['tidak bisa', 'error', 'bermasalah', 'rusak', 'mati'])) {
      return 'Untuk masalah teknis, sebaiknya bawa device ke toko kami atau hubungi teknisi. Kami siap membantu diagnosa dan perbaikan.';
    }

    if (_containsAny(
        processedQuery, ['kapan', 'berapa lama', 'estimasi waktu'])) {
      return 'Estimasi waktu service tergantung kompleksitas masalah. Untuk informasi akurat, silakan konsultasikan dengan teknisi kami.';
    }

    if (_containsAny(processedQuery, ['mahal', 'murah', 'nego', 'diskon'])) {
      return 'Harga service kami sudah competitive dengan garansi resmi. Tanyakan promo terbaru atau paket service hemat kami.';
    }

    if (_containsAny(processedQuery, ['jaminan', 'garansi', 'klaim'])) {
      return 'Semua service kami memberikan garansi resmi. Simpan nota service untuk klaim garansi di kemudian hari.';
    }

    // Generate suggestions based on entities
    if (entities['product'] != null) {
      final product = entities['product'];
      return 'Untuk informasi lengkap tentang $product, Anda bisa kunjungi menu "Beli" atau tanyakan spesifikasi, harga, dan ketersediaan stok.';
    }

    if (entities['service_type'] != null) {
      final serviceType = entities['service_type'];
      return 'Untuk layanan $serviceType, kami menyediakan berbagai paket mulai dari basic hingga premium. Tanyakan detail harga dan estimasi waktu.';
    }

    if (entities['intent'] == 'pricing') {
      return 'Informasi harga service dan produk tersedia di aplikasi. Cek menu "Service" untuk harga perbaikan atau menu "Beli" untuk harga produk.';
    }

    if (entities['intent'] == 'location') {
      return 'Toko kami berlokasi di Cibubur, Jakarta Timur. Layanan pickup & delivery tersedia untuk area Jabodetabek dengan biaya terjangkau.';
    }

    if (entities['intent'] == 'schedule') {
      return 'Jam operasional toko: Senin-Sabtu pukul 08:00-17:00 WIB. Customer service via WhatsApp tersedia selama jam kerja.';
    }

    if (entities['urgency'] == 'high') {
      return 'Untuk keadaan urgent, hubungi emergency hotline kami di 0812-3456-7890. Kami prioritaskan handling kasus darurat dengan response time 2-4 jam.';
    }

    // Generic helpful responses with personality
    final genericSuggestions = [
      'Coba tanyakan tentang produk seperti "harga laptop gaming" atau service seperti "biaya service printer".',
      'Anda bisa tanya tentang lokasi toko, jam operasional, atau metode pembayaran yang tersedia.',
      'Informasi tentang garansi service, pickup & delivery, atau konsultasi teknis juga tersedia.',
      'Tanyakan tentang promo terbaru, paket service hemat, atau layanan emergency kami.',
      'Butuh bantuan dengan aplikasi? Tanyakan tentang cara daftar, login, atau fitur-fitur yang tersedia.',
    ];

    return genericSuggestions[
        DateTime.now().millisecondsSinceEpoch % genericSuggestions.length];
  }

  // Adaptive response based on conversation history
  static String _adaptResponseToHistory(String baseResponse, String userQuery) {
    final context = ContextManager.getCurrentContext();

    if (context != null) {
      final timeSinceLastInteraction =
          DateTime.now().difference(context.timestamp);

      // If returning user, acknowledge previous context
      if (timeSinceLastInteraction.inHours < 24) {
        return 'Selamat datang kembali! $baseResponse';
      }
    }

    return baseResponse;
  }

  // Main flexible response method
  static Future<FlexibleAIResponse> getFlexibleResponse(
      String userMessage) async {
    try {
      // Preprocess and enhance query
      final enhancedQuery = ContextManager.enhanceQueryWithContext(userMessage);
      final processedQuery = _preprocessQuery(enhancedQuery);
      final entities = _extractFlexibleEntities(processedQuery);

      // Try standard query detection first
      final detectionResult = QueryDetection.detectQueryType(processedQuery);

      // If we have a clear detection, use knowledge base
      if (detectionResult.type != QueryType.general) {
        final knowledgeResults =
            await KnowledgeService.searchKnowledge(processedQuery);

        if (knowledgeResults.isNotEmpty) {
          final knowledge = knowledgeResults.first;
          String contextTopic = 'general';

          // Determine context topic from entities
          if (entities['product'] != null) {
            contextTopic = 'product';
          } else if (entities['service_type'] != null)
            contextTopic = 'service';
          else if (entities['intent'] == 'pricing')
            contextTopic = 'price';
          else if (entities['intent'] == 'location') contextTopic = 'location';

          final enhancedResponse = ConversationEnhancer.enhanceResponse(
            knowledge.content,
            topic: contextTopic,
            addFollowUp: true,
            makeCasual: true,
          );

          final adaptedResponse =
              _adaptResponseToHistory(enhancedResponse, userMessage);

          return FlexibleAIResponse(
            response: adaptedResponse,
            confidence: 'high',
            metadata: {
              'detection_type': detectionResult.type.toString(),
              'entities': entities,
              'knowledge_used': true,
            },
          );
        }
      }

      // If no clear detection or knowledge found, use intelligent fallback
      final fallbackResponse =
          await _generateIntelligentFallback(processedQuery);
      final adaptedFallback =
          _adaptResponseToHistory(fallbackResponse, userMessage);

      return FlexibleAIResponse(
        response: adaptedFallback,
        confidence: 'medium',
        metadata: {
          'detection_type': 'fallback',
          'entities': entities,
          'knowledge_used': false,
        },
      );
    } catch (e) {
      // Ultimate fallback for errors
      return FlexibleAIResponse(
        response: ConversationEnhancer.enhanceResponse(
          'Maaf, terjadi kesalahan. Silakan coba lagi atau hubungi customer service kami.',
          addFollowUp: true,
        ),
        confidence: 'low',
        metadata: {'error': e.toString()},
      );
    }
  }

  // Method to get response suggestions for ambiguous queries
  static List<String> getResponseSuggestions(String query) {
    final entities = _extractFlexibleEntities(query);
    final suggestions = <String>[];

    if (entities['product'] != null) {
      suggestions.addAll([
        'Tanya harga ${entities['product']}',
        'Tanya spesifikasi ${entities['product']}',
        'Tanya ketersediaan ${entities['product']}',
      ]);
    }

    if (entities['service_type'] != null) {
      suggestions.addAll([
        'Tanya estimasi waktu ${entities['service_type']}',
        'Tanya harga ${entities['service_type']}',
        'Tanya cara pesan ${entities['service_type']}',
      ]);
    }

    if (entities['intent'] == 'pricing') {
      suggestions.addAll([
        'Tanya harga service laptop',
        'Tanya harga produk',
        'Tanya metode pembayaran',
      ]);
    }

    // Generic suggestions if no specific entities
    if (suggestions.isEmpty) {
      suggestions.addAll([
        'Tanya tentang produk',
        'Tanya tentang service',
        'Tanya tentang lokasi toko',
        'Tanya tentang jam operasional',
      ]);
    }

    return suggestions.take(3).toList(); // Return top 3 suggestions
  }

  // Helper method to check if query contains any of the keywords
  static bool _containsAny(String query, List<String> keywords) {
    return keywords.any((keyword) => query.contains(keyword));
  }

  // Method to check if query needs clarification
  static bool needsClarification(String query) {
    final processedQuery = _preprocessQuery(query);
    final entities = _extractFlexibleEntities(processedQuery);

    // Check for ambiguous terms
    final ambiguousTerms = [
      'itu',
      'ini',
      'yang',
      'situ',
      'sana',
      'tadi',
      'kemarin'
    ];

    return ambiguousTerms.any((term) => processedQuery.contains(term)) ||
        entities.isEmpty ||
        (processedQuery.split(' ').length < 3); // Very short queries
  }
}
