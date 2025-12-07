import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../widgets/doctor_bottom_nav.dart';
import '../../../services/chat_service.dart';
import '../../../services/auth_service.dart';
import '../../../data/models/chat_models.dart';
import 'screen_doctor_chat_detail.dart';
import 'screen_select_patient_chat.dart';

class ScreenDoctorChat extends StatefulWidget {
  const ScreenDoctorChat({super.key});

  @override
  State<ScreenDoctorChat> createState() => _ScreenDoctorChatState();
}

class _ScreenDoctorChatState extends State<ScreenDoctorChat> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  
  String? _doctorId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctorId();
  }

  Future<void> _loadDoctorId() async {
    final doctorId = await _authService.getUserId();
    setState(() {
      _doctorId = doctorId;
      _isLoading = false;
    });
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
      return DateFormat('EEEE', 'vi').format(date);
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    const textSecondary = Color(0xFF6B7280);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgLight,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text('Tin nhắn', style: TextStyle(color: textPrimary)),
        ),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: const DoctorBottomNav(currentIndex: -1),
      );
    }

    if (_doctorId == null) {
      return Scaffold(
        backgroundColor: bgLight,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text('Tin nhắn', style: TextStyle(color: textPrimary)),
        ),
        body: const Center(
          child: Text('Không thể tải thông tin bác sĩ'),
        ),
        bottomNavigationBar: const DoctorBottomNav(currentIndex: -1),
      );
    }

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Tin nhắn',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Show total unread count
          StreamBuilder<int>(
            stream: _chatService.getUnreadCount(_doctorId!),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              if (unreadCount == 0) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount chưa đọc',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ConversationModel>>(
        stream: _chatService.getDoctorConversations(_doctorId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có cuộc trò chuyện nào',
                    style: TextStyle(
                      fontSize: 16,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bệnh nhân sẽ liên hệ với bạn qua đây',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return _buildConversationTile(
                context,
                conversation,
                primary,
                textPrimary,
                textSecondary,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ScreenSelectPatientChat(),
            ),
          );
        },
        backgroundColor: primary,
        icon: const Icon(Icons.add_comment, color: Colors.white),
        label: const Text('Nhắn tin mới', style: TextStyle(color: Colors.white)),
      ),
      bottomNavigationBar: const DoctorBottomNav(currentIndex: -1),
    );
  }


  Widget _buildConversationTile(
    BuildContext context,
    ConversationModel conversation,
    Color primary,
    Color textPrimary,
    Color textSecondary,
  ) {
    final patientName = conversation.patientName ?? 'Bệnh nhân';
    final hasUnread = conversation.doctorUnreadCount > 0;
    final isOnline = conversation.isOnline;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: hasUnread ? primary.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.15),
                shape: BoxShape.circle,
                image: conversation.patientAvatar != null
                    ? DecorationImage(
                        image: NetworkImage(conversation.patientAvatar!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: conversation.patientAvatar == null
                  ? Icon(Icons.person, color: primary, size: 24)
                  : null,
            ),
            // Online indicator
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                patientName,
                style: TextStyle(
                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                  color: textPrimary,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _formatTime(conversation.lastMessageTime),
              style: TextStyle(
                fontSize: 12,
                color: hasUnread ? primary : textSecondary,
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                conversation.lastMessage ?? 'Bắt đầu cuộc trò chuyện',
                style: TextStyle(
                  color: hasUnread ? textPrimary : textSecondary,
                  fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasUnread)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${conversation.doctorUnreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScreenDoctorChatDetail(
                conversationId: conversation.conversationId,
                patientName: patientName,
                userId: conversation.userId,
              ),
            ),
          );
        },
      ),
    );
  }
}
