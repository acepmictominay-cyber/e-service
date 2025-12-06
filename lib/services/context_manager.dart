class ContextManager {
  static final Map<String, dynamic> _context = {};
  static final List<Map<String, dynamic>> _conversationHistory = [];
  static const int _maxHistoryLength = 10;

  static void clearContext() {
    _context.clear();
  }

  static String enhanceQueryWithContext(String userMessage) {
    if (_context.isEmpty) {
      return userMessage;
    }

    // Enhance query based on current context
    String enhanced = userMessage;

    // If we have product context, add product reference
    if (_context['product'] != null) {
      final product = _context['product'];
      if (!enhanced.toLowerCase().contains(product.toLowerCase())) {
        enhanced = '$product $enhanced';
      }
    }

    // If we have service context, add service reference
    if (_context['service_type'] != null) {
      final serviceType = _context['service_type'];
      if (!enhanced.toLowerCase().contains(serviceType.toLowerCase())) {
        enhanced = '$serviceType $enhanced';
      }
    }

    // If we have location context, add location reference
    if (_context['location'] != null &&
        enhanced.toLowerCase().contains('lokasi')) {
      enhanced = 'lokasi toko $enhanced';
    }

    return enhanced;
  }

  static Map<String, dynamic> extractEntities(String query) {
    final entities = <String, dynamic>{};
    final q = query.toLowerCase();

    // Extract product entities
    if (q.contains('laptop') || q.contains('komputer') || q.contains('pc')) {
      entities['product'] = 'laptop';
      entities['product_category'] = 'computer';
    } else if (q.contains('printer') ||
        q.contains('epson') ||
        q.contains('canon')) {
      entities['product'] = 'printer';
      entities['product_category'] = 'peripheral';
    } else if (q.contains('mouse')) {
      entities['product'] = 'mouse';
      entities['product_category'] = 'accessory';
    } else if (q.contains('keyboard')) {
      entities['product'] = 'keyboard';
      entities['product_category'] = 'accessory';
    }

    // Extract service entities
    if (q.contains('perbaikan') ||
        q.contains('repair') ||
        q.contains('benerin')) {
      entities['service_type'] = 'repair';
    } else if (q.contains('cleaning') || q.contains('bersih')) {
      entities['service_type'] = 'cleaning';
    }

    // Extract intent
    if (q.contains('harga') || q.contains('biaya') || q.contains('berapa')) {
      entities['intent'] = 'pricing';
    } else if (q.contains('beli') ||
        q.contains('pesan') ||
        q.contains('order')) {
      entities['intent'] = 'purchase';
    } else if (q.contains('lokasi') ||
        q.contains('alamat') ||
        q.contains('dimana')) {
      entities['intent'] = 'location';
    } else if (q.contains('jam') ||
        q.contains('operasional') ||
        q.contains('buka')) {
      entities['intent'] = 'schedule';
    }

    return entities;
  }

  static void updateContext(String type,
      {String? product, String? serviceType, String? originalQuery}) {
    _context['last_update'] = DateTime.now();

    switch (type) {
      case 'product':
        if (product != null) {
          _context['product'] = product;
          _context['context_type'] = 'product';
        }
        break;
      case 'service':
        if (serviceType != null) {
          _context['service_type'] = serviceType;
          _context['context_type'] = 'service';
        }
        break;
      case 'location':
        _context['location'] = true;
        _context['context_type'] = 'location';
        break;
      case 'price':
        _context['pricing'] = true;
        _context['context_type'] = 'price';
        if (product != null) {
          _context['product'] = product;
        }
        break;
      case 'general':
        _context['context_type'] = 'general';
        break;
    }

    if (originalQuery != null) {
      _context['last_query'] = originalQuery;
    }
  }

  static ConversationContext? getCurrentContext() {
    if (_context.isEmpty) return null;
    return ConversationContext(_context, DateTime.now());
  }

  static bool isContextValid() {
    return _context.isNotEmpty;
  }

  // Conversation memory methods
  static void addToConversationHistory(String userMessage, String botResponse,
      {Map<String, dynamic>? metadata}) {
    final conversationEntry = {
      'timestamp': DateTime.now(),
      'user_message': userMessage,
      'bot_response': botResponse,
      'metadata': metadata ?? {},
    };

    _conversationHistory.add(conversationEntry);

    // Keep only the most recent conversations
    if (_conversationHistory.length > _maxHistoryLength) {
      _conversationHistory.removeAt(0);
    }
  }

  static List<Map<String, dynamic>> getRecentConversations({int limit = 5}) {
    final recent = _conversationHistory.reversed.take(limit).toList();
    return recent.reversed.toList(); // Return in chronological order
  }

  static String getConversationSummary() {
    if (_conversationHistory.isEmpty) return '';

    final topics = <String>[];
    final products = <String>[];
    final services = <String>[];

    for (final entry in _conversationHistory) {
      final metadata = entry['metadata'] as Map<String, dynamic>? ?? {};
      if (metadata['topic'] != null) topics.add(metadata['topic']);
      if (metadata['product'] != null) products.add(metadata['product']);
      if (metadata['service_type'] != null)
        services.add(metadata['service_type']);
    }

    final summary = <String>[];
    if (topics.isNotEmpty) summary.add('Topik: ${topics.toSet().join(', ')}');
    if (products.isNotEmpty)
      summary.add('Produk: ${products.toSet().join(', ')}');
    if (services.isNotEmpty)
      summary.add('Service: ${services.toSet().join(', ')}');

    return summary.isNotEmpty
        ? 'Percakapan sebelumnya: ${summary.join('. ')}.'
        : '';
  }

  static bool hasRecentContext(String topic, {Duration? within}) {
    final timeLimit = within ?? const Duration(minutes: 30);
    final cutoff = DateTime.now().subtract(timeLimit);

    return _conversationHistory.any((entry) {
      final timestamp = entry['timestamp'] as DateTime;
      final metadata = entry['metadata'] as Map<String, dynamic>? ?? {};
      return timestamp.isAfter(cutoff) && metadata['topic'] == topic;
    });
  }

  static void clearConversationHistory() {
    _conversationHistory.clear();
  }

  // Session persistence (simplified - in real app would use SharedPreferences or database)
  static Map<String, dynamic> exportSessionData() {
    return {
      'context': _context,
      'conversation_history': _conversationHistory,
      'export_timestamp': DateTime.now(),
    };
  }

  static void importSessionData(Map<String, dynamic> sessionData) {
    if (sessionData['context'] != null) {
      _context.clear();
      _context.addAll(sessionData['context'] as Map<String, dynamic>);
    }

    if (sessionData['conversation_history'] != null) {
      _conversationHistory.clear();
      _conversationHistory.addAll((sessionData['conversation_history'] as List)
          .cast<Map<String, dynamic>>());
    }
  }
}

class ConversationContext {
  final Map<String, dynamic> data;
  final DateTime timestamp;

  ConversationContext(this.data, this.timestamp);
}
