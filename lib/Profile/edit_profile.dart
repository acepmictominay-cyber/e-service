import 'package:azza_service/Others/notifikasi.dart';
import 'package:azza_service/api_services/api_service.dart';
import 'package:azza_service/config/api_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    namaController = TextEditingController(
      text: widget.userData['cos_nama'] ?? '-',
    );
    teleponController = TextEditingController(
      text: widget.userData['cos_hp'] ?? '-',
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? fotoPath = widget.userData['cos_gambar'];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        titleTextStyle: const TextStyle(color: Colors.white),
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
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
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
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[700]
                          : Colors.black12,
                    ),
                    child: ClipOval(
                      child: _image != null
                          ? Image.file(_image!, fit: BoxFit.cover)
                          : (fotoPath != null && fotoPath.isNotEmpty)
                              ? CachedNetworkImage(
                                  imageUrl:
                                      "${ApiConfig.storageBaseUrl}$fotoPath",
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.blue,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white70
                                        : Colors.black,
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white70
                                      : Colors.black,
                                ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _pickImage,
                    child: const Text(
                      "Edit Foto",
                      style: TextStyle(
                        color: Color(0xFF0041c3),
                        fontSize: 16,
                      ),
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
                  backgroundColor: const Color(0xFF0041c3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        setState(() => isSaving = true);
                        try {
                          String? imagePath;

                          // Upload foto hanya jika user memilih foto baru
                          if (_image != null) {
                            final uploadResult =
                                await ApiService.uploadProfile(_image!);
                            imagePath = uploadResult['path'];

                            if (mounted) {
                              setState(() {
                                widget.userData['cos_gambar'] =
                                    imagePath; // langsung update di UI
                              });
                            }
                          }

                          // Bangun map hanya dari field yang berubah
                          final updatedData = <String, dynamic>{};

                          if (namaController.text.isNotEmpty &&
                              namaController.text !=
                                  widget.userData['cos_nama']) {
                            updatedData['cos_nama'] = namaController.text;
                          }

                          if (teleponController.text.isNotEmpty &&
                              teleponController.text !=
                                  widget.userData['cos_hp']) {
                            updatedData['cos_hp'] = teleponController.text;
                          }

                          if (imagePath != null) {
                            updatedData['cos_gambar'] = imagePath;
                          }

                          if (updatedData.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "Tidak ada perubahan yang disimpan")),
                            );
                            return;
                          }

                          await ApiService.updateCostomer(
                            widget.userData['id_costomer'],
                            updatedData,
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Profil berhasil diperbarui")),
                          );

                          Navigator.pop(context, updatedData);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text("Gagal menyimpan perubahan: $e")),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => isSaving = false);
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
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

  Widget _infoTile(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          width: 1,
        ),
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
              Icon(icon, color: const Color(0xFF0041c3)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }
}
