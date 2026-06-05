import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/session_service.dart';
import '../../core/utils/app_messenger.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/dynamic_colors.dart';
import '../providers/user_provider.dart';
import '../widgets/app_bottom_nav.dart';

/// Profile Screen — polished user hub.
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
    final backendUser  = context.watch<UserProvider>().backendUser;

    final displayName = backendUser?.name ??
        firebaseUser?.displayName ??
        'Unknown User';
    final email              = backendUser?.email ?? firebaseUser?.email ?? '';
    final trustScore         = backendUser?.trustScore;
    final verificationStatus = backendUser?.verificationStatus;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              size: 22,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: () =>
                Navigator.pushNamed(context, '/notifications'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Avatar + identity ────────────────────────────────────────
            _AvatarSection(
              backendUser: backendUser,
              firebaseUser: firebaseUser,
              displayName: displayName,
              email: email,
              trustScore: trustScore,
              verificationStatus: verificationStatus,
            ),

            const SizedBox(height: AppSpacing.xl2),

            // ── Trust score card ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl2),
              child: _TrustCard(
                trustScore: trustScore,
                verificationStatus: verificationStatus,
                backendUser: backendUser,
                isExpanded: _isBreakdownExpanded,
                onToggleExpand: () => setState(
                    () => _isBreakdownExpanded = !_isBreakdownExpanded),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Recovery rewards card ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl2),
              child: _RewardsCard(
                  points: backendUser?.recoveryPoints ?? 0,
                  onRedeem: () =>
                      Navigator.pushNamed(context, '/rewards-catalog')),
            ),

            const SizedBox(height: AppSpacing.xl2),

            // ── Account section ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl2),
              child: _AccountSection(
                backendUser: backendUser,
                verificationStatus: verificationStatus,
              ),
            ),

            const SizedBox(height: AppSpacing.xl2),

            // ── Danger zone ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl2),
              child: _buildLogoutButton(context),
            ),

            const SizedBox(height: AppSpacing.xl4),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: NavTab.profile,
        onTap: (i) {
          if (i == NavTab.profile) return;
          AppBottomNav.navigateToTab(context, i);
        },
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Sign out?'),
              content: const Text(
                  'You will need to sign in again to use Finder.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          );
          if (confirm != true || !context.mounted) return;

          await SessionService.instance.clearSession();
          context.read<UserProvider>().clear();
          await AuthService.instance.signOut();
          if (!context.mounted) return;
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (_) => false);
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
          minimumSize: Size.zero,
        ),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text(
          'Sign Out',
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ─── Avatar Section ───────────────────────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  final dynamic backendUser;
  final dynamic firebaseUser;
  final String displayName;
  final String email;
  final double? trustScore;
  final String? verificationStatus;

  const _AvatarSection({
    required this.backendUser,
    required this.firebaseUser,
    required this.displayName,
    required this.email,
    required this.trustScore,
    required this.verificationStatus,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = backendUser?.profileImageUrl ??
        backendUser?.selfieImageUrl ??
        firebaseUser?.photoURL;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl2, AppSpacing.xl2, AppSpacing.xl2, AppSpacing.xl2),
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outline, width: 3),
                ),
                child: ClipOval(child: _buildAvatarContent(avatarUrl, context)),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, '/edit-profile'),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        size: 14, color: AppColors.white),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Name
          Text(
            displayName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            email,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),

          // Verification badge
          if (verificationStatus != null) ...[
            const SizedBox(height: AppSpacing.md),
            _VerificationBadge(status: verificationStatus!),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatarContent(String? url, BuildContext context) {
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          Icons.person_rounded,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Theme.of(context).colorScheme.primary),
            ),
          );
        },
      );
    }
    return Icon(
        Icons.person_rounded, size: 48, color: Theme.of(context).colorScheme.primary);
  }
}

// ─── Trust Card ───────────────────────────────────────────────────────────────

