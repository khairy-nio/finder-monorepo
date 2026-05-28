import 'package:flutter/material.dart';
import '../../data/models/feed_post_model.dart';

/// Compact, security-focused card for the public home feed.
/// Shows NO images — uses category icon instead.
/// Tapping opens PostProtectedPreviewScreen.
class SecureFeedCard extends StatelessWidget {
  final FeedPost post;

  const SecureFeedCard({super.key, required this.post});

  static const Color _primary = Color(0xFF0A3D91);

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
    final badgeColor = isLost ? const Color(0xFFE53935) : const Color(0xFF2E7D32);
    final badgeLabel = isLost ? 'LOST' : 'FOUND';

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/post-protected-preview',
          arguments: {'post': post},
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ── Category Icon ────────────────────────────────────────────
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _categoryIcon(post.category),
                  color: _primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),

              // ── Text Content ─────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + Lost/Found badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            post.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Description (short)
                    if (post.description != null &&
                        post.description!.isNotEmpty)
                      Text(
                        post.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 6),

                    // Location + Time row
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            post.roughLocation,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.access_time_rounded,
                            size: 13, color: Colors.grey.shade400),
                        const SizedBox(width: 3),
                        Text(
                          post.timeAgo,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Protected notice + verified badge
                    Row(
                      children: [
                        Icon(Icons.lock_rounded,
                            size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          'Sensitive details hidden',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const Spacer(),
                        if (post.ownerVerified)
                          Row(
                            children: [
                              const Icon(Icons.verified_rounded,
                                  size: 13, color: Color(0xFF0A3D91)),
                              const SizedBox(width: 3),
                              Text(
                                'Verified',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Chevron ──────────────────────────────────────────────────
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey.shade300, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
