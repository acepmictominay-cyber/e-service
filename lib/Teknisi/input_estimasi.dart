import 'dart:io';
import 'package:e_service/models/technician_order_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class InputEstimasiPage extends StatefulWidget {
  const InputEstimasiPage({super.key});

  @override
  State<InputEstimasiPage> createState() => _InputEstimasiPageState();
}

class _InputEstimasiPageState extends State<InputEstimasiPage> {
  List<TechnicianOrder> activeOrders = [];
  bool isLoading = true;

  // Form controllers
  final TextEditingController damageDescriptionController =
      TextEditingController();
  final TextEditingController partsCostController = TextEditingController();
  final TextEditingController laborCostController = TextEditingController();
  List<XFile> selectedMedia = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    damageDescriptionController.dispose();
    partsCostController.dispose();
    laborCostController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => isLoading = true);

    // Sample data - in real app, this would come from API
    activeOrders = [
      TechnicianOrder(
        orderId: 'TTS001-REP',
        customerName: 'John Doe',
        customerAddress: 'Jl. Sudirman No. 123, Jakarta',
        deviceType: 'Laptop',
        deviceBrand: 'Asus',
        deviceSerial: 'ASUS123456',
        serviceType: 'Repair',
        status: OrderStatus.arrived,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        visitCost: 50000,
      ),
      TechnicianOrder(
        orderId: 'TTS002-CLEAN',
        customerName: 'Jane Smith',
        customerAddress: 'Jl. Thamrin No. 456, Jakarta',
        deviceType: 'Desktop',
        deviceBrand: 'Dell',
        deviceSerial: 'DELL789012',
        serviceType: 'Cleaning',
        status: OrderStatus.repairing,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        visitCost: 30000,
      ),
    ];

    setState(() => isLoading = false);
  }

  Future<void> _pickMedia() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        selectedMedia.addAll(pickedFiles);
      });
    }
  }

  void _showEstimationForm(TechnicianOrder order) {
    damageDescriptionController.clear();
    partsCostController.clear();
    laborCostController.clear();
    selectedMedia.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 16,
                    right: 16,
                    top: 16,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Input Estimasi - ${order.orderId}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Diagnosis description
                        TextField(
                          controller: damageDescriptionController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: 'Hasil Diagnosa Kerusakan',
                            hintText:
                                'Jelaskan detail kerusakan yang ditemukan...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Parts cost
                        TextField(
                          controller: partsCostController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Biaya Part (Rp)',
                            hintText: '0',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Labor cost
                        TextField(
                          controller: laborCostController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Biaya Jasa (Rp)',
                            hintText: '0',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Media upload
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _pickMedia();
                            setModalState(() {});
                          },
                          icon: const Icon(Icons.photo_camera),
                          label: const Text('Upload Foto/Video Kerusakan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${selectedMedia.length} file(s) dipilih',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),

                        // Media preview
                        if (selectedMedia.isNotEmpty)
                          Container(
                            height: 100,
                            margin: const EdgeInsets.only(top: 8),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: selectedMedia.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  width: 80,
                                  height: 80,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: FileImage(
                                        File(selectedMedia[index].path),
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Total estimation display
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Total Estimasi',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Builder(
                                builder: (context) {
                                  final partsCost =
                                      double.tryParse(
                                        partsCostController.text,
                                      ) ??
                                      0;
                                  final laborCost =
                                      double.tryParse(
                                        laborCostController.text,
                                      ) ??
                                      0;
                                  final total = partsCost + laborCost;
                                  return Text(
                                    'Rp ${total.toStringAsFixed(0)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  side: const BorderSide(color: Colors.grey),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Batal',
                                  style: GoogleFonts.poppins(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (damageDescriptionController
                                      .text
                                      .isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Harap isi hasil diagnosa',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  final partsCost =
                                      double.tryParse(
                                        partsCostController.text,
                                      ) ??
                                      0;
                                  final laborCost =
                                      double.tryParse(
                                        laborCostController.text,
                                      ) ??
                                      0;
                                  final totalCost = partsCost + laborCost;

                                  // Save estimation
                                  final updatedOrder = order.copyWith(
                                    damageDescription:
                                        damageDescriptionController.text,
                                    estimatedPrice: totalCost,
                                    damagePhotos:
                                        selectedMedia
                                            .map((f) => f.path)
                                            .toList(),
                                  );

                                  // Update order status to waiting approval
                                  final orderWithNewStatus = updatedOrder
                                      .copyWith(
                                        status: OrderStatus.waitingApproval,
                                      );

                                  setState(() {
                                    final index = activeOrders.indexWhere(
                                      (o) => o.orderId == order.orderId,
                                    );
                                    if (index != -1) {
                                      activeOrders[index] = orderWithNewStatus;
                                    }
                                  });

                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Estimasi berhasil dikirim, menunggu persetujuan pelanggan',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1976D2),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Kirim Estimasi',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        title: Text(
          'Input Estimasi',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : activeOrders.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tidak ada pesanan yang perlu estimasi',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: activeOrders.length,
                itemBuilder: (context, index) {
                  final order = activeOrders[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order ID and Status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                order.orderId,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: order.status.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  order.status.displayName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: order.status.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Customer and Device Info
                          Text(
                            '${order.customerName} - ${order.deviceBrand} ${order.deviceType}',
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),

                          const SizedBox(height: 16),

                          // Action button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showEstimationForm(order),
                              icon: const Icon(Icons.edit_document),
                              label: const Text('Input Estimasi'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
