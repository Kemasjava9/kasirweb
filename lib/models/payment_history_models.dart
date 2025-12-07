import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentRecord {
  final DateTime date;
  final double amount;
  final String? note;

  PaymentRecord({
    required this.date,
    required this.amount,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'amount': amount,
      'note': note ?? '',
    };
  }

  static PaymentRecord fromMap(Map<String, dynamic> map) {
    return PaymentRecord(
      date: (map['date'] as Timestamp).toDate(),
      amount: map['amount'].toDouble(),
      note: map['note'] as String?,
    );
  }
}

class PaymentHistory {
  final String id;
  final String invoiceNumber;
  final String customerName;
  final double totalSales;
  final List<PaymentRecord> payments;
  final double totalPayment;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentHistory({
    required this.id,
    required this.invoiceNumber,
    required this.customerName,
    required this.totalSales,
    required this.payments,
    required this.totalPayment,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'invoice_number': invoiceNumber,
      'customer': customerName,
      'total_sales': totalSales,
      'payment_history': payments.map((p) => p.toMap()).toList(),
      'total_payment': totalPayment,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  static PaymentHistory fromMap(Map<String, dynamic> map, String documentId) {
    final paymentList = (map['payment_history'] as List<dynamic>?)
        ?.map((item) => PaymentRecord.fromMap(Map<String, dynamic>.from(item)))
        .toList() ?? [];

    return PaymentHistory(
      id: documentId,
      invoiceNumber: map['invoice_number'] ?? '',
      customerName: map['customer'] ?? '',
      totalSales: (map['total_sales'] ?? 0).toDouble(),
      payments: paymentList,
      totalPayment: (map['total_payment'] ?? 0).toDouble(),
      createdAt: (map['created_at'] as Timestamp).toDate(),
      updatedAt: (map['updated_at'] as Timestamp).toDate(),
    );
  }
}
