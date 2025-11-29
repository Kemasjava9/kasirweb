// Models for Pembayaran (payment installments) related classes
class Pembayaran {
  final String id;
  final String nofakturJual;
  final int termin;
  final double jumlah;
  final String tanggalJatuhTempo;
  final String status; // 'Belum Dibayar', 'Dibayar'

  Pembayaran({
    required this.id,
    required this.nofakturJual,
    required this.termin,
    required this.jumlah,
    required this.tanggalJatuhTempo,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nofaktur_jual': nofakturJual,
      'termin': termin,
      'jumlah': jumlah,
      'tanggal_jatuh_tempo': tanggalJatuhTempo,
      'status': status,
    };
  }

  static Pembayaran fromMap(Map<String, dynamic> map) {
    return Pembayaran(
      id: map['id'] ?? '',
      nofakturJual: map['nofaktur_jual'] ?? '',
      termin: (map['termin'] ?? 0).toInt(),
      jumlah: (map['jumlah'] ?? 0).toDouble(),
      tanggalJatuhTempo: map['tanggal_jatuh_tempo'] ?? '',
      status: map['status'] ?? 'Belum Dibayar',
    );
  }
}
