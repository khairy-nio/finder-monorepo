import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/finder_colors.dart';
import '../../core/services/auth_service.dart';
import '../providers/user_provider.dart';

/// Email Verification Screen
class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    this.email = 'user@example.com',
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  int _remainingSeconds = 30;
  Timer? _timer;
  bool _isLoading = false;
  String? _statusMessage;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _startTimer(30);
    _ensureAuthenticatedUser();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _ensureAuthenticatedUser() {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      _statusMessage = 'No signed-in user. Please log in again.';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  void _startTimer(int seconds) {
    setState(() => _remainingSeconds = seconds);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _onResendEmail() {
    if (_remainingSeconds == 0) {
      _resendVerificationEmail();
    }
  }

  Future<void> _verifyEmail() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _isError = false;
    });

    final verified = await AuthService.instance.reloadAndCheckEmailVerified();

    if (!mounted) return;

    if (verified) {
      // Load backend user profile before navigating home (non-fatal).
      if (mounted) {
        await context.read<UserProvider>().loadUser();
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() {
        _isError = true;
        _statusMessage = 'Email not verified yet. Please check your inbox (and spam folder).';
        _isLoading = false;
      });
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _isError = false;
    });

    try {
      await AuthService.instance.sendEmailVerification();
      if (!mounted) return;
      // Start a 60-second cooldown after a successful resend
      _startTimer(60);
      setState(() {
        _isError = false;
        _statusMessage = 'Verification email sent! Please check your inbox and spam folder.';
        _isLoading = false;
      });
    } on TooManyRequestsException catch (e) {
      if (!mounted) return;
      // Firebase is rate-limiting — enforce a 3-minute wait
      _startTimer(180);
      setState(() {
        _isError = true;
        _statusMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _statusMessage = 'Failed to resend email. Please try again later.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FinderColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: FinderColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Verify Your Account',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: FinderColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a verification link to\n${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: FinderColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'Edit Email',
                  style: TextStyle(
                    fontSize: 14,
                    color: FinderColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (_statusMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _isError
                          ? Colors.red.withOpacity(0.08)
                          : Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isError
                            ? Colors.red.withOpacity(0.3)
                            : Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _isError ? Icons.error_outline : Icons.check_circle_outline,
                          size: 16,
                          color: _isError ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusMessage!,
                            style: TextStyle(
                              fontSize: 12,
                              color: _isError ? Colors.red.shade700 : Colors.green.shade700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FinderColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _isLoading ? 'Checking...' : 'I Verified My Email',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: (_remainingSeconds == 0 && !_isLoading) ? _onResendEmail : null,
                child: Text(
                  _remainingSeconds == 0
                      ? 'Resend verification email'
                      : _remainingSeconds > 60
                          ? 'Resend in ${_remainingSeconds ~/ 60}m ${_remainingSeconds % 60}s'
                          : 'Resend email in $_remainingSeconds s',
                  style: TextStyle(
                    color: (_remainingSeconds == 0 && !_isLoading)
                        ? FinderColors.primaryBlue
                        : FinderColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
