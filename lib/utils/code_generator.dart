import 'package:cloud_firestore/cloud_firestore.dart';

/// Utilities to generate sequential codes based on existing documents in Firestore.
class CodeGenerator {
  /// Generate next sequential code for a collection using a prefix and fixed width.
  /// Example: prefix='B', width=5 -> B00001
  static Future<String> nextSequentialCode(
    FirebaseFirestore firestore,
    String collection,
    String fieldName,
    String prefix,
    int width,
  ) async {
    final snapshot = await firestore.collection(collection).get();
    int maxNum = 0;

    // pattern: ^PREFIX(\d+)$
    final regex = RegExp(r'^' + RegExp.escape(prefix) + r'(\d+)$');

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final value = data[fieldName]?.toString() ?? doc.id;
      final m = regex.firstMatch(value);
      if (m != null) {
        final n = int.tryParse(m.group(1) ?? '0') ?? 0;
        if (n > maxNum) maxNum = n;
      }
    }

    final next = maxNum + 1;
    final numStr = next.toString().padLeft(width, '0');
    return '$prefix$numStr';
  }

  /// Generate next monthly code with prefix, width and current month/year suffix.
  /// Example: prefix='PB', width=5 -> PB00001/09/2025
  static Future<String> nextMonthlyCode(
    FirebaseFirestore firestore,
    String collection,
    String fieldName,
    String prefix,
    int width,
    int month,
    int year,
  ) async {
    final snapshot = await firestore.collection(collection).get();
    int maxNum = 0;

    final monthStr = month.toString().padLeft(2, '0');
    final yearStr = year.toString();

    // pattern: PREFIX + digits + '/' + MM + '/' + YYYY
    final regex = RegExp(r'^' + RegExp.escape(prefix) + r'(\d+)/' + monthStr + '/' + yearStr + r'$');

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final value = data[fieldName]?.toString() ?? doc.id;
      final m = regex.firstMatch(value);
      if (m != null) {
        final n = int.tryParse(m.group(1) ?? '0') ?? 0;
        if (n > maxNum) maxNum = n;
      }
    }

    final next = maxNum + 1;
    final numStr = next.toString().padLeft(width, '0');
    return '$prefix$numStr/$monthStr/$yearStr';
  }
}
