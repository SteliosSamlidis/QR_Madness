import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class UserService {
  final _col = FirebaseFirestore.instance.collection('users');

  Stream<List<UserModel>> getUsersStream() {
    return _col.orderBy('email').snapshots().map(
          (snap) => snap.docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> updateRole(String uid, UserRole role) =>
      _col.doc(uid).update({'role': role.name}).timeout(const Duration(seconds: 15));
}
