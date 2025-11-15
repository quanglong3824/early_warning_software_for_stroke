import 'package:flutter/material.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/app_bottom_nav.dart';

class ScreenPredictionHub extends StatelessWidget {
  const ScreenPredictionHub({super.key});

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);

    return Scaffold(
      drawer: const AppDrawer(userName: 'Admin'),
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        centerTitle: true,
        title: const Text('Dự đoán Sức khỏe', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Công cụ dự đoán',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sử dụng AI để đánh giá nguy cơ sức khỏe của bạn',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _PredictionCard(
            title: 'Dự đoán Đột quỵ',
            description: 'Đánh giá nguy cơ đột quỵ dựa trên các chỉ số sức khỏe',
            icon: Icons.favorite,
            color: Colors.red,
            onTap: () => Navigator.pushNamed(context, '/stroke-form'),
          ),
          const SizedBox(height: 16),
          _PredictionCard(
            title: 'Dự đoán Tiểu đường',
            description: 'Phân tích nguy cơ mắc bệnh tiểu đường type 2',
            icon: Icons.water_drop,
            color: Colors.blue,
            onTap: () => Navigator.pushNamed(context, '/diabetes-form'),
          ),
          const SizedBox(height: 32),
          const Text(
            'Lịch sử & Kết quả',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 16),
          _HistoryCard(
            title: 'Kết quả Đột quỵ',
            subtitle: 'Xem kết quả dự đoán gần nhất',
            icon: Icons.insights,
            onTap: () => Navigator.pushNamed(context, '/stroke-result'),
          ),
          const SizedBox(height: 12),
          _HistoryCard(
            title: 'Kết quả Tiểu đường',
            subtitle: 'Xem kết quả dự đoán gần nhất',
            icon: Icons.query_stats,
            onTap: () => Navigator.pushNamed(context, '/diabetes-result'),
          ),
          const SizedBox(height: 12),
          _HistoryCard(
            title: 'Lịch sử Sức khỏe',
            subtitle: 'Xem biểu đồ và xu hướng',
            icon: Icons.timeline,
            onTap: () => Navigator.pushNamed(context, '/health-history'),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}

class _PredictionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PredictionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: color, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}