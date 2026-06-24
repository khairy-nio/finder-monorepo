import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/dynamic_colors.dart';
import '../../core/utils/app_messenger.dart';
import '../../data/datasources/post_remote_data_source.dart';
import '../../domain/entities/post.dart';
import '../widgets/app_bottom_nav.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<Post> _allUserPosts = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  final Set<String> _updatingPosts = {};
  late final PostRemoteDataSourceImpl _dataSource;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _dataSource = PostRemoteDataSourceImpl(
      apiClient: ApiClient(tokenProvider: AuthService.instance.getIdToken),
    );
    _searchController.addListener(
        () => setState(() => _searchQuery = _searchController.text.toLowerCase()));
    _loadUserPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPosts() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final posts = await _dataSource.getUserPosts('');
      if (mounted) setState(() { _allUserPosts = List<Post>.from(posts); _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() { _error = 'Unable to load posts right now.'; _isLoading = false; });
        AppMessenger.showError('Unable to load posts. Please try again.');
      }
    }
  }

  Future<void> _toggleResolved(String postId, String currentStatus) async {
    if (_updatingPosts.contains(postId)) return;
    final isResolved = currentStatus == 'resolved' || currentStatus == 'closed';
    final newStatus = isResolved ? 'active' : 'resolved';
    final idx = _allUserPosts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final previousPost = _allUserPosts[idx];

    setState(() {
      _updatingPosts.add(postId);
      final newList = List<Post>.from(_allUserPosts);
      newList[idx] = previousPost.copyWith(status: newStatus);
      _allUserPosts = newList;
    });

    try {
      await _dataSource.updatePostStatus(postId, newStatus);
      AppMessenger.showSuccess(
          newStatus == 'resolved' ? 'Post marked as resolved' : 'Post restored to active');
    } catch (e) {
      if (mounted) {
        setState(() {
          final rb = List<Post>.from(_allUserPosts);
          final ri = rb.indexWhere((p) => p.id == postId);
          if (ri != -1) { rb[ri] = previousPost; _allUserPosts = rb; }
        });
      }
      AppMessenger.showError('Could not update post status. Please try again.');
    } finally {
      if (mounted) setState(() => _updatingPosts.remove(postId));
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'My Posts',
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, size: 22, color: Theme.of(context).colorScheme.primary),
            onPressed: () => Navigator.pushNamed(context, '/create-post'),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl2, 0, AppSpacing.xl2, AppSpacing.sm),
            child: Container(
              decoration: BoxDecoration(
                color: context.colors.neutral100,
                borderRadius: AppSpacing.brMd,
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: AppSpacing.brMd,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.white,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                labelStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
                dividerColor: Colors.transparent,
                tabs: const [Tab(text: 'Lost'), Tab(text: 'Found')],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl2, AppSpacing.md, AppSpacing.xl2, AppSpacing.xs),
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search my posts…',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                prefixIcon: Icon(Icons.search_rounded,
                    size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.brMd,
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppSpacing.brMd,
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppSpacing.brMd,
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                ),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: 12),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                : _error != null
                    ? _ErrorState(message: _error!, onRetry: _loadUserPosts)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _PostsList(
                            posts: _allUserPosts,
                            type: 'lost',
                            searchQuery: _searchQuery,
                            updatingPosts: _updatingPosts,
                            onToggleResolved: _toggleResolved,
                          ),
                          _PostsList(
                            posts: _allUserPosts,
                            type: 'found',
                            searchQuery: _searchQuery,
                            updatingPosts: _updatingPosts,
                            onToggleResolved: _toggleResolved,
                          ),
                        ],
                      ),
          ),
        ],
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
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _PostsList extends StatelessWidget {
  final List<Post> posts;
  final String type;
  final String searchQuery;
  final Set<String> updatingPosts;
  final Future<void> Function(String, String) onToggleResolved;

  const _PostsList({
    required this.posts,
    required this.type,
    required this.searchQuery,
    required this.updatingPosts,
    required this.onToggleResolved,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = posts
        .where((p) => p.postType == type)
        .where((p) =>
            searchQuery.isEmpty ||
            p.title.toLowerCase().contains(searchQuery))
        .toList();

    if (filtered.isEmpty) {
      return _EmptyState(type: type, isSearching: searchQuery.isNotEmpty);
    }

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl2, AppSpacing.md, AppSpacing.xl2, AppSpacing.xl4),
        itemCount: filtered.length,
        itemBuilder: (context, i) => _PostCard(
          post: filtered[i],
          isUpdating: updatingPosts.contains(filtered[i].id),
          onToggleResolved: onToggleResolved,
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Post post;
  final bool isUpdating;
  final Future<void> Function(String, String) onToggleResolved;

  const _PostCard({
    required this.post,
    required this.isUpdating,
    required this.onToggleResolved,
  });

  @override
  Widget build(BuildContext context) {
    final isResolved = post.status == 'resolved' || post.status == 'closed';
    final isHidden = post.moderationStatus == 'hidden';
    final isRemoved = post.moderationStatus == 'removed';
    final isBlocked = isHidden || isRemoved;

    return Container(
      key: ValueKey('${post.id}_${post.status}_${post.moderationStatus}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isBlocked ? context.colors.neutral50 : Theme.of(context).colorScheme.surface,
        borderRadius: AppSpacing.brLg,
        border: Border.all(
          color: isBlocked ? AppColors.error.withOpacity(0.2) : Theme.of(context).colorScheme.outline,
        ),
        boxShadow: AppShadows.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: AppSpacing.brMd,
                  child: isBlocked 
                    ? ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          Colors.grey,
                          BlendMode.saturation,
                        ),
                        child: Image.network(
                          post.imageUrl,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 72,
                            height: 72,
                            color: context.colors.neutral100,
                            child: Icon(Icons.image_outlined,
                                color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                      )
                    : Image.network(
                        post.imageUrl,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 72,
                          height: 72,
                          color: context.colors.neutral100,
                          child: Icon(Icons.image_outlined,
                              color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                ),

                const SizedBox(width: AppSpacing.md),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status badges row
                      Row(
                        children: [
                          _StatusBadge(
                            label: isResolved ? 'Resolved' : 'Active',
                            color: isResolved
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : AppColors.success,
                            bgColor: isResolved
                                ? context.colors.neutral100
                                : context.colors.successMuted,
                          ),
                          if (isBlocked) ...[
                            const SizedBox(width: AppSpacing.xs),
                            _StatusBadge(
                              label: isHidden ? 'Hidden' : 'Removed',
                              color: AppColors.error,
                              bgColor: AppColors.errorMuted,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        post.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isBlocked
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Theme.of(context).colorScheme.onSurface,
                          decoration: isRemoved ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isBlocked) ...[
                        const SizedBox(height: 2),
                        Text(
                          isHidden
                              ? 'Hidden by moderator for review.'
                              : 'Removed for policy violation.',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.error.withOpacity(0.8),
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              '${post.city ?? ''}, ${post.country}',
                              style: TextStyle(
                                  fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Action row
            if (isBlocked)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.errorMuted,
                  borderRadius: AppSpacing.brSm,
                ),
                child: const Text(
                  'Moderation actions cannot be overridden.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                      fontWeight: FontWeight.w600),
                ),
              )
            else if (isResolved)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      isUpdating ? null : () => onToggleResolved(post.id, post.status),
                  icon: isUpdating
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Theme.of(context).colorScheme.onSurfaceVariant))
                      : const Icon(Icons.undo_rounded, size: 16),
                  label: const Text('Undo Resolved'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    side: BorderSide(color: Theme.of(context).colorScheme.outline),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.brSm),
                  ),
                ),
              )
            else
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/create-post',
                      arguments: {'editPost': post},
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                      side: BorderSide(color: Theme.of(context).colorScheme.outline),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: 10),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.brSm),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Tooltip(
                    message: 'Verification Questions',
                    child: OutlinedButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/post-questions',
                        arguments: {'postId': post.id, 'postTitle': post.title},
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(color: Theme.of(context).colorScheme.primary),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: 10),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                            borderRadius: AppSpacing.brSm),
                      ),
                      child: const Icon(Icons.quiz_rounded, size: 16),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isUpdating
                          ? null
                          : () => onToggleResolved(post.id, post.status),
                      icon: isUpdating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.white))
                          : const Icon(Icons.check_circle_outline_rounded,
                              size: 16),
                      label: const Text('Resolved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                            borderRadius: AppSpacing.brSm),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _StatusBadge(
      {required this.label, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.6),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String type;
  final bool isSearching;

  const _EmptyState({required this.type, required this.isSearching});

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
                color: context.colors.neutral100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: Icon(Icons.inbox_outlined,
                  size: 32, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              isSearching
                  ? 'No results found'
                  : 'No ${type == 'lost' ? 'lost' : 'found'} posts yet',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isSearching
                  ? 'Try a different search term.'
                  : 'Posts you share will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5),
            ),
          ],
        ),
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
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Icon(Icons.wifi_off_rounded,
                  size: 30, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Could not load posts',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl2),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(140, 46)),
            ),
          ],
        ),
      ),
    );
  }
}
