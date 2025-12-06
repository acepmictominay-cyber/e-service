// File: lib/services/location_service.dart

import 'dart:async';
import 'package:azza_service/api_services/api_service.dart'; // Pastikan path ini benar
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  // Singleton pattern untuk memastikan hanya ada satu instance service di seluruh aplikasi.
  // Ini mencegah beberapa pelacakan berjalan secara bersamaan secara tidak sengaja.
  LocationService._privateConstructor();
  static final LocationService instance = LocationService._privateConstructor();

  StreamSubscription<Position>? _positionStream;
  Timer? _locationTimer;
  bool _isTracking = false;

  // Variabel untuk menyimpan data order yang sedang aktif dilacak
  String? _currentTransKode;
  String? _currentKryKode;

  // Public getter untuk status tracking
  bool get isTracking => _isTracking;


  /// Memulai proses pelacakan lokasi teknisi.
  ///
  /// [transKode] dan [kryKode] diperlukan untuk dikirim ke API.
  Future<void> startTracking({
    required String transKode,
    required String kryKode,
  }) async {
    // Jika sudah melacak order yang sama, jangan mulai lagi untuk efisiensi.
    if (_isTracking && _currentTransKode == transKode) {
      print(
        '📍 [LocationService] Pelacakan sudah aktif untuk order $transKode.',
      );
      return;
    }

    print(
      '🚀 [LocationService] Memulai pelacakan untuk TransKode: $transKode, KryKode: $kryKode',
    );
    _currentTransKode = transKode;
    _currentKryKode = kryKode;

    // 1. Cek dan minta izin lokasi dari pengguna
    bool permissionGranted = await _handleLocationPermission();
    if (!permissionGranted) {
      print(
        '🚫 [LocationService] Izin lokasi tidak diberikan. Pelacakan dibatalkan.',
      );
      return;
    }

    // Hentikan stream lama jika ada (untuk keamanan)
    await stopTracking();

    // 4. Also start foreground tracking as fallback
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high, // Akurasi tertinggi untuk pelacakan
      distanceFilter: 0, // Tidak ada filter jarak, update berdasarkan waktu
    );

    // 5. Mulai mendengarkan perubahan posisi (foreground)
    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        print(
          '📍 [LocationService] Foreground posisi baru: ${position.latitude}, ${position.longitude}',
        );
        _onPositionUpdate(position);
      },
      onError: (error) {
        print('❌ [LocationService] Error pada stream lokasi: $error');
        // Mungkin GPS mati atau ada masalah lain
        _isTracking = false;
      },
    );

    // 6. Mulai timer untuk update lokasi setiap 30 detik sebagai fallback (lebih jarang untuk efisiensi)
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!_isTracking) {
        timer.cancel();
        return;
      }

      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        print(
          '⏰ [LocationService] Timer update posisi: ${position.latitude}, ${position.longitude}',
        );
        _onPositionUpdate(position);
      } catch (e) {
        print('❌ [LocationService] Error getting position from timer: $e');
      }
    });

    _isTracking = true;

    // Save tracking state to SharedPreferences for background sync
    await _saveTrackingState();

    print('✅ [LocationService] Pelacakan berhasil dimulai (foreground + background).');
  }

  /// Dipanggil setiap kali ada posisi baru dari Geolocator.
  void _onPositionUpdate(Position position) {
    // Pastikan data yang dibutuhkan lengkap sebelum mengirim ke server
    if (_currentTransKode == null || _currentKryKode == null || !_isTracking) {
      return;
    }

    // Panggil API untuk mengirim data lokasi ke server
    ApiService.updateDriverLocation(
      transKode: _currentTransKode!,
      kryKode: _currentKryKode!,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  /// Menghentikan proses pelacakan lokasi.
  Future<void> stopTracking() async {
    if (!_isTracking) {
      // Jika memang sudah tidak aktif, tidak perlu melakukan apa-apa.
      return;
    }
    print('🛑 [LocationService] Menghentikan pelacakan...');

    // Stop foreground tracking
    await _positionStream?.cancel();
    _positionStream = null;

    if (_locationTimer != null) {
      _locationTimer!.cancel();
      _locationTimer = null;
    }

    _isTracking = false;
    _currentTransKode = null;
    _currentKryKode = null;

    // Clear tracking state from SharedPreferences
    await _clearTrackingState();

    print('✅ [LocationService] Pelacakan berhasil dihentikan.');
  }

  /// Save tracking state to SharedPreferences for background sync
  Future<void> _saveTrackingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('location_tracking_active', _isTracking);
      if (_currentTransKode != null) {
        await prefs.setString('current_trans_kode', _currentTransKode!);
      }
      if (_currentKryKode != null) {
        await prefs.setString('current_kry_kode', _currentKryKode!);
      }
    } catch (e) {
      print('❌ [LocationService] Failed to save tracking state: $e');
    }
  }

  /// Clear tracking state from SharedPreferences
  Future<void> _clearTrackingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('location_tracking_active');
      await prefs.remove('current_trans_kode');
      await prefs.remove('current_kry_kode');
    } catch (e) {
      print('❌ [LocationService] Failed to clear tracking state: $e');
    }
  }

  /// Fungsi internal untuk menangani logika perizinan lokasi.
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Cek apakah layanan lokasi di perangkat aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('⚠️ [LocationService] Layanan lokasi (GPS) mati.');
      // Anda bisa menampilkan dialog untuk meminta user menyalakan GPS
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('🚫 [LocationService] Pengguna menolak izin lokasi.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print(
        '🚫 [LocationService] Izin lokasi ditolak permanen. Buka pengaturan aplikasi.',
      );
      // Anda bisa menampilkan dialog yang mengarahkan user ke pengaturan aplikasi
      return false;
    }

    // Jika izin diberikan
    return true;
  }
}
