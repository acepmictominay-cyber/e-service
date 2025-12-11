import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:azza_service/config/api_config.dart';
import 'package:azza_service/services/knowledge_service.dart';
import 'package:azza_service/services/context_manager.dart';
import 'package:azza_service/services/query_detection.dart';
import 'package:azza_service/services/conversation_enhancer.dart';
import 'package:azza_service/services/flexible_ai_service.dart';
import 'package:azza_service/api_services/api_service.dart';

class ChatResponse {
  final String text;
  final List<Map<String, dynamic>>? recommendedProducts;

  ChatResponse({required this.text, this.recommendedProducts});
}

class AIChatService {
  static const String _openAIUrl = 'https://api.openai.com/v1/chat/completions';

  static Future<ChatResponse> getAIResponse(String userMessage) async {
    // Use consolidated query detection first to determine query type
    final initialDetection = QueryDetection.detectQueryType(userMessage);

    // Skip conversation context enhancement for product queries to avoid confusion
    final enhancedQuery = (initialDetection.type == QueryType.product)
        ? userMessage
        : ContextManager.enhanceQueryWithContext(userMessage);

    final entities = ContextManager.extractEntities(enhancedQuery);
    // Use consolidated query detection on enhanced query
    final detectionResult = QueryDetection.detectQueryType(enhancedQuery);

    // Handle direct knowledge queries first
    if (detectionResult.type == QueryType.faq ||
        detectionResult.type == QueryType.orderingService ||
        detectionResult.type == QueryType.capabilities ||
        detectionResult.type == QueryType.product) {
      // For product queries that seem to be asking for recommendations/availability,
      // skip knowledge search and go directly to product recommendations
      final isRecommendationQuery = detectionResult.type == QueryType.product &&
          _isProductRecommendationQuery(enhancedQuery);

      if (!isRecommendationQuery) {
        final relevantKnowledge =
            await KnowledgeService.searchKnowledge(enhancedQuery);
        if (relevantKnowledge.isNotEmpty) {
          final knowledge = relevantKnowledge.first;

          // Update context based on response
          String contextTopic = 'general';
          if (entities['product'] != null) {
            contextTopic = 'product';
            ContextManager.updateContext('product',
                product: entities['product'], originalQuery: userMessage);
          } else if (enhancedQuery.toLowerCase().contains('lokasi') ||
              enhancedQuery.toLowerCase().contains('alamat') ||
              enhancedQuery.toLowerCase().contains('toko')) {
            contextTopic = 'location';
            ContextManager.updateContext('location',
                originalQuery: userMessage);
          } else if (enhancedQuery.toLowerCase().contains('harga') ||
              enhancedQuery.toLowerCase().contains('biaya')) {
            contextTopic = 'price';
            ContextManager.updateContext('price',
                product: entities['product'], originalQuery: userMessage);
          } else if (detectionResult.type == QueryType.orderingService) {
            contextTopic = 'service';
            ContextManager.updateContext('service',
                serviceType: entities['service_type'],
                originalQuery: userMessage);
          } else if (detectionResult.type == QueryType.capabilities) {
            contextTopic = 'general';
            ContextManager.updateContext('general', originalQuery: userMessage);
          }

          // Create conversational response without template
          String baseResponse = knowledge.content;

          // For product queries, add product recommendations
          List<Map<String, dynamic>>? recommendedProducts;
          if (detectionResult.type == QueryType.product) {
            recommendedProducts =
                await _getRecommendedProducts(enhancedQuery, entities);
            if (recommendedProducts != null && recommendedProducts.isNotEmpty) {
              baseResponse +=
                  '\n\nBerikut beberapa produk yang sesuai dengan permintaan Anda:';
            }
          }

          String enhancedResponse = ConversationEnhancer.enhanceResponse(
            baseResponse,
            topic: contextTopic,
            addFollowUp: true,
            makeCasual: false, // Disable casual transitions to avoid duplicates
          );

          return ChatResponse(
              text: enhancedResponse, recommendedProducts: recommendedProducts);
        }
      }

      // For product recommendation queries or when no knowledge is found, proceed with AI response
      if (detectionResult.type == QueryType.product) {
        // Get product recommendations
        final recommendedProducts =
            await _getRecommendedProducts(enhancedQuery, entities);
        final baseResponse = recommendedProducts != null &&
                recommendedProducts.isNotEmpty
            ? 'Berdasarkan permintaan Anda, berikut beberapa rekomendasi produk yang sesuai:'
            : 'Maaf, saat ini tidak ada produk yang sesuai dengan kriteria Anda. Silakan cek halaman Beli untuk pilihan produk lainnya.';

        String enhancedResponse = ConversationEnhancer.enhanceResponse(
          baseResponse,
          topic: 'product',
          addFollowUp: true,
          makeCasual: false,
        );

        return ChatResponse(
            text: enhancedResponse, recommendedProducts: recommendedProducts);
      }

      if (detectionResult.type == QueryType.general) {
        // For general queries that don't match knowledge, try flexible AI
        final flexibleResponse =
            await FlexibleAIService.getFlexibleResponse(userMessage);
        return ChatResponse(text: flexibleResponse.response);
      }
    }

    // Check if API key is configured
    if (ApiConfig.openAIApiKey.isEmpty ||
        ApiConfig.openAIApiKey == 'YOUR_OPENAI_API_KEY') {
      return await _getFallbackResponse(userMessage);
    }

    try {
      // Get knowledge context
      final knowledgeContext = await KnowledgeService.getKnowledgeAsContext();

      // Create system prompt with knowledge base
      final systemPrompt = '''
Anda adalah NanyaAzza, AI asisten untuk aplikasi AzzaService yang menyediakan layanan service dan penjualan produk komputer/elektronik.

INFORMASI PENTING:
- Nama Anda adalah NanyaAzza
- Anda adalah asisten yang membantu, profesional, dan ramah
- Jawab dalam bahasa Indonesia dengan gaya percakapan yang natural
- Kami menyediakan: service laptop, PC, printer, cleaning perangkat, dan penjualan produk seperti mouse, keyboard, laptop
- Kami TIDAK menyediakan layanan service untuk motor, mobil, atau kendaraan bermotor lainnya

PERATURAN MENJAWAB:
- Untuk pertanyaan random atau di luar konteks (seperti "apakah Anda punya jempol?"): Jawab dengan natural dan lucu, tapi selalu arahkan kembali ke topik aplikasi/store
- Untuk pertanyaan di luar scope layanan kami: Jelaskan dengan sopan bahwa kami fokus pada komputer/elektronik, tapi tetap jawab pertanyaan tersebut jika memungkinkan
- Selalu gunakan informasi dari knowledge base yang disediakan
- Jika informasi tidak tersedia, berikan jawaban umum yang berguna tentang layanan kami
- Untuk pertanyaan teknis sensitif (seperti database, server), jangan berikan detail spesifik
- Akhiri jawaban dengan mengajak user bertanya tentang produk atau layanan kami
- Selalu perkenalkan diri sebagai NanyaAzza saat diperlukan

${knowledgeContext.isNotEmpty ? knowledgeContext : 'Knowledge base sedang dimuat...'}
      ''';

      // Prepare request body
      final requestBody = {
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': systemPrompt,
          },
          {
            'role': 'user',
            'content': userMessage,
          }
        ],
        'max_tokens': 500,
        'temperature': 0.7,
      };

