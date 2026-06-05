import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../widgets/secure_feed_card.dart';
import '../widgets/app_bottom_nav.dart';
import '../providers/post_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/user_provider.dart';
import '../../data/models/feed_post_model.dart';
import '../../data/datasources/post_remote_data_source.dart';
import '../../core/network/api_client.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/dynamic_colors.dart';
import 'filter_screen.dart';

/// Home Screen — community incident board.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<FeedPost> _feedPosts = [];
  bool _isLoading = true;
  String? _error;
  late PostRemoteDataSourceImpl _ds;

  @override
  void initState() {
    super.initState();
    _ds = PostRemoteDataSourceImpl(
        apiClient:
            ApiClient(tokenProvider: AuthService.instance.getIdToken));
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final postProvider =
          Provider.of<PostProvider>(context, listen: false);
      final saved = postProvider.activeFilters;
      final category =
          saved?['category'] == 'All' ? null : saved?['category'];
      final country = saved?['country']?.trim();
      final city    = saved?['city']?.trim();

      final posts = await _ds.getPublicFeed(
        category: category,
        country: country,
        city: city,
        limit: 50,
        offset: 0,
      );
      if (mounted) setState(() { _feedPosts = posts; _isLoading = false; });
    } catch (_) {
      if (mounted)
        setState(() {
          _error = 'Unable to load the feed right now.';
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = context.watch<PostProvider>();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildSliverAppBar(context, postProvider, innerBoxIsScrolled),
          ],
          body: _buildBody(),
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: NavTab.home,
          onTap: (i) {
            if (i == NavTab.home) return;
            AppBottomNav.navigateToTab(context, i);
          },
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(
      BuildContext context,
      PostProvider postProvider,
      bool innerBoxIsScrolled) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 72,
      title: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
        child: Row(
          children: [
            // ── App Logo / Brand ──────────────────────────────────────
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/search'),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Finder',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const Spacer(),

            // ── Points Badge ──────────────────────────────────────────
            Consumer<UserProvider>(
              builder: (context, up, _) {
                final pts = up.backendUser?.recoveryPoints ?? 0;
                return GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, '/rewards-catalog'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.goldMuted,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 13, color: AppColors.goldDark),
                        const SizedBox(width: 4),
                        Text(
                          '$pts pts',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.goldDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(width: AppSpacing.sm),

            // ── Notifications ─────────────────────────────────────────
            _NotifButton(),

            const SizedBox(width: 4),

            // ── Filter ────────────────────────────────────────────────
            _FilterButton(
              hasActiveFilters: postProvider.hasActiveFilters,
              onTap: () async {
                await Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (c, a, b) => const FilterScreen(),
                    transitionsBuilder: (c, a, b, child) {
                      return FadeTransition(opacity: a, child: child);
                    },
                    transitionDuration:
                        const Duration(milliseconds: 220),
                  ),
                );
                _loadFeed();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const _LoadingState();
    if (_error != null) return _ErrorState(message: _error!, onRetry: _loadFeed);
    if (_feedPosts.isEmpty) return const _EmptyState();

    return RefreshIndicator(
      onRefresh: _loadFeed,
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: CustomScrollView(
        slivers: [
          // Section header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl2, AppSpacing.lg, AppSpacing.xl2, AppSpacing.xs),
              child: _SectionHeader(),
            ),
          ),

          // Feed list
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl2, AppSpacing.md, AppSpacing.xl2, AppSpacing.xl4),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => SecureFeedCard(post: _feedPosts[i]),
                childCount: _feedPosts.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Community Feed',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Active incidents · Details are protected',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _NotifButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            size: 22,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onPressed: () =>
              Navigator.pushNamed(context, '/notifications'),
          padding: const EdgeInsets.all(AppSpacing.sm),
          constraints: const BoxConstraints(),
        ),
        Consumer<NotificationProvider>(
          builder: (ctx, np, _) {
            if (np.unreadCount == 0) return const SizedBox.shrink();
            return Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Theme.of(ctx).scaffoldBackgroundColor, width: 1.5),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  final bool hasActiveFilters;
  final VoidCallback onTap;

  const _FilterButton(
      {required this.hasActiveFilters, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: hasActiveFilters
              ? Theme.of(context).colorScheme.primaryContainer
              : context.colors.neutral100,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: hasActiveFilters
              ? Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3))
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 18,
              color: hasActiveFilters
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            if (hasActiveFilters)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Theme.of(context).colorScheme.primaryContainer, width: 1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl2, AppSpacing.lg, AppSpacing.xl2, 0),
      itemCount: 5,
      itemBuilder: (_, __) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.colors.neutral100,
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.colors.neutral100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 180,
                  decoration: BoxDecoration(
                    color: context.colors.neutral100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 10,
                  width: 120,
                  decoration: BoxDecoration(
                    color: context.colors.neutral100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.colors.neutral100,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 30,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Connection error',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl2),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(140, 46),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: Icon(
                Icons.search_rounded,
                size: 34,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No incidents found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'There are no active reports matching\nyour current filters.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
