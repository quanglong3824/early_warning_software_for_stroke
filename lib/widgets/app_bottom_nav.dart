import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, Icons.dashboard_rounded, 'Trang chủ', '/dashboard', primary),
              _buildNavItem(context, 1, Icons.analytics_rounded, 'Dự đoán', '/prediction-hub', primary),
              _buildNavItem(context, 2, Icons.forum_rounded, 'Cộng đồng', '/forum', primary),
              _buildNavItem(context, 3, Icons.library_books_rounded, 'Kiến thức', '/knowledge', primary),
              _buildNavItem(context, 4, Icons.person_rounded, 'Cá nhân', '/profile', primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
    String route,
    Color activeColor,
  ) {
    final isActive = currentIndex == index;
    const inactiveColor = Color(0xFF6B7280);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (currentIndex != index) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isActive ? activeColor : inactiveColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? activeColor : inactiveColor,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
