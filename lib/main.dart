import 'package:e_service/Auth/login.dart';
import 'package:e_service/Home/Home.dart';
import 'package:e_service/Others/birthday_notification_service.dart';
import 'package:e_service/Others/new_order_notification_service.dart';
import 'package:e_service/Others/background_task_handler.dart';
import 'package:e_service/Teknisi/teknisi_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:workmanager/workmanager.dart';
import 'Others/session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification services
  await NewOrderNotificationService.initialize();
  await BirthdayNotificationService.initialize();

  // Initialize Workmanager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // Set false untuk production
  );

  // Register periodic task untuk NEW ORDERS
  await Workmanager().registerPeriodicTask(
    "checkNewOrdersTask",
    "checkNewOrders",
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );

  // Register periodic task untuk BIRTHDAYS
  await Workmanager().registerPeriodicTask(
    "checkBirthdaysTask",
    "checkBirthdays",
    frequency: const Duration(hours: 1),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );

  bool isLoggedIn = await SessionManager.isLoggedIn();
  final session = await SessionManager.getUserSession();
  final role = session['role'];

  runApp(MyApp(isLoggedIn: isLoggedIn, role: role));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? role;
  const MyApp({super.key, required this.isLoggedIn, this.role});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E Service',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      supportedLocales: const [Locale('en', 'US'), Locale('id', 'ID')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: SplashScreen(isLoggedIn: isLoggedIn, role: role),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final bool isLoggedIn;
  final String? role;
  const SplashScreen({super.key, required this.isLoggedIn, this.role});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _circleAnimation;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _circleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOutCubic),
    );

    _logoAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOutBack),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            // ✅ Cek birthday sekali saat app start
            BirthdayNotificationService.checkAndSendBirthdayNotifications();

            if (widget.isLoggedIn) {
              Widget nextPage;
              if (widget.role == 'technician') {
                nextPage = const TeknisiHomePage();
              } else {
                nextPage = const HomePage(isFreshLogin: true);
              }
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => nextPage),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            }
          }
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final circleValue = _circleAnimation.value;
          final logoVisible = _logoAnimation.value > 0.01;

          return Stack(
            fit: StackFit.expand,
            children: [
              Container(color: Colors.white),
              CustomPaint(
                painter: CircleRevealPainter(circleValue),
                child: Container(),
              ),
              if (logoVisible)
                Center(
                  child: Opacity(
                    opacity: _logoAnimation.value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: _logoAnimation.value.clamp(0.0, 1.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/image/logo.png',
                            width:
                                isLandscape
                                    ? screenSize.width * 0.15
                                    : screenSize.width * 0.4,
                            height:
                                isLandscape
                                    ? screenSize.height * 0.2
                                    : screenSize.height * 0.15,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class CircleRevealPainter extends CustomPainter {
  final double progress;
  CircleRevealPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.blue;
    final maxRadius =
        (size.width > size.height ? size.width : size.height) * 1.2;
    final radius = maxRadius * progress;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CircleRevealPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
