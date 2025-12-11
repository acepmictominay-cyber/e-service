import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:azza_service/config/api_config.dart';
import 'package:azza_service/api_services/api_service.dart';
import 'package:azza_service/Others/session_manager.dart';

class DetailAlamatPage extends StatefulWidget {
  const DetailAlamatPage({super.key});

  @override
  State<DetailAlamatPage> createState() => _DetailAlamatPageState();
}

class _DetailAlamatPageState extends State<DetailAlamatPage> {
  final TextEditingController labelController = TextEditingController();
  final TextEditingController detailController = TextEditingController();
  final TextEditingController catatanController = TextEditingController();
  final TextEditingController namaController = TextEditingController();
  final TextEditingController hpController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  Map<String, dynamic>? userData;

  bool jadikanUtama = false;
  bool _loading = true;
  bool _isGettingLocation = false;

  String _alamat = "Mendeteksi lokasi...";
  String _accuracy = "";
  String _provider = "";
  LatLng _currentLatLng = const LatLng(-6.200000, 106.816666);
  final MapController _mapController = MapController();

  Timer? _debounce;
  Position? _currentPosition;
  final List<Position> _positionHistory = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initializeLocationWithMaxAccuracy();
  }

  void _loadUserData() async {
    final session = await SessionManager.getUserSession();
    final userId = session['id'] as String?;
    if (userId != null) {
      try {
        final data = await ApiService.getCostomerById(userId);
        setState(() {
          userData = data;
          // Auto-fill name and phone from customer data
          namaController.text = data['cos_nama'] ?? '';
          hpController.text = data['cos_hp'] ?? '';
        });
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    labelController.dispose();
    detailController.dispose();
    catatanController.dispose();
    namaController.dispose();
    hpController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocationWithMaxAccuracy() async {
    setState(() {
      _loading = true;
      _alamat = "Mempersiapkan GPS...";
    });

    final hasPermission = await _ensureLocationServicesOptimal();
    if (!hasPermission) {
      setState(() {
        _loading = false;
        _alamat = "GPS tidak aktif atau izin ditolak";
      });
      return;
    }

    await Future.delayed(const Duration(seconds: 2));
    await _getUltraHighAccuracyLocation();
  }

  Future<bool> _ensureLocationServicesOptimal() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          final shouldOpenSettings = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  title: const Text('GPS Tidak Aktif'),
                  content: const Text(
                    'Untuk mendapatkan lokasi yang akurat, GPS harus diaktifkan.\n\n'
                    'Tips: Pastikan mode lokasi di setting adalah "Akurasi Tinggi" atau "High Accuracy".',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Buka Pengaturan'),
                    ),
                  ],
                ),
              ) ??
              false;

          if (shouldOpenSettings) {
            await Geolocator.openLocationSettings();
            await Future.delayed(const Duration(seconds: 3));
            serviceEnabled = await Geolocator.isLocationServiceEnabled();
          }
        }

        if (!serviceEnabled) return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Izin lokasi diperlukan untuk melanjutkan'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          final shouldOpenSettings = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Izin Lokasi Ditolak'),
                  content: const Text(
                    'Aplikasi memerlukan izin lokasi untuk menentukan alamat Anda.\n\n'
                    'Silakan aktifkan izin lokasi di pengaturan aplikasi.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Buka Pengaturan'),
                    ),
                  ],
                ),
              ) ??
              false;

          if (shouldOpenSettings) {
            await Geolocator.openAppSettings();
            return false;
          }
        }
        return false;
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      debugPrint("Error ensuring location services: $e");
      return false;
    }
  }

  Future<void> _getUltraHighAccuracyLocation() async {
    if (_isGettingLocation) return;

    setState(() {
      _isGettingLocation = true;
      _loading = true;
      _alamat = "Mengkalibrasi GPS (0%)...";
    });

    try {
      _positionHistory.clear();
      Position? bestPosition;
      double bestAccuracy = double.infinity;

      const int sampleCount = 5;

      for (int i = 0; i < sampleCount; i++) {
        setState(() {
          _alamat =
              "Mengkalibrasi GPS (${((i + 1) / sampleCount * 100).round()}%)...";
        });

        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.bestForNavigation,
            forceAndroidLocationManager: false,
            timeLimit: const Duration(seconds: 10),
          ).timeout(
            const Duration(seconds: 12),
            onTimeout: () async {
              final lastKnown = await Geolocator.getLastKnownPosition();
              if (lastKnown != null) return lastKnown;
              throw TimeoutException('GPS timeout');
            },
          );

          _positionHistory.add(position);

          if (position.accuracy < bestAccuracy) {
            bestAccuracy = position.accuracy;
            bestPosition = position;
          }

          if (position.accuracy <= 5) {
            debugPrint("Excellent accuracy achieved: ${position.accuracy}m");
            break;
          }

          if (i < sampleCount - 1) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } catch (e) {
          debugPrint("Sample $i error: $e");
        }
      }

      Position finalPosition;

      if (_positionHistory.length > 1) {
        double avgLat = 0;
        double avgLon = 0;
        double avgAlt = 0;
        double totalWeight = 0;

        for (final pos in _positionHistory) {
          double weight = 1 / (pos.accuracy + 1);
          avgLat += pos.latitude * weight;
          avgLon += pos.longitude * weight;
          avgAlt += pos.altitude * weight;
          totalWeight += weight;
        }

        avgLat /= totalWeight;
        avgLon /= totalWeight;
        avgAlt /= totalWeight;

        finalPosition = Position(
          latitude: avgLat,
          longitude: avgLon,
          altitude: avgAlt,
          accuracy: bestPosition?.accuracy ?? bestAccuracy,
          timestamp: DateTime.now(),
          heading: bestPosition?.heading ?? 0,
          speed: bestPosition?.speed ?? 0,
          speedAccuracy: bestPosition?.speedAccuracy ?? 0,
          altitudeAccuracy: bestPosition?.altitudeAccuracy ?? 0,
          headingAccuracy: bestPosition?.headingAccuracy ?? 0,
        );

        _provider = "GPS Presisi Tinggi (Averaged)";
      } else if (bestPosition != null) {
        finalPosition = bestPosition;
        _provider = "GPS Presisi Tinggi";
      } else {
        finalPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          forceAndroidLocationManager: true,
        );
        _provider = "GPS Standard";
      }

      _currentPosition = finalPosition;
      final latLng = LatLng(finalPosition.latitude, finalPosition.longitude);

      setState(() {
        _accuracy = "${finalPosition.accuracy.toStringAsFixed(1)}m";
        _currentLatLng = latLng;
      });

      await _updateAddressFromLatLng(latLng, moveMap: true);

      if (mounted) {
        Color accuracyColor;
        String accuracyText;

        if (finalPosition.accuracy <= 5) {
          accuracyColor = Colors.green;
          accuracyText = "Sangat Akurat";
        } else if (finalPosition.accuracy <= 10) {
          accuracyColor = const Color(0xFF0041c3);
          accuracyText = "Akurat";
        } else if (finalPosition.accuracy <= 20) {
          accuracyColor = Colors.orange;
          accuracyText = "Cukup Akurat";
        } else {
          accuracyColor = Colors.red;
          accuracyText = "Kurang Akurat";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.gps_fixed, color: accuracyColor),
                const SizedBox(width: 8),
                Text(
                  "$accuracyText (±${finalPosition.accuracy.toStringAsFixed(0)}m)",
                ),
              ],
            ),
            backgroundColor: accuracyColor.withOpacity(0.9),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _alamat = "Gagal mendapatkan lokasi";
        _loading = false;
      });

      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          _currentPosition = lastKnown;
          final latLng = LatLng(lastKnown.latitude, lastKnown.longitude);
          await _updateAddressFromLatLng(latLng, moveMap: true);
        }
      } catch (_) {}
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  Future<String> _getAddressFromCoordinates(double lat, double lng) async {
    String bestAddress = "";

    lat = double.parse(lat.toStringAsFixed(6));
    lng = double.parse(lng.toStringAsFixed(6));

    try {
      final placemarks = await placemarkFromCoordinates(
        lat,
        lng,
      ).timeout(const Duration(seconds: 5));

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final List<String> components = [];

        if (p.name != null && p.name!.isNotEmpty) components.add(p.name!);
        if (p.street != null && p.street!.isNotEmpty) components.add(p.street!);
        if (p.subLocality != null && p.subLocality!.isNotEmpty) {
          components.add(p.subLocality!);
        }
        if (p.locality != null && p.locality!.isNotEmpty) {
          components.add(p.locality!);
        }
        if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) {
          components.add(p.administrativeArea!);
        }
        if (p.postalCode != null && p.postalCode!.isNotEmpty) {
          components.add(p.postalCode!);
        }

        bestAddress = components.join(', ');
        if (bestAddress.isNotEmpty) return bestAddress;
      }
    } catch (e) {
      debugPrint("Device geocoding error: $e");
    }

    try {
      final nominatimUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=jsonv2'
        '&lat=$lat'
        '&lon=$lng'
        '&zoom=19'
        '&addressdetails=1'
        '&namedetails=1'
        '&extratags=1'
        '&accept-language=id'
        '&countrycodes=id',
      );

      final response = await http.get(
        nominatimUrl,
        headers: {
          'User-Agent': 'E-Service-App/1.0',
          'Referer': 'https://e-service.app',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] ?? {};
        final List<String> components = [];

        if (address['house_number'] != null) {
          components.add(address['house_number']);
        }
        if (address['road'] != null) components.add(address['road']);
        if (address['village'] != null) components.add(address['village']);
        if (address['hamlet'] != null) components.add(address['hamlet']);
        if (address['neighbourhood'] != null) {
          components.add(address['neighbourhood']);
        }
        if (address['suburb'] != null) components.add(address['suburb']);
        if (address['city'] != null) components.add(address['city']);
        if (address['state'] != null) components.add(address['state']);
        if (address['postcode'] != null) components.add(address['postcode']);

        if (components.isNotEmpty) {
          bestAddress = components.join(', ');
        } else if (data['display_name'] != null) {
          bestAddress = data['display_name'];
        }

        if (bestAddress.isNotEmpty) return bestAddress;
      }
    } catch (e) {
      debugPrint("Nominatim error: $e");
    }

    const apiKey = ApiConfig.googleMapsApiKey;
    if (apiKey.isNotEmpty) {
      try {
        final googleUrl = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=$lat,$lng'
          '&key=$apiKey'
          '&language=id'
          '&components=country:ID',
        );

        final response =
            await http.get(googleUrl).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' && data['results'].isNotEmpty) {
            bestAddress = data['results'][0]['formatted_address'];
            return bestAddress;
          }
        }
      } catch (e) {
        debugPrint("Google Maps geocoding error: $e");
      }
    }

    if (bestAddress.isEmpty) {
      bestAddress =
          "Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}";
    }

    return bestAddress;
  }

  Future<void> _updateAddressFromLatLng(
    LatLng latLng, {
    bool moveMap = false,
  }) async {
    setState(() {
      _loading = true;
      _currentLatLng = latLng;
    });

    _alamat = await _getAddressFromCoordinates(
      latLng.latitude,
      latLng.longitude,
    );
    detailController.text = _alamat;

    if (moveMap) {
      try {
        _mapController.move(latLng, 19);
      } catch (e) {
        debugPrint("Map controller error: $e");
      }
    }

    setState(() => _loading = false);
  }

  Future<void> _searchAddress(String address) async {
    if (address.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _alamat = "Mencari alamat...";
    });
    try {
      LatLng? foundLatLng;
      final trimmedAddress = address.trim();
      if (ApiConfig.googleMapsApiKey.isNotEmpty) {
        final googleUrl = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(trimmedAddress)}&key=${ApiConfig.googleMapsApiKey}&language=id',
        );
        final response =
            await http.get(googleUrl).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' && data['results'].isNotEmpty) {
            final location = data['results'][0]['geometry']['location'];
            foundLatLng = LatLng(location['lat'], location['lng']);
          }
        }
      }
      if (foundLatLng == null) {
        final nominatimUrl = Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(trimmedAddress)}&limit=1&accept-language=id',
        );
        final response = await http.get(
          nominatimUrl,
          headers: {
            'User-Agent': 'E-Service-App/1.0',
            'Referer': 'https://e-service.app',
          },
        ).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data.isNotEmpty) {
            foundLatLng = LatLng(
              double.parse(data[0]['lat']),
              double.parse(data[0]['lon']),
            );
          }
        }
      }
      if (foundLatLng != null) {
        _currentPosition = Position(
          latitude: foundLatLng.latitude,
          longitude: foundLatLng.longitude,
          accuracy: 0,
          timestamp: DateTime.now(),
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
        setState(() {
          _currentLatLng = foundLatLng!;
          _alamat = trimmedAddress;
          detailController.text = trimmedAddress;
          _accuracy = "0.0m";
          _provider = "Pencarian Alamat";
          _loading = false;
        });
        try {
          _mapController.move(foundLatLng, 19);
        } catch (e) {
          debugPrint("Map controller error: $e");
        }
        searchController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Alamat ditemukan dan dipindahkan ke peta"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _alamat = "Alamat tidak ditemukan. Coba kata kunci lain.";
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Alamat tidak ditemukan"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Search address error: $e");
      setState(() {
        _alamat = "Gagal mencari alamat";
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal mencari alamat"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _simpanAlamat() async {
    if (labelController.text.isEmpty ||
        detailController.text.isEmpty ||
        namaController.text.isEmpty ||
        hpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Harap isi semua field wajib"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final addressData = {
      'label': labelController.text,
      'detailAlamat': detailController.text,
      'catatan': catatanController.text,
      'nama': namaController.text,
      'hp': hpController.text,
      'jadikanUtama': jadikanUtama,
      'alamat': _alamat,
      'latitude': _currentLatLng.latitude,
      'longitude': _currentLatLng.longitude,
      'accuracy': _currentPosition?.accuracy ?? 0,
      'altitude': _currentPosition?.altitude ?? 0,
      'provider': _provider,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // If jadikanUtama is true, save address to customer cos_alamat
    if (jadikanUtama) {
      try {
        final customerId = await SessionManager.getCustomerId();
        if (customerId != null) {
          await ApiService.updateCostomer(customerId, {'cos_alamat': _alamat});
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Alamat utama berhasil disimpan"),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal menyimpan alamat utama: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    Navigator.pop(context, addressData);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final mapHeight = screenHeight * 0.35; // 35% of screen height

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[900]
          : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : const Color(0xFF0041c3),
        title: Text(
          "Detail Alamat",
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.white,
            fontSize: 18,
          ),
        ),
        iconTheme: IconThemeData(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.white,
        ),
        actions: [
          if (_accuracy.isNotEmpty || _provider.isNotEmpty)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_provider.isNotEmpty)
                      Text(
                        _provider,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white70,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (_accuracy.isNotEmpty)
                      Text(
                        "±$_accuracy",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            children: [
              // MAP Section - Responsive height
              SizedBox(
                height: mapHeight.clamp(250.0, 400.0),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentLatLng,
                        initialZoom: 18,
                        minZoom: 12,
                        maxZoom: 22,
                        interactionOptions: const InteractionOptions(
                          enableMultiFingerGestureRace: true,
                          pinchZoomThreshold: 0.5,
                          rotationThreshold: 15.0,
                          pinchMoveThreshold: 20.0,
                        ),
                        onMapEvent: (event) {
                          if (event is MapEventMove ||
                              event is MapEventMoveEnd) {
                            if (_debounce?.isActive ?? false) {
                              _debounce!.cancel();
                            }
                            _debounce = Timer(
                              const Duration(milliseconds: 300),
                              () {
                                final center = _mapController.camera.center;
                                _updateAddressFromLatLng(center);
                              },
                            );
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                          subdomains: const ["a", "b", "c"],
                          maxZoom: 22,
                          maxNativeZoom: 19,
                        ),
                        if (_currentPosition != null)
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                point: LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                ),
                                radius: 3,
                                color: const Color(0xFF0041c3),
                                borderStrokeWidth: 2,
                                borderColor: Colors.white,
                              ),
                              CircleMarker(
                                point: LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                ),
                                radius: _currentPosition!.accuracy.clamp(
                                  5,
                                  100,
                                ),
                                color: const Color(
                                  0xFF0041c3,
                                ).withOpacity(0.1),
                                borderStrokeWidth: 2,
                                borderColor: const Color(
                                  0xFF0041c3,
                                ).withOpacity(0.3),
                              ),
                            ],
                          ),
                      ],
                    ),

                    // Center Marker
                    const Center(
                      child: Icon(
                        Icons.location_pin,
                        size: 40,
                        color: Colors.red,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),

                    // Map Controls
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.add, size: 20),
                                  onPressed: () {
                                    final zoom =
                                        (_mapController.camera.zoom + 1)
                                            .clamp(12.0, 22.0);
                                    _mapController.move(
                                      _mapController.camera.center,
                                      zoom,
                                    );
                                  },
                                  color: const Color(0xFF0041c3),
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(),
                                ),
                                Container(height: 1, color: Colors.grey[300]),
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 20),
                                  onPressed: () {
                                    final zoom =
                                        (_mapController.camera.zoom - 1)
                                            .clamp(12.0, 22.0);
                                    _mapController.move(
                                      _mapController.camera.center,
                                      zoom,
                                    );
                                  },
                                  color: const Color(0xFF0041c3),
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton(
                            mini: true,
                            onPressed: _isGettingLocation
                                ? null
                                : _getUltraHighAccuracyLocation,
                            backgroundColor: Colors.white,
                            child: _isGettingLocation
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF0041c3),
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.gps_fixed,
                                    size: 20,
                                    color: _currentPosition != null &&
                                            _currentPosition!.accuracy <= 10
                                        ? Colors.green
                                        : const Color(0xFF0041c3),
                                  ),
                          ),
                        ],
                      ),
                    ),

                    // Accuracy indicator
                    if (_currentPosition != null)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _currentPosition!.accuracy <= 10
                                ? Colors.green
                                : _currentPosition!.accuracy <= 20
                                    ? Colors.orange
                                    : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.radar,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                "±${_currentPosition!.accuracy.toStringAsFixed(0)}m",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ADDRESS DISPLAY
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _alamat,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 26, top: 2),
                      child: Text(
                        "${_currentLatLng.latitude.toStringAsFixed(6)}, ${_currentLatLng.longitude.toStringAsFixed(6)}",
                        style: TextStyle(
                          fontSize: 9,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ADDRESS SEARCH
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: "Cari alamat untuk akurasi lebih baik...",
                          prefixIcon: const Icon(Icons.search, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 12),
                        onSubmitted: _searchAddress,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _searchAddress(searchController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0041c3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Cari",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              // FORM Section
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildCompactTextField(
                      "Label Alamat*",
                      labelController,
                      hint: "Rumah, Kantor, dll",
                      icon: Icons.label_outline,
                    ),
                    _buildCompactTextField(
                      "Detail Alamat*",
                      detailController,
                      maxLines: 2,
                      hint: "Alamat lengkap (otomatis terisi)",
                      icon: Icons.home_outlined,
                    ),
                    _buildCompactTextField(
                      "Catatan Untuk Teknisi",
                      catatanController,
                      hint: "Patokan, warna rumah",
                      icon: Icons.note_outlined,
                    ),
                    _buildCompactTextField(
                      "Nama Penerima*",
                      namaController,
                      hint: "Nama lengkap",
                      icon: Icons.person_outline,
                      enabled: true,
                    ),
                    _buildCompactTextField(
                      "No. HP*",
                      hpController,
                      keyboardType: TextInputType.phone,
                      hint: "08xx-xxxx-xxxx",
                      icon: Icons.phone_outlined,
                      enabled: true,
                    ),

                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[700]
                            : const Color(0xFF0041c3).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[600]!
                              : const Color(0xFF0041c3).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star_outline,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : const Color(0xFF0041c3),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Jadikan alamat utama",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: 0.9,
                            child: Switch(
                              value: jadikanUtama,
                              onChanged: (v) =>
                                  setState(() => jadikanUtama = v),
                              activeThumbColor: const Color(0xFF0041c3),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    ElevatedButton(
                      onPressed: _simpanAlamat,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0041c3),
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            "Simpan Alamat",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20), // Bottom padding
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hint,
    IconData? icon,
    bool enabled = true,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            enabled: enabled,
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                fontSize: 12,
              ),
              filled: true,
              fillColor: enabled
                  ? (isDarkMode ? Colors.grey[800] : const Color(0xFFF8F9FA))
                  : (isDarkMode ? Colors.grey[700] : Colors.grey.shade100),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDarkMode ? Colors.grey[500]! : Colors.grey[300]!,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF0041c3),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}
