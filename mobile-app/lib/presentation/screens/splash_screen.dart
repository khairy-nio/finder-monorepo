import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/session_service.dart';
import '../providers/user_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    final isValidSession = await SessionService.instance.isSessionValid();
    final user = AuthService.instance.currentUser;

    if (isValidSession && user != null) {
      // Auto login successful - load backend data and go home
      if (mounted) {
        // Load the full backend user profile and store in app state.
        // We await it here so that the provider is populated before going to home.
        try {
          await context.read<UserProvider>().loadUser();
        } catch (e) {
          // Proceed to home even if backend user load fails, gracefully handle in app
        }
        if (mounted) {
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
      }
    } else {
      // Session expired or no user - clear session and sign out of Firebase
      await SessionService.instance.clearSession();
      await AuthService.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0A3D91),
        ),
      ),
    );
  }
}
