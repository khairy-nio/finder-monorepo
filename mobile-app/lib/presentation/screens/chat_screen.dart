import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_client.dart';
import '../../core/network/socket_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/dynamic_colors.dart';
import '../../core/utils/app_messenger.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../../data/datasources/user_remote_data_source.dart';
import '../../domain/entities/chat_message.dart';
import '../../data/models/chat_message_model.dart';
import '../providers/user_provider.dart';

class ChatScreen extends StatefulWidget {
  final String? chatId;
  final String? userName;
  final String? userId;
  final bool? isOnline;
  final String? postTitle;
  final String? postImage;
  final String? postStatus;
  final String? postId;
  final String? userAvatar;
  final String? postOwnerId;

  const ChatScreen({
    super.key,
    this.chatId,
    this.userName,
    this.userId,
    this.isOnline,
    this.postTitle,
    this.postImage,
    this.postStatus,
    this.postId,
    this.userAvatar,
    this.postOwnerId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasText = false;

  List<ChatMessage> _messages = [];
  bool _isLoadingMessages = true;
  bool _isSending = false;
  String? _error;
  String? _otherUserAvatar;
  String _currentUserId = '';
  late bool _isUserOnline;
  String? _postStatus;
  String? _fetchedPostOwnerId;

  late final ChatRemoteDataSource _dataSource;
  final SocketService _socketService = SocketService();
  late final dynamic Function(dynamic) _messageHandler;
  late final dynamic Function(dynamic) _statusHandler;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(tokenProvider: AuthService.instance.getIdToken);
    _dataSource = ChatRemoteDataSourceImpl(apiClient: apiClient);
    _isUserOnline = widget.isOnline ?? false;
    _otherUserAvatar = widget.userAvatar;
    _postStatus = widget.postStatus;

    _resolveCurrentUserId();
    _messageController.addListener(
      () => setState(() => _hasText = _messageController.text.trim().isNotEmpty),
    );
    _loadMessages();
    _markAsRead();
    _fetchMissingPostOwnerId();

    // Debug Prints
    debugPrint('=== CHAT SCREEN DEBUG ===');
    debugPrint('Current User ID: $_currentUserId');
    debugPrint('Post Owner ID: ${widget.postOwnerId}');
    debugPrint('Post Status: $_postStatus');
    debugPrint('Is Post Owner: ${_currentUserId.isNotEmpty && _currentUserId == widget.postOwnerId}');
    debugPrint('=========================');

    if (widget.chatId != null) {
      _socketService.activeChatId = widget.chatId;
      _loadMessages();
      _initSocket();
      _markAsRead();
    } else {
      setState(() { _isLoadingMessages = false; _error = 'No chat ID provided.'; });
    }
  }

  Future<void> _resolveCurrentUserId() async {
    final providerUser = context.read<UserProvider>().backendUser;
    if (providerUser != null) {
      if (mounted) setState(() => _currentUserId = providerUser.id);
      return;
    }
    try {
      final apiClient = ApiClient(tokenProvider: AuthService.instance.getIdToken);
      final user = await UserRemoteDataSourceImpl(apiClient: apiClient).fetchMe();
      if (mounted) setState(() => _currentUserId = user.id);
    } catch (e) {
      if (mounted) setState(() => _currentUserId = AuthService.instance.currentUser?.uid ?? '');
    }
  }

  Future<void> _initSocket() async {
    final token = await AuthService.instance.getIdToken();
    if (token == null) return;
    _socketService.setAuthToken(token);
    _socketService.connect();
    _socketService.joinChat(widget.chatId!);

    _messageHandler = (payload) {
      if (!mounted) return;
      if (payload['event_type'] == 'message.created') {
        final data = payload['data']['message'];
        setState(() {
          _messages.removeWhere(
              (m) => m.id.startsWith('temp-') && m.message == data['content']);
          if (!_messages.any((m) => m.id == data['id'])) {
            _messages.add(ChatMessageModel.fromJson(data));
            _scrollToBottom();
          }
        });
      }
    };

    _statusHandler = (data) {
      if (mounted && widget.userId != null && data['userId'] == widget.userId) {
        setState(() => _isUserOnline = data['status'] == 'online');
      }
    };

    _socketService.onEvent(_messageHandler);
    _socketService.on('user_status', _statusHandler);
    if (widget.userId != null) _socketService.checkUserStatus(widget.userId!);
  }

  @override
  void dispose() {
    if (widget.chatId != null) {
      _socketService.leaveChat(widget.chatId!);
      if (_socketService.activeChatId == widget.chatId) {
        _socketService.activeChatId = null;
      }
    }
    _socketService.offEvent(_messageHandler);
    _socketService.off('user_status', _statusHandler);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() { _isLoadingMessages = true; _error = null; });
    try {
      if (widget.chatId != null) {
        final meta = await _dataSource.getChatMetadata(widget.chatId!);
        if (meta != null && mounted) {
          setState(() => _otherUserAvatar = meta['other_user_avatar'] as String?);
        }
      }
      final messages = await _dataSource.getChatMessages(widget.chatId!);
      if (mounted) {
        setState(() { _messages = messages; _isLoadingMessages = false; });
        _scrollToBottom();
        _markAsRead();
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load messages.'; _isLoadingMessages = false; });
    }
  }

  Future<void> _markAsRead() async {
    if (widget.chatId == null) return;
    try { await _dataSource.markAsRead(widget.chatId!, _currentUserId); } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || widget.chatId == null || _isSending) return;

    final optimistic = ChatMessageModel(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      chatId: widget.chatId!,
      senderId: _currentUserId,
      message: text,
      timestamp: DateTime.now(),
    );
    setState(() { _messages.add(optimistic); _isSending = true; });
    _messageController.clear();
    _scrollToBottom();

    try {
      final sent = await _dataSource.sendMessage(
          chatId: widget.chatId!, senderId: _currentUserId, message: text);
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.id == optimistic.id);
          if (!_messages.any((m) => m.id == sent.id)) _messages.add(sent);
          _isSending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.id == optimistic.id);
          _isSending = false;
        });
        AppMessenger.showError('Failed to send message. Please try again.');
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    if (widget.chatId == null) return;
    final file = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
    if (file == null) return;

    final optimistic = ChatMessageModel(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      chatId: widget.chatId!,
      senderId: _currentUserId,
      message: 'Uploading image…',
      timestamp: DateTime.now(),
    );
    setState(() { _messages.add(optimistic); _isSending = true; });
    _scrollToBottom();

    try {
      final token = await AuthService.instance.getIdToken();
      final request = http.MultipartRequest(
          'POST', Uri.parse('${ApiConstants.baseUrl}/chat/upload-image'));
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('image', file.path));
      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final urlMatch = RegExp(r'"url"\s*:\s*"([^"]+)"').firstMatch(resp.body);
        final imageUrl = urlMatch?.group(1) ?? '';
        if (imageUrl.isNotEmpty) {
          final sent = await _dataSource.sendMessage(
              chatId: widget.chatId!, senderId: _currentUserId, message: imageUrl);
          if (mounted) {
            setState(() {
              _messages.removeWhere((m) => m.id == optimistic.id);
              if (!_messages.any((m) => m.id == sent.id)) _messages.add(sent);
            });
            _scrollToBottom();
          }
        }
      } else if (mounted) {
        setState(() => _messages.removeWhere((m) => m.id == optimistic.id));
        AppMessenger.showError('Failed to upload image. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _messages.removeWhere((m) => m.id == optimistic.id));
        AppMessenger.showError('Failed to upload image. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _fetchMissingPostOwnerId() async {
    if (widget.postOwnerId != null) return;
    if (widget.postId == null) return;

    try {
      final apiClient = ApiClient(tokenProvider: AuthService.instance.getIdToken);
      final response = await apiClient.get('${ApiConstants.postDetailEndpoint}/${widget.postId}');
      if (response['success'] == true && response['data'] != null) {
        if (mounted) {
          setState(() {
            _fetchedPostOwnerId = response['data']['user_id'];
          });
          debugPrint('Fetched missing Post Owner ID: $_fetchedPostOwnerId');
        }
      }
    } catch (e) {
      debugPrint('Error fetching missing post owner id: $e');
    }
  }

  Future<void> _resolvePost() async {
    if (widget.postId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Post'),
        content: const Text(
            'Are you sure you want to mark this item as resolved with this user? '
            'This will close the post and award recovery points.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Resolve Post'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final apiClient = ApiClient(tokenProvider: AuthService.instance.getIdToken);
      // Using PostRemoteDataSource dynamically here, alternatively we could add it to imports
      // but to avoid massive import changes we can just do this:
      final request = http.Request('PATCH', Uri.parse('${ApiConstants.baseUrl}/post/${widget.postId}/status'));
      final token = await AuthService.instance.getIdToken();
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Content-Type'] = 'application/json';
      request.body = '{"status": "resolved"}';
      
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      
      if (!mounted) return;
      Navigator.pop(context); // close loading dialog
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() => _postStatus = 'resolved');
        AppMessenger.showSuccess('Post marked as resolved! Points awarded.');
      } else {
        AppMessenger.showError('Failed to resolve post.');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        AppMessenger.showError('Failed to resolve post.');
      }
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
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
            child: Icon(Icons.arrow_back_rounded,
                size: 18, color: Theme.of(context).colorScheme.onSurface),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // Avatar with online dot
            Stack(
              children: [
                _UserAvatar(url: _otherUserAvatar, name: widget.userName ?? '?', size: 38),
                if (_isUserOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.userName ?? 'Chat',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _isUserOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isUserOnline
                          ? AppColors.success
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded,
                size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
            shape: RoundedRectangleBorder(borderRadius: AppSpacing.brMd),
            onSelected: (value) {
              if (value == 'report') {
                Navigator.pushNamed(context, '/report-problem', arguments: {
                  'reportType': 'chat',
                  'targetId': widget.chatId,
                  'targetName': widget.userName ?? 'Chat',
                });
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                value: 'report',
                child: Row(
                  children: [
                    const Icon(Icons.flag_outlined, color: AppColors.error, size: 18),
                    const SizedBox(width: 10),
                    Text('Report chat',
                        style: TextStyle(
                            fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Post context bar
          if (widget.postTitle != null && widget.postTitle!.isNotEmpty)
            _PostContextBar(
              title: widget.postTitle!,
              imageUrl: widget.postImage,
              status: _postStatus,
              postId: widget.postId,
              isPostOwner: _currentUserId.isNotEmpty && _currentUserId == (widget.postOwnerId ?? _fetchedPostOwnerId),
              onResolve: _resolvePost,
            ),

          // Messages list
          Expanded(
            child: _isLoadingMessages
                ? Center(
                    child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                : _error != null
                    ? _ErrorState(error: _error!, onRetry: _loadMessages)
                    : _messages.isEmpty
                        ? const _EmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg, AppSpacing.lg,
                                AppSpacing.lg, AppSpacing.sm),
                            itemCount: _messages.length,
                            itemBuilder: (context, i) {
                              final msg = _messages[i];
                              final isMine = msg.senderId == _currentUserId;
                              final showDate = i == 0 ||
                                  _messages[i].timestamp.day !=
                                      _messages[i - 1].timestamp.day;
                              return Column(
                                children: [
                                  if (showDate)
                                    _DateSeparator(dt: msg.timestamp),
                                  _Bubble(
                                    message: msg,
                                    isMine: isMine,
                                    otherAvatar: _otherUserAvatar,
                                    myAvatar: context
                                        .read<UserProvider>()
                                        .backendUser
                                        ?.profileImageUrl,
                                    formatTime: _formatTime,
                                  ),
                                ],
                              );
                            },
                          ),
          ),

          // Input bar
          _InputBar(
            controller: _messageController,
            hasText: _hasText,
            isSending: _isSending,
            onSend: _sendMessage,
            onImage: _pickAndSendImage,
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  final String? url;
  final String name;
  final double size;

  const _UserAvatar({required this.url, required this.name, this.size = 44});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return ClipOval(
        child: Image.network(url!, width: size, height: size, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initials(context)),
      );
    }
    return _initials(context);
  }

  Widget _initials(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer, shape: BoxShape.circle),
      child: Center(
        child: Text(initial,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary)),
      ),
    );
  }
}

class _PostContextBar extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final String? status;
  final String? postId;
  final bool isPostOwner;
  final VoidCallback? onResolve;

  const _PostContextBar({
    required this.title,
    this.imageUrl,
    this.status,
    this.postId,
    this.isPostOwner = false,
    this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final isLost = (status ?? '').toLowerCase() == 'lost';
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline)),
      ),
      child: Row(
        children: [
          if (imageUrl != null && imageUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: AppSpacing.brXs,
              child: Image.network(imageUrl!, width: 36, height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const SizedBox(width: 36, height: 36)),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isLost ? AppColors.lostBadgeBg : AppColors.foundBadgeBg,
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              isLost ? 'Lost' : 'Found',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isLost ? AppColors.lostBadge : AppColors.foundBadge,
              ),
            ),
          ),
          if (isPostOwner && (status ?? '').toLowerCase() != 'resolved' && (status ?? '').toLowerCase() != 'closed') ...[
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton(
              onPressed: onResolve,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                minimumSize: const Size(0, 26),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusFull)),
              ),
              child: Text(
                'Resolve Post',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime dt;
  const _DateSeparator({required this.dt});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label;
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      label = 'Today';
    } else if (dt.day == now.day - 1 &&
        dt.month == now.month &&
        dt.year == now.year) {
      label = 'Yesterday';
    } else {
      label = '${dt.day}/${dt.month}/${dt.year}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: context.colors.neutral100,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Text(
            label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final String? otherAvatar;
  final String? myAvatar;
  final String Function(DateTime) formatTime;

  const _Bubble({
    required this.message,
    required this.isMine,
    required this.otherAvatar,
    required this.myAvatar,
    required this.formatTime,
  });

  bool get _isImage =>
      message.message.startsWith('http') &&
      message.message.contains('res.cloudinary.com');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: AppSpacing.sm,
        left: isMine ? 40 : 0,
        right: isMine ? 0 : 40,
      ),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            _UserAvatar(url: otherAvatar, name: '?', size: 28),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: _isImage
                      ? EdgeInsets.zero
                      : const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMine ? Theme.of(context).colorScheme.primary : context.colors.bubbleReceived,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppSpacing.radiusMd),
                      topRight: const Radius.circular(AppSpacing.radiusMd),
                      bottomLeft:
                          Radius.circular(isMine ? AppSpacing.radiusMd : 4),
                      bottomRight:
                          Radius.circular(isMine ? 4 : AppSpacing.radiusMd),
                    ),
                    border: isMine
                        ? null
                        : Border.all(color: Theme.of(context).colorScheme.outline),
                  ),
                  clipBehavior: _isImage ? Clip.antiAlias : Clip.none,
                  child: _isImage
                      ? _ImageMessage(url: message.message)
                      : Text(
                          message.message,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: isMine
                                ? AppColors.white
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                ),
                const SizedBox(height: 3),
                Text(
                  formatTime(message.timestamp),
                  style: TextStyle(
                      fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (isMine) ...[
            const SizedBox(width: AppSpacing.sm),
            _UserAvatar(url: myAvatar, name: 'Me', size: 28),
          ],
        ],
      ),
    );
  }
}

