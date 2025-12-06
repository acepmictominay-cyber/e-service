class ApiConfig {
  // Change this domain when your server domain changes
  // Current: api.azzahracomputertegal.com - Update this to match your hosted API domain
  static const String serverIp = 'https://api.azzahracomputertegal.com';
  // static const String serverIp = 'http://192.168.1.8:8000';

  // API Base URLs
  static String get apiBaseUrl => '$serverIp/api';
  static String get storageBaseUrl => '$serverIp/api/storage/';
  static String get imageBaseUrl => '$serverIp/api/storage/assets/image/';

  // Webhook and other service URLs
  static String get webhookBaseUrl => '$serverIp/api/payment/webhook';

  // Midtrans Configuration
  static const String midtransServerKey =
      'YOUR_MIDTRANS_SERVER_KEY'; // Replace with your actual Midtrans server key

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
