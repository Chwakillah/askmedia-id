import 'package:firebase_auth/firebase_auth.dart';
import '../models/auth_result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<AuthResult> loginWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null && !user.emailVerified) {
        return AuthResult(user: null, error: 'Email belum diverifikasi.');
      }

      return AuthResult(user: user, error: null);
    } catch (e) {
      return AuthResult(user: null, error: 'Login gagal. Cek email & password.');
    }
  }

  Future<AuthResult> loginWithGoogle() async {
    try {
      final googleProvider = GoogleAuthProvider();
      final userCredential = await _auth.signInWithProvider(googleProvider);
      return AuthResult(user: userCredential.user, error: null);
    } catch (e) {
      return AuthResult(user: null, error: 'Google login gagal.');
    }
  }
  
  Future<AuthResult> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'id': user.uid,
          'name': name,
          'bio': '',
          'email': email,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });

        await user.sendEmailVerification();
      }

      return AuthResult(user: user, error: null);
    } catch (e) {
      return AuthResult(
        user: null,
        error: 'Pendaftaran gagal. Silakan coba lagi.',
      );
    }
  }

  String? validateEmail(String value) {
    if (value.isEmpty || !value.contains('@')) {
      return 'Email tidak valid';
    }
    return null;
  }

  String? validatePassword(String value) {
    if (value.isEmpty || value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }
}
