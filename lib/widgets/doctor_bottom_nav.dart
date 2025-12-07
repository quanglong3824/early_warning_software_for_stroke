import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/auth_service.dart';

class DoctorBottomNav extends StatefulWidget {
  final int currentIndex;

  const DoctorBottomNav({super.key, required this.currentIndex});

  @override
  State<DoctorBottomNav> createState() => _DoctorBottomNavState();
}

class _DoctorBottomNavState extends State<DoctorBottomNav> {
  final _database = FirebaseDatabase.instance.ref();
  final _authService = AuthService();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final doctorId = await _authService.getUserId();
    if (doctorId == null) return;

    _database.child('conversations').onValue.listen((event) {
      if (!mounted) return;
      
      int count = 0;
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final conv = Map<String, dynamic>.from(value as Map);
          final participants = conv['participants'] as Map?;
          if (participants != null && participants.containsKey(doctorId)) {
            final unread = conv['unreadCount_$doctorId'] as int? ?? 0;
            count += unread;
          }
        });
      }
      
      if (mounted) {
        setState(() => _unreadCount = count);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    const success = Color(0xFF10B981);
    const warning = Color(0xFFEF4444);
    const purple = Color(0xFF8B5CF6);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, Icons.dashboard_rounded, 'Dashboard', '/doctor/dashboard', primary),
              _buildNavItem(context, 1, Icons.people_rounded, 'Bệnh nhân', '/doctor/patients', success),
              _buildCenterChatButton(context),
              _buildNavItem(context, 2, Icons.calendar_today_rounded, 'Lịch hẹn', '/doctor/appointments', warning),
              _buildNavItem(context, 3, Icons.person_rounded, 'Cá nhân', '/doctor/settings', purple),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label, String route, Color color) {
    final isActive = widget.currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (widget.currentIndex != index) {
            if (route == '/doctor/dashboard') {
              Navigator.pushReplacementNamed(context, route);
            } else {
              Navigator.pushNamedAndRemoveUntil(
                context,
                route,
                (r) => r.settings.name == '/doctor/dashboard',
              );
            }
          }
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(isActive ? 10 : 6),
                decoration: BoxDecoration(
                  color: isActive ? color.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isActive ? color : const Color(0xFF9CA3AF),
                  size: isActive ? 24 : 20,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? color : const Color(0xFF9CA3AF),
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterChatButton(BuildContext context) {
    const chatColor = Color(0xFF135BEC);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/doctor/chat',
          (r) => r.settings.name == '/doctor/dashboard',
        );
      },
      child: Container(
        width: 56,
        height: 56,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [chatColor, Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: chatColor.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Center(
              child: Icon(
                Icons.chat_bubble_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            if (_unreadCount > 0)
              Positioned(
                right: -4,
                top: -4,
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
                    _unreadCount > 9 ? '9+' : '$_unreadCount',
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
      ),
    );
  }
}
