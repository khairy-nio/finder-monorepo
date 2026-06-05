import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/services/auth_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/socket_service.dart';
import '../../core/utils/app_messenger.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/dynamic_colors.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

/// Notifications Screen — premium, action-rich.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading     = true;
  bool _isLoadingMore = false;
  bool _hasMore       = true;
  final int _limit    = 15;
  int _offset         = 0;

  final Set<String> _respondingIds = {};
  late final ApiClient _apiClient;
  late final ChatRemoteDataSourceImpl _chatDs;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(
        tokenProvider: AuthService.instance.getIdToken);
    _chatDs = ChatRemoteDataSourceImpl(apiClient: _apiClient);
    _loadNotifications();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _hasMore) {
        _loadMoreNotifications();
      }
    });

    SocketService().on('new_notification', _handleNewNotif);
  }

  void _handleNewNotif(dynamic _) {
    if (mounted) _loadNotifications(refresh: true);
  }

  @override
  void dispose() {
    SocketService().off('new_notification', _handleNewNotif);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (refresh) { _offset = 0; _hasMore = true; }
    try {
      final res = await _apiClient.get(
          '${ApiConstants.notificationsEndpoint}?limit=$_limit&offset=$_offset');
      final raw = res['data'] as List<dynamic>? ?? [];
      final pg  = res['pagination'] as Map<String, dynamic>?;
      if (mounted) {
        setState(() {
          if (refresh) {
            _notifications = raw.cast();
          } else {
            for (final item in raw) {
              if (!_notifications.any((e) => e['id'] == item['id'])) {
                _notifications.add(item as Map<String, dynamic>);
              }
            }
          }
          _hasMore = pg != null ? (pg['hasMore'] ?? false) : raw.length == _limit;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { if (refresh) _notifications = []; _isLoading = false; });
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() { _isLoadingMore = true; _offset += _limit; });
    await _loadNotifications();
    if (mounted) setState(() => _isLoadingMore = false);
  }

  Future<void> _markAsRead(String id, int index) async {
    try {
      await _apiClient.patch(
          '${ApiConstants.notificationsEndpoint}/$id/read', body: {});
      if (mounted) {
        setState(() => _notifications[index]['is_read'] = true);
        context.read<NotificationProvider>().markAsRead();
      }
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    try {
      await _apiClient.post(ApiConstants.notificationReadAllEndpoint, body: {});
      if (mounted) {
        setState(() { for (final n in _notifications) n['is_read'] = true; });
        context.read<NotificationProvider>().markAllAsRead();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((n) => n['is_read'] == false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications'),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Mark all read',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : _notifications.isEmpty
              ? const _EmptyState()
              : RefreshIndicator(
                  onRefresh: () => _loadNotifications(refresh: true),
                  color: Theme.of(context).colorScheme.primary,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount:
                        _notifications.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == _notifications.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.primary),
                          ),
                        );
                      }
                      return _NotifTile(
                        notification: _notifications[i],
                        index: i,
                        onMarkRead: _markAsRead,
                        onTap: _handleNotifTap,
                      );
                    },
                  ),
                ),
    );
  }

  Future<void> _handleNotifTap(
      Map<String, dynamic> notification) async {
    final type  = notification['type'] as String? ?? '';
    final refId = notification['reference_id'] as String? ?? '';
    if (refId.isEmpty) return;

    if (type == 'contact_request') {
      final status = notification['request_status'] as String?;
      if (status == 'accepted' || status == 'rejected') return;
      _showRequestDialog(refId, notification);
    } else if (type == 'contact_accepted' || type == 'new_message') {
      _navigateToChat(refId);
    }
  }

  Future<void> _navigateToChat(String chatId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
      ),
    );
    try {
      final meta = await _chatDs.getChatMetadata(chatId);
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pushNamed(context, '/chat', arguments: {
        'chatId': chatId,
        'userId': meta?['other_user_id'],
        'userName': meta?['other_user_name'] ?? 'Chat',
        'isOnline': false,
      });
    } catch (_) {
      if (mounted) {
        Navigator.pop(context);
        Navigator.pushNamed(context, '/chat',
            arguments: {'chatId': chatId});
      }
    }
  }

  Future<void> _showRequestDialog(
      String requestId, Map<String, dynamic> notification) async {
    if (_respondingIds.contains(requestId)) return;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
        ),
      );
      final res = await _apiClient.get(
          '${ApiConstants.respondContactRequestEndpoint}/$requestId');
      if (!mounted) return;
      Navigator.pop(context);

      if (res['success'] != true || res['data'] == null) {
        AppMessenger.showError('Request not found.');
        return;
      }

      final reqData     = res['data'] as Map<String, dynamic>;
      final currentStatus = reqData['status'] as String? ?? 'pending';
      if (currentStatus != 'pending') {
        AppMessenger.showInfo(
            'This request has already been $currentStatus.');
        return;
      }

      final senderName     = reqData['sender']?['name'] ?? 'Someone';
      final senderVerified =
          reqData['sender']?['verified'] as bool? ?? false;
      final introMessage   = (reqData['intro_message'] as String?)
              ?.isNotEmpty == true
          ? reqData['intro_message'] as String
          : null;

      final rawQ = reqData['post']?['verification_questions'];
      final rawA = reqData['verification_answers'];
      final questions = rawQ != null
          ? (rawQ as List<dynamic>).cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];
      final answers   = rawA != null
          ? (rawA as List<dynamic>).cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];
      final answerMap = {
        for (final a in answers)
          (a['questionId'] as int? ?? 0): (a['answer'] as String? ?? ''),
      };

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person_rounded,
                          color: Theme.of(context).colorScheme.primary, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Request from $senderName',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          if (senderVerified)
                            Row(
                              children: [
                                Icon(Icons.verified_rounded,
                                    size: 12, color: Theme.of(context).colorScheme.primary),
                                SizedBox(width: 3),
                                Text(
                                  'Verified user',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                // Scroll content
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight:
                        MediaQuery.of(context).size.height * 0.45,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (introMessage != null) ...[
                          Text(
                            'Message',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: context.colors.neutral50,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSm),
                              border: Border.all(color: Theme.of(context).colorScheme.outline),
                            ),
                            child: Text(
                              introMessage,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        if (questions.isNotEmpty) ...[
                          Text(
                            "Claimant's Answers",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ...questions.map((q) {
                            final qId     = q['id'] as int? ?? 0;
                            final question = q['question'] as String? ?? '';
                            final answer  = answerMap[qId] ?? '—';
                            return Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Q: $question',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(
                                        AppSpacing.md),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primaryContainer,
                                      borderRadius:
                                          BorderRadius.circular(AppSpacing.radiusSm),
                                    ),
                                    child: Text(
                                      answer,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.warningMuted,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 14, color: AppColors.warning),
                              SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Only accept if answers match what only the real owner would know.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.warning,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _respondingIds.contains(requestId)
                            ? null
                            : () {
                                Navigator.pop(ctx);
                                _respondToRequest(
                                    requestId, 'rejected', notification);
                              },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(
                              color: AppColors.error, width: 1.5),
                          minimumSize: const Size(0, 46),
                        ),
                        child: const Text('Reject',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _respondingIds.contains(requestId)
                            ? null
                            : () {
                                Navigator.pop(ctx);
                                _respondToRequest(
                                    requestId, 'accepted', notification);
                              },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                        ),
                        child: const Text('Accept',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (_) {
      if (mounted) Navigator.pop(context);
      AppMessenger.showError('Something went wrong. Please try again.');
    }
  }

  Future<void> _respondToRequest(String requestId, String status,
      Map<String, dynamic> notification) async {
    if (_respondingIds.contains(requestId)) return;
    if (mounted) setState(() => _respondingIds.add(requestId));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
      ),
    );

    Map<String, dynamic>? res;
    try {
      res = await _apiClient.put(
        '${ApiConstants.respondContactRequestEndpoint}/$requestId/respond',
        body: {'status': status},
      );
    } catch (_) {
      res = null;
    } finally {
      if (mounted) Navigator.pop(context);
      if (mounted) setState(() => _respondingIds.remove(requestId));
    }

    if (res == null) {
      AppMessenger.showError('Network error. Please try again.');
      return;
    }

    if (res['success'] == true) {
      if (mounted) {
        setState(() {
          final idx = _notifications.indexOf(notification);
          if (idx != -1) {
            _notifications[idx] =
                Map<String, dynamic>.from(notification)
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
        _navigateToChat(res['data']['chat_id'] as String);
      }
      _loadNotifications(refresh: true);
    } else {
      AppMessenger.showError(res['message'] ?? 'Failed to respond.');
    }
  }

  String _timeAgo(String isoDate) {
    try {
      final dt   = DateTime.parse(isoDate);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}

// ─── Notification Tile ────────────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final int index;
  final Future<void> Function(String, int) onMarkRead;
  final Future<void> Function(Map<String, dynamic>) onTap;

  const _NotifTile({
    required this.notification,
    required this.index,
    required this.onMarkRead,
    required this.onTap,
  });

  static _NotifMeta _meta(String type, BuildContext context) {
    switch (type) {
      case 'match_found':
        return _NotifMeta(Icons.auto_awesome_rounded, AppColors.warning,
            AppColors.warningMuted, 'Match Found');
      case 'contact_request':
        return _NotifMeta(Icons.person_add_rounded, Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer, 'Contact Request');
      case 'contact_accepted':
        return _NotifMeta(Icons.check_circle_rounded, AppColors.success,
            AppColors.successMuted, 'Request Accepted');
      case 'post_resolved':
        return _NotifMeta(Icons.task_alt_rounded, Theme.of(context).colorScheme.onSurfaceVariant,
            Theme.of(context).colorScheme.surfaceContainerHighest, 'Post Resolved');
      case 'contact_rejected':
        return _NotifMeta(Icons.cancel_rounded, AppColors.error,
            AppColors.errorMuted, 'Request Rejected');
      case 'new_message':
        return _NotifMeta(Icons.chat_bubble_rounded, AppColors.info,
            AppColors.infoMuted, 'New Message');
      default:
        return _NotifMeta(Icons.notifications_rounded, Theme.of(context).colorScheme.onSurfaceVariant,
            Theme.of(context).colorScheme.surfaceContainerHighest, 'Notification');
    }
  }

  String _defaultMessage(String type) {
    switch (type) {
      case 'match_found':      return 'A potential match was found for your item.';
      case 'contact_request':  return 'Someone wants to contact you about an item.';
      case 'contact_accepted': return 'Your contact request was accepted.';
      case 'post_resolved':    return 'An item you were following was resolved.';
      case 'contact_rejected': return 'Your contact request was rejected.';
      case 'new_message':      return 'You have a new message.';
      default:                 return 'You have a new notification.';
    }
  }

  String _timeAgo(String isoDate) {
    try {
      final dt   = DateTime.parse(isoDate);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final type      = notification['type'] as String? ?? '';
    final isRead    = notification['is_read'] as bool? ?? false;
    final createdAt = notification['created_at'] as String? ?? '';
    final meta      = _meta(type, context);

    return InkWell(
      onTap: () {
        if (!isRead) onMarkRead(notification['id'] as String, index);
        onTap(notification);
      },
      child: Container(
        color: isRead ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl2, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: meta.bgColor,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(meta.icon, color: meta.color, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          meta.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isRead ? FontWeight.w500 : FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _defaultMessage(type),
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
}

class _NotifMeta {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String title;

  const _NotifMeta(this.icon, this.color, this.bgColor, this.title);
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
                color: context.colors.neutral100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 32,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No notifications',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "You're all caught up. We'll notify you\nwhen something important happens.",
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
