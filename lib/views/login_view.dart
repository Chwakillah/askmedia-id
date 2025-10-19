import 'package:flutter/material.dart';
import '../../../controllers/auth_controller.dart';
import '../themes/app_collors.dart';
import '../widget/custom_input_field.dart';
import '../widget/primmary_button.dart';
import '../widget/secondary_button.dart';
import '../widget/tittle.text.dart';
import '../widget/auth_card.dart';
import '../widget/google_button.dart';
import '../views/register_view.dart';
import '../views/home_view.dart';
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}
class _LoginViewState extends State<LoginView> {
  final _authController = AuthController();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordObscured = true;
  bool _isEmailLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isEmailLoading = true);

    try {
      final result = await _authController.loginWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (result.user != null) {
        _showSuccessMessage('Login berhasil! Selamat datang kembali.');
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RegisterView()),
        );
        
      } else {
        _showErrorMessage(result.error ?? 'Login gagal. Silakan coba lagi.');
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

  Future<void> _handleGoogleLogin() async {
    setState(() => _isGoogleLoading = true);

    try {
      final result = await _authController.loginWithGoogle();

      if (!mounted) return;

      if (result.user != null) {
        _showSuccessMessage('Login Google berhasil!');
      } else {
        _showErrorMessage(result.error ?? 'Login Google gagal. Silakan coba lagi.');
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

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterView()),
    );
  }

  void _togglePasswordVisibility() {
    setState(() => _isPasswordObscured = !_isPasswordObscured);
  }

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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                const TitleText(
                  "Selamat Datang!",
                  subtitle: "Masuk ke akun Anda untuk mulai berdiskusi dan berbagi ide.",
                ),
                
                const SizedBox(height: 40),
                
                AuthCard(
                  child: Column(
                    children: [
                      CustomInputField(
                        label: "Email",
                        icon: Icons.email_outlined,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) => _authController.validateEmail(val ?? ''),
                      ),
                      
                      const SizedBox(height: 20),
                      
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
                      
                      PrimaryButton(
                        text: "Masuk",
                        onPressed: _isLoading ? null : _handleEmailLogin,
                        isLoading: _isEmailLoading,
                        icon: Icons.login,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
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
                
                GoogleButton(
                  onPressed: _isLoading ? () {} : _handleGoogleLogin,
                  isLoading: _isGoogleLoading,
                ),
                
                const SizedBox(height: 32),
                
                SecondaryButton(
                  text: "Belum punya akun? Daftar sekarang",
                  onPressed: _isLoading ? () {} : _navigateToRegister,
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