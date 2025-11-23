import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../widgets/app_bottom_nav.dart';
import '../../../widgets/app_drawer.dart';
import '../../../services/auth_service.dart';

class ScreenDoctorsHub extends StatefulWidget {
  const ScreenDoctorsHub({super.key});

  @override
  State<ScreenDoctorsHub> createState() => _ScreenDoctorsHubState();
}

class _ScreenDoctorsHubState extends State<ScreenDoctorsHub> {
  final _authService = AuthService();
  final _database = FirebaseDatabase.instance.ref();
  
  String _userName = 'User';
  String? _userId;
  int _appointmentsCount = 0;
  int _messagesCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final name = await _authService.getUserName();
    final userId = await _authService.getUserId();
    
    if (mounted) {
      setState(() {
        _userName = name;
        _userId = userId;
      });
    }

    if (userId != null) {
      await Future.wait([
        _loadAppointmentsCount(userId),
        _loadMessagesCount(userId),
      ]);
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAppointmentsCount(String userId) async {
    try {
      final snapshot = await _database.child('appointments').get();
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        int count = 0;
        
        data.forEach((key, value) {
          final appointment = Map<String, dynamic>.from(value as Map);
          if (appointment['userId'] == userId) {
            final status = appointment['status'] as String?;
            // Count only upcoming/confirmed appointments
            if (status == 'confirmed' || status == 'pending') {
              count++;
            }
          }
        });
        
        if (mounted) {
          setState(() => _appointmentsCount = count);
        }
      }
    } catch (e) {
      print('Error loading appointments count: $e');
    }
  }

  Future<void> _loadMessagesCount(String userId) async {
    try {
      final snapshot = await _database.child('conversations').get();
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        int count = 0;
        
        data.forEach((key, value) {
          final conversation = Map<String, dynamic>.from(value as Map);
          if (conversation['userId'] == userId) {
            final unreadCount = conversation['userUnreadCount'] as int? ?? 0;
            count += unreadCount;
          }
        });
        
        if (mounted) {
          setState(() => _messagesCount = count);
        }
      }
    } catch (e) {
      print('Error loading messages count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFFEF4444);
    const textPrimary = Color(0xFF111318);

    return Scaffold(
      drawer: AppDrawer(userName: _userName),
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: textPrimary, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Bác sĩ',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primary.withOpacity(0.1), Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.medical_services_rounded, color: primary, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Trung tâm Bác sĩ',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Kết nối với bác sĩ và quản lý lịch hẹn',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Main Features
                    const Text(
                      'Tính năng chính',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _FeatureCard(
                      icon: Icons.chat_bubble_rounded,
                      title: 'Chat Bác sĩ',
                      subtitle: 'Tư vấn trực tuyến với bác sĩ',
                      color: const Color(0xFF135BEC),
                      badge: _messagesCount > 0 ? '$_messagesCount' : null,
                      onTap: () => Navigator.pushNamed(context, '/chat'),
                    ),
                    const SizedBox(height: 12),

                    _FeatureCard(
                      icon: Icons.videocam_rounded,
                      title: 'Cuộc gọi Video',
                      subtitle: 'Đang phát triển',
                      color: const Color(0xFF10B981),
                      isComingSoon: true,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tính năng đang phát triển')),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    _FeatureCard(
                      icon: Icons.calendar_today_rounded,
                      title: 'Lịch hẹn & Báo cáo',
                      subtitle: 'Quản lý lịch hẹn và tạo báo cáo',
                      color: const Color(0xFFF59E0B),
                      badge: _appointmentsCount > 0 ? '$_appointmentsCount' : null,
                      onTap: () => Navigator.pushNamed(context, '/report-appointment'),
                    ),
                    const SizedBox(height: 12),

                    _FeatureCard(
                      icon: Icons.star_rounded,
                      title: 'Đánh giá Bác sĩ',
                      subtitle: 'Xem và đánh giá bác sĩ',
                      color: const Color(0xFF8B5CF6),
                      onTap: () => Navigator.pushNamed(context, '/doctor-list'),
                    ),
                    const SizedBox(height: 24),

                    // Quick Stats
                    const Text(
                      'Thống kê nhanh',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _StatCard(
                          title: 'Lịch hẹn',
                          value: '$_appointmentsCount',
                          icon: Icons.calendar_today,
                          color: const Color(0xFFF59E0B),
                        ),
                        _StatCard(
                          title: 'Tin nhắn mới',
                          value: '$_messagesCount',
                          icon: Icons.chat_bubble,
                          color: const Color(0xFF135BEC),
                        ),
                      ],
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final String? badge;
  final bool isComingSoon;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badge,
    this.isComingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                if (badge != null)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111318),
                        ),
                      ),
                      if (isComingSoon) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Soon',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
