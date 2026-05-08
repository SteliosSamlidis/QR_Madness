import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference collection(String path) => _db.collection(path);

  Future<void> set(String col, String docId, Map<String, dynamic> data,
          {bool merge = false}) =>
      _db.collection(col).doc(docId).set(data, SetOptions(merge: merge));

  Future<DocumentSnapshot<Map<String, dynamic>>> getDoc(
          String col, String docId) =>
      _db.collection(col).doc(docId).get();

  Future<void> update(String col, String docId, Map<String, dynamic> data) =>
      _db.collection(col).doc(docId).update(data);

  Future<void> delete(String col, String docId) =>
      _db.collection(col).doc(docId).delete();

  Stream<QuerySnapshot> streamCollection(String path) =>
      _db.collection(path).snapshots();
}
