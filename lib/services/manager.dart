class ConversationContext {
  final String topic;
  final String? product;
  final String? serviceType;
  final DateTime timestamp;
  final String originalQuery;

  ConversationContext({
    required this.topic,
    this.product,
    this.serviceType,
    required this.timestamp,
    required this.originalQuery,
  });

  Map<String, dynamic> toMap() {
    return {
      'topic': topic,
      'product': product,
      'service_type': serviceType,
      'timestamp': timestamp.toIso8601String(),
      'query': originalQuery,
    };
  }

  factory ConversationContext.fromMap(Map<String, dynamic> map) {
    return ConversationContext(
      topic: map['topic'] ?? '',
      product: map['product'],
      serviceType: map['service_type'],
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      originalQuery: map['query'] ?? '',
    );
  }
}

class ContextManager {
  static ConversationContext? _currentContext;

  // Context expiration time (10 minutes)
  static const Duration _contextExpiry = Duration(minutes: 10);

  static void updateContext(String topic, {
    String? product,
    String? serviceType,
    String? originalQuery
  }) {
    _currentContext = ConversationContext(
      topic: topic,
      product: product,
      serviceType: serviceType,
      timestamp: DateTime.now(),
      originalQuery: originalQuery ?? '',
    );
  }

  static void clearContext() {
    _currentContext = null;
  }

  static ConversationContext? getCurrentContext() {
    if (_currentContext == null) return null;

    // Check if context is still valid
    if (DateTime.now().difference(_currentContext!.timestamp) > _contextExpiry) {
      _currentContext = null;
      return null;
    }

    return _currentContext;
  }

  static bool isContextValid() {
    return getCurrentContext() != null;
  }

  static String enhanceQueryWithContext(String userMessage) {
    final context = getCurrentContext();
    if (context == null) return userMessage;

    final q = userMessage.toLowerCase();

    // Check if this is a follow-up question
    final isFollowUp = q.contains('nya') || q.contains('itu') || q.contains('yang') ||
                      q.contains('gimana') || q.contains('gmana') || q.contains('bagaimana') ||
                      q.contains('berapa') || q.contains('harga') || q.contains('biaya') ||
                      q.startsWith('dan') || q.startsWith('terus');

    if (!isFollowUp) return userMessage;

    // Enhance query with context
    String enhancedQuery = userMessage;

    if (context.product != null && context.product!.isNotEmpty) {
      enhancedQuery += " (mengenai ${context.product})";
    }

    if (context.serviceType != null && context.serviceType!.isNotEmpty) {
      enhancedQuery += " (layanan ${context.serviceType})";
    }

    if (context.topic == 'location') {
      enhancedQuery += " (lokasi toko)";
    } else if (context.topic == 'payment') {
      enhancedQuery += " (pembayaran)";
    } else if (context.topic == 'service') {
      enhancedQuery += " (service)";
    }

    return enhancedQuery;
  }

  static Map<String, dynamic> extractEntities(String query) {
    final q = query.toLowerCase();
    final entities = <String, dynamic>{};

    // Extract product
    if (q.contains('printer') || q.contains('epson') || q.contains('canon') || q.contains('hp')) {
      entities['product'] = 'printer';
    } else if (q.contains('laptop') || q.contains('komputer') || q.contains('pc') || q.contains('notebook')) {
      entities['product'] = 'laptop';
    } else if (q.contains('mouse') || q.contains('keyboard')) {
      entities['product'] = 'peripheral';
    }

    // Extract service type
    if (q.contains('perbaikan') || q.contains('repair') || q.contains('benerin') || q.contains('fix')) {
      entities['service_type'] = 'repair';
    } else if (q.contains('cleaning') || q.contains('bersih')) {
      entities['service_type'] = 'cleaning';
    }

    return entities;
  }
}
