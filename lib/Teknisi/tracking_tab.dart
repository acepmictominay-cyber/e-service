import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TrackingTab extends StatelessWidget {
  final String customerAddress;

  const TrackingTab({super.key, required this.customerAddress});

  Future<void> _openGoogleMaps(String address) async {
    final Uri url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Tidak dapat membuka Google Maps');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi Pelanggan'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(
                customerAddress,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text('Buka di Google Maps'),
                onPressed: () => _openGoogleMaps(customerAddress),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}