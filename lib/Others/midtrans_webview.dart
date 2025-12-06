import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../api_services/payment_service.dart';

class MidtransWebView extends StatefulWidget {
  final String redirectUrl;
  final String orderId;
  final Function(String) onTransactionFinished;

  const MidtransWebView({
    super.key,
    required this.redirectUrl,
    required this.orderId,
    required this.onTransactionFinished,
  });

  @override
  State<MidtransWebView> createState() => _MidtransWebViewState();
}

class _MidtransWebViewState extends State<MidtransWebView> {
  late final WebViewController _controller;
  Timer? _pollingTimer;
  bool _isLoading = true;
  bool _shouldPop = false;
  String? _popStatus;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _startPolling();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            _injectJavaScript();
          },
          onNavigationRequest: (NavigationRequest request) {
            // Handle external links if needed
            if (request.url.startsWith('http') &&
                !request.url.contains('app.midtrans.com') &&
                !request.url.contains('snap.midtrans.com')) {
              // Open external links in browser
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: _handleJavaScriptMessage,
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  void _injectJavaScript() {
    const String jsCode = '''
      // Override Midtrans Snap events
      if (window.snap) {
        var originalPay = window.snap.pay;
        window.snap.pay = function(token, options) {
          options = options || {};
          var originalOnSuccess = options.onSuccess;
          var originalOnPending = options.onPending;
          var originalOnError = options.onError;
          var originalOnClose = options.onClose;

          options.onSuccess = function(result) {
            FlutterChannel.postMessage(JSON.stringify({
              event: 'success',
              data: result
            }));
            if (originalOnSuccess) originalOnSuccess(result);
          };

          options.onPending = function(result) {
            FlutterChannel.postMessage(JSON.stringify({
              event: 'pending',
              data: result
            }));
            if (originalOnPending) originalOnPending(result);
          };

          options.onError = function(result) {
            FlutterChannel.postMessage(JSON.stringify({
              event: 'error',
              data: result
            }));
            if (originalOnError) originalOnError(result);
          };

          options.onClose = function() {
            FlutterChannel.postMessage(JSON.stringify({
              event: 'close',
              data: {}
            }));
            if (originalOnClose) originalOnClose();
          };

          return originalPay(token, options);
        };
      }

      // Listen for page events
      window.addEventListener('beforeunload', function(event) {
        FlutterChannel.postMessage(JSON.stringify({
          event: 'close',
          data: {}
        }));
      });

      // Hide "Leave This Page" button
      setTimeout(function() {
        var elements = document.querySelectorAll('button, a, div, span');
        for (var i = 0; i < elements.length; i++) {
          if (elements[i].textContent.trim() === 'Leave This Page' || elements[i].innerText.trim() === 'Leave This Page') {
            elements[i].style.display = 'none';
          }
        }
      }, 2000);
    ''';

    _controller.runJavaScript(jsCode);
  }

  void _handleJavaScriptMessage(JavaScriptMessage message) {
    // Check if widget is still mounted before processing
    if (!mounted) {
      print('Widget disposed, ignoring JavaScript message');
      return;
    }

    try {
      final data = json.decode(message.message);
      final event = data['event'];
      final eventData = data['data'];

      print('Midtrans Event: $event, Data: $eventData');

      switch (event) {
        case 'success':
          _handlePaymentResult('success');
          break;
        case 'pending':
          _handlePaymentResult('pending');
          break;
        case 'error':
          _handlePaymentResult('error');
          break;
        case 'close':
          _handlePaymentResult('cancel');
          break;
      }
    } catch (e) {
      print('Error parsing JavaScript message: $e');
      // Don't crash on parsing errors
    }
  }

  void _startPolling() {
    // Production-ready: Reduce polling frequency to save resources
    // Note: _isProduction is private, so we use a different approach
    const bool isProduction = false; // Set to true for production deployment
    final pollingInterval = isProduction
        ? const Duration(seconds: 5)  // Less frequent in production
        : const Duration(seconds: 3); // More frequent in development

    _pollingTimer = Timer.periodic(pollingInterval, (timer) async {
      // Check if widget is still mounted before polling
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        final statusData = await PaymentService.getPaymentStatus(widget.orderId);
        final status = statusData['transaction_status']?.toString() ?? '';

        print('Polling status for ${widget.orderId}: $status');

        if (status.isNotEmpty && status != 'pending') {
          _handlePaymentResult(status);
        }
      } catch (e) {
        print('Error polling payment status: $e');
        // If we get HTML response (server error), stop polling
        if (e.toString().contains('FormatException') || e.toString().contains('<!DOCTYPE html>')) {
          timer.cancel();
        }
      }
    });
  }

  void _handlePaymentResult(String status) {
    _pollingTimer?.cancel();
    // Prevent multiple calls
    if (_shouldPop) return;

    widget.onTransactionFinished(status);
    if (mounted) {
      setState(() {
        _shouldPop = true;
        _popStatus = status;
      });
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    // Remove JavaScript channel to prevent further messages
    try {
      _controller.removeJavaScriptChannel('FlutterChannel');
    } catch (e) {
      // Ignore errors if channel doesn't exist
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Handle pop after build if needed
    if (_shouldPop && _popStatus != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
          setState(() {
            _shouldPop = false;
            _popStatus = null;
          });
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0041c3),
        titleTextStyle: const TextStyle(color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Pembayaran'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _handlePaymentResult('cancel');
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
