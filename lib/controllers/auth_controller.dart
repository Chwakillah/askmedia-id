import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
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
      UserCredential userCredential;
      
      if (kIsWeb) {
        // SOLUSI 1: Popup flow untuk web (paling reliable)
        final googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // SOLUSI 2: google_sign_in package untuk mobile
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email'],
        );
        
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        
        if (googleUser == null) {
          return AuthResult(user: null, error: 'Login dibatalkan.');
        }
        
        final GoogleSignInAuthentication googleAuth = 
            await googleUser.authentication;
        
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        userCredential = await _auth.signInWithCredential(credential);
      }
      
      return AuthResult(user: userCredential.user, error: null);
      
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Google login gagal.';
      
      if (e.code == 'popup-closed-by-user') {
        errorMessage = 'Login dibatalkan.';
      } else if (e.code == 'popup-blocked') {
        errorMessage = 'Popup diblokir. Izinkan popup untuk situs ini.';
      } else if (e.code == 'web-storage-unsupported') {
        errorMessage = 'Browser tidak mendukung storage. Coba browser lain.';
      }
      
      return AuthResult(user: null, error: errorMessage);
    } catch (e) {
      return AuthResult(user: null, error: 'Terjadi kesalahan: ${e.toString()}');
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