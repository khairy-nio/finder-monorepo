import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/socket_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/dynamic_colors.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../providers/user_provider.dart';
import '../widgets/app_bottom_nav.dart';
import 'package:provider/provider.dart';

/// Messages Screen — polished chat list.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  bool _isLoading  = true;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _chats = [];

  final SocketService _socketService = SocketService();
  String _currentUserId = '';
  late final dynamic Function(dynamic) _eventHandler;

  @override
  void initState() {
    super.initState();
    _loadChats();
    _eventHandler = (payload) {
      if (!mounted) return;
      if (payload['event_type'] == 'conversation.updated') {
        final user = context.read<UserProvider>().backendUser;
        if (user != null) _currentUserId = user.id;
        _updateChatList({
          'chat_id': payload['conversation']['id'],
          'last_message': payload['data']['last_message'],
          'last_message_sender_id': payload['data']['last_message_sender_id'],
          'updated_at': payload['emitted_at'],
        });
      }
    };
    _initSocket();
  }

  @override
  void dispose() {
    _socketService.offEvent(_eventHandler);
    _socketService.off('chat_read');
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initSocket() async {
    final token = await AuthService.instance.getIdToken();
    if (token == null) return;
    _socketService.setAuthToken(token);
    _socketService.connect();

    final up = context.read<UserProvider>();
    if (up.backendUser != null) _currentUserId = up.backendUser!.id;

    _socketService.onEvent(_eventHandler);
    _socketService.on('chat_read', (data) {
      if (!mounted) return;
      final chatId = data['chat_id'] as String?;
      if (chatId == null) return;
      setState(() {
        final idx = _chats.indexWhere((c) => c['id'] == chatId);
        if (idx != -1) {
          final chat = Map<String, dynamic>.from(_chats[idx]);
          chat['unread_count'] = 0;
          _chats[idx] = chat;
        }
      });
    });
  }

  void _updateChatList(Map<String, dynamic> data) {
    final chatId = data['chat_id'] as String?;
    if (chatId == null) return;
    setState(() {
      final idx = _chats.indexWhere((c) => c['id'] == chatId);
      if (idx != -1) {
        final chat = Map<String, dynamic>.from(_chats[idx]);
        final isYou = data['last_message_sender_id'] == _currentUserId;
        final senderName = isYou
            ? 'You: '
            : '${(chat['other_user_name'] as String?)?.split(' ').first ?? ''}: ';
        chat['last_message'] = '$senderName${data['last_message']}';
        chat['updated_at'] = data['updated_at'];
        if (!isYou && _socketService.activeChatId != chatId) {
          chat['unread_count'] =
              (int.tryParse(chat['unread_count']?.toString() ?? '0') ?? 0) + 1;
        } else if (_socketService.activeChatId == chatId) {
          chat['unread_count'] = 0;
        }
        _chats.removeAt(idx);
        _chats.insert(0, chat);
      } else {
        _loadChats();
      }
    });
  }

  Future<void> _loadChats() async {
    try {
      final ds = ChatRemoteDataSourceImpl(
          apiClient: ApiClient(
              tokenProvider: AuthService.instance.getIdToken));
      final chats = await ds.getMyChats();
      if (mounted) setState(() { _chats = chats; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _chats = []; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _chats.where((c) {
      final name =
          ((c['other_user_name'] ?? c['otherUserName']) as String?)
                  ?.toLowerCase() ??
              '';
      final last =
          ((c['last_message'] ?? c['lastMessage']) as String?)
                  ?.toLowerCase() ??
              '';
      return name.contains(_searchQuery) || last.contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: _isSearching
            ? null
            : IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () => Navigator.pop(context),
              ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Search conversations…',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
              )
            : Text(
                'Messages',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              size: 22,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : filtered.isEmpty
              ? _EmptyState(isSearching: _searchQuery.isNotEmpty)
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) =>
                      _ChatTile(chat: filtered[i]),
                ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: NavTab.messages,
        onTap: (i) {
          if (i == NavTab.messages) return;
          AppBottomNav.navigateToTab(context, i);
        },
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final Map<String, dynamic> chat;

  const _ChatTile({required this.chat});

  @override
  Widget build(BuildContext context) {
    final chatId         = chat['id'] as String? ?? '';
    final otherUserId    = chat['other_user_id'] as String? ?? '';
    final otherUserName  = chat['other_user_name'] as String? ?? 'Unknown';
    final otherAvatar    = chat['other_user_avatar'] as String?;
    final lastMessage    = chat['last_message'] as String? ?? '';
    final time           = chat['updated_at'] as String? ?? '';
    final unread         =
        int.tryParse(chat['unread_count']?.toString() ?? '0') ?? 0;
    final isOnline       = (chat['is_online'] as bool?) ?? false;
    final post           = chat['post'] as Map<String, dynamic>?;
    final postTitle      = post?['title'] as String? ?? '';

    // Format time
    String displayTime = time;
    try {
      if (time.length > 10) {
        final dt = DateTime.parse(time).toLocal();
        final now = DateTime.now();
        if (now.difference(dt).inDays == 0) {
          displayTime =
              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        } else if (now.difference(dt).inDays == 1) {
          displayTime = 'Yesterday';
        } else {
          displayTime = '${dt.day}/${dt.month}';
        }
      }
    } catch (_) {}

    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        '/chat',
        arguments: {
          'chatId': chatId,
          'userId': otherUserId,
          'userName': otherUserName,
          'isOnline': isOnline,
          'postTitle': post?['title'],
          'postImage': post?['image_url'],
          'postStatus': post?['status'],
          'postId': post?['id'],
          'userAvatar': otherAvatar,
          'postOwnerId': post?['user_id'],
        },
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl2, vertical: 12),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    _Avatar(url: otherAvatar, name: otherUserName),
                    if (isOnline)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                width: 2),
                          ),
                        ),
                      ),
                  ],
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
                              otherUserName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: unread > 0
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            displayTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: unread > 0
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: unread > 0
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      if (postTitle.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          'Re: $postTitle',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMessage,
                              style: TextStyle(
                                fontSize: 13,
                                color: unread > 0
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: unread > 0
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unread > 0) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusFull),
                              ),
                              child: Text(
                                '$unread',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            indent: AppSpacing.xl2 + 52 + AppSpacing.md,
            endIndent: 0,
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String name;

  const _Avatar({required this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: ClipOval(
          child: Image.network(
            url!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initials(context),
          ),
        ),
      );
    }
    return _initials(context);
  }

  Widget _initials(BuildContext context) {
    final initial =
        name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearching;

  const _EmptyState({required this.isSearching});

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
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 32,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              isSearching ? 'No results found' : 'No conversations yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isSearching
                  ? 'Try a different search term.'
                  : 'When you contact someone about a lost item,\nyour conversation will appear here.',
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
