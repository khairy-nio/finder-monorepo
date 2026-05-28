import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_rounded_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_divider.dart';
import '../../core/utils/app_messenger.dart';
import '../../core/constants/finder_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/session_service.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../providers/user_provider.dart';

/// Sign Up/Register Screen
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _buildSafeName(String? rawName, String email) {
    var name = (rawName ?? '').trim();
    if (name.isEmpty) {
      name = email.split('@').first;
    }
    name = name.replaceAll(RegExp(r'[^A-Za-z\s]'), ' ');
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (name.length < 2) {
      return 'User';
    }
    if (name.length > 100) {
      return name.substring(0, 100).trim();
    }
    return name;
  }

  Future<void> _syncBackendUser({required String name, required String email}) async {
    final apiClient = ApiClient(
      tokenProvider: AuthService.instance.getIdToken,
    );
    await apiClient.post(
      ApiConstants.loginEndpoint,
      body: {'name': name, 'email': email},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FinderColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color.fromARGB(255, 78, 73, 73)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Profile Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: FinderColors.primaryBlue.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 40,
                    color: FinderColors.primaryBlue,
                  ),
                ),

                const SizedBox(height: 16),

                // Create Account Text
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: FinderColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 16),

                // Sign Up Mode Info Box
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: FinderColors.textSecondary.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    'Sign up using any method\nassociated with your email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color.fromARGB(255, 75, 71, 71),
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Sign Up with Google Button
                CustomRoundedButton(
                  text: 'Sign up with Google',
                  onPressed: _isLoading 
                      ? () {} 
                      : () {
                          _handleGoogleSignUp();
                        },
                  backgroundColor: FinderColors.primaryBlue,
                  height: 50,
                ),

                const SizedBox(height: 24),

                // Divider with "or"
                const CustomDivider(),

                const SizedBox(height: 24),

                // Full Name Field
                CustomTextField(
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Email Address Field
                CustomTextField(
                  label: 'Email Address',
                  hint: 'Enter your email address',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Password Field
                CustomTextField(
                  label: 'Password',
                  hint: 'Enter your password',
                  controller: _passwordController,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Confirm Password Field
                CustomTextField(
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  controller: _confirmPasswordController,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Sign Up Button
                CustomRoundedButton(
                  text: 'Sign Up',
                  onPressed: () {
                    _handleSignUp();
                  },
                  backgroundColor: FinderColors.primaryBlue,
                  height: 50,
                ),

                if (_isLoading) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(
                    color: FinderColors.primaryBlue,
                  ),
                ],

                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 24),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        fontSize: 13,
                        color: FinderColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Need Help Link
                GestureDetector(
                  onTap: () {
                    // Navigate to home or show help dialog
                    Navigator.pushNamed(context, '/home');
                  },
                  child: Text(
                    'Have you lost something? Need Help?',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.instance.signInWithGoogle();

      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      await SessionService.instance.saveSession();

      final email = user.email ?? '';
      final name = _buildSafeName(user.displayName, email);

      try {
        await _syncBackendUser(name: name, email: email);

        if (mounted) {
          await context.read<UserProvider>().loadUser();
        }
      } on Exception catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to register user in backend: ${e.toString()}';
        });
        return;
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.pushReplacementNamed(context, '/home');
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _mapAuthError(e);
      });
    }
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Create Firebase account
      await AuthService.instance.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );
      
      await SessionService.instance.saveSession();
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _mapAuthError(e);
      });
      return;
    }

    try {
      final user = AuthService.instance.currentUser;
      final email = user?.email ?? _emailController.text.trim();
      final name = _buildSafeName(user?.displayName, email);
      await _syncBackendUser(name: name, email: email);

      // Load the full backend user and store in app state (non-fatal).
      if (mounted) {
        await context.read<UserProvider>().loadUser();
      }
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to register user in backend: ${e.toString()}';
      });
      return;
    }

    try {
      // Step 2: Send verification email
      await AuthService.instance.sendEmailVerification();
    } on Exception catch (e) {
      // Account was created but email sending failed.
      // Still navigate — user can resend from the verification screen.
      debugPrint('[SignUpScreen] sendEmailVerification failed: $e');
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    Navigator.pushReplacementNamed(
      context,
      '/email-verification',
      arguments: {'email': _emailController.text.trim()},
    );
  }

  String _mapAuthError(Object error) {
    final raw = error.toString();
    if (raw.contains('email-already-in-use')) {
      return 'This email is already registered. Please log in instead.';
    } else if (raw.contains('invalid-email')) {
      return 'The email address is not valid.';
    } else if (raw.contains('weak-password')) {
      return 'Your password is too weak. Use at least 6 characters.';
    } else if (raw.contains('network-request-failed')) {
      return 'No internet connection. Please check your network.';
    } else if (raw.contains('operation-not-allowed')) {
      return 'Email/password sign-up is not enabled. Contact support.';
    }
    return raw.replaceAll('Exception: ', '').replaceAll('[firebase_auth/]', '').trim();
  }
}
