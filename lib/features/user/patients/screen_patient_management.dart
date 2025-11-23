import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/family_service.dart';
import '../../../data/models/user_model.dart'; // Assuming FamilyMember is mapped to UserModel or similar

class ScreenPatientManagement extends StatefulWidget {
  const ScreenPatientManagement({super.key});

  @override
  State<ScreenPatientManagement> createState() => _ScreenPatientManagementState();
}

class _ScreenPatientManagementState extends State<ScreenPatientManagement> {
  final _authService = AuthService();
  final _familyService = FamilyService();
  
  // Since FamilyService returns Stream<List<Map<String, dynamic>>>, we'll use that.
  // Ideally, we should have a FamilyMemberModel.
  
  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF1C1C1E);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: bgLight,
        elevation: 0.5,
        title: const Text(
          'Quản lý Hồ sơ Người thân',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Navigate to search or add member
            },
            icon: const Icon(Icons.search, color: textPrimary),
          ),
        ],
      ),
      body: FutureBuilder<String?>(
        future: _authService.getUserId(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final userId = snapshot.data!;

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _familyService.getFamilyMembers(userId).asStream(), // Convert Future to Stream or use FutureBuilder
            // Actually, getFamilyMembers returns Future<List<...>> in FamilyService? Let's check.
            // If it returns Future, use FutureBuilder.
            // The error says: argument type 'Future<...>' can't be assigned to 'Stream<...>?'.
            // So getFamilyMembers returns Future.
            // I should use FutureBuilder.
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Lỗi: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final members = snapshot.data ?? [];

              if (members.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có hồ sơ người thân nào',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to add member screen (ScreenFamilyManagement handles invitations)
                          // Or show dialog to add
                          Navigator.pushNamed(context, '/family-management');
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm người thân'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  // Map data to display
                  final name = member['name'] ?? 'Không tên';
                  final role = member['role'] == 'admin' ? 'Quản trị viên' : 'Thành viên';
                  final photoUrl = member['photoUrl'] ?? ''; // Check field name in FamilyService
                  
                  return _PatientCard(
                    name: name,
                    info: role,
                    imageUrl: photoUrl,
                    onTap: () {
                      // Navigate to detail or health record of this member
                      // For now, just show snackbar or navigate to profile
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/family-management'),
        backgroundColor: primary,
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final String name;
  final String info;
  final String imageUrl;
  final VoidCallback onTap;

  const _PatientCard({
    required this.name,
    required this.info,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
              child: imageUrl.isEmpty ? const Icon(Icons.person, size: 30) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    info,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFC7C7CC)),
          ],
        ),
      ),
    );
  }
}