class _ImageMessage extends StatelessWidget {
  final String url;
  const _ImageMessage({required this.url});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220, maxHeight: 280),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            width: 220,
            height: 180,
            color: context.colors.neutral100,
            child: Center(
                child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary, strokeWidth: 2)),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          width: 220,
          height: 120,
          color: context.colors.neutral100,
          child: Icon(Icons.broken_image_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant, size: 36),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool hasText;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onImage;

  const _InputBar({
    required this.controller,
    required this.hasText,
    required this.isSending,
    required this.onSend,
    required this.onImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Image picker button
          GestureDetector(
            onTap: isSending ? null : onImage,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.colors.neutral100,
                borderRadius: AppSpacing.brSm,
              ),
              child: Icon(Icons.image_outlined,
                  size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Text input
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: context.colors.neutral100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: TextField(
                controller: controller,
                enabled: !isSending,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: TextStyle(
                    fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: TextStyle(
                      fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 10),
                ),
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Send button
          GestureDetector(
            onTap: isSending ? null : (hasText ? onSend : onImage),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasText ? Theme.of(context).colorScheme.primary : context.colors.neutral200,
                borderRadius: AppSpacing.brSm,
              ),
              child: isSending
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          color: AppColors.white, strokeWidth: 2))
                  : Icon(
                      hasText ? Icons.send_rounded : Icons.camera_alt_rounded,
                      size: 18,
                      color: hasText
                          ? AppColors.white
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: Icon(Icons.chat_bubble_outline_rounded,
                size: 32, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No messages yet',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Say hello!',
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: AppSpacing.md),
          Text(error,
              style: TextStyle(
                  fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.md),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
