import 'package:flutter/material.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_content_widgets.dart';
import '../../mixins/account_status_check_mixin.dart';

class ScreenAdminMain extends StatefulWidget {
  final int initialIndex;
  
  const ScreenAdminMain({super.key, this.initialIndex = 0});

  @override
  State<ScreenAdminMain> createState() => _ScreenAdminMainState();
}

class _ScreenAdminMainState extends State<ScreenAdminMain> 
    with AccountStatusCheckMixin {
  late int _selectedIndex;

  final List<String> _titles = [
    'Tổng quan',
    'Quản lý Users',
    'Quản lý Bác sĩ',
    'Quản lý Bệnh nhân',
    'Quản lý SOS',
    'Quản lý Dự đoán',
    'Quản lý Lịch hẹn',
    'Quản lý Kiến thức',
    'Quản lý Cộng đồng',
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
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
            // Sidebar - Fixed
            AdminSidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: (index) {
                setState(() => _selectedIndex = index);
              },
            ),
            // Main content area
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
                        Text(
                          _titles[_selectedIndex],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            setState(() {});
                          },
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
                  // Content - Dynamic
                  Expanded(
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: const [
                        AdminDashboardContent(),
                        AdminUsersContent(),
                        AdminDoctorsContent(),
                        AdminPatientsContent(),
                        AdminSOSContent(),
                        AdminPredictionsContent(),
                        AdminAppointmentsContent(),
                        AdminKnowledgeContent(),
                        AdminCommunityContent(),
                      ],
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
