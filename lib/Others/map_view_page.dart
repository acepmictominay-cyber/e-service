import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MapsWebViewPage extends StatefulWidget {
  final String address;

  const MapsWebViewPage({super.key, required this.address});

  @override
  State<MapsWebViewPage> createState() => _MapsWebViewPageState();
}

class _MapsWebViewPageState extends State<MapsWebViewPage> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
            // Deteksi URL dengan skema "intent://"
            if (request.url.startsWith('intent://')) {
              // Ubah jadi URL biasa yang bisa dibuka di aplikasi Maps
              final newUrl = request.url
                  .replaceFirst('intent://', 'https://')
                  .split('#Intent')[0];

              if (await canLaunchUrl(Uri.parse(newUrl))) {
                await launchUrl(Uri.parse(newUrl),
                    mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tidak bisa membuka Maps')),
                );
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
        Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(widget.address)}',
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lokasi Pelanggan"),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
