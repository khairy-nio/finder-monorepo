import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_client.dart';
import '../../core/services/auth_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/app_messenger.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../../core/theme/dynamic_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _checkingVerification = false;

  Future<void> _handleVerifyAccount() async {
    setState(() => _checkingVerification = true);
    try {
      final apiClient = ApiClient(tokenProvider: AuthService.instance.getIdToken);
      final response = await apiClient.get(ApiConstants.verificationStatusEndpoint);
      final status = (response['data']?['status'] as String?) ?? 'not_submitted';
      if (!mounted) return;
      setState(() => _checkingVerification = false);
      if (status == 'approved') {
        _showStatusDialog(
          icon: Icons.verified_rounded,
          iconColor: AppColors.success,
          title: 'Already Verified',
          body: 'Your account is verified. You have full access to all features.',
        );
      } else if (status == 'pending') {
        _showStatusDialog(
          icon: Icons.hourglass_top_rounded,
          iconColor: AppColors.warning,
          title: 'Under Review',
          body: 'Your verification documents are being reviewed. This usually takes 24–48 hours.',
        );
      } else {
        Navigator.pushNamed(context, '/privacy-policy', arguments: {'isFromOnboarding': true});
      }
    } catch (_) {
      setState(() => _checkingVerification = false);
      if (mounted) Navigator.pushNamed(context, '/privacy-policy', arguments: {'isFromOnboarding': true});
    }
  }

  void _showStatusDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.brLg),
        icon: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: AppSpacing.brMd,
          ),
          child: Icon(icon, color: iconColor, size: 26),
        ),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          body,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(minimumSize: const Size(120, 44)),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final firebaseUser = AuthService.instance.currentUser;
    final userName = userProvider.backendUser?.name ?? firebaseUser?.displayName ?? 'User';
    final userEmail = userProvider.backendUser?.email ?? firebaseUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.colors.neutral100,
              borderRadius: AppSpacing.brSm,
            ),
            child: Icon(Icons.arrow_back_rounded, size: 18, color: Theme.of(context).colorScheme.onSurface),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileCard(name: userName, email: userEmail),
            const SizedBox(height: AppSpacing.xl3),

            const _SectionLabel('Account'),
            const SizedBox(height: AppSpacing.md),
            _MenuItem(
              icon: Icons.person_outline_rounded,
              title: 'Edit Profile',
              subtitle: 'Update your personal information',
              onTap: () => Navigator.pushNamed(context, '/edit-profile'),
            ),
            const SizedBox(height: AppSpacing.sm),
            _MenuItem(
              icon: Icons.verified_user_outlined,
              title: 'Verify Account',
              subtitle: 'Unlock full access to all features',
              trailing: _checkingVerification
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Theme.of(context).colorScheme.primary))
                  : null,
              onTap: _checkingVerification ? null : _handleVerifyAccount,
            ),

            const SizedBox(height: AppSpacing.xl3),

            const _SectionLabel('Privacy'),
            const SizedBox(height: AppSpacing.md),
            _MenuItem(
              icon: Icons.lock_outline_rounded,
              title: 'Change Password',
              subtitle: 'Update your account password',
              onTap: () {
                if (AuthService.instance.isGoogleUser) {
                  AppMessenger.showInfo(
                      'Password change is not available for Google accounts');
                } else {
                  Navigator.pushNamed(context, '/change-password');
                }
              },
            ),

            const SizedBox(height: AppSpacing.xl3),

            const _SectionLabel('Notifications'),
            const SizedBox(height: AppSpacing.md),
            _NotificationToggle(
              value: _notificationsEnabled,
              onChanged: (v) => setState(() => _notificationsEnabled = v),
            ),

            const SizedBox(height: AppSpacing.xl3),

            // ── APPEARANCE ──────────────────────────────────────────────
            const _SectionLabel('Appearance'),
            const SizedBox(height: AppSpacing.md),
            _ThemeSelector(),

            const SizedBox(height: AppSpacing.xl3),

            const _SectionLabel('About'),
            const SizedBox(height: AppSpacing.md),
            const _MenuItem(
              icon: Icons.info_outline_rounded,
              title: 'About Finder',
              subtitle: 'App version 1.0.0',
              onTap: null,
            ),

            const SizedBox(height: AppSpacing.xl4),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String name;
  final String email;
  const _ProfileCard({required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: AppSpacing.brLg,
        boxShadow: AppShadows.md,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.white),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.white),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  style: TextStyle(
                      fontSize: 13, color: AppColors.white.withOpacity(0.75)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: AppSpacing.brMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.brMd,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppSpacing.brMd,
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: AppSpacing.brSm,
                ),
                child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                          fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(Icons.chevron_right_rounded,
                      size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: AppSpacing.brMd,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: AppSpacing.brSm,
            ),
            child: Icon(
                Icons.notifications_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Push Notifications',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  value ? 'Enabled' : 'Disabled',
                  style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.white,
            activeTrackColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final current = themeProvider.mode;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: AppSpacing.brMd,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        children: [
          _ThemeOption(
            icon: Icons.light_mode_rounded,
            label: 'Light',
            selected: current == ThemeMode.light,
            onTap: () => themeProvider.setMode(ThemeMode.light),
            isFirst: true,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _ThemeOption(
            icon: Icons.dark_mode_rounded,
            label: 'Dark',
            selected: current == ThemeMode.dark,
            onTap: () => themeProvider.setMode(ThemeMode.dark),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _ThemeOption(
            icon: Icons.brightness_auto_rounded,
            label: 'System default',
            selected: current == ThemeMode.system,
            onTap: () => themeProvider.setMode(ThemeMode.system),
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = AppSpacing.radiusMd;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? Radius.circular(radius) : Radius.zero,
          bottom: isLast ? Radius.circular(radius) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_rounded,
                    size: 18, color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
