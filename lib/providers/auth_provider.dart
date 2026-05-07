import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

const bool kBypassAuth = true;

const _kGuestUser = UserModel(uid: 'guest', email: 'guest@test.com');

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();

  UserModel? _user = kBypassAuth ? _kGuestUser : null;
  bool _initialized = kBypassAuth;
  bool _loading = false;
  String? _error;

  UserModel? get user => _user;
  bool get initialized => _initialized;
  bool get isAuthenticated => _user != null;
  bool get loading => _loading;
  String? get error => _error;

  AuthProvider() {
    // authStateChanges fires immediately with the persisted session (or null),
    // so _initialized is set to true after the very first emission.
    if (kBypassAuth) return;
    _repo.authStateChanges.listen((User? firebaseUser) {
      _user = firebaseUser == null
          ? null
          : UserModel(uid: firebaseUser.uid, email: firebaseUser.email ?? '');
      _initialized = true;
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    try {
      _user = await _repo.signIn(email, password);
      _error = null;
    } on FirebaseAuthException catch (e) {
      _error = _mapError(e.code);
    } catch (_) {
      _error = 'An unexpected error occurred.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register(String email, String password) async {
    _setLoading(true);
    try {
      _user = await _repo.register(email, password);
      _error = null;
    } on FirebaseAuthException catch (e) {
      _error = _mapError(e.code);
    } catch (_) {
      _error = 'An unexpected error occurred.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    _user = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  String _mapError(String code) => switch (code) {
    'user-not-found' || 'wrong-password' || 'invalid-credential' =>
      'Invalid email or password.',
    'invalid-email' => 'Please enter a valid email address.',
    'user-disabled' => 'This account has been disabled.',
    'too-many-requests' => 'Too many attempts. Please try again later.',
    'email-already-in-use' => 'An account with this email already exists.',
    'weak-password' => 'Password must be at least 6 characters.',
    'network-request-failed' => 'Network error. Check your connection.',
    _ => 'Authentication failed. Please try again.',
  };
}
