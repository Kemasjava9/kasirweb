// Models for Penjualan (sales) related classes that match the SQL schema
class Penjualan {
  final String nofakturJual;
  final String tanggalJual;
  final double totalJual;
  final String idUser;
  final String namaSales;
  final double bayar;
  final String namaPelanggan;
  final String caraBayar;
  final String status;
  final double diskon;
  final double biayaLainLain;
  final double ongkosKirim;

  Penjualan({
    required this.nofakturJual,
    required this.tanggalJual,
    required this.totalJual,
    required this.idUser,
    required this.namaSales,
    required this.bayar,
    required this.namaPelanggan,
    required this.caraBayar,
    required this.status,
    this.diskon = 0.0,
    this.biayaLainLain = 0.0,
    this.ongkosKirim = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'nofaktur_jual': nofakturJual,
      'tanggal_jual': tanggalJual,
      'total_jual': totalJual,
      'id_user': idUser,
      'nama_sales': namaSales,
      'bayar': bayar,
      'nama_pelanggan': namaPelanggan,
      'cara_bayar': caraBayar,
      'status': status,
      'diskon': diskon,
      'biaya_lain_lain': biayaLainLain,
      'ongkos_kirim': ongkosKirim,
    };
  }

  static Penjualan fromMap(Map<String, dynamic> map) {
    return Penjualan(
      nofakturJual: map['nofaktur_jual'] ?? '',
      tanggalJual: map['tanggal_jual'] ?? '',
      totalJual: (map['total_jual'] ?? 0).toDouble(),
      idUser: map['id_user']?.toString() ?? '',
      namaSales: map['nama_sales'] ?? '',
      bayar: (map['bayar'] ?? 0).toDouble(),
      namaPelanggan: map['nama_pelanggan'] ?? '',
      caraBayar: map['cara_bayar'] ?? '',
      status: map['status'] ?? '',
      diskon: (map['diskon'] ?? 0).toDouble(),
      biayaLainLain: (map['biaya_lain_lain'] ?? 0).toDouble(),
      ongkosKirim: (map['ongkos_kirim'] ?? 0).toDouble(),
    );
  }
}

class DetailPenjualan {
  final String idDetailJual;
  final String nofakturJual;
  final String kodeBarang;
  final int jumlah;
  final double hargaSatuan;
  final double subtotal;
  final String satuan;
  final double nilaiKomisi;
  final String namaKomisi;

  DetailPenjualan({
    required this.idDetailJual,
    required this.nofakturJual,
    required this.kodeBarang,
    required this.jumlah,
    required this.hargaSatuan,
    required this.subtotal,
    required this.satuan,
    required this.nilaiKomisi,
    required this.namaKomisi,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_detail_jual': idDetailJual,
      'nofaktur_jual': nofakturJual,
      'kode_barang': kodeBarang,
      'jumlah': jumlah,
      'harga_satuan': hargaSatuan,
      'subtotal': subtotal,
      'satuan': satuan,
      'nilai_komisi': nilaiKomisi,
      'nama_komisi': namaKomisi,
    };
  }

  static DetailPenjualan fromMap(Map<String, dynamic> map) {
    return DetailPenjualan(
      idDetailJual: map['id_detail_jual'] ?? '',
      nofakturJual: map['nofaktur_jual'] ?? '',
      kodeBarang: map['kode_barang'] ?? '',
      jumlah: (map['jumlah'] ?? 0).toInt(),
      hargaSatuan: (map['harga_satuan'] ?? 0).toDouble(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      satuan: map['satuan'] ?? '',
      nilaiKomisi: (map['nilai_komisi'] ?? 0).toDouble(),
      namaKomisi: map['nama_komisi'] ?? '',
    );
  }
}