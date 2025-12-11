class ApiConfig {
  // Change this domain when your server domain changes
  // Current: api.azzahracomputertegal.com - Update this to match your hosted API domain
  static const String serverIp = 'https://api.azzahracomputertegal.com';
  //static const String serverIp = 'http://192.168.1.19:8000';

  // API Base URLs
  static String get apiBaseUrl => '$serverIp/api';
  static String get storageBaseUrl => '$serverIp/api/storage/';
  static String get imageBaseUrl => '$serverIp/api/storage/assets/image/';

  // Profile image specific URL - try different paths
  static String get profileImageBaseUrl => '$serverIp/'; // Direct server path
  static String get profileImageStorageUrl =>
      '$serverIp/storage/'; // Laravel storage link
  static String get profileImageAssetsUrl =>
      '$serverIp/'; // Direct server path (path already contains assets/)

  // Webhook and other service URLs
  static String get webhookBaseUrl => '$serverIp/api/payment/webhook';

  // Midtrans Configuration
  static const String midtransServerKey =
      'SB-Mid-server-yKTO-_jT2d60u3M1'; // Sandbox server key
  static const String midtransClientKey =
      'SB-Mid-client-yKTO-_jT2d60u3M1'; // Sandbox client key

  // Doku Configuration (kept for reference)
  static const String dokuClientKey = 'BRN-0281-1764997135219';
  static const String dokuSignature =
      'Pxlv2IIUVdlzdUnbSQqug8YeghmKXJ7Rw5P4xBOOB/tC457UsoZXkO4S1R3oszVcjZDSh38+==';
  static const String dokuBaseUrl = 'https://api-uat.doku.com';
  static const String dokuTokenEndpoint =
      '/adv-core-api/partner/v1.0/authorization/v1/access-token/b2b';

  // Google Maps API Configuration
  static const String googleMapsApiKey =
      'YOUR_GOOGLE_MAPS_API_KEY'; // Replace with your actual Google Maps API key

  // OpenAI API Configuration
  static const String openAIApiKey =
      'YOUR_OPENAI_API_KEY'; // Replace with your actual OpenAI API key

  // Instructions for changing IP:
  // 1. Change the serverIp above to your new server IP
  // 2. Restart the Flutter app (hot reload may not pick up const changes)
  // 3. Make sure your Laravel server is running on the new IP:port
}