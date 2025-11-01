import 'package:flutter/material.dart';

// =========================================================================
// === FUNGSI HELPER UNTUK PARSING STATUS (ANTI CASE-SENSITIVE) ===
// =========================================================================
OrderStatus _parseStatus(String? statusString) {
  if (statusString == null) {
    print("⚠️ [MODEL] Status dari API adalah null, menggunakan 'waiting'.");
    return OrderStatus.waiting;
  }

  final statusLower = statusString.toLowerCase().trim();
  print("🔍 [MODEL] Parsing status: '$statusString' → '$statusLower'");

  // Mapping khusus untuk status yang mungkin berbeda format
  const statusMap = {
    'waiting': OrderStatus.waiting,
    'pending': OrderStatus.waiting,
    'accepted': OrderStatus.accepted,
    'enroute': OrderStatus.enRoute,
    'en_route': OrderStatus.enRoute,
    'dalam perjalanan': OrderStatus.enRoute,
    'arrived': OrderStatus.arrived,
    'tiba': OrderStatus.arrived,
    'waitingapproval': OrderStatus.waitingApproval,
    'waiting_approval': OrderStatus.waitingApproval,
    'menunggu persetujuan': OrderStatus.waitingApproval,
    'pickingparts': OrderStatus.pickingParts,
    'picking_parts': OrderStatus.pickingParts,
    'repairing': OrderStatus.repairing,
    'memperbaiki': OrderStatus.repairing,
    'completed': OrderStatus.completed,
    'selesai': OrderStatus.completed,
    'done': OrderStatus.completed,
    'delivering': OrderStatus.delivering,
  };

  if (statusMap.containsKey(statusLower)) {
    final parsedStatus = statusMap[statusLower]!;
    print("✅ [MODEL] Status matched: ${parsedStatus.name}");
    return parsedStatus;
  }

  // Fallback: coba cocokkan dengan enum name
  for (var statusValue in OrderStatus.values) {
    if (statusValue.name.toLowerCase() == statusLower) {
      print("✅ [MODEL] Status matched via enum: ${statusValue.name}");
      return statusValue;
    }
  }

  print("⚠️ [MODEL] Status '$statusString' tidak dikenali, menggunakan 'waiting'.");
  return OrderStatus.waiting;
}

enum OrderStatus {
  waiting('Menunggu', Icons.assignment, Colors.grey),
  accepted('Diterima', Icons.assignment_turned_in, Colors.blueGrey),
  enRoute('Dalam Perjalanan', Icons.directions_car, Colors.orange),
  arrived('Tiba', Icons.location_on, Colors.blue),
  waitingApproval(
    'Menunggu Persetujuan',
    Icons.hourglass_empty,
    Color.fromARGB(255, 221, 151, 1),
  ),
  pickingParts('Mengambil Suku Cadang', Icons.build, Colors.purple),
  repairing('Memperbaiki', Icons.settings, Colors.red),
  completed('Selesai', Icons.check_circle, Colors.green),
  delivering('Mengantar', Icons.local_shipping, Colors.teal);

  const OrderStatus(this.displayName, this.icon, this.color);
  final String displayName;
  final IconData icon;
  final Color color;
}

class TechnicianOrder {
  final String orderId;
  final String customerName;
  final String customerAddress;
  final String deviceType;
  final String deviceBrand;
  final String deviceSerial;
  final String serviceType;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? scheduledTime;
  final double? visitCost;
  final String? customerPhone;
  final String? notes;
  final List<String>? damagePhotos;
  final String? damageDescription;
  final double? estimatedPrice;
  final String? cosKode;
  final String? warrantyStatus;
  final String? warrantyExpiry;

  TechnicianOrder({
    required this.orderId,
    required this.customerName,
    required this.customerAddress,
    required this.deviceType,
    required this.deviceBrand,
    required this.deviceSerial,
    required this.serviceType,
    required this.status,
    required this.createdAt,
    this.scheduledTime,
    this.visitCost,
    this.customerPhone,
    this.notes,
    this.damagePhotos,
    this.damageDescription,
    this.estimatedPrice,
    this.cosKode,
    this.warrantyStatus,
    this.warrantyExpiry,
  });

