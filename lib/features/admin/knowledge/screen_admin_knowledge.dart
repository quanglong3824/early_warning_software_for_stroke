import 'package:flutter/material.dart';

class ScreenAdminKnowledge extends StatefulWidget {
  const ScreenAdminKnowledge({super.key});

  @override
  State<ScreenAdminKnowledge> createState() => _ScreenAdminKnowledgeState();
}

class _ScreenAdminKnowledgeState extends State<ScreenAdminKnowledge> {
  String _selectedTab = 'articles';

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6B46C1);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: const Text('Tổng hợp Ngăn ngừa'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _TabButton(
                  label: 'Kiến thức',
                  isSelected: _selectedTab == 'articles',
                  onTap: () => setState(() => _selectedTab = 'articles'),
                ),
                const SizedBox(width: 8),
                _TabButton(
                  label: 'Nhắc nhở',
                  isSelected: _selectedTab == 'reminders',
                  onTap: () => setState(() => _selectedTab = 'reminders'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedTab == 'articles' ? _buildArticles() : _buildReminders(),
          ),
        ],
      ),
    );
  }

  Widget _buildArticles() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              _StatCard(title: 'Tổng bài viết', value: '156', color: Colors.blue),
              const SizedBox(width: 16),
              _StatCard(title: 'Video', value: '45', color: Colors.red),
              const SizedBox(width: 16),
              _StatCard(title: 'Lượt xem', value: '12.5K', color: Colors.green),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: Center(
                          child: Icon(index % 3 == 0 ? Icons.play_circle : Icons.article,
                              size: 48, color: Colors.grey[600]),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bài viết ${index + 1}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text('${100 + index * 10} lượt xem',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminders() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              _StatCard(title: 'Tổng nhắc nhở', value: '234', color: Colors.orange),
              const SizedBox(width: 16),
              _StatCard(title: 'Đang hoạt động', value: '189', color: Colors.green),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
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
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications, color: Colors.orange),
                    ),
                    title: Text('Nhắc nhở ${index + 1}'),
                    subtitle: Text('User ${index + 1} • Uống thuốc • 08:00 hàng ngày'),
                    trailing: Switch(value: index % 3 != 0, onChanged: (value) {}),
                  );
                },
              ),
            ),
          ),
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
