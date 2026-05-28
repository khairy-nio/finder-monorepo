import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/socket_service.dart';
import '../../core/services/auth_service.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';

/// Messages Screen - Chat List
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  // Each map holds: id, otherUserName, lastMessage, time, unreadCount, isOnline
  List<Map<String, dynamic>> _chats = [];

  final SocketService _socketService = SocketService();
  String _currentUserId = '';
  late final dynamic Function(dynamic) _eventHandler;

  @override
  void dispose() {
    _socketService.offEvent(_eventHandler);
    _socketService.off('chat_read');
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadChats();
    _eventHandler = (payload) {
      if (mounted) {
        final eventType = payload['event_type'];
        if (eventType == 'conversation.updated') {
          final currentUser = context.read<UserProvider>().backendUser;
          if (currentUser != null) {
            _currentUserId = currentUser.id;
          }
          final data = payload['data'];
          final conversation = payload['conversation'];
          _updateChatList({
            'chat_id': conversation['id'],
            'last_message': data['last_message'],
            'last_message_sender_id': data['last_message_sender_id'],
            'updated_at': payload['emitted_at']
          });
        }
      }
    };
    _initSocket();
  }

  Future<void> _initSocket() async {
    final token = await AuthService.instance.getIdToken();
    if (token != null) {
      _socketService.setAuthToken(token);
      _socketService.connect();

      final userProvider = context.read<UserProvider>();
      if (userProvider.backendUser != null) {
        _currentUserId = userProvider.backendUser!.id;
      }

      _socketService.onEvent(_eventHandler);

      _socketService.on('chat_read', (data) {
        if (mounted) {
          final chatId = data['chat_id'] as String?;
          if (chatId == null) return;
          setState(() {
            final index = _chats.indexWhere((c) => c['id'] == chatId);
            if (index != -1) {
              final chat = Map<String, dynamic>.from(_chats[index]);
              chat['unread_count'] = 0;
              _chats[index] = chat;
            }
          });
        }
      });
    }
  }

  void _updateChatList(dynamic data) {
    final chatId = data['chat_id'] as String?;
    if (chatId == null) return;

    setState(() {
      final index = _chats.indexWhere((c) => c['id'] == chatId);
      if (index != -1) {
        final chat = Map<String, dynamic>.from(_chats[index]);
        final isYou = data['last_message_sender_id'] == _currentUserId;
        final senderName = isYou ? 'You: ' : '${(chat['other_user_name'] as String?)?.split(' ').first ?? ''}: ';
        final preview = '$senderName${data['last_message']}';

        // Update fields
        chat['last_message'] = preview;
        chat['updated_at'] = data['updated_at'];
        
        // Unread logic: Only increment if someone else sent it AND we are not currently viewing the chat
        if (!isYou && _socketService.activeChatId != chatId) {
          chat['unread_count'] = (int.tryParse(chat['unread_count']?.toString() ?? '0') ?? 0) + 1;
        } else if (_socketService.activeChatId == chatId) {
          chat['unread_count'] = 0; // Auto-mark read if we are looking at it
        }

        // Move to top
        _chats.removeAt(index);
        _chats.insert(0, chat);
      } else {
        // Completely new chat not in list yet, refetch securely
        _loadChats();
      }
    });
  }

  Future<void> _loadChats() async {
    try {
      final apiClient = ApiClient(
        tokenProvider: AuthService.instance.getIdToken,
      );
      final dataSource = ChatRemoteDataSourceImpl(apiClient: apiClient);
      final chats = await dataSource.getMyChats();
      if (mounted) {
        setState(() {
          _chats = chats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chats = [];
          _isLoading = false;
        });
      }
    }
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
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search conversations...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              )
            : const Text(
                'Messages',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.black, size: 24),
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
        ],
      ),
      body: Builder(builder: (context) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0A3D91)));
        }

        final filteredChats = _chats.where((chat) {
          final name = (chat['otherUserName'] as String?)?.toLowerCase() ?? '';
          final lastMessage = (chat['lastMessage'] as String?)?.toLowerCase() ?? '';
          return name.contains(_searchQuery) || lastMessage.contains(_searchQuery);
        }).toList();

        if (filteredChats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty ? 'No conversations yet' : 'No matches found',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredChats.length,
          itemBuilder: (context, index) {
            final chat = filteredChats[index];
            return _buildChatItem(context, chat);
          },
        );
      }),
      bottomNavigationBar: SizedBox(
        height: 100,
        child: Stack(
          children: [
            // Color bar positioned in the middle
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A3D91),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
              ),
            ),
            // Icons positioned to overlap the bar
            Positioned(
              left: 0,
              right: 0,
              top: 10,
              bottom: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavButton(Icons.home, false, () {
                    Navigator.pushReplacementNamed(context, '/home');
                  }),
                  _buildNavButton(Icons.chat_bubble_outline, true, () {}),
                  _buildNavButton(Icons.file_upload_outlined, false, () {
                    Navigator.pushNamed(context, '/create-post');
                  }),
                  _buildNavButton(Icons.person, false, () {
                    Navigator.pushNamed(context, '/profile');
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? imageUrl, {double size = 56, double iconSize = 28}) {
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
                color: Colors.grey[300],
                child: Icon(Icons.person, size: iconSize, color: Colors.grey[700]),
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
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.person, size: iconSize, color: Colors.grey[700]),
    );
  }

  Widget _buildChatItem(BuildContext context, Map<String, dynamic> chat) {
    final chatId = chat['id'] as String? ?? '';
    final otherUserId = chat['other_user_id'] as String? ?? '';
    final otherUserName = chat['other_user_name'] as String? ?? 'Unknown';
    final otherUserAvatar = chat['other_user_avatar'] as String?;
    final lastMessage = chat['last_message'] as String? ?? '';
    final time = chat['updated_at'] as String? ?? '';
    final unreadCount = int.tryParse(chat['unread_count']?.toString() ?? '0') ?? 0;
    final isOnline = (chat['is_online'] as bool?) ?? false;
    final post = chat['post'] as Map<String, dynamic>?;
    final postTitle = post?['title'] as String? ?? '';

    // Helper to format time strings (if it's a full ISO date, we want just the time or simple date)
    String displayTime = time;
    try {
      if (time.length > 10) {
        final dt = DateTime.parse(time).toLocal();
        displayTime = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {}

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
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
            'userAvatar': otherUserAvatar,
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
        ),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    _buildAvatar(otherUserAvatar, size: 56, iconSize: 28),
                    if (isOnline)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 14,
                          height: 14,
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
                  child: Padding(
                    padding: const EdgeInsets.only(right: 60.0), // space for time and unread
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otherUserName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        if (postTitle.isNotEmpty)
                          Text(
                            'Re: $postTitle',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: const Color(0xFF0A3D91), fontWeight: FontWeight.w500),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                            fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 0,
              top: 0,
              child: unreadCount > 0
                  ? Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Color(0xFF0A3D91), shape: BoxShape.circle),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Text(
                displayTime,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );  }

  Widget _buildNavButton(IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? const Color(0xFF0A3D91) : Colors.white,
          size: 38,
        ),
      ),
    );
  }
}

