import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/auth_controller.dart';
import '../controllers/user_controller.dart';
import '../themes/app_collors.dart';
import 'login_view.dart';
import 'home_view.dart';
import 'email_verification_view.dart';

class AuthStateHandler extends StatefulWidget {
  const AuthStateHandler({super.key});

  @override
  State<AuthStateHandler> createState() => _AuthStateHandlerState();
}

class _AuthStateHandlerState extends State<AuthStateHandler> {
  final AuthController _authController = AuthController();
  final UserController _userController = UserController();
  bool _isChecking = true;
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    _checkUserDocument();
  }

  Future<void> _checkUserDocument() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        // Only check if it's a different user
        if (_lastUserId != currentUser.uid) {
          print('🔍 Checking user document for: ${currentUser.uid}');
          print('📧 Email: ${currentUser.email}');
          print('✉️ Email Verified: ${currentUser.emailVerified}');
          print('👤 Display Name: ${currentUser.displayName}');
          
          // Ensure user document exists
          await _userController.ensureUserDocument(currentUser);
          
          // Wait a bit for Firestore to sync
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Verify document was created
          final userModel = await _userController.getCurrentUser();
          
          if (userModel != null) {
            print('✅ User document verified: ${userModel.name}');
            _lastUserId = currentUser.uid;
          } else {
            print('⚠️ User document still not found, retrying...');
            await _userController.ensureUserDocument(currentUser);
          }
        }
      } else {
        // User logged out, clear last user ID
        _lastUserId = null;
        print('🔓 User logged out, clearing session');
      }
    } catch (e) {
      print('❌ Error checking user document: $e');
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Memuat...",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: _authController.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while waiting for auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        // Check if user is logged in
        final user = snapshot.data;
        
        if (user == null) {
          // Not logged in -> show login page
          return const LoginView();
        }

        if (!user.emailVerified) {
          print('⚠️ User not verified, showing verification screen');
          return EmailVerificationView(user: user);
        }

        // Logged in & verified -> show home page
        print('✅ User verified, showing home');
        return const HomeView();
      },
    );
  }
}