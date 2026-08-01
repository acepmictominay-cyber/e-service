import 'package:azza_service/models/technician_order_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomerDetailPage extends StatelessWidget {
  final Map<String, dynamic> customer;
  final List<TechnicianOrder> relatedOrders;
  final void Function(TechnicianOrder order) onOrderTap;

  const CustomerDetailPage({
    super.key,
    required this.customer,
    required this.relatedOrders,
    required this.onOrderTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = customer['cos_nama']?.toString() ?? customer['nama']?.toString() ?? 'Tanpa Nama';
    final phone = customer['cos_hp']?.toString() ?? '';
    final address = customer['cos_alamat']?.toString() ?? '';
    final device = [
      customer['cos_tipe']?.toString(),
      customer['cos_model']?.toString(),
    ].where((e) => e != null && e.toString().isNotEmpty).join(' ');
    final serial = customer['cos_no_seri']?.toString() ?? '';
    final complaint = customer['cos_keluhan']?.toString() ?? '';
    final createdAt = customer['created_at']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informasi Customer',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (phone.isNotEmpty) _buildInfoRow('Telepon', phone),
                  if (address.isNotEmpty) _buildInfoRow('Alamat', address),
                  if (device.isNotEmpty) _buildInfoRow('Device', device),
                  if (serial.isNotEmpty) _buildInfoRow('Serial', serial),
                  if (complaint.isNotEmpty) _buildInfoRow('Keluhan', complaint),
                  if (createdAt.isNotEmpty)
                    _buildInfoRow('Didaftarkan', createdAt.split(' ').first),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Order Terkait',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          if (relatedOrders.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Belum ada order untuk customer ini',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            )
          else
            ...relatedOrders.map((order) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  title: Text(
                    order.orderId,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${order.status.displayName} • Rp ${order.estimatedPrice?.toStringAsFixed(0) ?? '0'}',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  trailing: Icon(
                    order.status.icon,
                    color: order.status.color,
                    size: 20,
                  ),
                  onTap: () => onOrderTap(order),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
