import 'package:flutter/material.dart';

class DoctorDrawer extends StatelessWidget {
  final String doctorName;
  const DoctorDrawer({super.key, required this.doctorName});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    const bgLight = Color(0xFFF6F6F8);
    
    return Drawer(
      backgroundColor: bgLight,
      child: Column(
        children: [
          // Header với gradient
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primary, primary.withOpacity(0.8)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                      ),
                      child: const CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.medical_services, size: 32, color: primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      doctorName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Bác sĩ - SEWS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _section('CHÍNH', [
                  _item(context, 'Dashboard', Icons.dashboard_rounded, '/doctor/dashboard', true),
                  _item(context, 'Bệnh nhân', Icons.people_rounded, '/doctor/patients', false),
                  _item(context, 'Lịch hẹn', Icons.calendar_today_rounded, '/doctor/appointments', false),
                  _item(context, 'Tin nhắn', Icons.chat_bubble_rounded, '/doctor/chat', false),
                  _item(context, 'Thông báo', Icons.notifications_rounded, '/doctor/notifications', false),
                ]),

                _section('KHẨN CẤP', [
                  _item(context, 'Hàng đợi SOS', Icons.emergency, '/doctor/sos-queue', false),
                ]),

                _section('CÔNG VIỆC', [
                  _item(context, 'Lịch làm việc', Icons.schedule, '/doctor/schedule', false),
                  _item(context, 'Đánh giá', Icons.star, '/doctor/reviews', false),
                ]),

                _section('CÀI ĐẶT', [
                  _item(context, 'Cài đặt tài khoản', Icons.settings, '/doctor/settings', false),
                  _item(context, 'Trợ giúp', Icons.help, '', false),
                ]),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'SEWS Doctor v1.0.0',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Đăng xuất'),
                          content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Hủy'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pushReplacementNamed(context, '/doctor/login');
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text('Đăng xuất'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.logout, color: Colors.red, size: 18),
                    label: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _item(BuildContext context, String label, IconData icon, String route, bool isDashboard) {
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF6B7280);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();
            if (route.isEmpty) return;
            
            // For dashboard, use replacement to clear stack
            // For other screens, keep dashboard in stack for back navigation
            if (isDashboard) {
              Navigator.of(context).pushReplacementNamed(route);
            } else {
              Navigator.of(context).pushNamedAndRemoveUntil(
                route,
                (r) => r.settings.name == '/doctor/dashboard',
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
