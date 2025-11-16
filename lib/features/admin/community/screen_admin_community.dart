import 'package:flutter/material.dart';

class ScreenAdminCommunity extends StatefulWidget {
  const ScreenAdminCommunity({super.key});

  @override
  State<ScreenAdminCommunity> createState() => _ScreenAdminCommunityState();
}

class _ScreenAdminCommunityState extends State<ScreenAdminCommunity> {
  String _selectedTab = 'forum';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: const Text('Tổng hợp Cộng đồng'),
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
                  label: 'Diễn đàn',
                  isSelected: _selectedTab == 'forum',
                  onTap: () => setState(() => _selectedTab = 'forum'),
                ),
                const SizedBox(width: 8),
                _TabButton(
                  label: 'Đánh giá',
                  isSelected: _selectedTab == 'reviews',
                  onTap: () => setState(() => _selectedTab = 'reviews'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedTab == 'forum' ? _buildForum() : _buildReviews(),
          ),
        ],
      ),
    );
  }

  Widget _buildForum() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              _StatCard(title: 'Tổng chủ đề', value: '345', color: Colors.blue),
              const SizedBox(width: 16),
              _StatCard(title: 'Bình luận', value: '1.2K', color: Colors.green),
              const SizedBox(width: 16),
              _StatCard(title: 'Thành viên', value: '567', color: Colors.orange),
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
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: const Icon(Icons.forum, color: Colors.blue),
                    ),
                    title: Text('Chủ đề ${index + 1}: Chia sẻ kinh nghiệm phục hồi'),
                    subtitle: Text('Bởi User ${index + 1} • ${index + 1}h trước • ${10 + index} bình luận'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility, size: 20),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviews() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              _StatCard(title: 'Tổng đánh giá', value: '234', color: Colors.amber),
              const SizedBox(width: 16),
              _StatCard(title: 'Điểm TB', value: '4.5', color: Colors.green),
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
                  final rating = 5 - (index % 3);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber.withOpacity(0.1),
                      child: const Icon(Icons.star, color: Colors.amber),
                    ),
                    title: Row(
                      children: [
                        Text('User ${index + 1} → BS. Nguyễn Văn A'),
                        const SizedBox(width: 8),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text('Bác sĩ rất tận tâm và chu đáo...'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () {},
                    ),
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
