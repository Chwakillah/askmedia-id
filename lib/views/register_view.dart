import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../controllers/auth_controller.dart';
import '../../../models/user_model.dart';
import '../themes/app_collors.dart';
import '../controllers/user_controller.dart';
import '../widget/custom_input_field.dart';
import '../widget/secondary_button.dart';
import '../widget/primmary_button.dart';
import '../widget/tittle.text.dart';
import '../widget/auth_card.dart';
import '../widget/google_button.dart';
import '../views/login_view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {

  final _authController = AuthController();
  final _userController = UserController();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordObscured = true;
  bool _isEmailLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Email registration handler
  Future<void> _handleEmailRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isEmailLoading = true);

    try {
      // Register with Firebase Auth
      final result = await _authController.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );

      if (result.user != null) {
        // Create user document in Firestore
        await _createUserDocument(result.user!);
        
        if (mounted) {
          _showSuccessMessage('Registrasi berhasil! Silakan login.');
          _navigateToLogin();
        }
      } else {
        if (mounted) {
          _showErrorMessage(result.error ?? 'Registrasi gagal. Silakan coba lagi.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Terjadi kesalahan: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isEmailLoading = false);
      }
    }
  }

  // Google registration handler
  Future<void> _handleGoogleRegister() async {
    setState(() => _isGoogleLoading = true);

    try {
      final result = await _authController.loginWithGoogle();

      if (result.user != null) {
        // Ensure user document exists
        await _userController.ensureUserDocument(result.user!);
        
        if (mounted) {
          _showSuccessMessage('Registrasi Google berhasil!');
          // Google login usually auto-navigates, but we can handle it here if needed
        }
      } else {
        if (mounted) {
          _showErrorMessage(result.error ?? 'Registrasi Google gagal. Silakan coba lagi.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Terjadi kesalahan: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User firebaseUser) async {
    final newUser = UserModel(
      id: firebaseUser.uid,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      bio: '',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _userController.saveUserToFirestore(newUser);
  }

  // Navigate to login
  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
    );
  }

  // Toggle password visibility
  void _togglePasswordVisibility() {
    setState(() => _isPasswordObscured = !_isPasswordObscured);
  }

  // Show success message
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Show error message
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  bool get _isLoading => _isEmailLoading || _isGoogleLoading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Daftar Akun',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Header Section
                const TitleText(
                  "Buat Akun Baru",
                  subtitle: "Bergabunglah dengan komunitas dan mulai berbagi pengalaman Anda.",
                ),
                
                const SizedBox(height: 40),
                
                // Registration Form Card
                AuthCard(
                  child: Column(
                    children: [
                      // Name Field
                      CustomInputField(
                        label: "Nama Lengkap",
                        icon: Icons.person_outlined,
                        controller: _nameController,
                        validator: (val) => val == null || val.trim().isEmpty 
                            ? "Nama lengkap wajib diisi" 
                            : null,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Email Field
                      CustomInputField(
                        label: "Email",
                        icon: Icons.email_outlined,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) => _authController.validateEmail(val ?? ''),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Password Field
                      CustomInputField(
                        label: "Password",
                        icon: Icons.lock_outlined,
                        controller: _passwordController,
                        obscureText: _isPasswordObscured,
                        validator: (val) => _authController.validatePassword(val ?? ''),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordObscured
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey[600],
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Register Button
                      PrimaryButton(
                        text: "Daftar",
                        onPressed: _isLoading ? null : _handleEmailRegister,
                        isLoading: _isEmailLoading,
                        icon: Icons.person_add,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Terms and Conditions
                      Text(
                        "Dengan mendaftar, Anda menyetujui Syarat & Ketentuan dan Kebijakan Privasi kami.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "atau",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Google Register Button
                GoogleButton(
                  onPressed: _isLoading ? () {} : _handleGoogleRegister,
                  isLoading: _isGoogleLoading,
                ),
                
                const SizedBox(height: 32),
                
                // Login Link
                SecondaryButton(
                  text: "Sudah punya akun? Masuk sekarang",
                  onPressed: _isLoading ? () {} : _navigateToLogin,
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}