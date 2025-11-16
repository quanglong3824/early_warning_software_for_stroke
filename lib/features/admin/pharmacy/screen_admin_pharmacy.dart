import 'package:flutter/material.dart';

class ScreenAdminPharmacy extends StatefulWidget {
  const ScreenAdminPharmacy({super.key});

  @override
  State<ScreenAdminPharmacy> createState() => _ScreenAdminPharmacyState();
}

class _ScreenAdminPharmacyState extends State<ScreenAdminPharmacy> {
  String _selectedTab = 'prescriptions';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: const Text('Tổng hợp Thuốc'),
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
                  label: 'Đơn thuốc',
                  isSelected: _selectedTab == 'prescriptions',
                  onTap: () => setState(() => _selectedTab = 'prescriptions'),
                ),
                const SizedBox(width: 8),
                _TabButton(
                  label: 'Nhà thuốc',
                  isSelected: _selectedTab == 'pharmacies',
                  onTap: () => setState(() => _selectedTab = 'pharmacies'),
                ),
                _TabButton(
                  label: 'Thống kê',
                  isSelected: _selectedTab == 'stats',
                  onTap: () => setState(() => _selectedTab = 'stats'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedTab == 'prescriptions'
                ? _buildPrescriptions()
                : _selectedTab == 'pharmacies'
                    ? _buildPharmacies()
                    : _buildStats(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptions() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 15,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.medication, color: Colors.green),
              ),
              title: Text('Đơn thuốc #${2000 + index}'),
              subtitle: Text('BN: User ${index + 1} • BS: Nguyễn Văn A\n${index + 1}h trước'),
              trailing: IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: () {},
              ),
              isThreeLine: true,
            );
          },
        ),
      ),
    );
  }

  Widget _buildPharmacies() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_pharmacy, color: Colors.blue),
                ),
                const Spacer(),
                Text('Nhà thuốc ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('Địa chỉ ${index + 1}', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text('4.${8 - (index % 3)}'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
        children: [
          _StatCard(title: 'Tổng đơn thuốc', value: '456', color: Colors.green),
          _StatCard(title: 'Đơn hôm nay', value: '23', color: Colors.blue),
          _StatCard(title: 'Nhà thuốc', value: '12', color: Colors.orange),
          _StatCard(title: 'Doanh thu', value: '45M', color: Colors.purple),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.isSelected, required this.onTap});

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
        child: Text(label,
            style: TextStyle(
                color: isSelected ? primary : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
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
