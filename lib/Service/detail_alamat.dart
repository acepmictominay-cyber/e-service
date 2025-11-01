import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

  bool jadikanUtama = false;
  bool _loading = true;
  bool _mapMoving = false;

  String _alamat = "Mendeteksi lokasi...";
  LatLng _currentLatLng = const LatLng(-6.200000, 106.816666);
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _loading = true);
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Layanan Lokasi Dinonaktifkan'),
            content: const Text(
              'Harap aktifkan layanan lokasi untuk menggunakan fitur ini.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _alamat = "GPS tidak aktif.";
                    _loading = false;
                  });
                },
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  bool opened = await Geolocator.openLocationSettings();
                  if (opened) {
                    _getCurrentLocation();
                  } else {
                    setState(() {
                      _alamat = "Tidak dapat membuka pengaturan.";
                      _loading = false;
                    });
                  }
                },
                child: const Text('Buka Pengaturan'),
              ),
            ],
          );
        },
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _alamat = "Izin lokasi ditolak.";
          _loading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _alamat = "Izin lokasi permanen ditolak.";
        _loading = false;
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _updateAddressFromLatLng(
      LatLng(position.latitude, position.longitude),
      moveMap: true,
    );
  }

  Future<void> _updateAddressFromLatLng(
    LatLng latLng, {
    bool moveMap = false,
  }) async {
    setState(() {
      _currentLatLng = latLng;
      _loading = true;
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _alamat =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}";
        detailController.text = _alamat;
      }
    } catch (_) {
      _alamat = "Gagal mendapatkan alamat.";
    }

    if (moveMap) {
      _mapController.move(latLng, 17);
    }

    setState(() => _loading = false);
  }

  void _pusatkanLokasi() {
    _mapController.move(_currentLatLng, 17);
  }

  void _simpanAlamat() {
    // Validation
    if (labelController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Label wajib diisi dan tidak boleh kosong'),
        ),
      );
      return;
    }
    if (detailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Detail Alamat wajib diisi dan tidak boleh kosong'),
        ),
      );
      return;
    }
    if (namaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama Penerima wajib diisi dan tidak boleh kosong'),
        ),
      );
      return;
    }
    if (hpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No. HP Penerima wajib diisi dan tidak boleh kosong'),
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
    };

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Alamat berhasil disimpan ✅")));

    Navigator.pop(context, addressData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          "Detail Alamat",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Map
              SizedBox(
                height: 250,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentLatLng,
                        initialZoom: 17,
                        onPositionChanged: (pos, hasGesture) {
                          if (hasGesture) _mapMoving = true;
                        },
                        onMapEvent: (event) {
                          if (event is MapEventMoveEnd && _mapMoving) {
                            _updateAddressFromLatLng(
                              _mapController.camera.center,
                            );
                            _mapMoving = false;
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                          subdomains: const ['a', 'b', 'c'],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _currentLatLng,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.redAccent,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: FloatingActionButton(
                        heroTag: "center",
                        mini: true,
                        backgroundColor: Colors.white,
                        onPressed: _pusatkanLokasi,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Alamat teks
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _alamat,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.blueAccent),
                      onPressed: _getCurrentLocation,
                    ),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField("Label*", labelController),
                        _buildTextField("Detail Alamat*", detailController),
                        _buildTextField(
                          "Catatan (Opsional)",
                          catatanController,
                        ),
                        _buildTextField("Nama Penerima*", namaController),
                        _buildTextField(
                          "No. HP Penerima*",
                          hpController,
                          keyboardType: TextInputType.phone,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Jadikan alamat utama"),
                            Switch(
                              value: jadikanUtama,
                              onChanged:
                                  (v) => setState(() => jadikanUtama = v),
                              activeThumbColor: Colors.blue,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _simpanAlamat,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Simpan",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (_loading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF9F9F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.black26),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Colors.blueAccent,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
