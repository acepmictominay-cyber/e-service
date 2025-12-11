import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:azza_service/api_services/api_service.dart';
import 'package:azza_service/Others/session_manager.dart';
import 'package:azza_service/config/api_config.dart';

/// Background service manager for efficient task scheduling
class BackgroundServiceManager {
  static const String _orderCheckTask = 'order_check_task';
  static const String _locationSyncTask = 'location_sync_task';
  static const String _notificationCleanupTask = 'notification_cleanup_task';
  static const String _birthdayCheckTask = 'birthday_check_task';

  static bool _isInitialized = false;

  /// Initialize background services
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize Workmanager for Android
    if (Platform.isAndroid) {
      await Workmanager().initialize(_callbackDispatcher, isInDebugMode: false);

      // Register periodic tasks
      await _registerPeriodicTasks();
    }

    _isInitialized = true;
  }

  /// Register periodic background tasks
  static Future<void> _registerPeriodicTasks() async {
    await Workmanager().registerPeriodicTask(
      _orderCheckTask,
      _orderCheckTask,
      frequency: const Duration(minutes: 30), // mengatur durasi load
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    // Location sync - every 15 minutes
    await Workmanager().registerPeriodicTask(
      _locationSyncTask,
      _locationSyncTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    // Notification cleanup - daily
    await Workmanager().registerPeriodicTask(
      _notificationCleanupTask,
      _notificationCleanupTask,
      frequency: const Duration(hours: 24),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    // Birthday check - every 6 hours
    await Workmanager().registerPeriodicTask(
      _birthdayCheckTask,
      _birthdayCheckTask,
      frequency: const Duration(hours: 6),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  /// Callback dispatcher for background tasks
  @pragma('vm:entry-point')
  static void _callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      try {
        switch (task) {
          case _orderCheckTask:
            return await _performOrderCheck();
          case _locationSyncTask:
            return await _performLocationSync();
          case _notificationCleanupTask:
            return await _performNotificationCleanup();
          case _birthdayCheckTask:
            return await _performBirthdayCheck();
          default:
            return false;
        }
      } catch (e) {
        // Log error but don't crash
        return false;
      }
    });
  }

  /// Perform background order status check
  static Future<bool> _performOrderCheck() async {
    try {
      // Check if user is logged in
      final isLoggedIn = await SessionManager.isLoggedIn();
      if (!isLoggedIn) return true;

      final session = await SessionManager.getUserSession();
      final role = session['role'];

      if (role == 'karyawan') {
        // Check for new orders for technicians
        final kryKode = session['kry_kode'];
        if (kryKode != null) {
          await ApiService.getkry_kode(kryKode);
        }
      } else {
        // Check for order updates for customers
        await ApiService.getOrderList();
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Perform background location sync
  static Future<bool> _performLocationSync() async {
    try {
      // Import location service dynamically to avoid initialization issues
      final locationService = await _getLocationServiceInstance();

      // Check if location tracking is active
      if (!locationService.isTracking) {
        return true; // Not an error, just not tracking
      }

      // Get current location and send to server
      // This is a fallback mechanism in case background geolocation fails
      final position = await _getCurrentPosition();
      if (position != null) {
        await _sendLocationToServer(position);
      }

      return true;
    } catch (e) {
      print('❌ [BackgroundServiceManager] Location sync failed: $e');
      return false;
    }
  }

  /// Get location service instance dynamically
  static Future<dynamic> _getLocationServiceInstance() async {
    // Import the location service dynamically
    // This prevents initialization issues in background isolate
    return await _importLocationService();
  }

  /// Import location service dynamically
  static Future<dynamic> _importLocationService() async {
    // Since we can't import directly in background isolate,
    // we'll use a different approach - check shared preferences for tracking state
    final prefs = await SharedPreferences.getInstance();
    final isTracking = prefs.getBool('location_tracking_active') ?? false;
    final transKode = prefs.getString('current_trans_kode');
    final kryKode = prefs.getString('current_kry_kode');

    return {
      'isTracking': isTracking,
      'transKode': transKode,
      'kryKode': kryKode,
    };
  }

  /// Get current position for background sync
  static Future<Position?> _getCurrentPosition() async {
    try {
      // Use geolocator to get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('❌ [BackgroundServiceManager] Failed to get current position: $e');
      return null;
    }
  }

  /// Send location data to server
  static Future<void> _sendLocationToServer(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transKode = prefs.getString('current_trans_kode');
      final kryKode = prefs.getString('current_kry_kode');

      if (transKode == null || kryKode == null) {
        return;
      }

      // Send to API
      await ApiService.updateDriverLocation(
        transKode: transKode,
        kryKode: kryKode,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      print(
        '✅ [BackgroundServiceManager] Location synced: ${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      print('❌ [BackgroundServiceManager] Failed to send location: $e');
    }
  }

  /// Perform notification cleanup
  static Future<bool> _performNotificationCleanup() async {
    try {
      // Clean up old notifications from local storage
      // Implementation depends on your notification storage
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Perform background birthday check
  static Future<bool> _performBirthdayCheck() async {
    try {
      // Import the birthday service dynamically to avoid initialization issues
      // This will be called from background isolate
      await _checkAndSendBirthdayNotifications();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check and send birthday notifications (background version)
  static Future<void> _checkAndSendBirthdayNotifications() async {
    try {
      // Get current date
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentDay = now.day;
      final todayKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Use real API to get customer data
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/costomers'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final customers = data['data'] as List<dynamic>;

        // Get already sent notifications for today
        // Note: SharedPreferences might not work in background on iOS
        // For now, we'll use a simple in-memory check or skip duplicate prevention
        final sentNotifications =
            <String>[]; // In production, use persistent storage

        for (var customer in customers) {
          final cosTglLahir = customer['cos_tgl_lahir'];
          if (cosTglLahir != null &&
              cosTglLahir.toString().isNotEmpty &&
              cosTglLahir != '0000-00-00') {
            try {
              // Parse birth date
              final birthDate = DateTime.parse(cosTglLahir);
              final birthMonth = birthDate.month;
              final birthDay = birthDate.day;

              // Check if today is their birthday
              if (birthMonth == currentMonth && birthDay == currentDay) {
                final customerId = customer['id_costomer'].toString();
                final customerName = customer['cos_nama'] ?? 'Pelanggan';

                // For background notifications, we'll send without duplicate check
                // In production, implement persistent storage for sent notifications
                await _sendBirthdayNotificationBackground(
                  customerName,
                  customerId,
                );
              }
            } catch (e) {
              // Skip invalid dates
            }
          }
        }
      }
    } catch (e) {
      // Background task failed silently
    }
  }

  /// Send birthday notification in background
  static Future<void> _sendBirthdayNotificationBackground(
    String customerName,
    String customerId,
  ) async {
    try {
      // For background notifications, we need to initialize the plugin if not already done
      // This is a simplified version - in production, ensure proper initialization
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'birthday_channel',
        'Birthday Notifications',
        channelDescription: 'Notifications for customer birthdays',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap(
          '@mipmap/ic_launcher',
        ),
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

// belum ada link untuk mendapat hadiah atau promo khusus
      await flutterLocalNotificationsPlugin.show(
        customerId.hashCode, // Unique ID based on customer ID
        'Selamat Ulang Tahun! 🎉',
        'Halo $customerName, selamat ulang tahun! Semoga hari Anda menyenangkan.',
        platformChannelSpecifics,
        payload: 'birthday_$customerId',
      );
    } catch (e) {}
  }

  /// Schedule one-time task
  static Future<void> scheduleOneTimeTask(
    String taskName,
    Duration delay, {
    Map<String, dynamic>? inputData,
  }) async {
    await Workmanager().registerOneOffTask(
      taskName,
      taskName,
      initialDelay: delay,
      inputData: inputData,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  /// Cancel specific task
  static Future<void> cancelTask(String taskName) async {
    await Workmanager().cancelByUniqueName(taskName);
  }

  /// Cancel all tasks
  static Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
  }
}

/// Efficient timer manager for periodic tasks
class TimerManager {
  static final Map<String, Timer> _timers = {};
  static final Map<String, StreamSubscription> _subscriptions = {};

  /// Schedule periodic task with automatic cleanup
  static void schedulePeriodic(
    String key,
    Duration interval,
    VoidCallback task, {
    bool autoStart = true,
  }) {
    cancelTimer(key);

    if (autoStart) {
      _timers[key] = Timer.periodic(interval, (_) => task);
    }
  }

  /// Schedule delayed task
  static void scheduleDelayed(String key, Duration delay, VoidCallback task) {
    cancelTimer(key);
    _timers[key] = Timer(delay, task);
  }

  /// Cancel specific timer
  static void cancelTimer(String key) {
    _timers[key]?.cancel();
    _timers.remove(key);
  }

  /// Cancel all timers
  static void cancelAllTimers() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();

    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  /// Check if timer is active
  static bool isTimerActive(String key) {
    return _timers.containsKey(key) && _timers[key]!.isActive;
  }

  /// Get active timer count
  static int get activeTimerCount => _timers.length;
}

/// Resource pool for managing expensive resources
class ResourcePool<T> {
  final List<T> _available = [];
  final List<T> _inUse = [];
  final T Function() _factory;
  final void Function(T)? _cleanup;

  ResourcePool(this._factory, {void Function(T)? cleanup}) : _cleanup = cleanup;

  /// Get resource from pool
  T get() {
    if (_available.isNotEmpty) {
      final resource = _available.removeLast();
      _inUse.add(resource);
      return resource;
    }

    final resource = _factory();
    _inUse.add(resource);
    return resource;
  }

  /// Return resource to pool
  void release(T resource) {
    if (_inUse.remove(resource)) {
      _cleanup?.call(resource);
      _available.add(resource);
    }
  }

  /// Get pool statistics
  Map<String, int> get stats => {
        'available': _available.length,
        'inUse': _inUse.length,
        'total': _available.length + _inUse.length,
      };

  /// Clear pool
  void clear() {
    for (final resource in _available) {
      _cleanup?.call(resource);
    }
    for (final resource in _inUse) {
      _cleanup?.call(resource);
    }
    _available.clear();
    _inUse.clear();
  }
}
