import 'dart:io';
import 'dart:ui' as ui;
import 'package:azza_service/services/ocr_service.dart';
import 'package:azza_service/api_services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class InStoreTransactionPage extends StatefulWidget {
  const InStoreTransactionPage({super.key});

  @override
  State<InStoreTransactionPage> createState() => _InStoreTransactionPageState();
}

class _InStoreTransactionPageState extends State<InStoreTransactionPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _deviceController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _serialController = TextEditingController();
  final TextEditingController _problemController = TextEditingController();

  String _selectedSecurityType = 'Teks'; // Default

  bool _isLoading = false;
  File? _selectedImage;

  // Pattern drawing
  final List<int> _selectedDots = []; // Indices of selected dots (0-8)
  final GlobalKey _patternCanvasKey = GlobalKey();
  bool _patternSaved = false;
  String? _patternImagePath;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _birthdateController.dispose();
    _passwordController.dispose();
    _brandController.dispose();
    _deviceController.dispose();
    _modelController.dispose();
    _statusController.dispose();
    _serialController.dispose();
    _problemController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isLoading = true);
    try {
      final image = await OCRService.pickImage(source);
      if (image != null) {
        setState(() => _selectedImage = image);
        await _processImageWithOCR();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error memilih gambar: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processImageWithOCR() async {
    if (_selectedImage == null) return;

    setState(() => _isLoading = true);
    try {
      // Gunakan method debug untuk melihat raw text
      final result = await OCRService.extractWithDebug(_selectedImage!);

      if (result['success']) {
        final customerData = result['data'] as Map<String, String>;

        setState(() {
          _nameController.text = customerData['nama'] ?? '';
          _addressController.text = customerData['alamat'] ?? '';
          _birthdateController.text = customerData['tanggal_lahir'] ?? '';
        });

        // Log data yang akan diinput ke form
        print(
            'Data yang akan diinput ke form: Nama="${customerData['nama']}", Alamat="${customerData['alamat']}", Tanggal Lahir="${customerData['tanggal_lahir']}"');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data berhasil diekstrak dari KTP'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Tampilkan dialog debug jika gagal
        _showDebugDialog(result['rawText'], result['error']);
      }

      // Hapus foto KTP untuk keamanan
      try {
        await _selectedImage!.delete();
        setState(() => _selectedImage = null);
      } catch (e) {
        // Ignore
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Dialog untuk debug OCR
  void _showDebugDialog(String rawText, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug OCR'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Error:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(error, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              const Text('Raw OCR Text:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey.shade200,
                child: SelectableText(
                  rawText,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _handlePatternTouch(Offset position) {
    // Define 3x3 grid positions
    const int gridSize = 3;
    const double spacing = 60.0; // Space between dots
    const double startX = 50.0;
    const double startY = 50.0;

    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        int index = i * gridSize + j;
        double x = startX + j * spacing;
        double y = startY + i * spacing;

        // Check if touch is within dot radius
        if ((position - Offset(x, y)).distance < 30.0) {
          if (!_selectedDots.contains(index)) {
            setState(() {
              _selectedDots.add(index);
            });
          }
          return;
        }
      }
    }
  }

  Future<void> _createTransaction() async {
    print('DEBUG: _createTransaction called');
    if (!_formKey.currentState!.validate()) {
      print('DEBUG: Form validation failed');
      return;
    }
    print('DEBUG: Form validation passed');

    // Additional validation for pattern
    if (_selectedSecurityType == 'Pola' && !_patternSaved) {
      print('DEBUG: Pattern not saved');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap simpan pola keamanan')),
      );
      return;
    }
    // No validation needed for 'Tidak ada'
    print('DEBUG: Additional validation passed');

    setState(() => _isLoading = true);
    try {
      // Convert birthdate from dd-mm-yyyy to yyyy-mm-dd
      String birthdate = _birthdateController.text.trim();
      print('DEBUG: Original birthdate: $birthdate');
      if (birthdate.isNotEmpty && birthdate.contains('-')) {
        List<String> parts = birthdate.split('-');
        if (parts.length == 3) {
          birthdate = '${parts[2]}-${parts[1]}-${parts[0]}';
          print('DEBUG: Converted birthdate: $birthdate');
        }
      }

      // Handle password logic
      String pswdType = 'text';
      String pswd = '';
      String pswdDesc = '';
      String pswdCanvas = '';

      if (_selectedSecurityType == 'Teks' || _selectedSecurityType == 'PIN') {
        pswdType = 'text';
        pswd = _passwordController.text.trim();
        print(
            'DEBUG: Password type: $pswdType, password: ${pswd.isNotEmpty ? '[HIDDEN]' : 'empty'}');
      } else if (_selectedSecurityType == 'Pola') {
        pswdType = 'pattern_canvas';
        if (_patternImagePath != null) {
          print('DEBUG: Uploading pattern image');
          final file = File(_patternImagePath!);
          final uploadResult = await ApiService.uploadProfile(file);
          pswdCanvas = uploadResult['path'] ?? '';
          print('DEBUG: Pattern upload result: $uploadResult');
        } else {
          print('DEBUG: Pattern image path is null');
        }
      } else {
        print('DEBUG: No password type selected');
      }

      String formattedPhone = _phoneController.text.trim();
      if (formattedPhone.startsWith('0')) {
        formattedPhone = '62${formattedPhone.substring(1)}';
      }
      print('DEBUG: Formatted phone: $formattedPhone');

      print('DEBUG: Creating customer');
      final customerPayload = {
        'cos_nama': _nameController.text.trim(),
        'cos_hp': formattedPhone,
        'cos_alamat': _addressController.text.trim(),
        'cos_tgl_lahir': birthdate,
        'cos_tipe': _brandController.text.trim(),
        'cos_device': _deviceController.text.trim(),
        'cos_model': _modelController.text.trim(),
        'cos_no_seri': _serialController.text.trim(),
        'cos_status': _statusController.text.trim(),
        'cos_keluhan': _problemController.text.trim(),
        'cos_keterangan': _problemController.text.trim(),
        'pswd_type': pswdType,
        'pswd': pswd,
        'pswd_desc': pswdDesc,
        'pswd_canvas': pswdCanvas,
      };
      print('DEBUG: Customer payload: $customerPayload');
      final customerResponse = await ApiService.addCostomer(customerPayload);
      print('DEBUG: Customer creation response: $customerResponse');

      if (customerResponse == null ||
          !customerResponse.containsKey('id_costomer')) {
        throw Exception('Gagal membuat customer');
      }

      final cosKode = customerResponse['id_costomer'];
      print('DEBUG: Customer created with cos_kode: $cosKode');
      print('DEBUG: Updating customer with username and password');
      await ApiService.updateCostomer(cosKode, {
        'username': cosKode,
        'password': cosKode,
      });

      final transKode =
          'TR${DateTime.now().toString().replaceAll(RegExp(r'[- :.]'), '').substring(0, 17)}';
      print('DEBUG: Creating transaksi');
      final transaksiPayload = {
        'trans_kode': transKode,
        'cos_kode': cosKode,
        'kry_kode': null,
        'trans_total': 0,
        'trans_discount': 0,
        'trans_tanggal': DateTime.now().toString().substring(0, 19),
        'trans_status': _statusController.text.trim(),
      };
      final transaksiResponse =
          await ApiService.createTransaksi(transaksiPayload);
      print('DEBUG: Transaksi creation response: $transaksiResponse');
      print('DEBUG: Creating transaction');
      final transactionPayload = {
        'trans_kode': transKode,
        'cos_kode': cosKode,
        'kry_kode': null,
        'trans_total': 0,
        'trans_discount': 0,
        'trans_tanggal': DateTime.now().toString().substring(0, 19),
        'trans_status': _statusController.text.trim(),
        'merek': _brandController.text.trim(),
        'device': _deviceController.text.trim(),
        'model': _modelController.text.trim(),
        'status_garansi': _statusController.text.trim(),
        'seri': _serialController.text.trim(),
        'ket_keluhan': _problemController.text.trim(),
        'email': '',
        'alamat': _addressController.text.trim(),
      };
      print('DEBUG: Transaction payload: $transactionPayload');
      final transResponse =
          await ApiService.createOrderList(transactionPayload);
      print('DEBUG: Transaction creation response: $transResponse');

      final response = transResponse; // For compatibility

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil dibuat')),
        );
      }

      // Clear form
      _formKey.currentState?.reset();
      setState(() {
        _selectedImage = null;
        _selectedDots.clear();
        _selectedSecurityType = 'Teks';
        _patternSaved = false;
        _patternImagePath = null;
      });
      _modelController.clear();
      print('DEBUG: Form cleared successfully');
    } catch (e) {
      print('DEBUG: Exception in _createTransaction: $e');
      print('DEBUG: Exception type: ${e.runtimeType}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error membuat transaksi: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
      print('DEBUG: _createTransaction finished');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tambah Pelanggan Baru',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: _selectedSecurityType == 'Pola' && !_patternSaved
                  ? const NeverScrollableScrollPhysics()
                  : null,
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // OCR Section
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Input Data Customer',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ambil foto KTP dengan jelas untuk ekstrak data otomatis',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _pickImage(ImageSource.camera),
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('Kamera'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _pickImage(ImageSource.gallery),
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('Galeri'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_selectedImage != null) ...[
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImage!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Customer Information Form
                    Text(
                      'Informasi Customer',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildTextField('Nama', _nameController, Icons.person),
                    _buildTextField(
                        'Alamat', _addressController, Icons.location_on),
                    _buildTextField('Nomor HP', _phoneController, Icons.phone,
                        isPhone: true),
                    _buildTextField('Tanggal lahir', _birthdateController,
                        Icons.calendar_today),

                    // Security Section
                    Text(
                      'Keamanan',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSecurityTypeDropdown(),
                    _buildPasswordField(),

                    const SizedBox(height: 24),

                    // Device Information
                    Text(
                      'Informasi Perangkat',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                        'Merek', _brandController, Icons.branding_watermark),
                    _buildTextField('Device', _deviceController, Icons.devices),
                    _buildTextField(
                        'Model', _modelController, Icons.smartphone),
                    _buildTextField('Status', _statusController, Icons.info),
                    _buildTextField(
                        'Serial Number', _serialController, Icons.tag),
                    _buildTextField(
                        'Keterangan / keluhan', _problemController, Icons.build,
                        maxLines: 3),

                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _createTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Buat Transaksi',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isPhone = false,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isPhone
            ? TextInputType.phone
            : isNumber
                ? TextInputType.number
                : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '$label tidak boleh kosong';
          }
          if (isPhone && !RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) {
            return 'Nomor HP tidak valid';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSecurityTypeDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedSecurityType,
        decoration: InputDecoration(
          labelText: 'Tipe Keamanan',
          prefixIcon: const Icon(Icons.security),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        items: const [
          DropdownMenuItem(value: 'Tidak ada', child: Text('Tidak ada')),
          DropdownMenuItem(value: 'Pola', child: Text('Pola')),
          DropdownMenuItem(value: 'PIN', child: Text('PIN')),
          DropdownMenuItem(value: 'Teks', child: Text('Teks')),
        ],
        onChanged: (value) {
          setState(() {
            _selectedSecurityType = value!;
            _passwordController.clear(); // Clear password when type changes
            _selectedDots.clear(); // Clear pattern when type changes
            _patternSaved = false;
            _patternImagePath = null;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Tipe keamanan harus dipilih';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField() {
    bool isPin = _selectedSecurityType == 'PIN';
    bool isText = _selectedSecurityType == 'Teks';
    bool isPattern = _selectedSecurityType == 'Pola';
    bool isNone = _selectedSecurityType == 'Tidak ada';

    if (isNone) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Text(
          'Tidak menggunakan password',
          style: TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    if (isPattern) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gambar Pola Keamanan',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: RepaintBoundary(
                key: _patternCanvasKey,
                child: Listener(
                  onPointerMove: (event) {
                    _handlePatternTouch(event.localPosition);
                  },
                  child: CustomPaint(
                    painter: PatternPainter(_selectedDots),
                    size: const Size(200, 200),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedDots.clear();
                        _patternSaved = false;
                        _patternImagePath = null;
                      });
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Hapus Pola'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectedDots.isEmpty
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            try {
                              final boundary = _patternCanvasKey.currentContext!
                                  .findRenderObject() as RenderRepaintBoundary;
                              final image =
                                  await boundary.toImage(pixelRatio: 3.0);
                              final byteData = await image.toByteData(
                                  format: ui.ImageByteFormat.png);
                              final pngBytes = byteData!.buffer.asUint8List();

                              final tempDir = Directory.systemTemp;
                              final file = File(
                                  '${tempDir.path}/pattern_${DateTime.now().millisecondsSinceEpoch}.png');
                              await file.writeAsBytes(pngBytes);

                              setState(() {
                                _patternImagePath = file.path;
                                _patternSaved = true;
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Pola berhasil disimpan')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Error menyimpan pola: $e')),
                              );
                            } finally {
                              setState(() => _isLoading = false);
                            }
                          },
                    icon: const Icon(Icons.save),
                    label: const Text('Simpan Pola'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _passwordController,
        obscureText: isText, // Hide text for password
        keyboardType: isPin ? TextInputType.number : TextInputType.text,
        maxLength: isPin ? 6 : null, // PIN max 6 digits
        decoration: InputDecoration(
          labelText: isPin ? 'PIN' : 'Password',
          prefixIcon: const Icon(Icons.lock),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Password tidak boleh kosong';
          }
          if (isPin && !RegExp(r'^\d{4,6}$').hasMatch(value)) {
            return 'PIN harus 4-6 digit angka';
          }
          if (isText && value.length < 6) {
            return 'Password minimal 6 karakter';
          }
          return null;
        },
      ),
    );
  }
}

class PatternPainter extends CustomPainter {
  final List<int> selectedDots;

  PatternPainter(this.selectedDots);

  @override
  void paint(Canvas canvas, Size size) {
    const int gridSize = 3;
    const double spacing = 60.0;
    const double startX = 50.0;
    const double startY = 50.0;
    const double dotRadius = 10.0;

    // Paint for dots
    final dotPaint = Paint()..color = Colors.grey;
    final selectedDotPaint = Paint()..color = Colors.blue;
    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Draw dots
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        int index = i * gridSize + j;
        double x = startX + j * spacing;
        double y = startY + i * spacing;

        canvas.drawCircle(
          Offset(x, y),
          dotRadius,
          selectedDots.contains(index) ? selectedDotPaint : dotPaint,
        );
      }
    }

    // Draw lines between selected dots
    if (selectedDots.length > 1) {
      for (int k = 0; k < selectedDots.length - 1; k++) {
        int currentIndex = selectedDots[k];
        int nextIndex = selectedDots[k + 1];

        int currentRow = currentIndex ~/ gridSize;
        int currentCol = currentIndex % gridSize;
        int nextRow = nextIndex ~/ gridSize;
        int nextCol = nextIndex % gridSize;

        double currentX = startX + currentCol * spacing;
        double currentY = startY + currentRow * spacing;
        double nextX = startX + nextCol * spacing;
        double nextY = startY + nextRow * spacing;

        canvas.drawLine(
            Offset(currentX, currentY), Offset(nextX, nextY), linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