      // Make API request
      final response = await http.post(
        Uri.parse(_openAIUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.openAIApiKey}',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['choices'][0]['message']['content'] as String;

        // Update context based on AI response analysis
        final responseLower = aiResponse.toLowerCase();
        String contextTopic = 'general';
        if (responseLower.contains('lokasi') ||
            responseLower.contains('alamat') ||
            responseLower.contains('toko')) {
          contextTopic = 'location';
          ContextManager.updateContext('location',
              product: entities['product'], originalQuery: userMessage);
        } else if (responseLower.contains('harga') ||
            responseLower.contains('biaya') ||
            responseLower.contains('rp')) {
          contextTopic = 'price';
          ContextManager.updateContext('price',
              product: entities['product'], originalQuery: userMessage);
        } else if (responseLower.contains('service') ||
            responseLower.contains('perbaikan')) {
          contextTopic = 'service';
          ContextManager.updateContext('service',
              serviceType: entities['service_type'],
              originalQuery: userMessage);
        } else if (entities['product'] != null) {
          contextTopic = 'product';
          ContextManager.updateContext('product',
              product: entities['product'], originalQuery: userMessage);
        }

        // For product queries, add product recommendations
        List<Map<String, dynamic>>? recommendedProducts;
        if (detectionResult.type == QueryType.product) {
          recommendedProducts =
              await _getRecommendedProducts(enhancedQuery, entities);
        }

        // Make AI response more conversational (avoid duplicate enhancements)
        String enhancedResponse = ConversationEnhancer.enhanceResponse(
          aiResponse.trim(),
          topic: contextTopic,
          addFollowUp: true,
          addClosing:
              false, // Disable closing to avoid conflicts with system prompt
          makeCasual: false, // Disable casual transitions to avoid duplicates
        );

        return ChatResponse(
            text: enhancedResponse, recommendedProducts: recommendedProducts);
      } else {
        // Fallback to manual response if API fails
        return await _getFallbackResponse(userMessage);
      }
    } catch (e) {
      // Fallback to manual response if AI fails
      return await _getFallbackResponse(userMessage);
    }
  }

  static Future<List<Map<String, dynamic>>?> _getRecommendedProducts(
      String query, Map<String, dynamic> entities) async {
    try {
      final allProducts = await ApiService.getProduk();
      if (allProducts.isEmpty) return null;

      // Filter products based on query
      List<Map<String, dynamic>> filteredProducts =
          _filterProducts(allProducts, query, entities);

      // Sort by price (cheapest first) and take top 3
      filteredProducts.sort((a, b) {
        final priceA = _parsePrice(a['harga']);
        final priceB = _parsePrice(b['harga']);
        return priceA.compareTo(priceB);
      });

      return filteredProducts.take(3).toList();
    } catch (e) {
      return null;
    }
  }

  static List<Map<String, dynamic>> _filterProducts(
      List<dynamic> products, String query, Map<String, dynamic> entities) {
    final queryLower = query.toLowerCase();

    // First, try to filter by specific product type if detected
    List<Map<String, dynamic>> filtered = products
        .where((product) {
          final productName =
              (product['nama_produk'] ?? '').toString().toLowerCase();
          final description =
              (product['deskripsi'] ?? '').toString().toLowerCase();

          // Check for product type matches
          bool matchesType = true;
          bool isGamingQuery =
              queryLower.contains('gaming') || queryLower.contains('game');

          if (entities['product'] == 'laptop') {
            // For laptop queries, accept products with laptop keywords or common laptop brands
            matchesType = productName.contains('laptop') ||
                productName.contains('notebook') ||
                productName.contains('komputer') ||
                productName.contains('pc') ||
                productName.contains('asus') ||
                productName.contains('lenovo') ||
                productName.contains('acer') ||
                productName.contains('hp') ||
                productName.contains('dell') ||
                productName.contains('msi') ||
                productName.contains('apple') ||
                productName.contains('macbook') ||
                productName.contains('thinkpad') ||
                productName.contains('ideapad') ||
                productName.contains('vivobook') ||
                productName.contains('aspire') ||
                productName.contains('inspiron') ||
                productName.contains('latitude') ||
                productName.contains('rog') ||
                productName.contains('strix') ||
                productName.contains('legion') ||
                productName.contains('predator') ||
                productName.contains('tuf') ||
                productName.contains('nitro') ||
                productName.contains('omen') ||
                productName.contains('alienware');
          } else if (entities['product'] == 'printer') {
            matchesType = productName.contains('printer') ||
                productName.contains('print');
          } else if (entities['product'] == 'mouse') {
            matchesType = productName.contains('mouse');
          } else if (entities['product'] == 'keyboard') {
            matchesType = productName.contains('keyboard') ||
                productName.contains('keypad');
          }

          // If no specific product type detected, match any product that contains keywords from the query
          if (entities['product'] == null) {
            matchesType = queryLower.split(' ').any((word) =>
                word.length > 2 &&
                (productName.contains(word) || description.contains(word)));
          }

          // Check for usage type
          bool matchesUsage = true;
          if (queryLower.contains('gaming') || queryLower.contains('game')) {
            // Expanded gaming keywords to include common gaming laptop brands/series
            matchesUsage = productName.contains('gaming') ||
                description.contains('gaming') ||
                productName.contains('game') ||
                description.contains('game') ||
                productName.contains('rog') ||
                description.contains('rog') ||
                productName.contains('strix') ||
                description.contains('strix') ||
                productName.contains('legion') ||
                description.contains('legion') ||
                productName.contains('predator') ||
                description.contains('predator') ||
                productName.contains('tuf gaming') ||
                description.contains('tuf gaming') ||
                productName.contains('nitro') ||
                description.contains('nitro') ||
                productName.contains('omen') ||
                description.contains('omen') ||
                productName.contains('alienware') ||
                description.contains('alienware') ||
                productName.contains('gs') && productName.contains('asus') ||
                description.contains('gs') && description.contains('asus') ||
                productName.contains('gf') && productName.contains('msi') ||
                description.contains('gf') && description.contains('msi');
          } else if (queryLower.contains('kantor') ||
              queryLower.contains('office')) {
            matchesUsage = productName.contains('office') ||
                description.contains('office') ||
                productName.contains('business') ||
                description.contains('business');
          } else if (queryLower.contains('mahasiswa') ||
              queryLower.contains('kuliah') ||
              queryLower.contains('student')) {
            matchesUsage = productName.contains('student') ||
                description.contains('student') ||
                productName.contains('education') ||
                description.contains('education');
          }

          return matchesType && matchesUsage;
        })
        .toList()
        .cast<Map<String, dynamic>>();

    // If no products match the strict criteria, return some products anyway
    // This ensures we always show something for product queries
    // But for gaming queries, don't fallback to regular products
    if (filtered.isEmpty && products.isNotEmpty) {
      if (queryLower.contains('gaming') || queryLower.contains('game')) {
        // For gaming queries, don't show regular products as fallback
        // Return empty list so the caller knows no gaming products found
        filtered = [];
      } else {
        // Return first few products as general recommendations
        filtered = products.take(3).toList().cast<Map<String, dynamic>>();
      }
    }

    return filtered;
  }

  static double _parsePrice(dynamic price) {
    if (price == null) return double.infinity;
    if (price is num) return price.toDouble();
    if (price is String) {
      final cleaned = price.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned) ?? double.infinity;
    }
    return double.infinity;
  }

  static bool _isProductRecommendationQuery(String query) {
    final q = query.toLowerCase();

    // Keywords that indicate user is asking for product recommendations/availability
    final recommendationKeywords = [
      'apa ya',
      'yang mana',
      'rekomendasi',
      'saran',
      'pilih',
      'beli',
      'ada',
      'tersedia',
      'murah',
      'mahal',
      'bagus',
      'terbaik',
      'cocok',
      'untuk',
      'gaming',
      'game',
      'kantor',
      'office',
      'kerja',
      'kuliah',
      'mahasiswa',
      'student',
      'sekolah',
      'school'
    ];

    // If query contains recommendation keywords, it's likely asking for product suggestions
    return recommendationKeywords.any((keyword) => q.contains(keyword));
  }

  static Future<ChatResponse> _getFallbackResponse(String userMessage) async {
    // Check for greetings first
    if (_isGreeting(userMessage.toLowerCase())) {
      return ChatResponse(text: _getGreetingResponse());
    }

    // Use Flexible AI Service for more intelligent fallback
    try {
      final flexibleResponse =
          await FlexibleAIService.getFlexibleResponse(userMessage);

      // Update context based on flexible response metadata
      final metadata = flexibleResponse.metadata;
      if (metadata['entities'] != null) {
        final entities = metadata['entities'] as Map<String, dynamic>;
        if (entities['product'] != null) {
          ContextManager.updateContext('product',
              product: entities['product'], originalQuery: userMessage);
        } else if (entities['intent'] == 'location') {
          ContextManager.updateContext('location', originalQuery: userMessage);
        } else if (entities['intent'] == 'pricing') {
          ContextManager.updateContext('price',
              product: entities['product'], originalQuery: userMessage);
        }
      }

      return ChatResponse(text: flexibleResponse.response);
    } catch (e) {
      // If flexible AI fails, fall back to basic responses

      // Enhanced conversational fallback responses
      String baseResponse;

      // Simple keyword matching with enhanced responses
      final lowerMessage = userMessage.toLowerCase();
      if (lowerMessage.contains('produk') || lowerMessage.contains('barang')) {
        baseResponse =
            'Untuk informasi produk, Anda bisa melihat di halaman "Beli" atau tanyakan nama produk spesifik seperti laptop, mouse, atau keyboard.';
      } else if (lowerMessage.contains('harga') ||
          lowerMessage.contains('biaya')) {
        baseResponse =
            'Untuk informasi harga jasa service laptop/PC/printer, silakan lihat halaman "Service" atau hubungi teknisi kami. Ada yang bisa saya bantu?';
      } else {
        // For random or general questions, be engaging and redirect
        if (lowerMessage.contains('jempol') ||
            lowerMessage.contains('thumb') ||
            lowerMessage.contains('punya') &&
                (lowerMessage.contains('badan') ||
                    lowerMessage.contains('tubuh'))) {
          baseResponse =
              'Haha, sebagai AI tentu saya punya "jempol" digital! 😄 Tapi lebih seru lagi, saya punya banyak info tentang service komputer dan produk elektronik. Ada yang bisa saya bantu seputar laptop atau PC Anda?';
        } else {
          // Generate small talk for general queries but redirect to services
          String smallTalk = ConversationEnhancer.generateSmallTalk();
          baseResponse =
              '$smallTalk Ngomong-ngomong, ada yang bisa saya bantu seputar service komputer atau produk elektronik di AzzaService?';
        }
      }

      // Make response more conversational
      return ChatResponse(
          text: ConversationEnhancer.enhanceResponse(
        baseResponse,
        addFollowUp: true,
        makeCasual: true,
        addClosing: true,
      ));
    }
  }

  // Public method to clear conversation context (can be called when starting new conversation)
  static void clearConversationContext() {
    ContextManager.clearContext();
  }

  // Public method to get current context (for debugging)
  static ConversationContext? getCurrentContext() {
    return ContextManager.getCurrentContext();
  }

  static bool _isGreeting(String message) {
    final greetings = [
      'halo',
      'hallo',
      'hai',
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
      'salam',
      'apa kabar',
      'bagaimana kabar',
      'selamat datang',
      'welcome'
    ];

    return greetings
        .any((greeting) => message.toLowerCase().contains(greeting));
  }

  static String _getGreetingResponse() {
    // Use ConversationEnhancer for contextual greeting
    String baseGreeting = ConversationEnhancer.generateContextualGreeting();

    // Create personalized greeting response
    String greetingMessage =
        'Saya NanyaAzza, AI asisten E-Service yang siap membantu Anda!';

    // Add small talk and follow-up
    String enhancedGreeting = ConversationEnhancer.enhanceResponse(
      '$baseGreeting $greetingMessage',
      addFollowUp: true,
      addClosing: false,
    );

    return enhancedGreeting;
  }
}
