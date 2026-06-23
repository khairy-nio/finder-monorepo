import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:share_plus/share_plus.dart';
import '../../core/network/api_client.dart';
import '../../core/services/auth_service.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../../data/datasources/post_remote_data_source.dart';
import '../../data/models/post_model.dart';
import '../../core/utils/app_messenger.dart';
import '../../core/errors/exceptions.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> postData;

  const PostDetailScreen({super.key, required this.postData});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  PostModel? _livePost;
  bool _isLoading = false;
  String _requestStatus = 'none'; // 'none', 'pending', 'accepted', 'rejected'

  @override
  void initState() {
    super.initState();
    _fetchLivePost();
  }

  Future<void> _fetchLivePost() async {
    final postId = widget.postData['postId'];
    debugPrint('PostDetailScreen: Fetching live post for ID: $postId');
    if (postId == null || postId.toString().isEmpty) {
      debugPrint('PostDetailScreen Error: postId is missing in widget.postData!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiClient = ApiClient(tokenProvider: AuthService.instance.getIdToken);
      final ds = PostRemoteDataSourceImpl(apiClient: apiClient);
      final post = await ds.getPostById(postId);
      
      final chatDs = ChatRemoteDataSourceImpl(apiClient: apiClient);
      final requestStatusData = await chatDs.checkRequestStatus(postId);
      
      if (mounted) {
        setState(() {
          _livePost = post;
          _isLoading = false;
          if (requestStatusData.isNotEmpty) {
            _requestStatus = requestStatusData['status'] ?? 'none';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Merge live data with fallback arguments
    final String title = _livePost?.title ?? widget.postData['title'] ?? 'Unknown Item';
    final String category = _livePost?.category ?? widget.postData['category'] ?? 'Other';
    
    // Time formatter helper
    String timeAgo = widget.postData['timeAgo'] ?? 'Recently';
    if (_livePost?.createdAt != null) {
      final diff = DateTime.now().difference(_livePost!.createdAt);
      if (diff.inDays > 0) timeAgo = '${diff.inDays} days ago';
      else if (diff.inHours > 0) timeAgo = '${diff.inHours} hours ago';
      else if (diff.inMinutes > 0) timeAgo = '${diff.inMinutes} mins ago';
      else timeAgo = 'Just now';
    }

    final String posterName = _livePost?.ownerName ?? widget.postData['posterName'] ?? 'Unknown User';
    final bool isVerified = widget.postData['isVerified'] ?? false; // Fallback if backend doesn't provide owner verified status easily
    
    String dateLost = widget.postData['dateLost'] ?? 'Unknown';
    if (_livePost?.createdAt != null) {
      final dt = _livePost!.createdAt.toLocal();
      dateLost = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }

    String refId = _livePost?.id ?? widget.postData['refId'] ?? 'N/A';
    if (refId.length > 8 && !refId.startsWith('#')) {
      refId = '#${refId.substring(0, 8).toUpperCase()}';
    } else if (!refId.startsWith('#')) {
      refId = '#$refId';
    }

    final String description = _livePost?.description ?? widget.postData['description'] ?? 'No description available';
    final String location = _livePost?.location ?? widget.postData['location'] ?? 'Location Unknown';
    final String distance = widget.postData['distance'] ?? '';
    
    // Fix: Fallback to widget.postData if _livePost.imageUrl is empty (e.g. from protected DTO)
    final String imageUrl = (_livePost?.imageUrl != null && _livePost!.imageUrl.isNotEmpty)
        ? _livePost!.imageUrl
        : (widget.postData['imageUrl'] ?? '');
        
    final String status = _livePost?.status ?? widget.postData['status'] ?? 'Lost';
    final int matchPercentage = widget.postData['matchPercentage'] ?? 0;
    final double? latitude = _livePost?.latitude ?? widget.postData['latitude'];
    final double? longitude = _livePost?.longitude ?? widget.postData['longitude'];
    final String userId = _livePost?.userId ?? widget.postData['userId'] ?? '';
    final String currentPostId = _livePost?.id ?? widget.postData['postId'] ?? '';
    
    // Debug logging for ID sources
    if (currentPostId.isEmpty) {
      debugPrint('PostDetailScreen Warning: currentPostId is empty in build()');
      debugPrint('widget.postData keys: ${widget.postData.keys.toList()}');
    }

    final String currentUserId = AuthService.instance.currentUser?.uid ?? '';
    final bool isOwner = userId == currentUserId;
    final bool shouldBlur = !isOwner;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF0A3D91),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              if (matchPercentage > 0)
                Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'AI Match $matchPercentage%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: status.toLowerCase() == 'lost'
                      ? const Color(0xFFE53935)
                      : const Color(0xFF43A047),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: imageUrl.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        shouldBlur
                            ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  ImageFiltered(
                                    imageFilter: ImageFilter.blur(
                                        sigmaX: 10.0, sigmaY: 10.0),
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),
                                  Container(
                                    color: Colors.black.withOpacity(0.2),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.visibility_off,
                                          color: Colors.white, size: 48),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Protected Content',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          'Request contact to unlock full photo',
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image,
                                      size: 100,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image,
                        size: 100,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Category and Time
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A3D91).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0A3D91),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeAgo,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // User Info
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A3D91).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 28,
                                color: Color(0xFF0A3D91),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            posterName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          if (isVerified) ...[
                                            const SizedBox(width: 6),
                                            const Icon(
                                              Icons.verified,
                                              size: 18,
                                              color: Color(0xFF0A3D91),
                                            ),
                                          ],
                                        ],
                                      ),
                                      TextButton.icon(
                                        onPressed: () {
                                          if (userId.isEmpty) {
                                            AppMessenger.showError('User ID not found');
                                            return;
                                          }
                                          Navigator.pushNamed(
                                            context,
                                            '/report-problem',
                                            arguments: {
                                              'reportedUserId': userId,
                                              'reportedUserName': posterName,
                                            },
                                          );
                                        },
                                        icon: const Icon(Icons.report_outlined,
                                            size: 16, color: Colors.red),
                                        label: const Text(
                                          'Report',
                                          style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Verified User',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Date Lost and Ref ID
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'DATE LOST',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[600],
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      dateLost,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.fingerprint,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'REF ID',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[600],
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      refId,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Description
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Last Seen Location
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Last Seen Location',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            if (distance.isNotEmpty)
                              Text(
                                distance,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0A3D91),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0A3D91).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.location_on, color: Color(0xFF0A3D91)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Location',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      location,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Message Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF0A3D91)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Color(0xFF0A3D91)),
                  onPressed: () {
                    Share.share('Check this $status item: $title in $location — found on LostFinder app');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (userId.isEmpty) {
                      AppMessenger.showError('Cannot interact with this user.');
                      return;
                    }

                    if (_requestStatus == 'pending') {
                      AppMessenger.showError('Your contact request is still pending.');
                      return;
                    }

                    if (_requestStatus == 'accepted') {
                      // Show loading
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );

                      try {
                        final apiClient = ApiClient(tokenProvider: AuthService.instance.getIdToken);
                        final ds = ChatRemoteDataSourceImpl(apiClient: apiClient);
                        // Do not create chat, just get the existing one since they accepted
                        final chatId = await ds.getChatWithUser(userId);

                        if (!context.mounted) return;
                        Navigator.pop(context); // close dialog

                        if (chatId != null) {
                          Navigator.pushNamed(context, '/chat', arguments: {
                            'chatId': chatId,
                            'userName': posterName,
                            'userId': userId,
                            'isOnline': false,
                          });
                        } else {
                          AppMessenger.showError('Chat not found even though request was accepted.');
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        AppMessenger.showError('Failed to open chat. Please try again.');
                      }
                      return;
                    }

                    // For 'none' or 'rejected'
                    final introController = TextEditingController();
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Request Contact'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Send a request to the owner to start messaging.'),
                            const SizedBox(height: 16),
                            TextField(
                              controller: introController,
                              maxLength: 255,
                              decoration: const InputDecoration(
                                hintText: 'Add an optional intro message...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(dialogContext); // Close intro dialog

                              // Show loading spinner
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (c) => const Center(child: CircularProgressIndicator()),
                              );

                              final safePostId = _livePost?.id ?? widget.postData['postId'];
                              final introMessage = introController.text.trim();

                              debugPrint('--- CONTACT REQUEST PAYLOAD TRACE ---');
                              debugPrint('Receiver ID: $userId');
                              debugPrint('Post ID (Final): $safePostId');
                              debugPrint('Intro Message: "$introMessage"');

                              Exception? error;
                              bool success = false;

                              try {
                                if (safePostId == null || (safePostId as String).isEmpty) {
                                  throw ServerException('Post ID is missing. Request aborted.');
                                }
                                if (userId.isEmpty) {
                                  throw ServerException('Receiver User ID is missing.');
                                }
                                final apiClient = ApiClient(tokenProvider: AuthService.instance.getIdToken);
                                final ds = ChatRemoteDataSourceImpl(apiClient: apiClient);
                                await ds.sendContactRequest(userId, safePostId, introMessage);
                                success = true;
                              } on ServerException catch (e) {
                                error = e;
                              } catch (e) {
                                error = ServerException('Failed to send request: $e');
                              } finally {
                                // Always pop loading
                                if (context.mounted) {
                                  Navigator.pop(context); // Close loading spinner
                                }
                              }

                              if (!context.mounted) return;

                              if (success) {
                                AppMessenger.showSuccess('Contact request sent successfully!');
                                setState(() => _requestStatus = 'pending');
                              } else {
                                AppMessenger.showError(
                                  error is ServerException ? (error as ServerException).message : error.toString(),
                                );
                              }
                            },
                            child: const Text('Send Request'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _requestStatus == 'pending' 
                        ? Colors.grey 
                        : const Color(0xFF0A3D91),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _requestStatus == 'accepted' ? Icons.message : 
                        _requestStatus == 'pending' ? Icons.hourglass_empty : 
                        Icons.person_add, 
                        size: 20
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _requestStatus == 'accepted' ? 'Message $posterName' :
                        _requestStatus == 'pending' ? 'Request Pending' :
                        'Request Contact',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
