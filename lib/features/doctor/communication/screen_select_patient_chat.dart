import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../services/chat_service.dart';
import '../../../services/auth_service.dart';
import '../../../data/models/user_model.dart';
import 'screen_doctor_chat_detail.dart';

/// Screen for doctor to select an existing patient to start a chat
class ScreenSelectPatientChat extends StatefulWidget {
  const ScreenSelectPatientChat({super.key});

  @override
  State<ScreenSelectPatientChat> createState() => _ScreenSelectPatientChatState();
}

class _ScreenSelectPatientChatState extends State<ScreenSelectPatientChat> {
  final _chatService = ChatService();
  final _authService = AuthService();
  final _db = FirebaseDatabase.instance.ref();
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _startingChatWithPatientId;
  String? _doctorId;
  String? _doctorName;
  
  List<UserModel> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctorAndPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorAndPatients() async {
    try {
      _doctorId = await _authService.getUserId();
      _doctorName = await _authService.getUserName();
      
      if (_doctorId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get patients who have had appointments with this doctor
      // or have existing conversations
      await _loadPatients();
    } catch (e) {
      debugPrint('Error loading doctor info: $e');
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPatients() async {
    try {
      final Set<String> patientIds = {};
      
      // Get patients from appointments
      final appointmentsSnapshot = await _db
          .child('appointments')
          .orderByChild('doctorId')
          .equalTo(_doctorId)
          .get();
      
      if (appointmentsSnapshot.exists) {
        final data = appointmentsSnapshot.value;
        if (data is Map) {
          for (var entry in data.entries) {
            final appointment = Map<String, dynamic>.from(entry.value as Map);
            final userId = appointment['userId'] as String?;
            if (userId != null) {
              patientIds.add(userId);
            }
          }
        }
      }

      // Get patients from existing conversations
      final conversationsSnapshot = await _db
          .child('conversations')
          .orderByChild('doctorId')
          .equalTo(_doctorId)
          .get();
      
      if (conversationsSnapshot.exists) {
        final data = conversationsSnapshot.value;
        if (data is Map) {
          for (var entry in data.entries) {
            final conversation = Map<String, dynamic>.from(entry.value as Map);
            final userId = conversation['userId'] as String?;
            if (userId != null) {
              patientIds.add(userId);
            }
          }
        }
      }

      // Fetch patient details
      final List<UserModel> patients = [];
      for (final patientId in patientIds) {
        final userSnapshot = await _db.child('users').child(patientId).get();
        if (userSnapshot.exists) {
          final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
          // Only include users (not doctors or admins)
          if (userData['role'] == 'user' || userData['role'] == null) {
            patients.add(UserModel.fromJson(userData));
          }
        }
      }

      // Sort by name
      patients.sort((a, b) => a.name.compareTo(b.name));
      
      if (mounted) {
        setState(() => _patients = patients);
      }
    } catch (e) {
      debugPrint('Error loading patients: $e');
    }
  }

  Future<void> _startChat(UserModel patient) async {
    if (_doctorId == null) return;
    
    setState(() => _startingChatWithPatientId = patient.id);
    
    try {
      // Create or get existing conversation
      final conversationId = await _chatService.createOrGetConversation(
        userId: patient.id,
        doctorId: _doctorId!,
        doctorName: _doctorName,
      );

      if (conversationId == null) {
        throw Exception('Không thể tạo cuộc trò chuyện');
      }

      if (!mounted) return;

      // Navigate to chat detail
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ScreenDoctorChatDetail(
            conversationId: conversationId,
            patientName: patient.name,
            userId: patient.id,
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
        setState(() => _startingChatWithPatientId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgLight,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text('Chọn bệnh nhân', style: TextStyle(color: textPrimary)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Filter patients by search query
    var filteredPatients = _patients;
    if (_searchQuery.isNotEmpty) {
      filteredPatients = _patients.where((p) => 
        p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (p.phone?.contains(_searchQuery) ?? false) ||
        (p.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }

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
          'Chọn bệnh nhân để nhắn tin',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
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
                hintText: 'Tìm kiếm bệnh nhân...',
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
          
          // Info banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Danh sách bệnh nhân đã từng đặt lịch hoặc nhắn tin với bạn',
                    style: TextStyle(color: primary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Patient List
          Expanded(
            child: filteredPatients.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty 
                              ? 'Chưa có bệnh nhân nào'
                              : 'Không tìm thấy bệnh nhân',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Bệnh nhân sẽ xuất hiện khi họ đặt lịch\nhoặc nhắn tin với bạn',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[500], fontSize: 14),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredPatients.length,
                    itemBuilder: (context, index) {
                      final patient = filteredPatients[index];
                      final isStartingChat = _startingChatWithPatientId == patient.id;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          onTap: isStartingChat ? null : () => _startChat(patient),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Avatar
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    image: patient.avatarUrl != null
                                        ? DecorationImage(
                                            image: NetworkImage(patient.avatarUrl!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: patient.avatarUrl == null
                                      ? Icon(Icons.person, color: primary, size: 24)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        patient.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: textPrimary,
                                        ),
                                      ),
                                      if (patient.phone != null) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(Icons.phone, size: 14, color: Colors.grey[500]),
                                            const SizedBox(width: 4),
                                            Text(
                                              patient.phone!,
                                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (patient.email != null) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(Icons.email, size: 14, color: Colors.grey[500]),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                patient.email!,
                                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
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
                  ),
          ),
        ],
      ),
    );
  }
}
