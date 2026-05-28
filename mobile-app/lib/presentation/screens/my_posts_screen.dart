import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/app_messenger.dart';
import '../../data/datasources/post_remote_data_source.dart';
import '../../domain/entities/post.dart';

/// My Posts Screen
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

  late final PostRemoteDataSourceImpl _dataSource;
  String _searchQuery = '';
  final Set<String> _updatingPosts = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _dataSource = PostRemoteDataSourceImpl(
      apiClient: ApiClient(tokenProvider: AuthService.instance.getIdToken),
    );
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    _loadUserPosts();
  }

  String? _error;

  Future<void> _loadUserPosts() async {
    try {
      final posts = await _dataSource.getUserPosts('');
      if (mounted) {
        setState(() {
          // Enforce domain boundary: convert List<PostModel> to List<Post>
          _allUserPosts = List<Post>.from(posts);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load posts right now.';
          _allUserPosts = [];
          _isLoading = false;
        });
        AppMessenger.showError('Unable to load posts. Please try again.');
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleResolved(String postId, String currentStatus) async {
    if (_updatingPosts.contains(postId)) return;

    final isResolved = currentStatus == 'resolved' || currentStatus == 'closed';
    final newStatus = isResolved ? 'active' : 'resolved';
    final idx = _allUserPosts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final previousPost = _allUserPosts[idx];

    if (mounted) {
      setState(() {
        _updatingPosts.add(postId);
        final newList = List<Post>.from(_allUserPosts);
        newList[idx] = previousPost.copyWith(status: newStatus);
        _allUserPosts = newList;
      });
    }

    try {
      await _dataSource.updatePostStatus(postId, newStatus);
      AppMessenger.showSuccess(
        newStatus == 'resolved'
            ? 'Post marked as resolved'
            : 'Post restored to active',
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          final rollbackList = List<Post>.from(_allUserPosts);
          final rollbackIdx = rollbackList.indexWhere((p) => p.id == postId);
          if (rollbackIdx != -1) {
            rollbackList[rollbackIdx] = previousPost;
            _allUserPosts = rollbackList;
          }
        });
      }
      AppMessenger.showError('Could not update post status. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _updatingPosts.remove(postId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'My Shared Posts',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // balance the back button
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search my posts...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF0A3D91),
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Lost'),
                Tab(text: 'Found'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Posts List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildPostsList('lost'), _buildPostsList('found')],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create-post');
        },
        backgroundColor: const Color(0xFF0A3D91),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildPostsList(String type) {
    if (_isLoading)
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0A3D91)),
      );
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error: $_error',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final posts = _allUserPosts
        .where((p) => p.postType == type)
        .where(
          (p) =>
              _searchQuery.isEmpty ||
              p.title.toLowerCase().contains(_searchQuery),
        )
        .toList();
        
    final totalOtherPosts = _allUserPosts.where((p) => p.postType != type).length;
    
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No ${type == 'lost' ? 'lost' : 'found'} posts yet'
                  : 'No results for "$_searchQuery"',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            if (_searchQuery.isEmpty && totalOtherPosts > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '(You have $totalOtherPosts ${type == 'lost' ? 'found' : 'lost'} post(s) on the other tab)',
                  style: const TextStyle(color: Color(0xFF0A3D91), fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return _buildPostCardFromEntity(post);
      },
    );
  }

  Widget _buildPostCardFromEntity(Post post) {
    final bool isResolved =
        post.status == 'resolved' || post.status == 'closed';
    final bool isUpdating = _updatingPosts.contains(post.id);
    final bool isHidden = post.moderationStatus == 'hidden';
    final bool isRemoved = post.moderationStatus == 'removed';
    final bool isBlocked = isHidden || isRemoved;

    return Container(
      key: ValueKey('${post.id}_${post.status}_${post.moderationStatus}'),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isBlocked ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBlocked ? Colors.red[200]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        isBlocked ? Colors.grey : Colors.transparent,
                        BlendMode.saturation,
                      ),
                      child: Image.network(
                        post.imageUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  if (isBlocked)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.visibility_off_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isResolved
                                ? Colors.grey[300]
                                : const Color(0xFF0A3D91).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isResolved ? 'RESOLVED' : 'ACTIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isResolved
                                  ? Colors.grey[700]
                                  : const Color(0xFF0A3D91),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (isBlocked) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.red[100]!),
                            ),
                            child: Text(
                              isHidden ? 'HIDDEN' : 'REMOVED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.red[700],
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isBlocked ? Colors.grey[700] : Colors.black,
                        decoration: isRemoved ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (isBlocked)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          isHidden 
                            ? 'Hidden by moderator for review.'
                            : 'Removed by moderator for violation.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red[400],
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${post.city ?? ''}, ${post.country}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
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
          const SizedBox(height: 12),
          if (isBlocked)
             Container(
               width: double.infinity,
               padding: const EdgeInsets.symmetric(vertical: 10),
               decoration: BoxDecoration(
                 color: Colors.red[50]?.withOpacity(0.5),
                 borderRadius: BorderRadius.circular(8),
               ),
               child: Center(
                 child: Text(
                   'Moderation actions cannot be overridden.',
                   style: TextStyle(
                     color: Colors.red[700],
                     fontSize: 12,
                     fontWeight: FontWeight.bold,
                   ),
                 ),
               ),
             )
          else if (isResolved)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isUpdating ? null : () => _toggleResolved(post.id, post.status),
                    icon: isUpdating 
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.undo, size: 18),
                    label: const Text('Undo Resolved'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/create-post',
                      arguments: {'editPost': post},
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[400]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // ── Verification Questions Button ──────────────────────────
                Tooltip(
                  message: 'Set Verification Questions',
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/post-questions',
                        arguments: {
                          'postId': post.id,
                          'postTitle': post.title,
                        },
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0A3D91),
                      side: const BorderSide(color: Color(0xFF0A3D91)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    child: const Icon(Icons.quiz_rounded, size: 18),
                  ),
                ),
                const SizedBox(width: 8),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isUpdating ? null : () => _toggleResolved(post.id, post.status),
                    icon: isUpdating 
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Mark Resolved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A3D91),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),

        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Stack(
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
              _buildNavButton(Icons.grid_view, true, () {}),
              _buildNavButton(Icons.person, false, () {
                Navigator.pushReplacementNamed(context, '/profile');
              }),
            ],
          ),
        ),
      ],
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
}
