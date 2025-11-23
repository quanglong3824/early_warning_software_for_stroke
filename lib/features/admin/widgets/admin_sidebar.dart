import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static const primary = Color(0xFF6B46C1);
  static const bgSidebar = Color(0xFF1F2937);
  static const textLight = Color(0xFFE5E7EB);
  static const textDark = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    final navItems = [
      _NavItem(icon: Icons.dashboard, label: 'Tổng quan', route: '/admin/dashboard'),
      _NavItem(icon: Icons.people, label: 'Users', route: '/admin/users'),
      _NavItem(icon: Icons.medical_services, label: 'Bác sĩ', route: '/admin/doctors'),
      _NavItem(icon: Icons.personal_injury, label: 'Bệnh nhân', route: '/admin/patients'),
      _NavItem(icon: Icons.emergency, label: 'SOS', route: '/admin/sos'),
      _NavItem(icon: Icons.analytics, label: 'Dự đoán', route: '/admin/predictions'),
      _NavItem(icon: Icons.calendar_today, label: 'Lịch hẹn', route: '/admin/appointments'),
      _NavItem(icon: Icons.medication, label: 'Thuốc', route: '/admin/pharmacy'),
      _NavItem(icon: Icons.medication_liquid, label: 'Quản lý thuốc', route: '/admin/medications'),
      _NavItem(icon: Icons.library_books, label: 'Kiến thức', route: '/admin/knowledge'),
      _NavItem(icon: Icons.forum, label: 'Cộng đồng', route: '/admin/community'),
    ];

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: bgSidebar,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, primary.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Panel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textLight,
                      ),
                    ),
                    Text(
                      'SEWS Healthcare',
                      style: TextStyle(
                        fontSize: 11,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF374151)),
          // Navigation items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        onItemSelected(index);
                        Navigator.of(context).pushReplacementNamed(item.route);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? primary.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? primary.withOpacity(0.3) : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              color: isSelected ? primary : textDark,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              item.label,
                              style: TextStyle(
                                color: isSelected ? textLight : textDark,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFF374151)),
          // Logout
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).pushReplacementNamed('/admin/login');
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: const [
                    Icon(Icons.logout, color: Color(0xFFEF4444), size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Đăng xuất',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  _NavItem({required this.icon, required this.label, required this.route});
}
