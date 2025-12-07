import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_history_models.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore}) 
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<T>> getCollection<T>({
    required String path,
    required T Function(Map<String, dynamic> data, String documentId) fromMap,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)? queryBuilder,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection(path);
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      throw Exception('Error getting collection $path: $e');
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getDocuments({
    required String path,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)? queryBuilder,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection(path);
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }

      return await query.get();
    } catch (e) {
      throw Exception('Error getting documents from $path: $e');
    }
  }

  Future<void> addDocument<T>({
    required String path,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    try {
      final docRef = documentId != null 
        ? _firestore.collection(path).doc(documentId)
        : _firestore.collection(path).doc();
      await docRef.set(data);
    } catch (e) {
      throw Exception('Error adding document to $path: $e');
    }
  }

  Future<void> updateDocument({
    required String path,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(path).doc(documentId).update(data);
    } catch (e) {
      throw Exception('Error updating document $documentId in $path: $e');
    }
  }

  Future<void> deleteDocument({
    required String path,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(path).doc(documentId).delete();
    } catch (e) {
      throw Exception('Error deleting document $documentId from $path: $e');
    }
  }

  Future<void> batchWrite(List<void Function(WriteBatch batch)> operations) async {
    try {
      final batch = _firestore.batch();
      for (var operation in operations) {
        operation(batch);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Error executing batch write: $e');
    }
  }

  Stream<List<T>> streamCollection<T>({
    required String path,
    required T Function(Map<String, dynamic> data, String documentId) fromMap,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)? queryBuilder,
  }) {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection(path);
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }

      return query.snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList()
      );
    } catch (e) {
      throw Exception('Error streaming collection $path: $e');
    }
  }

  Future<void> createPaymentHistory({
    required String invoiceNumber,
    required String customerName,
    required double totalSales,
    required List<PaymentRecord> payments,
    required double totalPayment,
  }) async {
    final data = {
      'invoice_number': invoiceNumber,
      'customer': customerName,
      'total_sales': totalSales,
      'payment_history': payments.map((p) => p.toMap()).toList(),
      'total_payment': totalPayment,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('payment_history').add(data);
  }

  Stream<List<PaymentHistory>> streamPaymentHistory() {
    return _firestore
        .collection('payment_history')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentHistory.fromMap(doc.data(), doc.id))
            .toList());
  }
}
