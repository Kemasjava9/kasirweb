// Export models
export 'surat_jalan_models.dart';

class User {
  final String id;
  final String username;
  final String password;
  final String namaLengkap;
  final String level;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.namaLengkap,
    required this.level,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_user': id,
      'username': username,
      'password': password,
      'nama_lengkap': namaLengkap,
      'level': level,
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? map['id_user'] ?? '',  // Support both id formats
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      namaLengkap: map['nama_lengkap'] ?? '',
      level: map['level'] ?? 'user',  // Default to user level
    );
  }
}

class Barang {
  final String kodeBarang;
  final String namaBarang;
  final String satuanPcs;
  final String satuanDus;
  final int isiDus;
  final double hargaPcs;
  final double hargaDus;
  final int jumlah;
  final double hpp;
  final double hppDus;

  Barang({
    required this.kodeBarang,
    required this.namaBarang,
    required this.satuanPcs,
    required this.satuanDus,
    required this.isiDus,
    required this.hargaPcs,
    required this.hargaDus,
    required this.jumlah,
    required this.hpp,
    required this.hppDus,
  });

  Map<String, dynamic> toMap() {
    return {
      'kode_barang': kodeBarang,
      'nama_barang': namaBarang,
      'satuan_pcs': satuanPcs,
      'satuan_dus': satuanDus,
      'isi_dus': isiDus,
      'harga_pcs': hargaPcs,
      'harga_dus': hargaDus,
      'jumlah': jumlah,
      // 'harga_beli' intentionally not stored anymore
      'HPP': hpp,
      'HPP_dus': hppDus,
    };
  }

  static Barang fromMap(Map<String, dynamic> map) {
    return Barang(
      kodeBarang: map['kode_barang'] ?? '',
      namaBarang: map['nama_barang'] ?? '',
      satuanPcs: map['satuan_pcs'] ?? '',
      satuanDus: map['satuan_dus'] ?? '',
      isiDus: (map['isi_dus'] ?? 0).toInt(),
      hargaPcs: (map['harga_pcs'] ?? 0).toDouble(),
      hargaDus: (map['harga_dus'] ?? 0).toDouble(),
      jumlah: (map['jumlah'] ?? 0).toInt(),
      hpp: (map['HPP'] ?? 0).toDouble(),
      hppDus: (map['HPP_dus'] ?? 0).toDouble(),
    );
  }
}

class Supplier {
  final String kodeSupplier;
  final String namaSupplier;
  final String alamatSupplier;
  final String telpSupplier;

  Supplier({
    required this.kodeSupplier,
    required this.namaSupplier,
    required this.alamatSupplier,
    required this.telpSupplier,
  });

  Map<String, dynamic> toMap() {
    return {
      'kode_supplier': kodeSupplier,
      'nama_supplier': namaSupplier,
      'alamat_supplier': alamatSupplier,
      'telp_supplier': telpSupplier,
    };
  }

  static Supplier fromMap(Map<String, dynamic> map) {
    return Supplier(
      kodeSupplier: map['kode_supplier'] ?? '',
      namaSupplier: map['nama_supplier'] ?? '',
      alamatSupplier: map['alamat_supplier'] ?? '',
      telpSupplier: map['telp_supplier'] ?? '',
    );
  }
}

class Pelanggan {
  final String kodePelanggan;
  final String namaPelanggan;
  final String alamatPelanggan;
  final String noTelp;
  final String keterangan;

  Pelanggan({
    required this.kodePelanggan,
    required this.namaPelanggan,
    required this.alamatPelanggan,
    required this.noTelp,
    required this.keterangan,
  });

  Map<String, dynamic> toMap() {
    return {
      'kode_pelanggan': kodePelanggan,
      'nama_pelanggan': namaPelanggan,
      'alamat_pelanggan': alamatPelanggan,
      'no_telp': noTelp,
      'keterangan': keterangan,
    };
  }

  static Pelanggan fromMap(Map<String, dynamic> map) {
    return Pelanggan(
      kodePelanggan: map['kode_pelanggan'] ?? '',
      namaPelanggan: map['nama_pelanggan'] ?? '',
      alamatPelanggan: map['alamat_pelanggan'] ?? '',
      noTelp: map['no_telp'] ?? '',
      keterangan: map['keterangan'] ?? '',
    );
  }
}

// Tambahkan di akhir file models.dart

class Pembelian {
  final String idBeli;
  final String tanggalBeli;
  final String kodeSupplier;
  final double totalBeli;
  final String status;
  final String jatuhTempo;

  Pembelian({
    required this.idBeli,
    required this.tanggalBeli,
    required this.kodeSupplier,
    required this.totalBeli,
    required this.status,
    required this.jatuhTempo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_beli': idBeli,
      'tanggal_beli': tanggalBeli,
      'kode_supplier': kodeSupplier,
      'total_beli': totalBeli,
      'status': status,
      'jatuh_tempo': jatuhTempo,
    };
  }

  static Pembelian fromMap(Map<String, dynamic> map) {
    return Pembelian(
      idBeli: map['id_beli'] ?? '',
      tanggalBeli: map['tanggal_beli'] ?? '',
      kodeSupplier: map['kode_supplier'] ?? '',
      totalBeli: (map['total_beli'] ?? 0).toDouble(),
      status: map['status'] ?? '',
      jatuhTempo: map['jatuh_tempo'] ?? '',
    );
  }
}

class Penjualan {
  final String nofakturJual;
  final String tanggalJual;
  final double totalJual;
  final String idUser;
  final String namaSales;
  final String bayar;
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
    required this.diskon,
    required this.biayaLainLain,
    required this.ongkosKirim,
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
      idUser: map['id_user'] ?? '',
      namaSales: map['nama_sales'] ?? '',
      bayar: map['bayar'] ?? '',
      namaPelanggan: map['nama_pelanggan'] ?? '',
      caraBayar: map['cara_bayar'] ?? '',
      status: map['status'] ?? '',
      diskon: (map['diskon'] ?? 0).toDouble(),
      biayaLainLain: (map['biaya_lain_lain'] ?? 0).toDouble(),
      ongkosKirim: (map['ongkos_kirim'] ?? 0).toDouble(),
    );
  }
}




