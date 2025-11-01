import 'package:e_service/Beli/shop.dart';
import 'package:e_service/Home/Home.dart';
import 'package:e_service/Others/notifikasi.dart';
import 'package:e_service/Profile/profile.dart';
import 'package:e_service/Promo/promo.dart';
import 'package:e_service/Service/Service.dart';
import 'package:e_service/api_services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'progres_service.dart';
import 'teknisi_status.dart';

class TrackingPage extends StatefulWidget {
  final String? queueCode;

  const TrackingPage({super.key, this.queueCode});

  @override
  State<TrackingPage> createState() => _ServicePageState();
}

class _ServicePageState extends State<TrackingPage> {
  int currentIndex = 0;

  LatLng? _userLocation;
  LatLng _driverLocation = const LatLng(
    -6.256606,
    107.075187,
  ); // 📍 Default location (Tambun)
  List<LatLng> _routePoints = [];

  Timer? _locationPollingTimer;

  final mapController = MapController();

  // Data dari queue code
  String nama = "Udin";
  String device = "Laptop";
  String merek = "Asus";
  String seri = "xxxxxxxxxx";
  String layanan = "Cleaning";
  String jamMulai = "10.00";
  String jamSelesai = "-";
  List<String> jenisLayanan = [];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _parseQueueCode();
    _startLocationPolling();
  }

  @override
  void dispose() {
    _locationPollingTimer?.cancel();
    super.dispose();
  }

  void _startLocationPolling() {
    _locationPollingTimer = Timer.periodic(const Duration(seconds: 3), (
      timer,
    ) async {
      if (widget.queueCode != null && widget.queueCode!.isNotEmpty) {
        try {
          final locationData = await ApiService.getDriverLocation(
            widget.queueCode!,
          );
          if (locationData['success'] == true &&
              locationData['latitude'] != null) {
            final newLat = double.parse(locationData['latitude'].toString());
            final newLng = double.parse(locationData['longitude'].toString());

            setState(() {
              _driverLocation = LatLng(newLat, newLng);
            });

            // Update route if user location is available
            if (_userLocation != null) {
              await _getPolylineRoute();
            }

            print('📍 Driver location updated: $newLat, $newLng');
          }
        } catch (e) {
          print('❌ Failed to poll driver location: $e');
        }
      }
    });
  }

  void _parseQueueCode() async {
    if (widget.queueCode != null && widget.queueCode!.isNotEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Ambil data dari SharedPreferences berdasarkan queue code
      String? namaFromPrefs = prefs.getString('${widget.queueCode}_nama');
      String? serviceTypeFromPrefs = prefs.getString(
        '${widget.queueCode}_serviceType',
      );
      String? deviceFromPrefs = prefs.getString('${widget.queueCode}_device');
      String? merekFromPrefs = prefs.getString('${widget.queueCode}_merek');
      String? seriFromPrefs = prefs.getString('${widget.queueCode}_seri');
      String? jamMulaiFromPrefs = prefs.getString(
        '${widget.queueCode}_jamMulai',
      );

      // Debug print untuk melihat data yang diambil
      print('Data diambil untuk kode: ${widget.queueCode}');
      print('Nama: $namaFromPrefs');
      print('Service Type: $serviceTypeFromPrefs');
      print('Device: $deviceFromPrefs');
      print('Merek: $merekFromPrefs');
      print('Seri: $seriFromPrefs');
      print('Jam Mulai: $jamMulaiFromPrefs');

      setState(() {
        nama = namaFromPrefs ?? nama;
        device = deviceFromPrefs ?? device;
        merek = merekFromPrefs ?? merek;
        seri = seriFromPrefs ?? seri;
        layanan = serviceTypeFromPrefs == 'cleaning' ? 'Cleaning' : 'Perbaikan';
        jamMulai =
            jamMulaiFromPrefs != null
                ? _formatTime(jamMulaiFromPrefs)
                : jamMulai;

        // Set jenis layanan berdasarkan service type
        if (serviceTypeFromPrefs == 'cleaning') {
          jenisLayanan = ["Pembersihan Hardware", "Pembersihan Software"];
        } else if (serviceTypeFromPrefs == 'repair') {
          jenisLayanan = ["Upgrade RAM", "Upgrade SSD"];
        }
      });
    }
  }

  String _formatTime(String dateTimeString) {
    DateTime dateTime = DateTime.parse(dateTimeString);
    return '${dateTime.hour.toString().padLeft(2, '0')}.${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
    });

    await _getPolylineRoute();
  }

  Future<void> _getPolylineRoute() async {
    if (_userLocation == null) return;

    final url =
        'https://router.project-osrm.org/route/v1/driving/${_driverLocation.longitude},${_driverLocation.latitude};${_userLocation!.longitude},${_userLocation!.latitude}?geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);
      final coords =
          data['routes'][0]['geometry']['coordinates'] as List<dynamic>;

      setState(() {
        _routePoints =
            coords.map((c) => LatLng(c[1] as double, c[0] as double)).toList();
      });
    } catch (e) {
      debugPrint("Gagal ambil rute: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: Image.asset('assets/image/logo.png', width: 95, height: 30),
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: _bottomNavBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow("Nama", nama, "Jam Mulai", jamMulai),
                  const SizedBox(height: 8),
                  _infoRow("Device", device, "Jam Selesai", jamSelesai),
                  const SizedBox(height: 8),
                  _infoRow("Merek", merek, "", ""),
                  const SizedBox(height: 8),
                  _infoRow("Seri", seri, "", ""),
                  const SizedBox(height: 8),
                  _infoRow("Layanan", layanan, "", ""),
                  const SizedBox(height: 12),

                  // 🗺️ Map tampilan mini tracking
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[200],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildMap(),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statusBox(
                        color: Colors.green,
                        icon: Icons.check_circle_outline,
                        label: 'Menerima pesanan',
                      ),
                      _statusBox(
                        color: Colors.orange,
                        icon: Icons.timelapse,
                        label: 'Menuju lokasi',
                      ),
                      _statusBox(
                        color: Colors.red,
                        icon: Icons.schedule_outlined,
                        label: 'Sampai Lokasi',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _legendDot(Colors.green, "Selesai"),
                          const SizedBox(width: 6),
                          _legendDot(Colors.orange, "Proses"),
                          const SizedBox(width: 6),
                          _legendDot(Colors.red, "Menunggu"),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => TeknisiStatusPage(
                                    queueCode: widget.queueCode ?? '',
                                    serviceType:
                                        layanan == 'Cleaning'
                                            ? 'cleaning'
                                            : 'repair',
                                    nama: nama,
                                    jumlahBarang: 1, // Assuming 1 item for now
                                    items: [
                                      {
                                        'merek': merek,
                                        'device': device,
                                        'seri': seri,
                                        'status': '',
                                        'part': '',
                                      },
                                    ],
                                    alamat:
                                        'Default Address', // Need to get from prefs or pass properly
                                  ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Colors.black26),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          'Status Service',
                          style: GoogleFonts.poppins(
                            color: Colors.black87,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    if (_userLocation == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(initialCenter: _driverLocation, initialZoom: 13),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.azzahra.e_service',
        ),
        if (_routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                color: Colors.blueAccent,
                strokeWidth: 4,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            // Lokasi User 🟢
            Marker(
              point: _userLocation!,
              width: 16,
              height: 16,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Lokasi Driver 🛵
            Marker(
              point: _driverLocation,
              width: 40,
              height: 40,
              child: Transform.rotate(
                angle: 0,
                child: const Icon(
                  Icons.motorcycle,
                  color: Colors.blue,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- komponen UI pendukung ---

  Widget _infoRow(String label1, String value1, String label2, String value2) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label1,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value1,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (label2.isNotEmpty)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label2,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value2,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _chipService(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue[800]),
      ),
    );
  }

  Widget _statusBox({
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 12)),
      ],
    );
  }

  Widget _bottomNavBar() {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == 0) {
          // Service - stay on current page or navigate to service page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ServicePage()),
          );
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MarketplacePage()),
          );
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else if (index == 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TukarPoinPage()),
          );
        } else if (index == 4) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          );
        }
      },
      backgroundColor: Colors.blue,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      showUnselectedLabels: true,
      selectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
      unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.build_circle_outlined),
          label: 'Service',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart_outlined),
          label: 'Beli',
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon:
              currentIndex == 3
                  ? Image.asset('assets/image/promo.png', width: 24, height: 24)
                  : Opacity(
                    opacity: 0.6,
                    child: Image.asset(
                      'assets/image/promo.png',
                      width: 24,
                      height: 24,
                    ),
                  ),
          label: 'Promo',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}
