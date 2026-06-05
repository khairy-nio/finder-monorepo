import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_rounded_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_divider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/dynamic_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/session_service.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../providers/user_provider.dart';
import '../widgets/google_sign_in_button.dart';

/// Login Screen — clean, premium auth experience.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _buildSafeName(String? displayName, String email) {
    var name = (displayName ?? '').trim();
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
                    'Welcome back',
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
                    'Sign in to continue to Finder',
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl3),

                  // ── Google Sign In ───────────────────────────────────────
                  GoogleSignInButton(
                    isLoading: _isGoogleLoading,
                    onPressed: _handleGoogleSignIn,
                  ),

                  const SizedBox(height: AppSpacing.xl2),
                  const CustomDivider(),
                  const SizedBox(height: AppSpacing.xl2),

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
                    hint: '••••••••',
                    controller: _passwordController,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return 'Please enter your password';
                      if (v.length < 6)
                        return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(
                          context, '/forgot-password'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm),
                      ),
                      child: Text(
                        'Forgot password?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),

                  // ── Error ────────────────────────────────────────────────
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.errorMuted,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // ── Sign In Button ───────────────────────────────────────
                  CustomRoundedButton(
                    text: 'Sign In',
                    onPressed: _handleSignIn,
                    isLoading: _isLoading,
                    height: 54,
                  ),

                  const SizedBox(height: AppSpacing.xl2),

                  // ── Sign Up Link ─────────────────────────────────────────
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        children: [
                          const TextSpan(text: "Don't have an account? "),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                  context, '/signup'),
                              child: Text(
                                'Sign up free',
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

  Future<void> _handleGoogleSignIn() async {
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
        _navigateAfterAuth();
      }
    } on Exception catch (e) {
      if (mounted) setState(() => _errorMessage = _mapError(e));
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;
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

      if (mounted) {
        await context.read<UserProvider>().loadUser();
        _navigateAfterAuth();
      }
    } on Exception catch (e) {
      if (mounted) setState(() => _errorMessage = _mapError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateAfterAuth() {
    if (!mounted) return;
    final backendUser = context.read<UserProvider>().backendUser;
    if (backendUser != null &&
        (backendUser.status == 'suspended' ||
            backendUser.status == 'banned')) {
      Navigator.pushReplacementNamed(context, '/moderation-status',
          arguments: backendUser.status);
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  String _mapError(Object e) =>
      e.toString().replaceAll('Exception: ', '');
}

/// Google branded sign-in button.
