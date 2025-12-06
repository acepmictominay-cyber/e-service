import 'package:flutter/material.dart';

enum OrderStatus {
  waiting,
  accepted,
  enRoute,
  arrived,
  waitingApproval,
  approved, // Status baru untuk menandakan sudah diapprove admin
  pickingParts,
  repairing,
  completed,
  jobDone,
  waitingOrder, // Status untuk order yang bisa dialihkan
  waitingOrderList, // Status untuk order yang telah dialihkan
}

extension OrderStatusExtension on OrderStatus {
  String get name {
    switch (this) {
      case OrderStatus.waiting:
        return 'waiting';
      case OrderStatus.accepted:
        return 'accepted';
      case OrderStatus.enRoute:
        return 'enroute';
      case OrderStatus.arrived:
        return 'arrived';
      case OrderStatus.waitingApproval:
        return 'waitingapproval';
      case OrderStatus.approved:
        return 'approved';
      case OrderStatus.pickingParts:
        return 'pickingparts';
      case OrderStatus.repairing:
        return 'repairing';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.jobDone:
        return 'jobdone';
      case OrderStatus.waitingOrder:
        return 'waitingorder';
      case OrderStatus.waitingOrderList:
        return 'waitingorderlist';
    }
  }

  String get displayName {
    switch (this) {
      case OrderStatus.waiting:
        return 'Menunggu';
      case OrderStatus.accepted:
        return 'Diterima';
      case OrderStatus.enRoute:
        return 'Dalam Perjalanan';
      case OrderStatus.arrived:
        return 'Tiba';
      case OrderStatus.waitingApproval:
        return 'Menunggu Persetujuan';
      case OrderStatus.approved:
        return 'Disetujui';
      case OrderStatus.pickingParts:
        return 'Ambil Suku Cadang';
      case OrderStatus.repairing:
        return 'Perbaikan';
      case OrderStatus.completed:
        return 'Selesai';
      case OrderStatus.jobDone:
        return 'Pekerjaan Selesai';
      case OrderStatus.waitingOrder:
        return 'Menunggu Order';
      case OrderStatus.waitingOrderList:
        return 'Order Dialihkan';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.waiting:
        return Colors.grey;
      case OrderStatus.accepted:
        return const Color(0xFF0041c3);
      case OrderStatus.enRoute:
        return Colors.orange;
      case OrderStatus.arrived:
        return Colors.purple;
      case OrderStatus.waitingApproval:
        return Colors.amber;
      case OrderStatus.approved:
        return Colors.green;
      case OrderStatus.pickingParts:
        return Colors.indigo;
      case OrderStatus.repairing:
        return Colors.red;
      case OrderStatus.completed:
      case OrderStatus.jobDone:
        return Colors.green;
      case OrderStatus.waitingOrder:
        return Colors.teal;
      case OrderStatus.waitingOrderList:
        return Colors.orangeAccent;
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.waiting:
        return Icons.hourglass_empty;
      case OrderStatus.accepted:
        return Icons.check_circle;
      case OrderStatus.enRoute:
        return Icons.directions_car;
      case OrderStatus.arrived:
        return Icons.location_on;
      case OrderStatus.waitingApproval:
        return Icons.pending_actions;
      case OrderStatus.approved:
        return Icons.approval;
      case OrderStatus.pickingParts:
        return Icons.build;
      case OrderStatus.repairing:
        return Icons.engineering;
      case OrderStatus.completed:
      case OrderStatus.jobDone:
        return Icons.done_all;
      case OrderStatus.waitingOrder:
        return Icons.swap_horiz;
      case OrderStatus.waitingOrderList:
        return Icons.forward;
    }
  }

  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'waiting':
      case 'pending':
        return OrderStatus.waiting;
      case 'accepted':
        return OrderStatus.accepted;
      case 'enroute':
      case 'en_route':
        return OrderStatus.enRoute;
      case 'arrived':
        return OrderStatus.arrived;
      case 'waitingapproval':
      case 'waiting_approval':
        return OrderStatus.waitingApproval;
      case 'approved':
        return OrderStatus.approved;
      case 'pickingparts':
      case 'picking_parts':
        return OrderStatus.pickingParts;
      case 'repairing':
        return OrderStatus.repairing;
      case 'completed':
        return OrderStatus.completed;
      case 'jobdone':
      case 'job_done':
        return OrderStatus.jobDone;
      case 'waitingorder':
      case 'waiting_order':
        return OrderStatus.waitingOrder;
      case 'waitingorderlist':
      case 'waiting_order_list':
        return OrderStatus.waitingOrderList;
      default:
        return OrderStatus.waiting;
    }
  }
}

