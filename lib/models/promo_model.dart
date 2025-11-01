class Promo {
  final String kodeBarang;
  final String tipeProduk;
  final int diskon;
  final int koin;
  final String gambar;
  final double harga;

  Promo({
    required this.kodeBarang,
    required this.tipeProduk,
    required this.diskon,
    required this.koin,
    required this.gambar,
    required this.harga,
  });

  factory Promo.fromJson(Map<String, dynamic> json) {
    return Promo(
      kodeBarang: json['kode_barang'] ?? '',
      tipeProduk: json['tipe_produk'] ?? '',
      diskon: json['diskon'] ?? 0,
      koin: json['koin'] ?? 0,
      gambar: json['gambar'] ?? '',
      harga: double.tryParse(json['harga']?.toString() ?? '0') ?? 0.0,
    );
  }
}
