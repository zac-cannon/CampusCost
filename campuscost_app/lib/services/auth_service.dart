import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<User?> signUp(String email, String password) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    return userCredential.user;
  }

  static Future<User?> login(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return userCredential.user;
  }

  static Future<void> logout() async => await _auth.signOut();

  static Future<void> resetPassword(String email) async =>
      await _auth.sendPasswordResetEmail(email: email);

  static Stream<User?> get userChanges => _auth.authStateChanges();
}
