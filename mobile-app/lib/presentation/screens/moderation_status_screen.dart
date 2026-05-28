import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/session_service.dart';
import '../providers/user_provider.dart';

class ModerationStatusScreen extends StatelessWidget {
  final String status; // 'suspended' or 'banned'

  const ModerationStatusScreen({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().backendUser;
    final isBanned = status == 'banned';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Modern Status Card
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: (isBanned ? Colors.red : Colors.orange).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isBanned ? Icons.block_rounded : Icons.info_outline_rounded,
                        color: isBanned ? Colors.red : Colors.orange,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Title
                    Text(
                      isBanned ? 'Account Banned' : 'Account Suspended',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Description
                    Text(
                      isBanned
                          ? 'Your account has been permanently banned from the platform due to a violation of our community guidelines.'
                          : 'Your account has been temporarily suspended. Please review our safety policies or contact support for more information.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    if (user?.verificationNotes != null && user!.verificationNotes!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MODERATOR NOTE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.verificationNotes!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              // Help Message
              Text(
                'Need help? Contact our safety team at',
                style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w600),
              ),
              const Text(
                'support@lostproject.com',
                style: TextStyle(
                  color: Color(0xFF0A3D91),
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.underline,
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _handleLogout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await SessionService.instance.clearSession();
    await AuthService.instance.signOut();
    if (context.mounted) {
      context.read<UserProvider>().clear();
      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
    }
  }
}
