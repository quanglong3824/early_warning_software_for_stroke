import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../widgets/app_bottom_nav.dart';
import '../../../widgets/app_drawer.dart';
import '../../../services/auth_service.dart';

class ScreenHealthHub extends StatefulWidget {
  const ScreenHealthHub({super.key});

  @override
  State<ScreenHealthHub> createState() => _ScreenHealthHubState();
}

class _ScreenHealthHubState extends State<ScreenHealthHub> {
  final _authService = AuthService();
  final _database = FirebaseDatabase.instance.ref();
  
  String _userName = 'User';
  String? _userId;
  int _totalPredictions = 0;
  int _highRiskCount = 0;
  int _familyMembersCount = 0;
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
        _loadPredictionStats(userId),
        _loadFamilyCount(userId),
      ]);
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPredictionStats(String userId) async {
    try {
      final snapshot = await _database.child('predictions').get();
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        int total = 0;
        int highRisk = 0;
        
        data.forEach((key, value) {
          final prediction = Map<String, dynamic>.from(value as Map);
          if (prediction['userId'] == userId) {
            total++;
            final riskLevel = prediction['riskLevel'] as String?;
            if (riskLevel == 'high') {
              highRisk++;
            }
          }
        });
        
        if (mounted) {
          setState(() {
            _totalPredictions = total;
            _highRiskCount = highRisk;
          });
        }
      }
    } catch (e) {
      print('Error loading prediction stats: $e');
    }
  }

  Future<void> _loadFamilyCount(String userId) async {
    try {
      final snapshot = await _database.child('family_groups').get();
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        int count = 0;
        
        data.forEach((groupId, groupData) {
          final group = Map<String, dynamic>.from(groupData as Map);
          if (group['creatorId'] == userId) {
            // Count members in this group
            final membersSnapshot = _database.child('family_group_members').child(groupId);
            membersSnapshot.get().then((memberData) {
              if (memberData.exists) {
                final members = Map<String, dynamic>.from(memberData.value as Map);
                count += members.length;
                if (mounted) {
                  setState(() => _familyMembersCount = count);
                }
              }
            });
          }
        });
      }
    } catch (e) {
      print('Error loading family count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF10B981);
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
          'Sức khỏe',
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
                            child: Icon(Icons.favorite_rounded, color: primary, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Trung tâm Sức khỏe',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Theo dõi và quản lý sức khỏe của bạn',
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
                      icon: Icons.analytics_rounded,
                      title: 'Dự đoán Nguy cơ',
                      subtitle: 'Đánh giá nguy cơ đột quỵ và tiểu đường',
                      color: const Color(0xFF135BEC),
                      onTap: () => Navigator.pushNamed(context, '/prediction-hub'),
                    ),
                    const SizedBox(height: 12),

                    _FeatureCard(
                      icon: Icons.timeline_rounded,
                      title: 'Lịch sử Sức khỏe',
                      subtitle: 'Xem lại các chỉ số và kết quả dự đoán',
                      color: const Color(0xFF10B981),
                      onTap: () => Navigator.pushNamed(context, '/health-history'),
                    ),
                    const SizedBox(height: 12),

                    _FeatureCard(
                      icon: Icons.people_rounded,
                      title: 'Thành viên Gia đình',
                      subtitle: 'Quản lý thông tin thành viên gia đình',
                      color: const Color(0xFFF59E0B),
                      onTap: () => Navigator.pushNamed(context, '/family-management'),
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
                          title: 'Dự đoán',
                          value: '$_totalPredictions',
                          icon: Icons.analytics,
                          color: const Color(0xFF135BEC),
                        ),
                        _StatCard(
                          title: 'Nguy cơ cao',
                          value: '$_highRiskCount',
                          icon: Icons.warning,
                          color: const Color(0xFFEF4444),
                        ),
                        _StatCard(
                          title: 'Gia đình',
                          value: '$_familyMembersCount',
                          icon: Icons.people,
                          color: const Color(0xFF10B981),
                        ),
                        _StatCard(
                          title: 'Lịch sử',
                          value: '$_totalPredictions',
                          icon: Icons.history,
                          color: const Color(0xFFF59E0B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111318),
                    ),
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
