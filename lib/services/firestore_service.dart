import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore}) 
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<T>> getCollection<T>({
    required String path,
    required T Function(Map<String, dynamic> data) fromMap,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)? queryBuilder,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection(path);
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Error getting collection $path: $e');
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
    required T Function(Map<String, dynamic> data) fromMap,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)? queryBuilder,
  }) {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection(path);
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }
      
      return query.snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => fromMap(doc.data())).toList()
      );
    } catch (e) {
      throw Exception('Error streaming collection $path: $e');
    }
  }
}