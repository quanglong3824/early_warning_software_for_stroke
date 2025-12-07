import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/chat_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/appointment_service.dart';
import '../../../services/doctor_schedule_service.dart';
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
  final _appointmentService = AppointmentService();
  final _scheduleService = DoctorScheduleService();
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

  /// Show appointment booking dialog for doctor to schedule appointment with patient
  Future<void> _showAppointmentDialog() async {
    if (_doctorId == null) return;

    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeSlot? selectedSlot;
    List<TimeSlot> availableSlots = [];
    bool isLoadingSlots = true;
    final reasonController = TextEditingController();
    final locationController = TextEditingController(text: 'Phòng khám');

    // Load available slots for initial date
    Future<void> loadSlots(DateTime date, StateSetter setDialogState) async {
      setDialogState(() => isLoadingSlots = true);
      try {
        final slots = await _scheduleService.getAvailableSlots(_doctorId!, date);
        setDialogState(() {
          availableSlots = slots;
          selectedSlot = null;
          isLoadingSlots = false;
        });
      } catch (e) {
        setDialogState(() {
          availableSlots = [];
          isLoadingSlots = false;
        });
      }
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Load slots on first build
            if (isLoadingSlots && availableSlots.isEmpty) {
              loadSlots(selectedDate, setDialogState);
            }

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Color(0xFF135BEC)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Đặt lịch hẹn',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF135BEC).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person, color: Color(0xFF135BEC)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Bệnh nhân: ${widget.patientName}',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date picker
                      const Text('Chọn ngày:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (date != null) {
                            setDialogState(() => selectedDate = date);
                            loadSlots(date, setDialogState);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 20),
                              const SizedBox(width: 8),
                              Text(DateFormat('EEEE, dd/MM/yyyy', 'vi').format(selectedDate)),
                              const Spacer(),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Time slots
                      const Text('Chọn giờ:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (isLoadingSlots)
                        const Center(child: CircularProgressIndicator())
                      else if (availableSlots.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Không có lịch trống trong ngày này. Vui lòng chọn ngày khác.',
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: availableSlots.map((slot) {
                            final isSelected = selectedSlot == slot;
                            final timeStr = '${slot.startTime.hour.toString().padLeft(2, '0')}:${slot.startTime.minute.toString().padLeft(2, '0')}';
                            return ChoiceChip(
                              label: Text(timeStr),
                              selected: isSelected,
                              onSelected: (selected) {
                                setDialogState(() => selectedSlot = selected ? slot : null);
                              },
                              selectedColor: const Color(0xFF135BEC),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16),

                      // Location
                      const Text('Địa điểm:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: locationController,
                        decoration: InputDecoration(
                          hintText: 'Nhập địa điểm khám',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Reason
                      const Text('Lý do khám:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: reasonController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Nhập lý do khám (tùy chọn)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: selectedSlot == null
                      ? null
                      : () async {
                          Navigator.pop(dialogContext);
                          await _createAppointment(
                            selectedDate,
                            selectedSlot!,
                            locationController.text,
                            reasonController.text,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF135BEC),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Đặt lịch'),
                ),
              ],
            );
          },
        );
      },
    );

    reasonController.dispose();
    locationController.dispose();
  }

  /// Create appointment and send message to chat
  Future<void> _createAppointment(
    DateTime date,
    TimeSlot slot,
    String location,
    String reason,
  ) async {
    if (_doctorId == null) return;

    try {
      // Combine date and time
      final appointmentTime = DateTime(
        date.year,
        date.month,
        date.day,
        slot.startTime.hour,
        slot.startTime.minute,
      );

      // Create appointment
      final appointmentId = await _appointmentService.createAppointment(
        userId: widget.userId,
        doctorId: _doctorId!,
        doctorName: _doctorName,
        appointmentTime: appointmentTime.millisecondsSinceEpoch,
        location: location.isNotEmpty ? location : 'Phòng khám',
        reason: reason.isNotEmpty ? reason : 'Khám theo lịch hẹn',
      );

      if (appointmentId != null) {
        // Confirm appointment immediately since doctor created it
        await _appointmentService.confirmAppointment(appointmentId);

        // Send appointment message to chat
        final formattedDate = DateFormat('EEEE, dd/MM/yyyy', 'vi').format(appointmentTime);
        final formattedTime = '${slot.startTime.hour.toString().padLeft(2, '0')}:${slot.startTime.minute.toString().padLeft(2, '0')}';
        
        await _chatService.sendMessage(
          conversationId: widget.conversationId,
          senderId: _doctorId!,
          senderName: _doctorName,
          message: '📅 Đã đặt lịch hẹn khám\n\n'
              '📆 Ngày: $formattedDate\n'
              '⏰ Giờ: $formattedTime\n'
              '📍 Địa điểm: ${location.isNotEmpty ? location : 'Phòng khám'}\n'
              '${reason.isNotEmpty ? '📝 Lý do: $reason' : ''}',
          type: 'appointment',
        );

        _scrollToBottom();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã đặt lịch hẹn thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Không thể tạo lịch hẹn');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
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
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF135BEC).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calendar_month, color: Color(0xFF135BEC)),
                ),
                title: const Text('Đặt lịch hẹn'),
                onTap: () {
                  Navigator.pop(context);
                  _showAppointmentDialog();
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
