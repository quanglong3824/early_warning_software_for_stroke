import 'package:flutter/material.dart';

class AppBottomNav extends StatefulWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    const success = Color(0xFF10B981);
    const warning = Color(0xFFEF4444);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                0,
                Icons.home_rounded,
                'Trang chủ',
                '/dashboard',
                primary,
              ),
              _buildNavItem(
                context,
                1,
                Icons.favorite_rounded,
                'Sức khỏe',
                '/health-hub',
                success,
              ),
              _buildNavItem(
                context,
                2,
                Icons.medical_services_rounded,
                'Bác sĩ',
                '/doctors-hub',
                warning,
              ),
              _buildNavItem(
                context,
                3,
                Icons.local_pharmacy_rounded,
                'Thuốc',
                '/pharmacy',
                const Color(0xFFF59E0B),
              ),
              _buildNavItem(
                context,
                4,
                Icons.person_rounded,
                'Cá nhân',
                '/profile',
                const Color(0xFF8B5CF6),
              ),
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
    final isActive = widget.currentIndex == index;
    const inactiveColor = Color(0xFF9CA3AF);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (widget.currentIndex != index) {
            _animationController.forward().then((_) {
              _animationController.reverse();
            });
            Navigator.pushReplacementNamed(context, route);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: EdgeInsets.all(isActive ? 10 : 8),
                decoration: BoxDecoration(
                  color: isActive ? activeColor.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: isActive ? activeColor : inactiveColor,
                  size: isActive ? 26 : 24,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isActive ? activeColor : inactiveColor,
                  fontSize: isActive ? 11.5 : 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: isActive ? 0.2 : 0,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
