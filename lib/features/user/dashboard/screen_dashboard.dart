import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/app_bottom_nav.dart';
import '../../../widgets/sos_floating_button.dart';
import '../../../data/providers/app_data_provider.dart';

class ScreenDashboard extends StatelessWidget {
  const ScreenDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF6B7280);

    final appData = Provider.of<AppDataProvider>(context);
    final currentUser = appData.currentUser;
    final patients = appData.patients;
    final alerts = appData.alerts;
    final stats = appData.dashboardStats;
    final unreadCount = appData.unreadAlertsCount;

    return Scaffold(
      drawer: AppDrawer(userName: currentUser?.name ?? 'Admin'),
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
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: textPrimary, size: 28),
                onPressed: () {},
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
                ),
            ],
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text('Tổng quan',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary)),
            const SizedBox(height: 12),
            if (alerts.isNotEmpty)
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
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE4E6),
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
                              Text('Cảnh báo ${alerts.first.level == "high" ? "Nguy cơ Cao" : "Cảnh báo"}',
                                  style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13, fontWeight: FontWeight.w500)),
                              Text('Bệnh nhân ${alerts.first.patientName}',
                                  style: const TextStyle(color: Color(0xFF7F1D1D), fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      alerts.first.message,
                      style: const TextStyle(color: Color(0xFF991B1B)),
                    ),
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            appData.markAlertAsRead(alerts.first.id);
                          },
                          child: const Text('Xem Chi Tiết'),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _StatCard(title: 'Đang theo dõi', value: '${stats['totalPatients'] ?? 0}'),
                _StatCard(title: 'Cảnh báo (24h)', value: '${stats['alertsLast24h'] ?? 0}'),
                _StatCard(title: 'Bệnh nhân ổn định', value: '${stats['stablePatients'] ?? 0}', accent: Colors.green),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))))),
            const SizedBox(height: 16),
            Row(children: const [
              Expanded(child: _TabItem(label: 'Tất cả', active: true)),
              Expanded(child: _TabItem(label: 'Nguy cơ cao')),
              Expanded(child: _TabItem(label: 'Cảnh báo')),
            ]),
            const SizedBox(height: 12),
            ...patients.map((patient) => _PatientItem(
              name: patient.name,
              statusText: _getStatusText(patient.status),
              statusColor: _getStatusColor(patient.status),
              mainValue: patient.mainValue,
              unit: patient.unit,
            )),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      floatingActionButton: const SOSFloatingButton(),
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
  final Color? accent;
  const _StatCard({required this.title, required this.value, this.accent});

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF6B7280);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(color: accent ?? textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool active;
  const _TabItem({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    final borderColor = active ? primary : const Color(0x00000000);
    final textColor = active ? primary : const Color(0xFF6B7280);
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderColor, width: 3))),
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      child: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
    );
  }
}

class _PatientItem extends StatelessWidget {
  final String name;
  final String statusText;
  final Color statusColor;
  final String mainValue;
  final String unit;
  const _PatientItem({
    required this.name,
    required this.statusText,
    required this.statusColor,
    required this.mainValue,
    required this.unit,
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
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: statusColor.withOpacity(0.15), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(Icons.person, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(statusText, style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(mainValue, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(unit, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
        ],
      ),
    );
  }
}
