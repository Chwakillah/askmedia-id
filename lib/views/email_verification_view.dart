import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/auth_controller.dart';
import '../themes/app_collors.dart';
import '../widget/primmary_button.dart';
import '../widget/secondary_button.dart';
import 'home_view.dart';

class EmailVerificationView extends StatefulWidget {
  final User user;

  const EmailVerificationView({
    super.key,
    required this.user,
  });

  @override
  State<EmailVerificationView> createState() => _EmailVerificationViewState();
}

class _EmailVerificationViewState extends State<EmailVerificationView> with WidgetsBindingObserver {
  final AuthController _authController = AuthController();
  bool _isResendingEmail = false;
  bool _isCheckingVerification = false;
  Timer? _timer;
  int _countdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Auto check verifikasi setiap 3 detik
    _startAutoCheck();
    _startResendCountdown();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  // Detect saat app kembali ke foreground (setelah user klik link di email)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('🔄 App resumed, checking verification...');
      _checkEmailVerification();
    }
  }

  void _startAutoCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkEmailVerification();
    });
  }

  void _startResendCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        if (mounted) setState(() => _countdown--);
      } else {
        if (mounted) setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  Future<void> _checkEmailVerification() async {
    try {
      await widget.user.reload();
      final updatedUser = FirebaseAuth.instance.currentUser;

      if (updatedUser != null && updatedUser.emailVerified) {
        print('✅ Email verified! Redirecting to home...');
        _timer?.cancel();
        
        if (mounted) {
          // Langsung navigate ke HomeView dan hapus semua route sebelumnya
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeView()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      print('❌ Error checking verification: $e');
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResend || _isResendingEmail) return;

    setState(() {
      _isResendingEmail = true;
      _canResend = false;
      _countdown = 60;
    });

    try {
      await widget.user.sendEmailVerification();
      
      if (mounted) {
        _showSuccessMessage('Email verifikasi telah dikirim ulang! Cek inbox Anda.');
        _startResendCountdown();
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('too-many-requests')) {
          _showErrorMessage('Terlalu banyak permintaan. Tunggu beberapa saat.');
        } else {
          _showErrorMessage('Gagal mengirim email. Coba lagi.');
        }
        setState(() => _canResend = true);
      }
    } finally {
      if (mounted) {
        setState(() => _isResendingEmail = false);
      }
    }
  }

  Future<void> _manualCheckVerification() async {
    setState(() => _isCheckingVerification = true);

    try {
      await widget.user.reload();
      final updatedUser = FirebaseAuth.instance.currentUser;

      if (updatedUser != null && updatedUser.emailVerified) {
        _showSuccessMessage('Email berhasil diverifikasi!');
        await Future.delayed(const Duration(milliseconds: 800));
        
        if (mounted) {
          // Langsung navigate ke HomeView dan hapus semua route sebelumnya
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeView()),
            (route) => false,
          );
        }
      } else {
        _showErrorMessage('Email belum diverifikasi. Silakan cek inbox dan klik link verifikasi terlebih dahulu.');
      }
    } catch (e) {
      _showErrorMessage('Gagal mengecek verifikasi. Coba lagi.');
    } finally {
      if (mounted) {
        setState(() => _isCheckingVerification = false);
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _authController.signOut();
      // AuthStateHandler akan otomatis redirect ke LoginView
    } catch (e) {
      _showErrorMessage('Gagal logout');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Keluar'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Email
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Title
                Text(
                  'Verifikasi Email Anda',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Description
                Text(
                  'Kami telah mengirim email verifikasi ke:',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                // Email
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    widget.user.email ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Instructions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, 
                            color: Colors.blue[700], 
                            size: 22
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Langkah Verifikasi:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildStep('1', 'Buka inbox email Anda'),
                      _buildStep('2', 'Cari email dari Firebase/Askademia'),
                      _buildStep('3', 'Klik link verifikasi di email'),
                      _buildStep('4', 'Kembali ke sini & klik "Sudah Verifikasi"'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Check Verification Button
                PrimaryButton(
                  text: 'Sudah Verifikasi? Masuk Sekarang',
                  onPressed: _isCheckingVerification ? null : _manualCheckVerification,
                  isLoading: _isCheckingVerification,
                  icon: Icons.verified_user,
                ),
                
                const SizedBox(height: 16),
                
                // Resend Email Button
                SecondaryButton(
                  text: _canResend 
                    ? 'Kirim Ulang Email' 
                    : 'Kirim Ulang ($_countdown detik)',
                  onPressed: _canResend && !_isResendingEmail 
                    ? _resendVerificationEmail 
                    : null,
                  icon: Icons.email_outlined,
                ),
                
                if (_isResendingEmail)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Mengirim email...',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Auto check indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.green[600],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Mendeteksi verifikasi otomatis...',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Help text
                Text(
                  'Tidak menerima email? Cek folder spam atau kirim ulang',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.blue[700],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}