  factory TechnicianOrder.fromMap(Map<String, dynamic> map) {
    print('🔧 [MODEL] Creating TechnicianOrder from: ${map['trans_kode']}');
    
    try {
      final order = TechnicianOrder(
        orderId: map['trans_kode']?.toString() ?? map['orderId']?.toString() ?? 'N/A',
        customerName: map['cos_nama']?.toString() ?? map['customerName']?.toString() ?? 'Unknown Customer',
        customerAddress: map['alamat']?.toString() ?? 
                        map['cos_alamat']?.toString() ?? 
                        map['customerAddress']?.toString() ?? 
                        'No Address',
        deviceType: map['device']?.toString() ?? map['deviceType']?.toString() ?? 'N/A',
        deviceBrand: map['merek']?.toString() ?? map['deviceBrand']?.toString() ?? 'N/A',
        deviceSerial: map['seri']?.toString() ?? map['deviceSerial']?.toString() ?? 'N/A',
        serviceType: map['serviceType']?.toString() ?? 'Service',
        status: _parseStatus(map['trans_status']?.toString() ?? map['status']?.toString()),
        createdAt: DateTime.tryParse(map['created_at']?.toString() ?? map['createdAt']?.toString() ?? '') ?? DateTime.now(),
        scheduledTime: map['scheduledTime'] != null ? DateTime.tryParse(map['scheduledTime'].toString()) : null,
        visitCost: _parseDouble(map['visitCost']),
        customerPhone: map['cos_hp']?.toString() ?? map['customerPhone']?.toString(),
        notes: map['notes']?.toString(),
        damagePhotos: map['damagePhotos'] != null ? List<String>.from(map['damagePhotos']) : null,
        damageDescription: map['damageDescription']?.toString(),
        estimatedPrice: _parseDouble(map['trans_total']) ?? _parseDouble(map['estimatedPrice']),
        cosKode: map['cos_kode']?.toString() ?? map['cosKode']?.toString(),
        warrantyStatus: map['status_garansi']?.toString() ?? map['warrantyStatus']?.toString(),
        warrantyExpiry: map['warrantyExpiry']?.toString(),
      );
      
      print('✅ [MODEL] Order created successfully: ${order.orderId}, Status: ${order.status.name}');
      return order;
    } catch (e) {
      print('❌ [MODEL] Error creating TechnicianOrder: $e');
      print('   Map data: $map');
      rethrow;
    }
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleaned);
    }
    return null;
  }

  TechnicianOrder copyWith({
    String? orderId,
    String? customerName,
    String? customerAddress,
    String? deviceType,
    String? deviceBrand,
    String? deviceSerial,
    String? serviceType,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? scheduledTime,
    double? visitCost,
    String? customerPhone,
    String? notes,
    List<String>? damagePhotos,
    String? damageDescription,
    double? estimatedPrice,
    String? cosKode,
    String? warrantyStatus,
    String? warrantyExpiry,
  }) {
    return TechnicianOrder(
      orderId: orderId ?? this.orderId,
      customerName: customerName ?? this.customerName,
      customerAddress: customerAddress ?? this.customerAddress,
      deviceType: deviceType ?? this.deviceType,
      deviceBrand: deviceBrand ?? this.deviceBrand,
      deviceSerial: deviceSerial ?? this.deviceSerial,
      serviceType: serviceType ?? this.serviceType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      visitCost: visitCost ?? this.visitCost,
      customerPhone: customerPhone ?? this.customerPhone,
      notes: notes ?? this.notes,
      damagePhotos: damagePhotos ?? this.damagePhotos,
      damageDescription: damageDescription ?? this.damageDescription,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      cosKode: cosKode ?? this.cosKode,
      warrantyStatus: warrantyStatus ?? this.warrantyStatus,
      warrantyExpiry: warrantyExpiry ?? this.warrantyExpiry,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trans_kode': orderId,
      'cos_nama': customerName,
      'cos_alamat': customerAddress,
      'device': deviceType,
      'merek': deviceBrand,
      'seri': deviceSerial,
      'service_type': serviceType,
      'trans_status': status.name,
      'created_at': createdAt.toIso8601String(),
      'scheduledTime': scheduledTime?.toIso8601String(),
      'visitCost': visitCost,
      'cos_hp': customerPhone,
      'notes': notes,
      'damagePhotos': damagePhotos,
      'damageDescription': damageDescription,
      'trans_total': estimatedPrice,
      'cos_kode': cosKode,
      'status_garansi': warrantyStatus,
      'warrantyExpiry': warrantyExpiry,
    };
  }
}