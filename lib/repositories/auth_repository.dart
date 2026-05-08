import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthRepository {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  AuthRepository({
    AuthService? authService,
    FirestoreService? firestoreService,
  }) : _authService = authService ?? AuthService(),
       _firestoreService = firestoreService ?? FirestoreService();

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  Future<UserModel> signIn(String email, String password) async {
    final credential = await _authService.signIn(email, password);
    final uid = credential.user!.uid;
    // Merge so we don't overwrite the existing role.
    await _firestoreService.set('users', uid, {'email': email}, merge: true);
    return fetchUser(uid, email);
  }

  Future<UserModel> register(String email, String password) async {
    final credential = await _authService.register(email, password);
    final uid = credential.user!.uid;
    await _firestoreService.set('users', uid, {
      'email': email,
      'role': UserRole.employee.name,
    });
    return UserModel(uid: uid, email: email, role: UserRole.employee);
  }

  Future<UserModel> fetchUser(String uid, String email) async {
    final doc = await _firestoreService.getDoc('users', uid);
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!, uid);
    }
    // No doc yet — create with employee role.
    await _firestoreService.set('users', uid, {
      'email': email,
      'role': UserRole.employee.name,
    });
    return UserModel(uid: uid, email: email, role: UserRole.employee);
  }

  Future<void> signOut() => _authService.signOut();
}
