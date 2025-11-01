import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PilihLokasiPage extends StatefulWidget {
  const PilihLokasiPage({super.key});

  @override
  State<PilihLokasiPage> createState() => _PilihLokasiPageState();
} 

class _PilihLokasiPageState extends State<PilihLokasiPage> {
  late GoogleMapController mapController;
  final TextEditingController searchController = TextEditingController();

  static const LatLng _initialPosition =
      LatLng(-6.362750, 106.933800); // contoh lokasi
  LatLng? _selectedPosition;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Pilih Lokasi",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          // === MAP VIEW ===
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _initialPosition,
              zoom: 17,
            ),
            onMapCreated: (controller) {
              mapController = controller;
            },
            onCameraMove: (position) {
              setState(() {
                _selectedPosition = position.target;
              });
            },
            markers: _selectedPosition != null
                ? {
                    Marker(
                      markerId: const MarkerId("selected"),
                      position: _selectedPosition!,
                    ),
                  }
                : {},
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
          ),

          // === PIN TENGAH ===
          const Center(
            child: Icon(Icons.location_on, color: Colors.red, size: 48),
          ),

          // === PANEL BAWAH ===
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // === Input Pencarian ===
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: "Cari Alamat",
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // === Alamat Contoh ===
                  const Text(
                    "Jl. Ruko Kranggan Permai No.26, RT.003/RW.010,\n"
                    "Jatisampurna, Kec. Jatisampurna, Kota Bks, Jawa Barat 17435, Indonesia",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),

                  // === Tombol Pilih Lokasi ===
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      if (_selectedPosition != null) {
                        Navigator.pop(context, {
                          'latlng': _selectedPosition,
                          'address': "Jl. Ruko Kranggan Permai No.26, RT.003/RW.010,\nJatisampurna, Kec. Jatisampurna, Kota Bks, Jawa Barat 17435, Indonesia"
                        });
                      }
                    },
                    child: const Text(
                      "Pilih Titik Lokasi",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
