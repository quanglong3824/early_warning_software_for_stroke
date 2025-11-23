import 'package:flutter/material.dart';
import '../../../services/admin_user_service.dart';
import '../../../services/admin_prediction_service.dart';
import '../widgets/admin_sidebar.dart';
import '../../../mixins/account_status_check_mixin.dart';

class ScreenAdminDashboard extends StatefulWidget {
  const ScreenAdminDashboard({super.key});

  @override
  State<ScreenAdminDashboard> createState() => _ScreenAdminDashboardState();
}

class _ScreenAdminDashboardState extends State<ScreenAdminDashboard> 
    with AccountStatusCheckMixin {
  int _selectedIndex = 0;
  final AdminUserService _userService = AdminUserService();
  final AdminPredictionService _predictionService = AdminPredictionService();
  
  Map<String, dynamic> _stats = {
    'total': 0,
    'active': 0,
    'blocked': 0,
    'users': 0,
    'doctors': 0,
    'admins': 0,
    'newThisWeek': 0,
  };
  
  Map<String, dynamic> _predictionStats = {
    'total': 0,
    'stroke': 0,
    'diabetes': 0,
    'highRisk': 0,
    'mediumRisk': 0,
    'lowRisk': 0,
  };
  
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    print('📊 Loading dashboard stats...');
    setState(() => _isLoadingStats = true);
    
    try {
      final stats = await _userService.getUserStats();
      final predStats = await _predictionService.getPredictionStats();
      
      print('✅ Stats loaded: $stats');
      print('✅ Prediction stats loaded: $predStats');
      
      if (mounted) {
        setState(() {
          _stats = stats;
          _predictionStats = predStats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      print('❌ Error loading stats: $e');
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6B46C1);
    const bgLight = Color(0xFFF6F6F8);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Đăng xuất'),
            content: const Text('Bạn có muốn đăng xuất khỏi Admin Panel?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Đăng xuất'),
              ),
            ],
          ),
        );

        if (shouldLogout == true && context.mounted) {
          Navigator.of(context).pushReplacementNamed('/admin/login');
        }
      },
      child: Scaffold(
      backgroundColor: bgLight,
      body: Row(
        children: [
          // Sidebar
          AdminSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) => setState(() => _selectedIndex = index),
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  height: 70,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      const Text('Tổng quan hệ thống',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadStats,
                        tooltip: 'Làm mới',
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: primary.withOpacity(0.1),
                        child: const Icon(Icons.person, color: primary),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats cards
                        _isLoadingStats
                            ? const Center(child: CircularProgressIndicator())
                            : GridView.count(
                                crossAxisCount: 4,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.5,
                                children: [
                                  _StatCard(
                                    title: 'Tổng Users',
                                    value: '${_stats['users']}',
                                    icon: Icons.people,
                                    color: Colors.blue,
                                    trend: '+${_stats['newThisWeek']} tuần này',
                                  ),
                                  _StatCard(
                                    title: 'Bác sĩ',
                                    value: '${_stats['doctors']}',
                                    icon: Icons.medical_services,
                                    color: Colors.green,
                                    trend: 'Hoạt động: ${_stats['active']}',
                                  ),
                                  _StatCard(
                                    title: 'Admins',
                                    value: '${_stats['admins']}',
                                    icon: Icons.admin_panel_settings,
                                    color: Colors.purple,
                                    trend: 'Tổng: ${_stats['total']}',
                                  ),
                                  _StatCard(
                                    title: 'Bị chặn',
                                    value: '${_stats['blocked']}',
                                    icon: Icons.block,
                                    color: Colors.red,
                                    trend: 'Cần xem xét',
                                  ),
                                ],
                              ),
                        const SizedBox(height: 24),
                        // Prediction Stats
                        const Text(
                          'Thống kê Dự đoán',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_isLoadingStats)
                          const Center(child: CircularProgressIndicator())
                        else
                          GridView.count(
                            crossAxisCount: 4,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.5,
                            children: [
                              _StatCard(
                                title: 'Tổng Dự đoán',
                                value: '${_predictionStats['total']}',
                                icon: Icons.analytics,
                                color: Colors.blue,
                                trend: 'Tất cả loại',
                              ),
                              _StatCard(
                                title: 'Đột quỵ',
                                value: '${_predictionStats['stroke']}',
                                icon: Icons.favorite,
                                color: Colors.red,
                                trend: 'Dự đoán đột quỵ',
                              ),
                              _StatCard(
                                title: 'Tiểu đường',
                                value: '${_predictionStats['diabetes']}',
                                icon: Icons.water_drop,
                                color: Colors.orange,
                                trend: 'Dự đoán tiểu đường',
                              ),
                              _StatCard(
                                title: 'Nguy cơ cao',
                                value: '${_predictionStats['highRisk']}',
                                icon: Icons.warning,
                                color: Colors.red,
                                trend: 'Cần theo dõi',
                              ),
                            ],
                          ),
                        const SizedBox(height: 24),
                        // Recent activities
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _SectionCard(
                                title: 'Hoạt động gần đây',
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: 5,
                                  separatorBuilder: (_, __) => const Divider(),
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.blue.withOpacity(0.1),
                                        child: const Icon(Icons.person, size: 20),
                                      ),
                                      title: Text('User #${index + 1} đã đăng ký'),
                                      subtitle: Text('${index + 1} phút trước'),
                                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _SectionCard(
                                title: 'Thống kê nhanh',
                                child: Column(
                                  children: [
                                    _QuickStat(label: 'Dự đoán hôm nay', value: '123'),
                                    const Divider(),
                                    _QuickStat(label: 'Chat đang hoạt động', value: '34'),
                                    const Divider(),
                                    _QuickStat(label: 'Đơn thuốc mới', value: '12'),
                                    const Divider(),
                                    _QuickStat(label: 'Bài viết mới', value: '5'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
  final String trend;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, color.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: trend.contains('+') || trend.contains('Hoạt động')
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    color: trend.contains('+') || trend.contains('Hoạt động')
                        ? Colors.green
                        : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
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

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;

  const _QuickStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
