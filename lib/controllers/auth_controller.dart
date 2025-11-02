import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/auth_result.dart';
import '../models/user_model.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper method to ensure user document exists
  Future<void> _ensureUserDocument(User firebaseUser) async {
    try {
      final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        // Create new user document
        final newUser = UserModel(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'User',
          email: firebaseUser.email ?? '',
          bio: '',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        await userDoc.set(newUser.toMap());
        print('✅ User document created for: ${firebaseUser.uid}');
      } else {
        print('✅ User document already exists for: ${firebaseUser.uid}');
      }
    } catch (e) {
      print('❌ Error ensuring user document: $e');
      rethrow;
    }
  }

  Future<AuthResult> loginWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // Cek verifikasi email
        if (!user.emailVerified) {
          return AuthResult(
            user: user,
            error: 'Email belum diverifikasi. Silakan verifikasi email Anda terlebih dahulu.',
          );
        }

        // Ensure user document exists
        await _ensureUserDocument(user);
      }

      return AuthResult(user: user, error: null);
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login gagal. Cek email & password.';
      
      if (e.code == 'user-not-found') {
        errorMessage = 'Email tidak terdaftar.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Password salah.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'Akun ini telah dinonaktifkan.';
      } else if (e.code == 'invalid-credential') {
        errorMessage = 'Email atau password salah.';
      }

      return AuthResult(user: null, error: errorMessage);
    } catch (e) {
      return AuthResult(user: null, error: 'Login gagal. Silakan coba lagi.');
    }
  }

  Future<AuthResult> loginWithGoogle() async {
    try {
      UserCredential userCredential;
      
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters({
          'prompt': 'select_account',
        });
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email'],
        );
        
        await googleSignIn.signOut();
        
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
      
      final user = userCredential.user;
      if (user != null) {
        await _ensureUserDocument(user);
      }
      
      return AuthResult(user: user, error: null);
      
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Google login gagal.';
      
      if (e.code == 'popup-closed-by-user') {
        errorMessage = 'Login dibatalkan.';
      } else if (e.code == 'popup-blocked') {
        errorMessage = 'Popup diblokir. Izinkan popup untuk situs ini.';
      } else if (e.code == 'web-storage-unsupported') {
        errorMessage = 'Browser tidak mendukung storage. Coba browser lain.';
      } else if (e.code == 'account-exists-with-different-credential') {
        errorMessage = 'Email sudah terdaftar dengan metode login lain.';
      }
      
      return AuthResult(user: null, error: errorMessage);
    } catch (e) {
      print('❌ Error during Google login: $e');
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
        // Create user document
        final newUser = UserModel(
          id: user.uid,
          name: name.trim().isEmpty ? 'User' : name.trim(),
          email: email,
          bio: '',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        print('✅ User document created during registration: ${user.uid}');

        // Send email verification
        await user.sendEmailVerification();
        print('📧 Verification email sent to: ${user.email}');
      }

      return AuthResult(user: user, error: null);
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Pendaftaran gagal. Silakan coba lagi.';

      if (e.code == 'email-already-in-use') {
        errorMessage = 'Email sudah terdaftar. Silakan login.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Password terlalu lemah. Minimal 6 karakter.';
      }

      return AuthResult(user: null, error: errorMessage);
    } catch (e) {
      print('❌ Error during registration: $e');
      return AuthResult(
        user: null,
        error: 'Pendaftaran gagal. Silakan coba lagi.',
      );
    }
  }

  // Method to check and fix existing users without documents
  Future<bool> checkAndFixUserDocument() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      await _ensureUserDocument(currentUser);
      return true;
    } catch (e) {
      print('❌ Error checking/fixing user document: $e');
      return false;
    }
  }

  String? validateEmail(String value) {
    if (value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Email tidak valid';
    }
    return null;
  }

  String? validatePassword(String value) {
    if (value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  String? validateName(String value) {
    if (value.trim().isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    if (value.trim().length < 3) {
      return 'Nama minimal 3 karakter';
    }
    return null;
  }

  // Sign out
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
      }
      await _auth.signOut();
      print('✅ User signed out successfully');
    } catch (e) {
      print('❌ Error signing out: $e');
      rethrow;
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}