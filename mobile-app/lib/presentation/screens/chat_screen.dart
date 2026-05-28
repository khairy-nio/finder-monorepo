import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_client.dart';
import '../../core/network/socket_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/app_messenger.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../../data/datasources/user_remote_data_source.dart';
import '../../domain/entities/chat_message.dart';
import '../../data/models/chat_message_model.dart';
import '../providers/user_provider.dart';

/// Individual Chat Screen — wired to real backend API and Socket.io.
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
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasText = false;

  // State
  List<ChatMessage> _messages = [];
  bool _isLoadingMessages = true;
  bool _isSending = false;
  String? _error;
  String? _otherUserAvatar;

  // Data source & Socket
  late final ChatRemoteDataSource _dataSource;
  final SocketService _socketService = SocketService();
  // Postgres UUID of the current user — resolved async to avoid
  // initState race against UserProvider.loadUser().
  String _currentUserId = '';
  late bool _isUserOnline;

  late final dynamic Function(dynamic) _messageHandler;
  late final dynamic Function(dynamic) _statusHandler;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(
      tokenProvider: AuthService.instance.getIdToken,
    );
    _dataSource = ChatRemoteDataSourceImpl(apiClient: apiClient);
    _isUserOnline = widget.isOnline ?? false;
    _otherUserAvatar = widget.userAvatar;

    // Resolve the backend Postgres UUID asynchronously.
    // Do NOT rely on initState-time provider read — UserProvider may not
    // have completed loadUser() yet when navigating directly to ChatScreen.
    _resolveCurrentUserId();

    _messageController.addListener(() {
      setState(() {
        _hasText = _messageController.text.trim().isNotEmpty;
      });
    });

    if (widget.chatId != null) {
      _socketService.activeChatId = widget.chatId;
      _loadMessages();
      _initSocket();
      // Mark chat as read immediately so sender's own chat shows no badge
      _markAsRead();
    } else {
      setState(() {
        _isLoadingMessages = false;
        _error = 'No chat ID provided.';
      });
    }
  }

  Future<void> _resolveCurrentUserId() async {
    // 1. Try to get it from the provider (fast path)
    final providerUser = context.read<UserProvider>().backendUser;
    if (providerUser != null) {
      if (mounted) setState(() => _currentUserId = providerUser.id);
      return;
    }

    // 2. Not loaded yet? Fetch it directly to ensure we have the Postgres UUID
    try {
      final apiClient = ApiClient(tokenProvider: AuthService.instance.getIdToken);
      final userDataSource = UserRemoteDataSourceImpl(apiClient: apiClient);
      final user = await userDataSource.fetchMe();
      if (mounted) setState(() => _currentUserId = user.id);
    } catch (e) {
      debugPrint('[ChatScreen] Error resolving current user ID: $e');
      // Fallback to Firebase UID if REST fails, though this will likely cause isMine to fail
      if (mounted) {
        setState(() => _currentUserId = AuthService.instance.currentUser?.uid ?? '');
      }
    }
  }

  Future<void> _initSocket() async {
    final token = await AuthService.instance.getIdToken();
    if (token != null) {
      _socketService.setAuthToken(token);
      _socketService.connect();
      
      _socketService.joinChat(widget.chatId!);

      _messageHandler = (payload) {
        if (mounted) {
          final eventType = payload['event_type'];
          if (eventType == 'message.created') {
            final data = payload['data']['message'];
            setState(() {
              _messages.removeWhere((m) => m.id.startsWith('temp-') && m.message == data['content']);
              if (!_messages.any((m) => m.id == data['id'])) {
                _messages.add(ChatMessageModel.fromJson(data));
                _scrollToBottom();
              }
            });
          }
        }
      };

      _statusHandler = (data) {
        if (mounted && widget.userId != null && data['userId'] == widget.userId) {
          setState(() {
            _isUserOnline = data['status'] == 'online';
          });
        }
      };

      _socketService.onEvent(_messageHandler);
      _socketService.on('user_status', _statusHandler);

      if (widget.userId != null) {
        _socketService.checkUserStatus(widget.userId!);
      }
    }
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
    // Do NOT disconnect singleton, allow other screens to use it
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoadingMessages = true;
      _error = null;
    });
    try {
      if (widget.chatId != null) {
        final metadata = await _dataSource.getChatMetadata(widget.chatId!);
        if (metadata != null && mounted) {
          setState(() {
            _otherUserAvatar = metadata['other_user_avatar'] as String?;
          });
        }
      }

      final messages = await _dataSource.getChatMessages(widget.chatId!);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoadingMessages = false;
        });
        _scrollToBottom();
        // Mark read after messages are loaded
        _markAsRead();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load messages.';
          _isLoadingMessages = false;
        });
      }
    }
  }

  /// Tells the backend to reset unread count for this user in this chat.
  Future<void> _markAsRead() async {
    if (widget.chatId == null) return;
    try {
      await _dataSource.markAsRead(widget.chatId!, _currentUserId);
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || widget.chatId == null || _isSending) return;

    // Optimistic update
    final optimistic = ChatMessageModel(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      chatId: widget.chatId!,
      senderId: _currentUserId,
      message: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(optimistic);
      _isSending = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      // Send via REST API, which triggers backend to emit 'new_message' via socket
      final sent = await _dataSource.sendMessage(
        chatId: widget.chatId!,
        senderId: _currentUserId,
        message: text,
      );

      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.id == optimistic.id);
          if (!_messages.any((m) => m.id == sent.id)) {
            _messages.add(sent);
          }
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
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) return;

    final optimistic = ChatMessageModel(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      chatId: widget.chatId!,
      senderId: _currentUserId,
      message: '📷 Uploading image...',
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(optimistic);
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final token = await AuthService.instance.getIdToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/chat/upload-image'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('image', file.path));
      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final urlMatch = RegExp(r'"url"\s*:\s*"([^"]+)"').firstMatch(resp.body);
        final imageUrl = urlMatch?.group(1) ?? '';
        if (imageUrl.isNotEmpty) {
          final sent = await _dataSource.sendMessage(
            chatId: widget.chatId!,
            senderId: _currentUserId,
            message: imageUrl,
          );
          if (mounted) {
            setState(() {
              _messages.removeWhere((m) => m.id == optimistic.id);
              if (!_messages.any((m) => m.id == sent.id)) {
                _messages.add(sent);
              }
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildAvatar(String? imageUrl, {double size = 56, double iconSize = 28, bool isMine = false}) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Image.network(
            imageUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: isMine ? const Color(0xFF0A3D91) : Colors.grey[300],
                child: Icon(Icons.person, size: iconSize, color: isMine ? Colors.white : Colors.grey[700]),
              );
            },
          ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isMine ? const Color(0xFF0A3D91) : Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.person, size: iconSize, color: isMine ? Colors.white : Colors.grey[700]),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                Stack(
                  children: [
                    _buildAvatar(_otherUserAvatar, size: 45, iconSize: 24),
                    if (_isUserOnline)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.userName ?? 'Chat',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _isUserOnline ? 'Online' : 'Offline',
                        style: const TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'report') {
                    Navigator.pushNamed(
                      context,
                      '/report-problem',
                      arguments: {
                        'reportType': 'chat',
                        'targetId': widget.chatId,
                        'targetName': widget.userName ?? 'Chat',
                      },
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.report_problem, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Report Chat'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Date Badge
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0A3D91),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Today',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Messages
          Expanded(
            child: _isLoadingMessages
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0A3D91)),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Colors.grey[400], size: 48),
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _loadMessages,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 56,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No messages yet.\nSay hello!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              // isMine: sender_id (Postgres UUID) must exactly match
                              // current user's backend UUID — no fallback OR clause.
                              final isMine = msg.senderId == _currentUserId;
                              return _buildMessageBubble(msg, isMine);
                            },
                          ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _messageController,
                      enabled: !_isSending,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isSending
                      ? null
                      : (_hasText ? _sendMessage : _pickAndSendImage),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: (_hasText && !_isSending)
                          ? const Color(0xFF0A3D91)
                          : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: _isSending
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            _hasText ? Icons.send : Icons.camera_alt,
                            color: _hasText ? Colors.white : Colors.grey[500],
                            size: 22,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMine) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine)
            _buildAvatar(_otherUserAvatar, size: 32, iconSize: 16),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMine ? const Color(0xFF0A3D91) : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMine ? 16 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (message.message.startsWith('http') && message.message.contains('res.cloudinary.com'))
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            message.message,
                            width: 200,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const SizedBox(
                                height: 150,
                                width: 200,
                                child: Center(child: CircularProgressIndicator()),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
                          ),
                        )
                      else
                        Text(
                          message.message,
                          style: TextStyle(
                            fontSize: 14,
                            color: isMine ? Colors.white : Colors.black87,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMine ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isMine)
            Builder(
              builder: (context) {
                final myUser = context.read<UserProvider>().backendUser;
                final myAvatar = myUser?.profileImageUrl ?? myUser?.selfieImageUrl;
                return _buildAvatar(myAvatar, size: 32, iconSize: 16, isMine: true);
              },
            ),
        ],
      ),
    );
  }
}
