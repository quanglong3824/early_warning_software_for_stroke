import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/chat_service.dart';
import '../../../services/auth_service.dart';
import '../../../data/models/chat_models.dart';
import 'dialogs/create_prescription_dialog.dart';
import 'widgets/prescription_message_widget.dart';

class ScreenDoctorChatDetail extends StatefulWidget {
  final String conversationId;
  final String patientName;
  final String userId;

  const ScreenDoctorChatDetail({
    super.key,
    required this.conversationId,
    required this.patientName,
    required this.userId,
  });

  @override
  State<ScreenDoctorChatDetail> createState() => _ScreenDoctorChatDetailState();
}

class _ScreenDoctorChatDetailState extends State<ScreenDoctorChatDetail> {
  final _chatService = ChatService();
  final _authService = AuthService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  
  String? _doctorId;
  String? _doctorName;

  @override
  void initState() {
    super.initState();
    _loadDoctor();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctor() async {
    final doctorId = await _authService.getUserId();
    final doctorName = await _authService.getUserName();
    setState(() {
      _doctorId = doctorId;
      _doctorName = doctorName;
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _doctorId == null) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    await _chatService.sendMessage(
      conversationId: widget.conversationId,
      senderId: _doctorId!,
      senderName: _doctorName,
      message: message,
    );

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _createPrescription() async {
    if (_doctorId == null || _doctorName == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CreatePrescriptionDialog(
        conversationId: widget.conversationId,
        userId: widget.userId,
        patientName: widget.patientName,
        doctorId: _doctorId!,
        doctorName: _doctorName!,
      ),
    );

    if (result == true) {
      _scrollToBottom();
    }
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);

    if (_doctorId == null) {
      return Scaffold(
        backgroundColor: bgLight,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: Text(widget.patientName),
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
          onPressed: () {
            // Navigate back to doctor dashboard instead of pop
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/doctor/dashboard');
            }
          },
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(Icons.person, color: primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.patientName,
                    style: const TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Text(
                    'Bệnh nhân',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.medical_services, color: primary),
            onPressed: _createPrescription,
            tooltip: 'Tạo đơn thuốc',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Chưa có tin nhắn nào\nGửi tin nhắn đầu tiên!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _doctorId;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMe) ...[
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.person, color: Colors.blue, size: 16),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: message.type == 'prescription'
                                ? PrescriptionMessageWidget(
                                    message: message,
                                    isDoctor: true,
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isMe ? primary : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: isMe
                                          ? null
                                          : [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.05),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message.message,
                                          style: TextStyle(
                                            color: isMe ? Colors.white : textPrimary,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatTime(message.timestamp),
                                          style: TextStyle(
                                            color: isMe
                                                ? Colors.white.withOpacity(0.7)
                                                : Colors.grey,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.medical_services, color: primary),
                  onPressed: _createPrescription,
                  tooltip: 'Tạo đơn thuốc',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgLight,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
