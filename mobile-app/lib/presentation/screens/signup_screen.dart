import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_rounded_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_divider.dart';
import '../../core/utils/app_messenger.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/dynamic_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/session_service.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../providers/user_provider.dart';
import '../widgets/google_sign_in_button.dart';

/// Sign Up / Register Screen
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey               = GlobalKey<FormState>();
  final _nameController        = TextEditingController();
  final _emailController       = TextEditingController();
  final _passwordController    = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isLoading       = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  String _buildSafeName(String? rawName, String email) {
    var name = (rawName ?? '').trim();
    if (name.isEmpty) name = email.split('@').first;
    name = name.replaceAll(RegExp(r'[^A-Za-z\s]'), ' ');
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (name.length < 2) return 'User';
    if (name.length > 100) return name.substring(0, 100).trim();
    return name;
  }

  Future<void> _syncBackendUser(
      {required String name, required String email}) async {
    final apiClient =
        ApiClient(tokenProvider: AuthService.instance.getIdToken);
    await apiClient.post(
      ApiConstants.loginEndpoint,
      body: {'name': name, 'email': email},
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.colors.neutral100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),

                  // ── Header ───────────────────────────────────────────────
                  Text(
                    'Create account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Join the community to report and recover items',
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl3),

                  // ── Google Sign Up ───────────────────────────────────────
                  GoogleSignInButton(
                    isLoading: _isGoogleLoading,
                    onPressed: _handleGoogleSignUp,
                  ),

                  const SizedBox(height: AppSpacing.xl2),
                  const CustomDivider(),
                  const SizedBox(height: AppSpacing.xl2),

                  // ── Full Name ────────────────────────────────────────────
                  CustomTextField(
                    label: 'Full name',
                    hint: 'Your name',
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Please enter your name';
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Email ────────────────────────────────────────────────
                  CustomTextField(
                    label: 'Email address',
                    hint: 'you@example.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.mail_outline_rounded),
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return 'Please enter your email';
                      if (!v.contains('@'))
                        return 'Enter a valid email address';
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Password ─────────────────────────────────────────────
                  CustomTextField(
                    label: 'Password',
                    hint: 'At least 6 characters',
                    controller: _passwordController,
                    isPassword: true,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return 'Please enter a password';
                      if (v.length < 6)
                        return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Confirm Password ─────────────────────────────────────
                  CustomTextField(
                    label: 'Confirm password',
                    hint: 'Re-enter your password',
                    controller: _confirmPassController,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return 'Please confirm your password';
                      if (v != _passwordController.text)
                        return 'Passwords do not match';
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Error ────────────────────────────────────────────────
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.errorMuted,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 16, color: AppColors.error),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // ── Create Account Button ────────────────────────────────
                  CustomRoundedButton(
                    text: 'Create Account',
                    onPressed: _handleSignUp,
                    isLoading: _isLoading,
                    height: 54,
                  ),

                  const SizedBox(height: AppSpacing.xl2),

                  // ── Login Link ───────────────────────────────────────────
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        children: [
                          const TextSpan(text: 'Already have an account? '),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/login'),
                              child: Text(
                                'Sign in',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await AuthService.instance.signInWithGoogle();
      if (user == null) return;

      await SessionService.instance.saveSession();
      final email = user.email ?? '';
      final name = _buildSafeName(user.displayName, email);
      await _syncBackendUser(name: name, email: email);

      if (mounted) {
        await context.read<UserProvider>().loadUser();
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _mapError(e));
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );
      await SessionService.instance.saveSession();
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _mapError(e);
        });
      }
      return;
    }

    try {
      final user = AuthService.instance.currentUser;
      final email = user?.email ?? _emailController.text.trim();
      final name = _buildSafeName(user?.displayName, email);
      await _syncBackendUser(name: name, email: email);
      if (mounted) await context.read<UserProvider>().loadUser();
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to register: ${_mapError(e)}';
        });
      }
      return;
    }

    try {
      await AuthService.instance.sendEmailVerification();
    } on Exception catch (e) {
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

  String _mapError(Object e) {
    final raw = e.toString();
    if (raw.contains('email-already-in-use'))
      return 'This email is already registered. Please sign in instead.';
    if (raw.contains('invalid-email'))
      return 'The email address is not valid.';
    if (raw.contains('weak-password'))
      return 'Your password is too weak. Use at least 6 characters.';
    if (raw.contains('network-request-failed'))
      return 'No internet connection. Please check your network.';
    if (raw.contains('operation-not-allowed'))
      return 'Sign-up is currently disabled. Contact support.';
    return raw.replaceAll('Exception: ', '').trim();
  }
}
