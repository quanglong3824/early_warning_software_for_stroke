import 'package:flutter/material.dart';

class ScreenAdminSOS extends StatefulWidget {
  const ScreenAdminSOS({super.key});

  @override
  State<ScreenAdminSOS> createState() => _ScreenAdminSOSState();
}

class _ScreenAdminSOSState extends State<ScreenAdminSOS> {
  String _selectedTab = 'map';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: const Text('Tổng hợp SOS'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _TabButton(
                  label: 'Bản đồ',
                  icon: Icons.map,
                  isSelected: _selectedTab == 'map',
                  onTap: () => setState(() => _selectedTab = 'map'),
                ),
                const SizedBox(width: 8),
                _TabButton(
                  label: 'Danh sách',
                  icon: Icons.list,
                  isSelected: _selectedTab == 'list',
                  onTap: () => setState(() => _selectedTab = 'list'),
                ),
                const SizedBox(width: 8),
                _TabButton(
                  label: 'Thống kê',
                  icon: Icons.analytics,
                  isSelected: _selectedTab == 'stats',
                  onTap: () => setState(() => _selectedTab = 'stats'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedTab == 'map'
                ? _buildMapView()
                : _selectedTab == 'list'
                    ? _buildListView()
                    : _buildStatsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Bản đồ SOS', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Hiển thị vị trí các cuộc gọi SOS', style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final statuses = ['Đang chờ', 'Đang xử lý', 'Hoàn thành'];
          final colors = [Colors.orange, Colors.blue, Colors.green];
          final status = statuses[index % 3];
          final color = colors[index % 3];

          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emergency, color: Colors.red),
            ),
            title: Text('SOS #${1000 + index}'),
            subtitle: Text('Bệnh nhân: User ${index + 1} • ${10 + index} phút trước'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ),
            onTap: () {},
          );
        },
      ),
    );
  }

  Widget _buildStatsView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
        children: [
          _StatCard(title: 'Tổng SOS hôm nay', value: '24', color: Colors.red),
          _StatCard(title: 'Đang xử lý', value: '8', color: Colors.orange),
          _StatCard(title: 'Hoàn thành', value: '16', color: Colors.green),
          _StatCard(title: 'Thời gian TB', value: '12 phút', color: Colors.blue),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6B46C1);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? primary : Colors.grey),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: isSelected ? primary : Colors.grey,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
