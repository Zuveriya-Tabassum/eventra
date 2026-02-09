// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  Future<User?> signIn(String email, String pass) async {
    final res = await _auth.signInWithEmailAndPassword(
        email: email, password: pass);
    return res.user;
  }

  Future<User?> signUp(String email, String pass) async {
    final res = await _auth.createUserWithEmailAndPassword(
        email: email, password: pass);
    return res.user;
  }

  Future<void> signOut() => _auth.signOut();

  Stream<User?> get onAuthStateChanged => _auth.authStateChanges();
}
