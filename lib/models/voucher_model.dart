class Voucher {
  final int voucherId;
  final String voucherCode;
  final String? description;
  final double discountPercent;
  final DateTime startDate;
  final DateTime endDate;
  final int maxUsage;
  final String status;
  final String? image; // Add image field

  Voucher({
    required this.voucherId,
    required this.voucherCode,
    this.description,
    required this.discountPercent,
    required this.startDate,
    required this.endDate,
    required this.maxUsage,
    required this.status,
    this.image, // Add image parameter
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      voucherId: json['voucher_id'] ?? 0,
      voucherCode: json['voucher_code'] ?? '',
      description: json['description'],
      discountPercent: double.tryParse(json['discount_percent']?.toString() ?? '0') ?? 0.0,
      startDate: DateTime.parse(json['start_date'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['end_date'] ?? DateTime.now().toIso8601String()),
      maxUsage: json['max_usage'] ?? 1,
      status: json['status'] ?? 'active',
      image: json['voucher_gambar'] ?? json['image'], // Try both column names
    );
  }

  bool get isActive {
    final now = DateTime.now();
    return status == 'active' && now.isAfter(startDate) && now.isBefore(endDate);
  }
}

class UserVoucher {
  final int id;
  final String idCostomer;
  final int voucherId;
  final DateTime claimedDate;
  final String used;
  final Voucher? voucher; // Optional joined data

  UserVoucher({
    required this.id,
    required this.idCostomer,
    required this.voucherId,
    required this.claimedDate,
    required this.used,
    this.voucher,
  });

  factory UserVoucher.fromJson(Map<String, dynamic> json) {
    return UserVoucher(
      id: json['id'] ?? 0,
      idCostomer: json['id_costomer'] ?? '',
      voucherId: json['voucher_id'] ?? 0,
      claimedDate: DateTime.parse(json['claimed_date'] ?? DateTime.now().toIso8601String()),
      used: json['used'] ?? 'no',
      voucher: json['voucher'] != null ? Voucher.fromJson(json['voucher']) : null,
    );
  }

  bool get isAvailable => used == 'no';
}
