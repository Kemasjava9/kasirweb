import 'package:cloud_firestore/cloud_firestore.dart';

class SuratJalan {
  final String noSuratJalan;
  final DateTime tanggal;
  final String noPenjualan;
  final String pelangganId;
  final String namaPelanggan;
  final String alamat;
  final List<ItemSuratJalan> items;
  final String keterangan;
  final String status; // 'draft', 'terkirim', 'selesai'

  SuratJalan({
    required this.noSuratJalan,
    required this.tanggal,
    required this.noPenjualan,
    required this.pelangganId,
    required this.namaPelanggan,
    required this.alamat,
    required this.items,
    required this.keterangan,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'no_surat_jalan': noSuratJalan,
      'tanggal': tanggal,
      'no_penjualan': noPenjualan,
      'pelanggan_id': pelangganId,
      'nama_pelanggan': namaPelanggan,
      'alamat': alamat,
      'items': items.map((item) => item.toMap()).toList(),
      'keterangan': keterangan,
      'status': status,
    };
  }

  factory SuratJalan.fromMap(Map<String, dynamic> map) {
    return SuratJalan(
      noSuratJalan: map['no_surat_jalan'] ?? '',
      tanggal: (map['tanggal'] as Timestamp).toDate(),
      noPenjualan: map['no_penjualan'] ?? '',
      pelangganId: map['pelanggan_id'] ?? '',
      namaPelanggan: map['nama_pelanggan'] ?? '',
      alamat: map['alamat'] ?? '',
      items: List<ItemSuratJalan>.from(
        (map['items'] as List? ?? []).map(
          (item) => ItemSuratJalan.fromMap(item as Map<String, dynamic>),
        ),
      ),
      keterangan: map['keterangan'] ?? '',
      status: map['status'] ?? 'draft',
    );
  }
}

class ItemSuratJalan {
  final String kodeBarang;
  final String namaBarang;
  final int jumlah;
  final String satuan;

  ItemSuratJalan({
    required this.kodeBarang,
    required this.namaBarang,
    required this.jumlah,
    required this.satuan,
  });

  Map<String, dynamic> toMap() {
    return {
      'kode_barang': kodeBarang,
      'nama_barang': namaBarang,
      'jumlah': jumlah,
      'satuan': satuan,
    };
  }

  factory ItemSuratJalan.fromMap(Map<String, dynamic> map) {
    return ItemSuratJalan(
      kodeBarang: map['kode_barang'] ?? '',
      namaBarang: map['nama_barang'] ?? '',
      jumlah: map['jumlah']?.toInt() ?? 0,
      satuan: map['satuan'] ?? '',
    );
  }
}