import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/chat_service.dart';
import '../../../services/auth_service.dart';
import '../../../data/models/chat_models.dart';
import 'screen_chat_detail.dart';

class ScreenChatList extends StatefulWidget {
  const ScreenChatList({super.key});

  @override
  State<ScreenChatList> createState() => _ScreenChatListState();
}

class _ScreenChatListState extends State<ScreenChatList> {
  final _chatService = ChatService();
  final _authService = AuthService();
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userId = await _authService.getUserId();
    setState(() => _userId = userId);
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (diff.inDays == 1) {
      return 'Hôm qua';
    } else if (diff.inDays < 7) {
      // Use default locale instead of vi_VN
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('dd/MM').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const textPrimary = Color(0xFF111318);

    if (_userId == null) {
      return Scaffold(
        backgroundColor: bgLight,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text('Trò chuyện'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Trò chuyện',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<List<ConversationModel>>(
        stream: _chatService.getUserConversations(_userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có cuộc trò chuyện nào',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return _ConversationItem(
                title: conversation.doctorName ?? 'Bác sĩ',
                subtitle: conversation.lastMessage ?? 'Chưa có tin nhắn',
                time: _formatTime(conversation.lastMessageTime),
                unread: conversation.userUnreadCount,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ScreenChatDetail(
                        conversationId: conversation.conversationId,
                        title: conversation.doctorName ?? 'Bác sĩ',
                      ),
                    ),
                  );
                  // Mark as read when returning
                  await _chatService.markAsRead(
                    conversation.conversationId,
                    _userId!,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ConversationItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final int unread;
  final VoidCallback onTap;

  const _ConversationItem({
    required this.title,
    required this.subtitle,
    required this.time,
    this.unread = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const divider = Color(0xFFE5E7EB);
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF777777);
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: divider)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.person, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: const TextStyle(color: textMuted, fontSize: 12),
                ),
                if (unread > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B6B),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}