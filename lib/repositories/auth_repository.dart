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
    await _firestoreService.set('users', uid, {'email': email});
    return UserModel(uid: uid, email: email);
  }

  Future<UserModel> register(String email, String password) async {
    final credential = await _authService.register(email, password);
    final uid = credential.user!.uid;
    await _firestoreService.set('users', uid, {'email': email});
    return UserModel(uid: uid, email: email);
  }

  Future<void> signOut() => _authService.signOut();
}
