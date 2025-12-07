import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/chat_service.dart';
import '../../../services/auth_service.dart';
import '../../../data/models/chat_models.dart';

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
  final _imagePicker = ImagePicker();
  
  String? _doctorId;
  String? _doctorName;
  bool _isSendingMedia = false;

  @override
  void initState() {
    super.initState();
    _loadDoctor();
    _markAsRead();
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


  /// Mark conversation as read when opening
  /// Requirements: 4.6
  Future<void> _markAsRead() async {
    final doctorId = await _authService.getUserId();
    if (doctorId != null) {
      await _chatService.markConversationAsRead(widget.conversationId, doctorId);
    }
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

  /// Send image message
  /// Requirements: 4.3, 4.5
  Future<void> _sendImage() async {
    if (_doctorId == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      setState(() => _isSendingMedia = true);

      final file = File(pickedFile.path);
      await _chatService.sendMediaMessage(
        conversationId: widget.conversationId,
        senderId: _doctorId!,
        senderName: _doctorName,
        file: file,
        mediaType: 'image',
      );

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gửi hình ảnh: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingMedia = false);
      }
    }
  }

  /// Take photo from camera
  Future<void> _takePhoto() async {
    if (_doctorId == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      setState(() => _isSendingMedia = true);

      final file = File(pickedFile.path);
      await _chatService.sendMediaMessage(
        conversationId: widget.conversationId,
        senderId: _doctorId!,
        senderName: _doctorName,
        file: file,
        mediaType: 'image',
      );

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chụp ảnh: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingMedia = false);
      }
    }
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
    // Feature removed - prescription dialog no longer available
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tính năng đơn thuốc đã được tắt')),
      );
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.blue),
                ),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _sendImage();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.green),
                ),
                title: const Text('Chụp ảnh'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.medical_services, color: Colors.orange),
                ),
                title: const Text('Tạo đơn thuốc'),
                onTap: () {
                  Navigator.pop(context);
                  _createPrescription();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('HH:mm').format(date);
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Hôm nay';
    } else if (diff.inDays == 1) {
      return 'Hôm qua';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
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
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/doctor/dashboard');
            }
          },
        ),
        title: Row(
          children: [
            // Avatar with online status
            Stack(
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
                // Online status indicator - real-time
                StreamBuilder<bool>(
                  stream: _chatService.getPatientOnlineStatus(widget.userId),
                  builder: (context, snapshot) {
                    final isOnline = snapshot.data ?? false;
                    if (!isOnline) return const SizedBox.shrink();
                    return Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    );
                  },
                ),
              ],
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
                  // Online status text - real-time
                  StreamBuilder<bool>(
                    stream: _chatService.getPatientOnlineStatus(widget.userId),
                    builder: (context, snapshot) {
                      final isOnline = snapshot.data ?? false;
                      return Text(
                        isOnline ? 'Đang hoạt động' : 'Bệnh nhân',
                        style: TextStyle(
                          color: isOnline ? Colors.green : Colors.grey,
                          fontSize: 12,
                        ),
                      );
                    },
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
          // Loading indicator for media upload
          if (_isSendingMedia)
            Container(
              padding: const EdgeInsets.all(8),
              color: primary.withOpacity(0.1),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Đang gửi hình ảnh...'),
                ],
              ),
            ),
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

                // Group messages by date
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _doctorId;
                    
                    // Show date separator
                    Widget? dateSeparator;
                    if (index == 0 || 
                        _formatDate(messages[index - 1].timestamp) != _formatDate(message.timestamp)) {
                      dateSeparator = _buildDateSeparator(message.timestamp);
                    }
                    
                    return Column(
                      children: [
                        if (dateSeparator != null) dateSeparator,
                        _buildMessageBubble(message, isMe, primary, textPrimary),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(bgLight, primary),
        ],
      ),
    );
  }


  Widget _buildDateSeparator(int timestamp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatDate(timestamp),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    MessageModel message,
    bool isMe,
    Color primary,
    Color textPrimary,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
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
            child: _buildMessageContent(message, isMe, primary, textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(
    MessageModel message,
    bool isMe,
    Color primary,
    Color textPrimary,
  ) {
    // Prescription message
    if (message.type == 'prescription') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                const Text('Đơn thuốc', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
            const SizedBox(height: 8),
            Text(message.message),
            const SizedBox(height: 4),
            Text(_formatTime(message.timestamp), style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      );
    }

    // Image message
    if (message.type == 'image') {
      return Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showFullImage(message.message),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  message.message,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 150,
                      height: 150,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 150,
                      height: 150,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(message.timestamp),
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      );
    }

    // Text message
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  color: isMe ? Colors.white.withOpacity(0.7) : Colors.grey,
                  fontSize: 11,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(
                  message.isRead ? Icons.done_all : Icons.done,
                  size: 14,
                  color: message.isRead 
                      ? Colors.lightBlueAccent 
                      : Colors.white.withOpacity(0.7),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(imageUrl),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(Color bgLight, Color primary) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Attachment button
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.grey),
            onPressed: _showAttachmentOptions,
            tooltip: 'Đính kèm',
          ),
          const SizedBox(width: 4),
          // Text input
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
          // Send button
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
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
    );
  }
}
