import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/feed_post_model.dart';

/// Secure feed card — no images, privacy-first, polished.
class SecureFeedCard extends StatelessWidget {
  final FeedPost post;

  const SecureFeedCard({super.key, required this.post});

  static IconData _categoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'phone':
        return Icons.smartphone_rounded;
      case 'keys':
        return Icons.key_rounded;
      case 'bag':
        return Icons.backpack_rounded;
      case 'electronics':
        return Icons.devices_rounded;
      case 'documents':
        return Icons.description_rounded;
      case 'jewelry':
        return Icons.diamond_rounded;
      case 'clothing':
        return Icons.checkroom_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLost = post.isLost;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/post-protected-preview',
        arguments: {'post': post},
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1),
          boxShadow: AppShadows.sm,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Category icon ──────────────────────────────────────────
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isLost
                      ? AppColors.lostBadgeBg
                      : AppColors.foundBadgeBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  _categoryIcon(post.category),
                  size: 22,
                  color: isLost ? AppColors.lostBadge : AppColors.foundBadge,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // ── Content ────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row + badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            post.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _TypeBadge(isLost: isLost),
                      ],
                    ),

                    // Description
                    if (post.description != null &&
                        post.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        post.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: AppSpacing.md),

                    // Meta row
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 12,
                          color: onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            post.roughLocation,
                            style: TextStyle(
                              fontSize: 12,
                              color: onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          post.timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Footer: lock notice + verified
                    Row(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 11,
                          color: onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Details protected',
                          style: TextStyle(
                            fontSize: 11,
                            color: onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const Spacer(),
                        if (post.ownerVerified) ...[
                          Icon(
                            Icons.verified_rounded,
                            size: 13,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Verified',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Chevron
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm, top: 2),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final bool isLost;

  const _TypeBadge({required this.isLost});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isLost ? AppColors.lostBadgeBg : AppColors.foundBadgeBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        isLost ? 'LOST' : 'FOUND',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: isLost ? AppColors.lostBadge : AppColors.foundBadge,
        ),
      ),
    );
  }
}
