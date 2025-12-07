import 'package:flutter/material.dart';
import '../../../services/doctor_service.dart';
import '../../../services/chat_service.dart';
import '../../../services/auth_service.dart';
import '../../../data/models/doctor_models.dart';
import 'screen_chat_detail.dart';

/// Screen for user to select a doctor by specialty to start a chat
class ScreenSelectDoctorChat extends StatefulWidget {
  const ScreenSelectDoctorChat({super.key});

  @override
  State<ScreenSelectDoctorChat> createState() => _ScreenSelectDoctorChatState();
}

class _ScreenSelectDoctorChatState extends State<ScreenSelectDoctorChat> {
  final _doctorService = DoctorService();
  final _chatService = ChatService();
  final _authService = AuthService();
  
  String _selectedSpecialty = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _startingChatWithDoctorId;

  // List of specialties
  final List<Map<String, dynamic>> _specialties = [
    {'value': 'all', 'label': 'Tất cả', 'icon': Icons.medical_services},
    {'value': 'Tim mạch', 'label': 'Tim mạch', 'icon': Icons.favorite},
    {'value': 'Thần kinh', 'label': 'Thần kinh', 'icon': Icons.psychology},
    {'value': 'Huyết áp', 'label': 'Huyết áp', 'icon': Icons.monitor_heart},
    {'value': 'Nội khoa', 'label': 'Nội khoa', 'icon': Icons.local_hospital},
    {'value': 'Ngoại khoa', 'label': 'Ngoại khoa', 'icon': Icons.healing},
    {'value': 'Đột quỵ', 'label': 'Đột quỵ', 'icon': Icons.emergency},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startChat(DoctorModel doctor) async {
    setState(() => _startingChatWithDoctorId = doctor.doctorId);
    
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Vui lòng đăng nhập để nhắn tin');
      }

      // Create or get existing conversation
      final conversationId = await _chatService.createOrGetConversation(
        userId: userId,
        doctorId: doctor.doctorId,
        doctorName: doctor.name,
      );

      if (conversationId == null) {
        throw Exception('Không thể tạo cuộc trò chuyện');
      }

      if (!mounted) return;

      // Navigate to chat detail
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ScreenChatDetail(
            conversationId: conversationId,
            title: doctor.name,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _startingChatWithDoctorId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chọn bác sĩ để nhắn tin',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bác sĩ...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: bgLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          
          // Specialty Filter
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _specialties.length,
              itemBuilder: (context, index) {
                final specialty = _specialties[index];
                final isSelected = _selectedSpecialty == specialty['value'];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedSpecialty = specialty['value']),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isSelected ? primary : primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            specialty['icon'] as IconData,
                            color: isSelected ? Colors.white : primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          specialty['label'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? primary : textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Doctor List
          Expanded(
            child: StreamBuilder<List<DoctorModel>>(
              stream: _doctorService.getAvailableDoctors(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var doctors = snapshot.data ?? [];

                // Filter by specialty
                if (_selectedSpecialty != 'all') {
                  doctors = doctors.where((d) => d.specialization == _selectedSpecialty).toList();
                }

                // Filter by search query
                if (_searchQuery.isNotEmpty) {
                  doctors = doctors.where((d) => 
                    d.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    (d.specialization?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
                  ).toList();
                }

                if (doctors.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Không tìm thấy bác sĩ nào',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                        if (_selectedSpecialty != 'all') ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => setState(() => _selectedSpecialty = 'all'),
                            child: const Text('Xem tất cả bác sĩ'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = doctors[index];
                    final isStartingChat = _startingChatWithDoctorId == doctor.doctorId;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: isStartingChat ? null : () => _startChat(doctor),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Avatar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  doctor.photoURL ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(doctor.name)}&background=random',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 60,
                                    height: 60,
                                    color: primary.withOpacity(0.1),
                                    child: Icon(Icons.person, size: 30, color: primary),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doctor.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            doctor.specialization ?? 'Chưa cập nhật',
                                            style: TextStyle(
                                              color: primary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (doctor.hospital != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        doctor.hospital!,
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Chat button
                              isStartingChat
                                  ? const SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.chat_bubble_outline,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