class TechnicianOrder {
  final String orderId;
  final String customerName;
  final String customerAddress;
  final String? customerPhone;
  final String? deviceType;
  final String? deviceBrand;
  final String? deviceSerial;
  final String? warrantyStatus;
  final String? serviceType;
  final num? visitCost;
  final String? damageDescription;
  final List<String>? damagePhotos;
  final num? estimatedPrice;
  final OrderStatus status;
  final DateTime? createdAt;
  final String? cosKode;
  final String? approvalNotes;

  TechnicianOrder({
    required this.orderId,
    required this.customerName,
    required this.customerAddress,
    this.customerPhone,
    this.deviceType,
    this.deviceBrand,
    this.deviceSerial,
    this.warrantyStatus,
    this.serviceType,
    this.visitCost,
    this.damageDescription,
    this.damagePhotos,
    this.estimatedPrice,
    required this.status,
    this.createdAt,
    this.cosKode,
    this.approvalNotes,
  });

  // Helper method untuk cek apakah sudah diapprove
  bool get isApproved => status == OrderStatus.approved;

  static num? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  factory TechnicianOrder.fromMap(Map<String, dynamic> map) {
    return TechnicianOrder(
      orderId: map['order_id']?.toString() ?? map['trans_kode']?.toString() ?? '',
      customerName: map['cos_nama']?.toString() ?? map['customer_name']?.toString() ?? 'Unknown',
      customerAddress: map['alamat']?.toString() ?? map['cos_alamat']?.toString() ?? 'Unknown',
      customerPhone: map['cos_hp']?.toString() ?? map['cos_hp']?.toString() ?? map['cos_tlp']?.toString(),
      deviceType: map['device']?.toString() ?? map['brg_nama']?.toString(),
      deviceBrand: map['merek']?.toString() ?? map['brg_merk']?.toString(),
      deviceSerial: map['seri']?.toString() ?? map['brg_sn']?.toString(),
      warrantyStatus: map['status_garansi']?.toString() ?? map['garansi_status']?.toString(),
      estimatedPrice: _parseNum(map['trans_total']) ?? _parseNum(map['trans_total']) ?? _parseNum(map['total']),
      // Membaca status dari trans_status field di database
      status: OrderStatusExtension.fromString(
        map['trans_status']?.toString() ?? map['status']?.toString() ?? 'waiting'
      ),
      createdAt: map['created_at'] != null
        ? DateTime.tryParse(map['created_at'].toString())
        : null,
      cosKode: map['cos_kode']?.toString(),
      approvalNotes: map['approval_notes']?.toString() ?? map['ket_keluhan']?.toString(),
    );
  }

  TechnicianOrder copyWith({
    String? orderId,
    String? customerName,
    String? customerAddress,
    String? customerPhone,
    String? deviceType,
    String? deviceBrand,
    String? deviceSerial,
    String? warrantyStatus,
    String? serviceType,
    num? visitCost,
    String? damageDescription,
    List<String>? damagePhotos,
    num? estimatedPrice,
    OrderStatus? status,
    DateTime? createdAt,
    String? cosKode,
    String? approvalNotes,
  }) {
    return TechnicianOrder(
      orderId: orderId ?? this.orderId,
      customerName: customerName ?? this.customerName,
      customerAddress: customerAddress ?? this.customerAddress,
      customerPhone: customerPhone ?? this.customerPhone,
      deviceType: deviceType ?? this.deviceType,
      deviceBrand: deviceBrand ?? this.deviceBrand,
      deviceSerial: deviceSerial ?? this.deviceSerial,
      warrantyStatus: warrantyStatus ?? this.warrantyStatus,
      serviceType: serviceType ?? this.serviceType,
      visitCost: visitCost ?? this.visitCost,
      damageDescription: damageDescription ?? this.damageDescription,
      damagePhotos: damagePhotos ?? this.damagePhotos,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      cosKode: cosKode ?? this.cosKode,
      approvalNotes: approvalNotes ?? this.approvalNotes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'order_id': orderId,
      'customer_name': customerName,
      'customer_address': customerAddress,
      'customer_phone': customerPhone,
      'device_type': deviceType,
      'device_brand': deviceBrand,
      'device_serial': deviceSerial,
      'warranty_status': warrantyStatus,
      'estimated_price': estimatedPrice,
      'trans_status': status.name,
      'created_at': createdAt?.toIso8601String(),
      'cos_kode': cosKode,
      'approval_notes': approvalNotes,
    };
  }
}
