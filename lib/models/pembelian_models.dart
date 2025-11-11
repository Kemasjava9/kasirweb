class DetailPembelian {
  final String idDetailBeli;
  final String idBeli;
  final String kodeBarang;
  final String satuan;
  final int jumlah;
  final double hargaSatuan;
  final double subtotal;

  DetailPembelian({
    required this.idDetailBeli,
    required this.idBeli,
    required this.kodeBarang,
    this.satuan = 'pcs',
    required this.jumlah,
    required this.hargaSatuan,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_detail_beli': idDetailBeli,
      'id_beli': idBeli,
      'kode_barang': kodeBarang,
      'satuan': satuan,
      'jumlah': jumlah,
      'harga_satuan': hargaSatuan,
      'subtotal': subtotal,
    };
  }

  static DetailPembelian fromMap(Map<String, dynamic> map) {
    return DetailPembelian(
      idDetailBeli: map['id_detail_beli'] ?? '',
      idBeli: map['id_beli'] ?? '',
      kodeBarang: map['kode_barang'] ?? '',
      satuan: map['satuan'] ?? '',
      jumlah: (map['jumlah'] ?? 0).toInt(),
      hargaSatuan: (map['harga_satuan'] ?? 0).toDouble(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
    );
  }
}
