import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get a Firestore collection reference
  CollectionReference collection(String path) => _db.collection(path);

  /// Get a Firestore document reference
  DocumentReference document(String path) => _db.doc(path);

  /// Add a document to a collection
  Future<DocumentReference> addDocument(
    String collectionPath,
    Map<String, dynamic> data,
  ) {
    return _db.collection(collectionPath).add(data);
  }

  /// Set (create/overwrite) a document
  Future<void> setDocument(
    String docPath,
    Map<String, dynamic> data, {
    bool merge = true,
  }) {
    return _db.doc(docPath).set(data, SetOptions(merge: merge));
  }

  /// Update specific fields in a document
  Future<void> updateDocument(String docPath, Map<String, dynamic> data) {
    return _db.doc(docPath).update(data);
  }

  /// Delete a document
  Future<void> deleteDocument(String docPath) {
    return _db.doc(docPath).delete();
  }

  /// Stream a single document
  Stream<DocumentSnapshot> streamDocument(String docPath) {
    return _db.doc(docPath).snapshots();
  }

  /// Stream a collection
  Stream<QuerySnapshot> streamCollection(String collectionPath) {
    return _db.collection(collectionPath).snapshots();
  }
}
