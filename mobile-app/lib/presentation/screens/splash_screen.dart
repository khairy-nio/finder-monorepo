import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/session_service.dart';
import '../../core/theme/app_colors.dart';
import '../providers/user_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    _ctrl.forward();
    _checkSessionAndNavigate();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _checkSessionAndNavigate() async {
    debugPrint("=== SplashScreen: checking session... ===");
    // Brief branded moment
    await Future.delayed(const Duration(milliseconds: 1400));

    try {
      debugPrint("=== SplashScreen: calling isSessionValid... ===");
      final isValidSession = await SessionService.instance.isSessionValid();
      debugPrint("=== SplashScreen: isSessionValid returned: $isValidSession ===");
      final user = AuthService.instance.currentUser;
      debugPrint("=== SplashScreen: currentUser = $user ===");

      if (!mounted) {
        debugPrint("=== SplashScreen: Widget not mounted, aborting navigation ===");
        return;
      }

      if (isValidSession && user != null) {
        debugPrint("=== SplashScreen: Session is valid, loading backend user... ===");
        try {
          await context.read<UserProvider>().loadUser();
          debugPrint("=== SplashScreen: Backend user loaded successfully ===");
        } catch (e) {
          debugPrint("=== SplashScreen: Loading backend user failed: $e ===");
        }

        if (!mounted) return;
        final backendUser = context.read<UserProvider>().backendUser;
        debugPrint("=== SplashScreen: Backend user status = ${backendUser?.status} ===");
        if (backendUser != null &&
            (backendUser.status == 'suspended' || backendUser.status == 'banned')) {
          debugPrint("=== SplashScreen: Navigating to moderation status page ===");
          Navigator.pushReplacementNamed(
            context,
            '/moderation-status',
            arguments: backendUser.status,
          );
        } else {
          debugPrint("=== SplashScreen: Navigating to home page ===");
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        debugPrint("=== SplashScreen: Session invalid or no user, clearing and navigating to welcome ===");
        await SessionService.instance.clearSession();
        await AuthService.instance.signOut();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/welcome');
        }
      }
    } catch (e) {
      debugPrint("=== SplashScreen: Fatal session check error: $e ===");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo mark
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    size: 40,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 20),
                // App name
                const Text(
                  'FINDER',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Lost & Found — Reimagined',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                    color: AppColors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
