import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/session_service.dart';
import '../../core/utils/app_messenger.dart';
import '../providers/user_provider.dart';

/// Profile Screen
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isBreakdownExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = AuthService.instance.currentUser;
    final backendUser = context.watch<UserProvider>().backendUser;

    // Prefer backend name; fall back to Firebase displayName.
    final displayName =
        backendUser?.name ?? firebaseUser?.displayName ?? 'Unknown User';
    final email = backendUser?.email ?? firebaseUser?.email ?? '';
    final trustScore = backendUser?.trustScore;
    final verificationStatus = backendUser?.verificationStatus;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0A3D91),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48),
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/notifications');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),

              // Profile Avatar with Edit Button
              Stack(
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0A3D91).withOpacity(0.2),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _buildAvatar(backendUser, firebaseUser),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0A3D91),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // User Name
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 8),

              // Email
              Text(
                email,
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),

              // Trust score + verification status badges
              if (trustScore != null || verificationStatus != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    if (trustScore != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A3D91).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Color(0xFF0A3D91),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Trust ${trustScore.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0A3D91),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (verificationStatus != null)
                      _buildVerificationChip(verificationStatus),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // ==================== TRUST SECTION ====================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.verified_user_rounded, color: _getTrustColor(trustScore ?? 0.0), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'IDENTITY & SAFETY SCORE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.grey.shade800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Trust Gauge Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Safety Level',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _getTrustLabel(trustScore ?? 0.0).toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: _getTrustColor(trustScore ?? 0.0),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${(trustScore ?? 0.0).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: _getTrustColor(trustScore ?? 0.0),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: (trustScore ?? 0.0) / 100.0,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey.shade200,
                                    color: _getTrustColor(trustScore ?? 0.0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Status Detail Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verification',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              _buildVerificationChip(verificationStatus ?? 'not_submitted'),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Safety Standing',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    (backendUser?.status ?? 'active') == 'active'
                                        ? Icons.check_circle_rounded
                                        : Icons.warning_rounded,
                                    color: (backendUser?.status ?? 'active') == 'active'
                                        ? Colors.green
                                        : Colors.red,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    (backendUser?.status ?? 'active').toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: (backendUser?.status ?? 'active') == 'active'
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 24),
                      
                      // Expandable Trust Breakdown Header
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isBreakdownExpanded = !_isBreakdownExpanded;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'View Security Breakdown',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0A3D91),
                                  letterSpacing: 0.2,
                                ),
                              ),
                              Icon(
                                _isBreakdownExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: const Color(0xFF0A3D91),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (_isBreakdownExpanded) ...[
                        const SizedBox(height: 12),
                        // Breakdown list
                        _buildBreakdownItem(
                          label: 'Identity Verified',
                          isMet: backendUser?.verificationStatus == 'approved',
                          pts: '+45 Pts',
                        ),
                        _buildBreakdownItem(
                          label: 'Phone Verified',
                          isMet: backendUser?.phoneNumber != null &&
                              backendUser!.phoneNumber!.trim().isNotEmpty,
                          pts: '+10 Pts',
                        ),
                        _buildBreakdownItem(
                          label: 'Complete Address',
                          isMet: backendUser?.country != null &&
                              backendUser!.country!.trim().isNotEmpty &&
                              backendUser?.city != null &&
                              backendUser!.city!.trim().isNotEmpty &&
                              backendUser?.area != null &&
                              backendUser!.area!.trim().isNotEmpty,
                          pts: '+10 Pts',
                        ),
                        _buildBreakdownItem(
                          label: 'Profile Photo / Verified Selfie',
                          isMet: backendUser?.profileImageUrl != null ||
                              backendUser?.selfieImageUrl != null,
                          pts: '+5 Pts',
                        ),
                        _buildBreakdownItem(
                          label: 'Good Moderation Standing',
                          isMet: backendUser?.status == 'active' &&
                              (backendUser?.trustScore ?? 0.0) >= 40.0,
                          pts: '+5 Pts',
                        ),
                        _buildBreakdownItem(
                          label: 'Account Age & History',
                          isMet: (backendUser?.createdAt != null &&
                              DateTime.now().difference(backendUser!.createdAt).inDays >= 30),
                          pts: 'Up to +5 Pts',
                        ),
                        const Divider(height: 20),
                        // Advanced Factors Section
                        const Text(
                          'Advanced Security (Exceeding 70-80%):',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildBreakdownItem(
                          label: 'Successful Recovery History',
                          isMet: (backendUser?.trustScore ?? 0.0) >= 80.0 || (backendUser?.recoveryPoints ?? 0) > 0,
                          pts: 'Up to +15 Pts',
                        ),
                        _buildBreakdownItem(
                          label: 'Long-term Trust Standing (>90 days)',
                          isMet: (backendUser?.createdAt != null &&
                              DateTime.now().difference(backendUser!.createdAt).inDays > 90),
                          pts: '+5 Pts',
                        ),
                        _buildBreakdownItem(
                          label: 'Long-term Account Age (>150 days)',
                          isMet: (backendUser?.createdAt != null &&
                              DateTime.now().difference(backendUser!.createdAt).inDays > 150),
                          pts: 'Up to +5 Pts',
                        ),
                        const SizedBox(height: 12),
                        // Helper Explanation Box
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Text(
                            'Maintain a verified account, avoid moderation issues, and complete successful recoveries to increase trust over time.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ==================== RECOVERY SECTION ====================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade50, Colors.amber.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.emoji_events, color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'RECOVERY REWARDS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: Colors.orange, size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  '${backendUser?.recoveryPoints ?? 0} Pts',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Earn points by returning lost items, resolving claims, and assisting the community.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Redeem Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/rewards-catalog');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFA500), // Premium Orange
                            foregroundColor: Colors.white,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.shopping_bag_outlined),
                          label: const Text(
                            'Redeem Community Rewards',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ==================== SETTINGS / ACTIONS ====================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACCOUNT SETTINGS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // My Posts
                    _buildMenuItem(
                      icon: Icons.grid_view,
                      iconColor: const Color(0xFF0A3D91),
                      title: 'My Posts',
                      onTap: () {
                        Navigator.pushNamed(context, '/my-posts');
                      },
                    ),

                    const SizedBox(height: 12),

                    // Verify Account (KYC)
                    if (verificationStatus != 'approved') ...[
                      _buildMenuItem(
                        icon: Icons.verified_user_outlined,
                        iconColor: const Color(0xFF0A3D91),
                        title: verificationStatus == 'pending' ? 'Verification Pending' : 'Verify Account',
                        onTap: () async {
                          if (verificationStatus == 'pending') {
                            AppMessenger.showInfo('Your verification request is still pending review.');
                            return;
                          }
                          await Navigator.pushNamed(
                            context,
                            '/privacy-policy',
                            arguments: {'isFromOnboarding': true},
                          );
                          if (context.mounted) {
                            await context.read<UserProvider>().loadUser();
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Settings
                    _buildMenuItem(
                      icon: Icons.settings_outlined,
                      iconColor: const Color(0xFF0A3D91),
                      title: 'Settings',
                      onTap: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),

                    const SizedBox(height: 12),

                    // Support
                    _buildMenuItem(
                      icon: Icons.help_outline,
                      iconColor: const Color(0xFF0A3D91),
                      title: 'Support',
                      onTap: () {
                        Navigator.pushNamed(context, '/support');
                      },
                    ),

                    const SizedBox(height: 12),

                    // Report a Problem
                    _buildMenuItem(
                      icon: Icons.report_problem_outlined,
                      iconColor: const Color(0xFF0A3D91),
                      title: 'Report a problem',
                      onTap: () {
                        Navigator.pushNamed(context, '/report-problem');
                      },
                    ),

                    const SizedBox(height: 12),

                    // Privacy Policy
                    _buildMenuItem(
                      icon: Icons.shield_outlined,
                      iconColor: const Color(0xFF0A3D91),
                      title: 'Privacy Policy',
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/privacy-policy',
                          arguments: {'isFromOnboarding': false},
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // Log Out Button
                    Center(
                      child: TextButton.icon(
                        onPressed: () async {
                          // Clear session
                          await SessionService.instance.clearSession();
                          // Clear backend user state
                          context.read<UserProvider>().clear();
                          // Sign out from Firebase
                          await AuthService.instance.signOut();
                          if (!context.mounted) return;
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                        },
                        icon: const Icon(
                          Icons.logout,
                          color: Colors.red,
                          size: 20,
                        ),
                        label: const Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),


                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Stack(
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Container(
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A3D91),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavButton(Icons.home, false, () {
                  Navigator.pushReplacementNamed(context, '/home');
                }),
                _buildNavButton(Icons.chat_bubble_outline_sharp, false, () {
                  Navigator.pushNamed(context, '/messages');
                }),
                _buildNavButton(Icons.file_upload_outlined, false, () {
                  Navigator.pushNamed(context, '/create-post');
                }),
                _buildNavButton(Icons.person, true, () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(backendUser, firebaseUser) {
    final avatarUrl = backendUser?.profileImageUrl ?? 
                      backendUser?.selfieImageUrl ?? 
                      firebaseUser?.photoURL;

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(65),
        child: Image.network(
          avatarUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.person,
            size: 60,
            color: Color(0xFF0A3D91),
          ),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: const Color(0xFF0A3D91),
              ),
            );
          },
        ),
      );
    }

    return const Icon(
      Icons.person,
      size: 60,
      color: Color(0xFF0A3D91),
    );
  }

  Widget _buildVerificationChip(String status) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (status) {
      case 'approved':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        icon = Icons.verified;
        label = 'Verified';
        break;
      case 'pending':
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade800;
        icon = Icons.hourglass_top;
        label = 'Pending';
        break;
      case 'rejected':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        icon = Icons.cancel_outlined;
        label = 'Rejected';
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade600;
        icon = Icons.shield_outlined;
        label = 'Unverified';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0A3D91) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.grey[600],
          size: 38,
        ),
      ),
    );
  }

  String _getTrustLabel(double score) {
    if (score <= 30) return 'Low Trust';
    if (score <= 60) return 'Basic Verified';
    if (score <= 80) return 'Trusted User';
    if (score <= 95) return 'Highly Trusted';
    return 'Elite Trusted';
  }

  Color _getTrustColor(double score) {
    if (score <= 30) return Colors.red.shade700;
    if (score <= 60) return Colors.orange.shade700;
    if (score <= 80) return const Color(0xFF0A3D91);
    if (score <= 95) return Colors.teal.shade700;
    return const Color(0xFFD4AF37); // Gold
  }

  Widget _buildBreakdownItem({
    required String label,
    required bool isMet,
    required String pts,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isMet ? Colors.green.shade600 : Colors.grey.shade400,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isMet ? Colors.black87 : Colors.black54,
                fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            pts,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isMet ? Colors.green.shade700 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
