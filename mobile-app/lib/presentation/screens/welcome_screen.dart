import 'package:flutter/material.dart';
import '../widgets/custom_rounded_button.dart';
import '../../core/constants/finder_colors.dart';

/// Welcome/Starting Screen - First screen users see
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Logo
              Image.asset(
                'assets/images/logo.png',
                width: 200,
                height: 200,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if logo doesn't exist yet
                  return Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: FinderColors.primaryBlue.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.search, size: 80, color: FinderColors.primaryBlue),
                  );
                },
              ),

              const SizedBox(height: 24),

              // App Name
              const Text(
                'FINDER',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: FinderColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              // Tagline with checkmark
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'LOST? FOUND',
                    style: TextStyle(
                      fontSize: 16,
                      letterSpacing: 1.5,
                      color: FinderColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: FinderColors.primaryBlue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Center(
                      child: Icon(Icons.check, size: 12, color: Colors.white),
                    ),
                  ),
                  const Text(
                    '.',
                    style: TextStyle(
                      fontSize: 16,
                      letterSpacing: 1.5,
                      color: FinderColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 2),

              // Login Button - Dark Blue
              CustomRoundedButton(
                text: 'Login',
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                backgroundColor: FinderColors.primaryBlue,
              ),

              const SizedBox(height: 16),

              // Sign Up Button - Dark Blue
              CustomRoundedButton(
                text: 'sign up',
                onPressed: () {
                  Navigator.pushNamed(context, '/signup');
                },
                backgroundColor: FinderColors.primaryBlue,
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
