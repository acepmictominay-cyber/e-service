import 'dart:async';
import 'dart:io';

import 'package:azza_service/Auth/login.dart';
import 'package:azza_service/Home/home.dart';
import 'package:azza_service/Others/background_order_service.dart';
import 'package:azza_service/Others/birthday_notification_service.dart';
import 'package:azza_service/providers/theme_provider.dart';
import 'package:azza_service/themes/app_themes.dart';
import 'package:azza_service/Teknisi/teknisi_home.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import 'Others/session_manager.dart';
import 'services/background_service_manager.dart';

// Global navigator key for navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ====================== Error handling utilities ======================
class ErrorHandler {
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Tutup',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static Future<T?> safeApiCall<T>(
    Future<T> Function() apiCall, {
    String? errorMessage,
    BuildContext? context,
  }) async {
    try {
      return await apiCall();
    } catch (e) {
      final message = errorMessage ?? 'Terjadi kesalahan: $e';
      if (context != null && context.mounted) {
        showErrorSnackBar(context, message);
      }
      return null;
    }
  }
}

// ====================== Global error handlers ======================
void _handleFlutterError(FlutterErrorDetails details) {
  if (kDebugMode) {
    FlutterError.dumpErrorToConsole(details);
  } else {
    // TODO: kirim ke crash reporting, contoh:
    // FirebaseCrashlytics.instance.recordFlutterError(details);
  }
}

bool _handlePlatformError(Object error, StackTrace stack) {
  if (kDebugMode) {
  } else {
    // TODO: kirim ke crash reporting
    // FirebaseCrashlytics.instance.recordError(error, stack);
  }
  // true = error tidak dilempar ulang ke framework
  return true;
}

void _handleZoneError(Object error, StackTrace stack) {
  if (kDebugMode) {
  } else {
    // TODO: kirim ke crash reporting
    // FirebaseCrashlytics.instance.recordError(error, stack);
  }
}

// Inisialisasi service berjalan di background agar UI cepat tampil
Future<void> _initServicesInBackground() async {
  try {
    await BirthdayNotificationService.initialize();
    await BackgroundOrderService.initialize();
    await BackgroundServiceManager.initialize();
    if (kDebugMode) {}
  } catch (e) {
    if (kDebugMode) {}
  }
}

// ====================== main ======================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set global error handling
  FlutterError.onError = _handleFlutterError;
  PlatformDispatcher.instance.onError = _handlePlatformError;

  runZonedGuarded(() async {
    // Ambil status login & role (biasanya cepat)
    final bool isLoggedIn = await SessionManager.isLoggedIn();
    final session = await SessionManager.getUserSession();
    final String? role = session['role'];

    // Tampilkan UI secepatnya
    runApp(MyApp(isLoggedIn: isLoggedIn, role: role));

    // Lanjutkan inisialisasi berat di background (tidak menghalangi UI)
    unawaited(_initServicesInBackground());
  }, _handleZoneError);
}

// ====================== ErrorBoundary ======================
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool hasError = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    ErrorWidget.builder = (FlutterErrorDetails details) {
      if (kDebugMode) {
        return ErrorWidget(details.exception);
      }
      return _buildErrorWidget(details.exception.toString());
    };
  }

  Widget _buildErrorWidget(String error) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Terjadi Kesalahan',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aplikasi mengalami masalah. Silakan restart aplikasi.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Restart app (cara cepat, tidak ideal untuk production)
                    exit(0);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    'Restart Aplikasi',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return _buildErrorWidget(errorMessage);
    }
    return widget.child;
  }
}

// ====================== MyApp ======================
class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? role;
  const MyApp({super.key, required this.isLoggedIn, this.role});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ErrorBoundary(
            child: MaterialApp(
              title: 'E Service',
              navigatorKey: navigatorKey,
              debugShowCheckedModeBanner: false,
              theme: AppThemes.lightTheme,
              darkTheme: AppThemes.darkTheme,
              themeMode: themeProvider.themeMode,
              supportedLocales: const [
                Locale('en', 'US'),
                Locale('id', 'ID'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: SplashScreen(
                isLoggedIn: isLoggedIn,
                role: role,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ====================== SplashScreen ======================
class SplashScreen extends StatefulWidget {
  final bool isLoggedIn;
  final String? role;
  const SplashScreen({super.key, required this.isLoggedIn, this.role});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset('assets/video/splash_screen.mp4')
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        _controller.play();
        _controller.setLooping(false);
      });

    // Navigate after 5 seconds regardless of video duration
    Timer(const Duration(seconds: 5), _navigateToNextScreen);
  }

  void _navigateToNextScreen() {
    if (mounted) {
      BirthdayNotificationService.scheduleDailyBirthdayCheck();

      if (widget.isLoggedIn) {
        Widget nextPage;
        if (widget.role == 'karyawan') {
          nextPage = const TeknisiHomePage();
        } else {
          nextPage = const HomePage();
        }
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (context) => nextPage));
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isVideoInitialized
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          : Container(color: Colors.white), // Placeholder while video loads
    );
  }
}
