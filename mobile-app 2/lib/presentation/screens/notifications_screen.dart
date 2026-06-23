import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/services/auth_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/socket_service.dart';
import '../../core/utils/app_messenger.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

/// Notifications Screen — wired to real backend API
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final int _limit = 15;
  int _offset = 0;

  // Prevents duplicate accept/reject taps mid-flight
  final Set<String> _respondingIds = {};

  late final ApiClient _apiClient;
  late final ChatRemoteDataSourceImpl _chatDataSource;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(tokenProvider: AuthService.instance.getIdToken);
    _chatDataSource = ChatRemoteDataSourceImpl(apiClient: _apiClient);
    _loadNotifications();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _hasMore) {
        _loadMoreNotifications();
      }
    });

    SocketService().on('new_notification', _handleNewNotificationEvent);
  }

  void _handleNewNotificationEvent(dynamic data) {
    if (mounted) {
      _loadNotifications(refresh: true);
    }
  }
  
  @override
  void dispose() {
    SocketService().off('new_notification', _handleNewNotificationEvent);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (refresh) {
      _offset = 0;
      _hasMore = true;
    }
    try {
      final response = await _apiClient.get('${ApiConstants.notificationsEndpoint}?limit=$_limit&offset=$_offset');
      final List<dynamic> raw = response['data'] as List<dynamic>? ?? [];
      final pagination = response['pagination'] as Map<String, dynamic>?;
      
      if (mounted) {
        setState(() {
          if (refresh) {
            _notifications = raw.map((n) => n as Map<String, dynamic>).toList();
          } else {
            // merge without duplicates
            for (var item in raw) {
              if (!_notifications.any((element) => element['id'] == item['id'])) {
                _notifications.add(item as Map<String, dynamic>);
              }
            }
          }
          
          if (pagination != null) {
            _hasMore = pagination['hasMore'] ?? false;
          } else {
            _hasMore = raw.length == _limit;
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (refresh) _notifications = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
      _offset += _limit;
    });
    await _loadNotifications();
    if (mounted) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _markAsRead(String id, int index) async {
    try {
      await _apiClient.patch(
        '${ApiConstants.notificationsEndpoint}/$id/read',
        body: {},
      );
      if (mounted) {
        setState(() => _notifications[index]['is_read'] = true);
        context.read<NotificationProvider>().markAsRead();
      }
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    try {
      await _apiClient.post(
        ApiConstants.notificationReadAllEndpoint,
        body: {},
      );
      if (mounted) {
        setState(() {
          for (var n in _notifications) {
            n['is_read'] = true;
          }
        });
        context.read<NotificationProvider>().markAllAsRead();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Icon at top
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications,
                size: 40,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Stay updated with all your notifications',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ),

            const SizedBox(height: 24),

            // Notifications List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A3D91)))
                  : _notifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No notifications yet',
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _loadNotifications(refresh: true),
                          color: const Color(0xFF0A3D91),
                          child: ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
                            separatorBuilder: (_, _s) => Divider(height: 1, color: Colors.grey[300]),
                            itemBuilder: (context, index) {
                              if (index == _notifications.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(child: CircularProgressIndicator(color: Color(0xFF0A3D91))),
                                );
                              }
                              return _buildNotificationItem(_notifications[index], index);
                            },
                          ),
                        ),
            ),

            const SizedBox(height: 16),

            // Mark all as read button
            if (_notifications.any((n) => n['is_read'] == false))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _markAllAsRead,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0A3D91)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Mark All as Read',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0A3D91),
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Need help? ', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/support'),
                    child: const Text(
                      'Contact Support',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8B7355),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification, int index) {
    final type = notification['type'] as String? ?? 'info';
    final isRead = notification['is_read'] as bool? ?? false;
    final createdAt = notification['created_at'] as String? ?? '';

    Color iconColor;
    IconData icon;
    String title;
    String message;

    switch (type) {
      case 'match_found':
        iconColor = Colors.orange;
        icon = Icons.stars;
        title = 'Match Found';
        message = 'A potential match was found for your item.';
        break;
      case 'contact_request':
        iconColor = const Color(0xFF0A3D91);
        icon = Icons.person_add;
        title = 'Contact Request';
        message = 'Someone wants to contact you about an item.';
        break;
      case 'contact_accepted':
        iconColor = Colors.green;
        icon = Icons.check_circle;
        title = 'Request Accepted';
        message = 'Your contact request was accepted.';
        break;
      case 'post_resolved':
        iconColor = Colors.grey;
        icon = Icons.task_alt;
        title = 'Post Resolved';
        message = 'An item you were following was resolved.';
        break;
      case 'contact_rejected':
        iconColor = Colors.red;
        icon = Icons.cancel;
        title = 'Request Rejected';
        message = 'Your contact request was rejected.';
        break;
      case 'new_message':
        iconColor = Colors.blue;
        icon = Icons.message;
        title = 'New Message';
        message = 'You have a new message.';
        break;
      default:
        iconColor = const Color(0xFF8B7355);
        icon = Icons.notifications;
        title = 'Notification';
        message = 'You have a new notification.';
    }

    return Container(
      color: isRead ? Colors.white : Colors.grey[50],
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                ),
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Color(0xFF0A3D91), shape: BoxShape.circle),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(message, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(_timeAgo(createdAt), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
        onTap: () {
          if (!isRead) _markAsRead(notification['id'] as String, index);
          _handleNotificationClick(notification);
        },
      ),
    );
  }

  Future<void> _handleNotificationClick(Map<String, dynamic> notification) async {
    final type = notification['type'] as String? ?? '';
    final refId = notification['reference_id'] as String? ?? '';
    if (refId.isEmpty) return;

    if (type == 'contact_request') {
      // Only show dialog if not already responded
      final status = notification['request_status'] as String?;
      if (status == 'accepted' || status == 'rejected') return;
      _showRequestDialog(refId, notification);
    } else if (type == 'contact_accepted' || type == 'new_message') {
      _navigateToChat(refId);
    }
  }

  Future<void> _navigateToChat(String chatId) async {
    // Fetch full metadata before pushing so AppBar is hydrated
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final meta = await _chatDataSource.getChatMetadata(chatId);
      if (!mounted) return;
      Navigator.pop(context); // pop loader
      Navigator.pushNamed(
        context,
        '/chat',
        arguments: {
          'chatId': chatId,
          'userId': meta?['other_user_id'] as String?,
          'userName': meta?['other_user_name'] as String? ?? 'Chat',
          'isOnline': false,
        },
      );
    } catch (_) {
      if (mounted) {
        Navigator.pop(context);
        Navigator.pushNamed(context, '/chat', arguments: {'chatId': chatId});
      }
    }
  }

  Future<void> _showRequestDialog(String requestId, Map<String, dynamic> notification) async {
    if (_respondingIds.contains(requestId)) return;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );
      final res = await _apiClient.get('${ApiConstants.respondContactRequestEndpoint}/$requestId');
      if (!mounted) return;
      Navigator.pop(context); // pop loading

      if (res['success'] != true || res['data'] == null) {
        AppMessenger.showError('Request not found.');
        return;
      }

      final reqData = res['data'] as Map<String, dynamic>;
      final currentStatus = reqData['status'] as String? ?? 'pending';
      if (currentStatus != 'pending') {
        AppMessenger.showInfo('This request has already been $currentStatus.');
        return;
      }

      final senderName = reqData['sender']?['name'] ?? 'Someone';
      final senderVerified = reqData['sender']?['verified'] as bool? ?? false;
      final introMessage = (reqData['intro_message'] as String?)?.isNotEmpty == true
          ? reqData['intro_message'] as String
          : null;

      // ── Verification Q&A ──────────────────────────────────────────────────
      // verification_questions from the post, verification_answers from the request
      final rawQuestions = reqData['post']?['verification_questions'];
      final rawAnswers   = reqData['verification_answers'];

      final List<Map<String, dynamic>> questions = rawQuestions != null
          ? (rawQuestions as List<dynamic>).map((q) => q as Map<String, dynamic>).toList()
          : [];

      final List<Map<String, dynamic>> answers = rawAnswers != null
          ? (rawAnswers as List<dynamic>).map((a) => a as Map<String, dynamic>).toList()
          : [];

      // Build a quick lookup: questionId → answer
      final Map<int, String> answerMap = {
        for (final a in answers)
          (a['questionId'] as int? ?? 0): (a['answer'] as String? ?? ''),
      };

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.person_rounded, color: Color(0xFF0A3D91), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request from $senderName',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (senderVerified)
                      const Row(children: [
                        Icon(Icons.verified_rounded, size: 13, color: Color(0xFF0A3D91)),
                        SizedBox(width: 3),
                        Text('Verified user', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ]),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Intro message ─────────────────────────────────────────
                if (introMessage != null) ...[
                  const Text(
                    'Message',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(introMessage, style: const TextStyle(fontSize: 13, height: 1.4)),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Verification Q&A ──────────────────────────────────────
                if (questions.isNotEmpty) ...[
                  Row(children: [
                    const Icon(Icons.quiz_rounded, size: 15, color: Color(0xFF0A3D91)),
                    const SizedBox(width: 6),
                    const Text(
                      'Claimant\'s Answers',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  ...questions.map((q) {
                    final qId      = q['id'] as int? ?? 0;
                    final question = q['question'] as String? ?? '';
                    final answer   = answerMap[qId] ?? '—';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Q: $question',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF444466),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F4FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF0A3D91).withOpacity(0.15)),
                            ),
                            child: Text(
                              'A: $answer',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A2E)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ] else if (introMessage == null) ...[
                  // No questions and no intro message
                  Text(
                    'The claimant did not provide any additional information.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],

                const SizedBox(height: 8),
                // Review guidance
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFCC02).withOpacity(0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF856404)),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Only accept if the answers match what only the real owner would know.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF856404), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _respondingIds.contains(requestId)
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      _respondToRequest(requestId, 'rejected', notification);
                    },
              child: const Text('Reject', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: _respondingIds.contains(requestId)
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      _respondToRequest(requestId, 'accepted', notification);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A3D91),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      AppMessenger.showError('Something went wrong. Please try again.');
    }
  }


  Future<void> _respondToRequest(String requestId, String status, Map<String, dynamic> notification) async {
    if (_respondingIds.contains(requestId)) return; // guard: prevent double tap
    if (mounted) setState(() => _respondingIds.add(requestId));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    Map<String, dynamic>? res;
    try {
      res = await _apiClient.put(
        '${ApiConstants.respondContactRequestEndpoint}/$requestId/respond',
        body: {'status': status},
      );
    } catch (e) {
      res = null;
    } finally {
      // ALWAYS pop the loading dialog regardless of outcome
      if (mounted) Navigator.pop(context);
      if (mounted) setState(() => _respondingIds.remove(requestId));
    }

    if (res == null) {
      AppMessenger.showError('Network error. Please try again.');
      return;
    }

    if (res['success'] == true) {
      // Optimistically update notification in local list so it stops showing action buttons
      if (mounted) {
        setState(() {
          final idx = _notifications.indexOf(notification);
          if (idx != -1) {
            _notifications[idx] = Map<String, dynamic>.from(notification)
              ..['request_status'] = status
              ..['is_read'] = true;
          }
        });
      }

      if (!mounted) return;
      if (status == 'accepted') {
        AppMessenger.showSuccess('Request accepted ✓');
      } else {
        AppMessenger.showInfo('Request rejected.');
      }

      if (status == 'accepted' && res['data']?['chat_id'] != null) {
        final chatId = res['data']['chat_id'] as String;
        _navigateToChat(chatId);
      }

      // Refresh list in background (don't await)
      _loadNotifications(refresh: true);
    } else {
      AppMessenger.showError(res['message'] ?? 'Failed to respond.');
    }
  }

  String _timeAgo(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}
