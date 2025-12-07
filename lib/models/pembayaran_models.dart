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

class PaymentHistory {
  final String invoiceNumber;
  final String customer;
  final double totalSales;
  final double? payment1;
  final double? payment2;
  final double? payment3;
  final double? payment4;
  final double? payment5;
  final double totalPayment;
  final String date;

  PaymentHistory({
    required this.invoiceNumber,
    required this.customer,
    required this.totalSales,
    this.payment1,
    this.payment2,
    this.payment3,
    this.payment4,
    this.payment5,
    required this.totalPayment,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'invoice_number': invoiceNumber,
      'customer': customer,
      'total_sales': totalSales,
      'payment1': payment1,
      'payment2': payment2,
      'payment3': payment3,
      'payment4': payment4,
      'payment5': payment5,
      'total_payment': totalPayment,
      'date': date,
    };
  }

  static PaymentHistory fromMap(Map<String, dynamic> map) {
    return PaymentHistory(
      invoiceNumber: map['invoice_number'] ?? '',
      customer: map['customer'] ?? '',
      totalSales: (map['total_sales'] ?? 0).toDouble(),
      payment1: map['payment1']?.toDouble(),
      payment2: map['payment2']?.toDouble(),
      payment3: map['payment3']?.toDouble(),
      payment4: map['payment4']?.toDouble(),
      payment5: map['payment5']?.toDouble(),
      totalPayment: (map['total_payment'] ?? 0).toDouble(),
      date: map['date'] ?? '',
    );
  }
}
