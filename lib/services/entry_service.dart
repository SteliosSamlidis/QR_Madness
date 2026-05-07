import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/entry_model.dart';

class EntryService {
  static const _collection = 'entries';

  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection(_collection);

  Future<void> addEntry(EntryModel entry) =>
      _col.add(entry.toMap()).timeout(const Duration(seconds: 15));

  Future<void> updateEntry(String id, EntryModel entry) =>
      _col.doc(id).update(entry.toMap()).timeout(const Duration(seconds: 15));

  Stream<List<EntryModel>> getEntriesStream(String storeId) {
    return _col
        .where('storeId', isEqualTo: storeId)
        .snapshots()
        .map((snap) {
      final entries = snap.docs.map(EntryModel.fromDoc).toList();
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return entries;
    });
  }

  Future<void> updateStatus(String entryId, EntryStatus status) {
    return _col.doc(entryId).update({'status': status.name});
  }

  Future<void> deleteEntry(String entryId) => _col.doc(entryId).delete();
}
