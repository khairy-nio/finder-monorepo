import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_rounded_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_divider.dart';
import '../../core/constants/finder_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/session_service.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../providers/user_provider.dart';

/// Login/Sign In Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _buildSafeName(String? displayName, String email) {
    var name = (displayName ?? '').trim();
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
          icon: const Icon(Icons.close, color: FinderColors.textSecondary),
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

                // Welcome Text
                const Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: FinderColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 16),

                // Login Mode Info Box
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
                    'Login Mode: sign in using any method\nassociated with your email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: FinderColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Login with Google Button
                CustomRoundedButton(
                  text: 'Login with Google',
                  onPressed: _isLoading 
                      ? () {} 
                      : () {
                          _handleGoogleSignIn();
                        },
                  backgroundColor: FinderColors.primaryBlue,
                  height: 50,
                ),

                const SizedBox(height: 24),

                // Divider with "or"
                const CustomDivider(),

                const SizedBox(height: 24),

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

                const SizedBox(height: 12),

                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/forgot-password');
                    },
                    child: const Text(
                      'Forget Password?',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Sign In Button
                CustomRoundedButton(
                  text: 'Sign In',
                  onPressed: () {
                    _handleSignIn();
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

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        fontSize: 13,
                        color: FinderColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: const Text(
                        'sign up',
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

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.instance.signInWithGoogle();
      
      // If user is null, they cancelled the login
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      await SessionService.instance.saveSession();

      final email = user.email ?? '';
      final name = _buildSafeName(user.displayName, email);

      await _syncBackendUser(name: name, email: email);

      if (mounted) {
        await context.read<UserProvider>().loadUser();
        final backendUser = context.read<UserProvider>().backendUser;
        
        if (backendUser != null && (backendUser.status == 'suspended' || backendUser.status == 'banned')) {
          Navigator.pushReplacementNamed(
            context, 
            '/moderation-status',
            arguments: backendUser.status,
          );
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on Exception catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _mapAuthError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await SessionService.instance.saveSession();

      final user = AuthService.instance.currentUser;
      final email = user?.email ?? _emailController.text.trim();
      final name = _buildSafeName(user?.displayName, email);

      await _syncBackendUser(name: name, email: email);

      // Load the full backend user profile and store in app state.
      // Non-fatal: if this fails the user still reaches home.
      if (mounted) {
        await context.read<UserProvider>().loadUser();
        final backendUser = context.read<UserProvider>().backendUser;

        if (backendUser != null && (backendUser.status == 'suspended' || backendUser.status == 'banned')) {
          Navigator.pushReplacementNamed(
            context,
            '/moderation-status',
            arguments: backendUser.status,
          );
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on Exception catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _mapAuthError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _mapAuthError(Object error) {
    return error.toString().replaceAll('Exception: ', '');
  }
}
