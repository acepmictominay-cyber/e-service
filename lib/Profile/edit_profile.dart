  import 'package:e_service/Others/notifikasi.dart';
  import 'package:e_service/api_services/api_service.dart';
  import 'package:flutter/material.dart';
  import 'package:image_picker/image_picker.dart';
  import 'dart:io';
  import 'edit_name.dart';
  import 'edit_nmtlpn.dart';

  class EditProfilePage extends StatefulWidget {
    final Map<String, dynamic> userData;

    const EditProfilePage({super.key, required this.userData});

    @override
    State<EditProfilePage> createState() => _EditProfilePageState();
  }

  class _EditProfilePageState extends State<EditProfilePage> {
    late TextEditingController namaController;
    late TextEditingController teleponController;

    File? _image;
    final ImagePicker _picker = ImagePicker();

    @override
    void initState() {
      super.initState();
      namaController = TextEditingController(text: widget.userData['cos_nama'] ?? '-');
      teleponController = TextEditingController(text: widget.userData['cos_hp'] ?? '-');
    }

    @override
    Widget build(BuildContext context) {
      final String? fotoPath = widget.userData['cos_gambar'];
      final ImageProvider? profileImage;

      if (_image != null) {
        // Jika user baru saja memilih foto baru
        profileImage = FileImage(_image!);
      } else if (fotoPath != null && fotoPath.isNotEmpty) {
        // Jika user punya foto dari database
        profileImage = NetworkImage("http://192.168.1.6:8000/storage/$fotoPath");
      } else {
        // Default foto
        profileImage = null;
      }

      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.blue,
          elevation: 0,
          title: const Text('Edit Profile'),
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
                  MaterialPageRoute(builder: (context) => const NotificationPage()),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Foto profil
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.black12,
                      backgroundImage: profileImage,
                      child: (_image == null && (fotoPath == null || fotoPath.isEmpty))
                          ? const Icon(Icons.person, size: 60, color: Colors.black)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _pickImage,
                      child: const Text(
                        "Edit Foto",
                        style: TextStyle(color: Colors.blue, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Data user
                    _infoTile(
                      Icons.person,
                      "Nama",
                      namaController.text,
                      onTap: () async {
                        final updatedName = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditNamaPage(
                              currentName: namaController.text,
                            ),
                          ),
                        );
                        if (updatedName != null) {
                          setState(() {
                            namaController.text = updatedName;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    _infoTile(
                      Icons.phone,
                      "Nomor Telepon",
                      teleponController.text,
                      onTap: () async {
                        final updatedPhone = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditNmtlpnPage(
                              currentPhone: teleponController.text,
                            ),
                          ),
                        );
                        if (updatedPhone != null) {
                          setState(() {
                            teleponController.text = updatedPhone;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Tombol simpan
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      String? imagePath;

                      // Upload foto hanya jika user memilih foto baru
                      if (_image != null) {
                        final uploadResult = await ApiService.uploadProfile(_image!);                        
                        imagePath = uploadResult['path'];

                        if (mounted) {
                          setState(() {
                            widget.userData['cos_gambar'] = imagePath; // langsung update di UI
                          });
                        }
                      }

                      // Bangun map hanya dari field yang berubah
                      final updatedData = <String, dynamic>{};

                      if (namaController.text.isNotEmpty &&
                          namaController.text != widget.userData['cos_nama']) {
                        updatedData['cos_nama'] = namaController.text;
                      }

                      if (teleponController.text.isNotEmpty &&
                          teleponController.text != widget.userData['cos_hp']) {
                        updatedData['cos_hp'] = teleponController.text;
                      }

                      if (imagePath != null) {
                        updatedData['cos_gambar'] = imagePath;
                      }

                      if (updatedData.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Tidak ada perubahan yang disimpan")),
                        );
                        return;
                      }

                      await ApiService.updateCostomer(
                        widget.userData['id_costomer'],
                        updatedData,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Profil berhasil diperbarui")),
                      );

                      Navigator.pop(context, updatedData);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Gagal menyimpan perubahan: $e")),
                      );
                    }
                  },
                  child: const Text(
                    "Simpan",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget _infoTile(IconData icon, String label, String value, {VoidCallback? onTap}) {
      return Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap ?? () {},
          splashColor: Colors.grey.withOpacity(0.3),
          highlightColor: Colors.grey.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
              ],
            ),
          ),
        ),
      );
    }

    Future<void> _pickImage() async { 
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    }
  }
