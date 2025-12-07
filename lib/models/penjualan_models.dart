// Models for Penjualan (sales) related classes that match the SQL schema
class Penjualan {
  final String id;
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
    required this.id,
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

  static Penjualan fromMap(Map<String, dynamic> map, String documentId) {
    return Penjualan(
      id: documentId,
      nofakturJual: map['nofaktur_jual'] ?? '',
      tanggalJual: map['tanggal_jual'] ?? '',
      totalJual: double.tryParse((map['total_jual'] ?? 0).toString()) ?? 0.0,
      idUser: map['id_user']?.toString() ?? '',
      namaSales: map['nama_sales'] ?? '',
      bayar: double.tryParse((map['bayar'] ?? 0).toString()) ?? 0.0,
      namaPelanggan: map['nama_pelanggan'] ?? '',
      caraBayar: map['cara_bayar'] ?? '',
      status: map['status'] ?? '',
      diskon: double.tryParse((map['diskon'] ?? 0).toString()) ?? 0.0,
      biayaLainLain: double.tryParse((map['biaya_lain_lain'] ?? 0).toString()) ?? 0.0,
      ongkosKirim: double.tryParse((map['ongkos_kirim'] ?? 0).toString()) ?? 0.0,
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
      jumlah: int.tryParse((map['jumlah'] ?? 0).toString()) ?? 0,
      hargaSatuan: double.tryParse((map['harga_satuan'] ?? 0).toString()) ?? 0.0,
      subtotal: double.tryParse((map['subtotal'] ?? 0).toString()) ?? 0.0,
      satuan: map['satuan'] ?? '',
      nilaiKomisi: double.tryParse((map['nilai_komisi'] ?? 0).toString()) ?? 0.0,
      namaKomisi: map['nama_komisi'] ?? '',
    );
  }
}