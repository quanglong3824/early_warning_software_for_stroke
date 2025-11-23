import 'package:flutter/material.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/app_bottom_nav.dart';
import '../../../widgets/sos_floating_button.dart';
import '../../../services/auth_service.dart';
import '../../../services/family_service.dart';
import '../../../services/user_dashboard_service.dart';
import '../../../mixins/account_status_check_mixin.dart';
import 'package:intl/intl.dart';

class ScreenDashboard extends StatefulWidget {
  const ScreenDashboard({super.key});

  @override
  State<ScreenDashboard> createState() => _ScreenDashboardState();
}

class _ScreenDashboardState extends State<ScreenDashboard> 
    with AccountStatusCheckMixin {
  final _authService = AuthService();
  final _familyService = FamilyService();
  final _dashboardService = UserDashboardService();
  
  String _userName = 'User';
  int _notificationCount = 0;
  Map<String, dynamic> _dashboardStats = {};
  List<Map<String, dynamic>> _familyMembers = [];
  List<Map<String, dynamic>> _upcomingAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    await Future.wait([
      _loadUserName(),
      _loadNotificationCount(),
      _loadDashboardStats(),
      _loadFamilyMembers(),
      _loadAppointments(),
    ]);
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadUserName() async {
    final name = await _authService.getUserName();
    if (mounted) {
      setState(() => _userName = name);
    }
  }

  Future<void> _loadNotificationCount() async {
    final userId = await _authService.getUserId();
    if (userId == null) return;

    final count = await _familyService.getUnreadNotificationCount(userId);
    if (mounted) {
      setState(() => _notificationCount = count);
    }
  }

  Future<void> _loadDashboardStats() async {
    final userId = await _authService.getUserId();
    if (userId == null) return;

    final stats = await _dashboardService.getDashboardStats(userId);
    if (mounted) {
      setState(() => _dashboardStats = stats);
    }
  }

  Future<void> _loadFamilyMembers() async {
    final userId = await _authService.getUserId();
    if (userId == null) return;

    final members = await _dashboardService.getFamilyMembers(userId);
    if (mounted) {
      setState(() => _familyMembers = members);
    }
  }

  Future<void> _loadAppointments() async {
    final userId = await _authService.getUserId();
    if (userId == null) return;

    final appointments = await _dashboardService.getUpcomingAppointments(userId);
    if (mounted) {
      setState(() => _upcomingAppointments = appointments);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF6B7280);

    final latestPrediction = _dashboardStats['latestPrediction'] as Map<String, dynamic>?;
    final hasHighRisk = (_dashboardStats['highRiskCount'] as int? ?? 0) > 0;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Đăng xuất'),
            content: const Text('Bạn có muốn đăng xuất?'),
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
          Navigator.of(context).pushReplacementNamed('/login');
        }
      },
      child: Scaffold(
      drawer: AppDrawer(userName: _userName),
      backgroundColor: bgLight,
      extendBody: true,
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
        title: const Text('SEWS', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: textPrimary, size: 28),
                onPressed: () async {
                  await Navigator.of(context).pushNamed('/notifications');
                  _loadNotificationCount();
                },
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      _notificationCount > 9 ? '9+' : '$_notificationCount',
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
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
                        children: [
                          const TextSpan(text: 'Xin chào, '),
                          TextSpan(
                            text: _userName,
                            style: const TextStyle(color: primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Cảnh báo nguy cơ cao
                    if (hasHighRisk && latestPrediction != null)
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                          boxShadow: const [BoxShadow(color: Color(0x1AEF4444), blurRadius: 8)],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFE4E6),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Cảnh báo Nguy cơ Cao',
                                        style: TextStyle(
                                          color: Color(0xFFB91C1C),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        latestPrediction['type'] == 'stroke'
                                            ? 'Dự đoán Đột quỵ'
                                            : 'Dự đoán Tiểu đường',
                                        style: const TextStyle(
                                          color: Color(0xFF7F1D1D),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bạn có nguy cơ ${latestPrediction['riskLevelVi']}. Vui lòng tham khảo ý kiến bác sĩ.',
                              style: const TextStyle(color: Color(0xFF991B1B)),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(
                                  height: 40,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/health-history');
                                    },
                                    child: const Text('Xem Chi Tiết'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Stats cards
                    GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _StatCard(
                          title: 'Dự đoán',
                          value: '${_dashboardStats['totalPredictions'] ?? 0}',
                          icon: Icons.analytics,
                          color: primary,
                        ),
                        _StatCard(
                          title: 'Nguy cơ cao',
                          value: '${_dashboardStats['highRiskCount'] ?? 0}',
                          icon: Icons.warning,
                          color: Colors.red,
                        ),
                        _StatCard(
                          title: 'Gia đình',
                          value: '${_dashboardStats['familyMembersCount'] ?? 0}',
                          icon: Icons.people,
                          color: Colors.green,
                        ),
                        _StatCard(
                          title: 'Lịch hẹn',
                          value: '${_dashboardStats['upcomingAppointments'] ?? 0}',
                          icon: Icons.calendar_today,
                          color: Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Gia đình section
                    if (_familyMembers.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Gia đình của bạn',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/family-management'),
                            child: const Text('Xem tất cả'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._familyMembers.take(3).map((member) => _FamilyMemberCard(
                        name: member['name'] ?? 'Unknown',
                        relationship: member['relationship'] ?? 'Member',
                        email: member['email'] ?? '',
                      )),
                      const SizedBox(height: 24),
                    ],
                    // Appointments section
                    if (_upcomingAppointments.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Lịch hẹn sắp tới',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/appointments'),
                            child: const Text('Xem tất cả'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._upcomingAppointments.take(3).map((appointment) {
                        final appointmentTime = appointment['appointmentTime'] as int?;
                        final dateStr = appointmentTime != null
                            ? DateFormat('dd/MM/yyyy HH:mm').format(
                                DateTime.fromMillisecondsSinceEpoch(appointmentTime),
                              )
                            : 'N/A';
                        
                        return _AppointmentCard(
                          doctorName: appointment['doctorName'] ?? 'Bác sĩ',
                          dateTime: dateStr,
                          type: appointment['type'] ?? 'Khám bệnh',
                        );
                      }),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      floatingActionButton: const SOSFloatingButton(),
    ),
    );
  }

  static String _getStatusText(String status) {
    switch (status) {
      case 'high_risk':
        return 'Nguy cơ cao';
      case 'warning':
        return 'Cảnh báo';
      case 'stable':
        return 'Ổn định';
      default:
        return status;
    }
  }

  static Color _getStatusColor(String status) {
    switch (status) {
      case 'high_risk':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'stable':
        return Colors.green;
      default:
        return Colors.grey;
    }
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
          Row(
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
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13,
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

class _FamilyMemberCard extends StatelessWidget {
  final String name;
  final String relationship;
  final String email;

  const _FamilyMemberCard({
    required this.name,
    required this.relationship,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.person, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  relationship,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final String doctorName;
  final String dateTime;
  final String type;

  const _AppointmentCard({
    required this.doctorName,
    required this.dateTime,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.medical_services, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctorName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  dateTime,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              type,
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
