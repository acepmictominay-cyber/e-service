import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/ocr_service.dart';

class OCRKTPPage extends StatefulWidget {
  const OCRKTPPage({super.key});

  @override
  State<OCRKTPPage> createState() => _OCRKTPPageState();
}

class _OCRKTPPageState extends State<OCRKTPPage> {
  File? _selectedImage;
  Map<String, String>? _parsedData;
  Map<String, double>? _confidence;
  Map<String, String>? _validationErrors;
  bool _isProcessing = false;

  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    const fields = ['nama', 'alamat', 'tanggal_lahir'];
    for (final field in fields) {
      _controllers[field] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final storageStatus = await Permission.storage.request();
    if (!cameraStatus.isGranted || !storageStatus.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin kamera dan penyimpanan diperlukan')),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    await _requestPermissions();
    final image = await OCRService.pickImage(source);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _parsedData = null;
        _confidence = null;
        _validationErrors = null;
      });
      await _processImage();
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await OCRService.extractWithDebug(_selectedImage!);
      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        final parsed = data['data'] as Map<String, String>;
        final conf = data['confidence'] as Map<String, double>;

        setState(() {
          _parsedData = parsed;
          _confidence = conf;
        });

        // Populate controllers
        for (final entry in parsed.entries) {
          if (_controllers.containsKey(entry.key)) {
            _controllers[entry.key]!.text = entry.value;
          }
        }

        // Validate
        _validateData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${result['error']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing image: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _validateData() {
    if (_parsedData != null) {
      final filteredData = <String, String>{};
      for (final field in _controllers.keys) {
        if (_parsedData!.containsKey(field)) {
          filteredData[field] = _parsedData![field]!;
        }
      }
      final errors = OCRService.validateKTPData(filteredData);
      setState(() {
        _validationErrors = errors;
      });
    }
  }

  void _saveData() {
    // Collect data from controllers
    final data = <String, String>{};
    for (final entry in _controllers.entries) {
      data[entry.key] = entry.value.text;
    }

    // Validate only the 3 fields
    final errors = OCRService.validateKTPData(data);
    final filteredErrors = <String, String>{};
    for (final field in _controllers.keys) {
      if (errors.containsKey(field)) {
        filteredErrors[field] = errors[field]!;
      }
    }
    if (filteredErrors.isNotEmpty) {
      setState(() {
        _validationErrors = filteredErrors;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data tidak valid, periksa kembali')),
      );
      return;
    }

    // Save or proceed
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data KTP berhasil disimpan')),
    );
    // TODO: Save to database or send to server
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR KTP'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image selection
            if (_selectedImage != null)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.file(_selectedImage!, fit: BoxFit.cover),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Text('Pilih gambar KTP')),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera),
                    label: const Text('Kamera'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo),
                    label: const Text('Galeri'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else if (_parsedData != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Hasil OCR:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._buildFormFields(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _processImage,
                          child: const Text('Coba Lagi'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveData,
                          child: const Text('Simpan Data'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFormFields() {
    const fieldLabels = {
      'nama': 'Nama',
      'alamat': 'Alamat',
      'tanggal_lahir': 'Tanggal Lahir',
    };

    return fieldLabels.entries.map((entry) {
      final field = entry.key;
      final label = entry.value;
      final controller = _controllers[field]!;
      final error = _validationErrors?[field];
      final conf = _confidence?[field] ?? 0.0;

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            errorText: error,
            suffixText: '${(conf * 100).toStringAsFixed(0)}%',
            suffixStyle: TextStyle(
              color: conf > 0.8
                  ? Colors.green
                  : conf > 0.5
                      ? Colors.orange
                      : Colors.red,
            ),
          ),
        ),
      );
    }).toList();
  }
}