import 'package:e_service/Beli/shop.dart';
import 'package:e_service/Home/Home.dart';
import 'package:e_service/Profile/profile.dart';
import 'package:e_service/Promo/promo.dart';
import 'package:e_service/Service/Service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/services.dart';


class PesanServicePage extends StatefulWidget {
  const PesanServicePage({super.key});

  @override
  State<PesanServicePage> createState() => _PesanServicePageState();
}

class _PesanServicePageState extends State<PesanServicePage> {
  int currentIndex = 0;

  final TextEditingController namaController = TextEditingController();
  final TextEditingController seriController = TextEditingController();
  final TextEditingController kerusakanController = TextEditingController();
  final TextEditingController alamatController = TextEditingController();

  String? selectedMerek;
  String? selectedDevice;

  final List<String> merekOptions = ['Asus', 'Dell', 'HP', 'Lenovo', 'Apple', 'Samsung', 'Sony', 'Toshiba'];
  final List<String> deviceOptions = ['Laptop', 'Desktop', 'Tablet', 'Smartphone', 'Printer', 'Monitor', 'Keyboard', 'Mouse'];

  GoogleMapController? mapController;
  LatLng? currentPosition;
  String? currentAddress;
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Layanan lokasi dinonaktifkan.")),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Izin lokasi ditolak.")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Izin lokasi ditolak permanen.")),
      );
      return;
    }

    // ✅ Ambil posisi awal
    Position position = await Geolocator.getCurrentPosition();
    await _updateLocation(position);

    // ✅ Update lokasi real-time (bergerak)
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5, // update tiap geser 5 meter
      ),
    ).listen((Position position) {
      _updateLocation(position, moveCamera: true);
    });
  }

  Future<void> _updateLocation(Position position, {bool moveCamera = false}) async {
    LatLng newPos = LatLng(position.latitude, position.longitude);

    // Kalau sudah ada marker lama, animasikan pergerakannya
    if (currentPosition != null) {
      _animateMarkerMovement(currentPosition!, newPos);
    }

    setState(() {
      currentPosition = newPos;
    });

    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks.first;
      setState(() {
        currentAddress =
            "${place.street}, ${place.subThoroughfare ?? ''}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}";
        alamatController.text = currentAddress ?? "";
      });
    } catch (e) {
      debugPrint("Gagal mendapatkan alamat: $e");
    }

    if (mapController != null && moveCamera) {
      mapController!.animateCamera(
        CameraUpdate.newLatLng(newPos),
      );
    }
  }

  void _animateMarkerMovement(LatLng from, LatLng to) async {
    // Waktu animasi (ms)
    const int steps = 30;
    const Duration stepDuration = Duration(milliseconds: 30);

    double latDiff = to.latitude - from.latitude;
    double lngDiff = to.longitude - from.longitude;

    for (int i = 1; i <= steps; i++) {
      await Future.delayed(stepDuration);
      double lat = from.latitude + (latDiff * (i / steps));
      double lng = from.longitude + (lngDiff * (i / steps));

      setState(() {
        markers = {
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: LatLng(lat, lng),
            infoWindow: const InfoWindow(title: 'Lokasi Anda Sekarang'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          ),
        };
      });
    }
  }

  void _showSuccessPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // biar gak bisa ditutup klik luar
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                decoration: BoxDecoration(
                  color: const Color(0xFF90CAF9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Pesanan Berhasil",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Tim pick-up kami akan segera sampai,\n"
                            "mohon menunggu selama beberapa menit",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black87),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1976D2),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Center(
                              child: Text(
                                "######",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Salin kode antrean untuk mengetahui\n"
                            "perkembangan service anda",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const ServicePage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text("Kembali", style: TextStyle(color: Colors.white)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Clipboard.setData(const ClipboardData(text: "######"));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Kode berhasil disalin")),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text("Salin Kode", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

    // ==== BODY ====
body: Column(
  children: [
    // ==== HEADER TETAP ====
    Container(
      height: 130,
      decoration: const BoxDecoration(
        color: Color(0xFF1976D2),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Image.asset('assets/image/logo.png', width: 130, height: 40),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.support_agent, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    ),

    // ==== KONTEN YANG BISA DI SCROLL ====
    Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 20, bottom: 100),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _inputField("Nama", namaController),
                  const SizedBox(height: 8),
                  _dropdownField("Merek", selectedMerek, merekOptions, (value) {
                    setState(() {
                      selectedMerek = value;
                    });
                  }),
                  const SizedBox(height: 8),
                  _dropdownField("Device", selectedDevice, deviceOptions, (value) {
                    setState(() {
                      selectedDevice = value;
                    });
                  }),
                  const SizedBox(height: 8),
                  _inputField("Seri", seriController),
                  const SizedBox(height: 12),
                  const Text("Kerusakan :", style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Container(
                    height: 80,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: kerusakanController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Deskripsikan kerusakan...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("Alamat :", style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: TextField(
                            controller: alamatController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Masukkan atau dapatkan alamat...',
                            ),
                            onSubmitted: (value) async {
                              if (value.isNotEmpty) {
                                try {
                                  List<Location> locations = await locationFromAddress(value);
                                  if (locations.isNotEmpty) {
                                    Location location = locations.first;
                                    LatLng newPos = LatLng(location.latitude, location.longitude);
                                    setState(() {
                                      currentPosition = newPos;
                                      markers = {
                                        Marker(
                                          markerId: const MarkerId('selectedLocation'),
                                          position: newPos,
                                          infoWindow: const InfoWindow(title: 'Lokasi Penjemputan'),
                                        ),
                                      };
                                    });
                                    if (mapController != null) {
                                      mapController!.animateCamera(
                                        CameraUpdate.newLatLng(newPos),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  debugPrint("Gagal mendapatkan lokasi dari alamat: $e");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Alamat tidak ditemukan. Coba alamat yang lebih spesifik.")),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                        SizedBox(
                          height: 250,
                          child: currentPosition != null
                              ? GoogleMap(
                                  mapType: MapType.normal,
                                  myLocationEnabled: true,
                                  myLocationButtonEnabled: true,
                                  zoomControlsEnabled: false,
                                  initialCameraPosition: CameraPosition(
                                    target: currentPosition!,
                                    zoom: 17,
                                  ),
                                  markers: markers,
                                  onMapCreated: (GoogleMapController controller) {
                                    mapController = controller;
                                  },
                                  onTap: (LatLng pos) async {
                                    setState(() => currentPosition = pos);
                                    List<Placemark> placemarks =
                                        await placemarkFromCoordinates(pos.latitude, pos.longitude);
                                    Placemark place = placemarks.first;
                                    setState(() {
                                      currentAddress =
                                          "${place.street}, ${place.subThoroughfare ?? ''}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}";
                                      alamatController.text = currentAddress ?? "";
                                    });
                                    setState(() {
                                      markers.clear();
                                      markers.add(
                                        Marker(
                                          markerId: const MarkerId('selectedLocation'),
                                          position: pos,
                                          infoWindow: const InfoWindow(title: 'Lokasi Penjemputan'),
                                        ),
                                      );
                                    });
                                  },
                                )
                              : const Center(child: CircularProgressIndicator()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        _showSuccessPopup(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Pesan",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ],
),

      // ==== BOTTOM NAVIGATION ====
      bottomNavigationBar: BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        setState(() {
          currentIndex = index; // Update index
        });
        switch (index) {
          case 0:
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const ServicePage()));
            break;
          case 1:
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const MarketplacePage()));
            break;
          case 2:
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const HomePage()));
            break;
          case 3:
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const TukarPoinPage()));
            break;
          case 4:
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const ProfilePage()));
            break;
        }
      },
      backgroundColor: const Color(0xFF1976D2),
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
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: currentIndex == 3
              ? Image.asset('assets/image/promo.png', width: 24, height: 24)
              : Opacity(
                  opacity: 0.6,
                  child: Image.asset('assets/image/promo.png', width: 24, height: 24),
                ),
          label: 'Promo',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    ),

    );
  }

  void _showMapDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Lokasi Penjemputan'),
          content: SizedBox(
            height: 300,
            width: double.maxFinite,
            child: currentPosition != null
                ? GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: currentPosition!,
                      zoom: 15,
                    ),
                    markers: markers,
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                    },
                    onTap: (LatLng position) {
                      setState(() {
                        markers.clear();
                        markers.add(
                          Marker(
                            markerId: const MarkerId('selectedLocation'),
                            position: position,
                            infoWindow: const InfoWindow(title: 'Lokasi Penjemputan'),
                          ),
                        );
                        currentPosition = position;
                      });
                    },
                  )
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ==== WIDGET FIELD ====
  Widget _inputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label :", style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
            ),
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _dropdownField(String label, String? selectedValue, List<String> options, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label :", style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButton<String>(
            value: selectedValue,
            hint: const Text('Pilih...'),
            isExpanded: true,
            underline: const SizedBox(),
            items: options.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
