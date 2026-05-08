import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/store_model.dart';

class StoreService {
  static const _collection = 'stores';

  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection(_collection);

  Stream<List<StoreModel>> getStoresStream() {
    return _col
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(StoreModel.fromDoc).toList());
  }

  Future<void> addStore(StoreModel store) =>
      _col.add(store.toMap()).timeout(const Duration(seconds: 15));

  Future<void> deleteStore(String id) =>
      _col.doc(id).delete().timeout(const Duration(seconds: 15));

  Future<void> updateStore(String id, String name, String? pin) {
    final data = <String, dynamic>{'name': name};
    if (pin != null && pin.isNotEmpty) {
      data['pin'] = pin;
    } else {
      data['pin'] = FieldValue.delete();
    }
    return _col.doc(id).update(data).timeout(const Duration(seconds: 15));
  }
}