class _TrustCard extends StatelessWidget {
  final double? trustScore;
  final String? verificationStatus;
  final dynamic backendUser;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const _TrustCard({
    required this.trustScore,
    required this.verificationStatus,
    required this.backendUser,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  Color _trustColor(double s, BuildContext context) {
    if (s <= 30) return AppColors.error;
    if (s <= 60) return AppColors.warning;
    if (s <= 80) return Theme.of(context).colorScheme.primary;
    if (s <= 95) return const Color(0xFF0D9488);
    return AppColors.goldDark;
  }

  String _trustLabel(double s) {
    if (s <= 30) return 'Low Trust';
    if (s <= 60) return 'Basic';
    if (s <= 80) return 'Trusted';
    if (s <= 95) return 'Highly Trusted';
    return 'Elite';
  }

  @override
  Widget build(BuildContext context) {
    final score = trustScore ?? 0.0;
    final color = _trustColor(score, context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Icon(Icons.verified_user_rounded,
                        size: 16, color: color),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Identity & Safety Score',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                            AppSpacing.radiusFull),
                      ),
                      child: Text(
                        _trustLabel(score),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Progress row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusFull),
                            child: LinearProgressIndicator(
                              value: score / 100.0,
                              minHeight: 8,
                              backgroundColor: context.colors.neutral200,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Safety level',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '${score.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Status row
                Row(
                  children: [
                    _InfoChip(
                      label: 'Standing',
                      value: (backendUser?.status ?? 'active').toUpperCase(),
                      valueColor:
                          (backendUser?.status ?? 'active') == 'active'
                              ? AppColors.success
                              : AppColors.error,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (verificationStatus != null)
                      _InfoChip(
                        label: 'Verification',
                        value: _verificationLabel(verificationStatus!),
                        valueColor:
                            _verificationColor(verificationStatus!),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Expand toggle
          GestureDetector(
            onTap: onToggleExpand,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: context.colors.neutral50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppSpacing.radiusLg),
                  bottomRight: Radius.circular(AppSpacing.radiusLg),
                ),
                border: Border(
                  top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'View score breakdown',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
              child: _BreakdownList(backendUser: backendUser),
            ),
        ],
      ),
    );
  }

  String _verificationLabel(String s) {
    switch (s) {
      case 'approved': return 'Verified';
      case 'pending':  return 'Pending';
      case 'rejected': return 'Rejected';
      default:         return 'Unverified';
    }
  }

  Color _verificationColor(String s) {
    switch (s) {
      case 'approved': return AppColors.success;
      case 'pending':  return AppColors.warning;
      case 'rejected': return AppColors.error;
      default:         return AppColors.textSecondary;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _InfoChip(
      {required this.label,
      required this.value,
      required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.colors.neutral50,
          borderRadius:
              BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownList extends StatelessWidget {
  final dynamic backendUser;

  const _BreakdownList({required this.backendUser});

  @override
  Widget build(BuildContext context) {
    final items = [
      _BreakdownItemData(
        'Identity Verified',
        backendUser?.verificationStatus == 'approved',
        '+45 pts',
      ),
      _BreakdownItemData(
        'Phone Verified',
        backendUser?.phoneNumber != null &&
            (backendUser!.phoneNumber as String).trim().isNotEmpty,
        '+10 pts',
      ),
      _BreakdownItemData(
        'Complete Address',
        backendUser?.country != null &&
            (backendUser!.country as String).trim().isNotEmpty,
        '+10 pts',
      ),
      _BreakdownItemData(
        'Profile Photo',
        backendUser?.profileImageUrl != null ||
            backendUser?.selfieImageUrl != null,
        '+5 pts',
      ),
      _BreakdownItemData(
        'Good Moderation Standing',
        backendUser?.status == 'active' &&
            (backendUser?.trustScore ?? 0.0) >= 40.0,
        '+5 pts',
      ),
      _BreakdownItemData(
        'Account Age (30+ days)',
        backendUser?.createdAt != null &&
            DateTime.now()
                .difference(backendUser!.createdAt)
                .inDays >= 30,
        '+5 pts',
      ),
    ];

    return Column(
      children: [
        const Divider(height: 24),
        ...items.map((item) => _BreakdownRow(item: item)),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.infoMuted,
            borderRadius:
                BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: const Text(
            'Complete verifications and maintain good standing to increase your score over time.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.info,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _BreakdownItemData {
  final String label;
  final bool isMet;
  final String pts;

  _BreakdownItemData(this.label, this.isMet, this.pts);
}

class _BreakdownRow extends StatelessWidget {
  final _BreakdownItemData item;

  const _BreakdownRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            item.isMet
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: item.isMet ? AppColors.success : AppColors.neutral300,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 13,
                color: item.isMet
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: item.isMet
                    ? FontWeight.w500
                    : FontWeight.w400,
              ),
            ),
          ),
          Text(
            item.pts,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: item.isMet
                  ? AppColors.success
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Rewards Card ─────────────────────────────────────────────────────────────

class _RewardsCard extends StatelessWidget {
  final int points;
  final VoidCallback onRedeem;

  const _RewardsCard({required this.points, required this.onRedeem});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded,
                  size: 18, color: AppColors.goldDark),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'Recovery Rewards',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldDark,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE68A),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                      color: const Color(0xFFFCD34D)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 12, color: AppColors.goldDark),
                    const SizedBox(width: 4),
                    Text(
                      '$points pts',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.goldDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Earn points by returning lost items and helping the community.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.goldDark,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onRedeem,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldDark,
                foregroundColor: AppColors.white,
                elevation: 0,
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm)),
              ),
              child: const Text(
                'Redeem Rewards',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Account Section ──────────────────────────────────────────────────────────

class _AccountSection extends StatelessWidget {
  final dynamic backendUser;
  final String? verificationStatus;

  const _AccountSection(
      {required this.backendUser, required this.verificationStatus});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACCOUNT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Column(
            children: [
              _MenuItem(
                icon: Icons.grid_view_rounded,
                label: 'My Posts',
                onTap: () =>
                    Navigator.pushNamed(context, '/my-posts'),
              ),
              if (verificationStatus != 'approved')
                _MenuItem(
                  icon: Icons.verified_user_outlined,
                  label: verificationStatus == 'pending'
                      ? 'Verification Pending'
                      : 'Verify Account',
                  badge: verificationStatus == 'pending'
                      ? 'Pending'
                      : 'Action needed',
                  badgeColor: verificationStatus == 'pending'
                      ? AppColors.warning
                      : Theme.of(context).colorScheme.primary,
                  onTap: () async {
                    if (verificationStatus == 'pending') {
                      AppMessenger.showInfo(
                          'Your verification request is still pending review.');
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
              _MenuItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () =>
                    Navigator.pushNamed(context, '/settings'),
              ),
              _MenuItem(
                icon: Icons.help_outline_rounded,
                label: 'Support',
                onTap: () =>
                    Navigator.pushNamed(context, '/support'),
              ),
              _MenuItem(
                icon: Icons.flag_outlined,
                label: 'Report a Problem',
                onTap: () =>
                    Navigator.pushNamed(context, '/report-problem'),
              ),
              _MenuItem(
                icon: Icons.shield_outlined,
                label: 'Privacy Policy',
                isLast: true,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/privacy-policy',
                  arguments: {'isFromOnboarding': false},
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;
  final bool isLast;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.badgeColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: isLast
              ? const BorderRadius.only(
                  bottomLeft: Radius.circular(AppSpacing.radiusLg),
                  bottomRight: Radius.circular(AppSpacing.radiusLg),
                )
              : BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.colors.neutral100,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(icon,
                      size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                if (badge != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? Theme.of(context).colorScheme.primary)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badgeColor ?? Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(
              height: 1,
              indent: AppSpacing.lg + 36 + AppSpacing.md,
              endIndent: 0),
      ],
    );
  }
}

// ─── Verification Badge ───────────────────────────────────────────────────────

class _VerificationBadge extends StatelessWidget {
  final String status;

  const _VerificationBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (status) {
      case 'approved':
        bg    = AppColors.successMuted;
        fg    = AppColors.success;
        icon  = Icons.verified_rounded;
        label = 'Identity Verified';
        break;
      case 'pending':
        bg    = AppColors.warningMuted;
        fg    = AppColors.warning;
        icon  = Icons.hourglass_top_rounded;
        label = 'Verification Pending';
        break;
      case 'rejected':
        bg    = AppColors.errorMuted;
        fg    = AppColors.error;
        icon  = Icons.cancel_outlined;
        label = 'Verification Rejected';
        break;
      default:
        bg    = context.colors.neutral100;
        fg    = Theme.of(context).colorScheme.onSurfaceVariant;
        icon  = Icons.shield_outlined;
        label = 'Unverified';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius:
            BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
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
}
