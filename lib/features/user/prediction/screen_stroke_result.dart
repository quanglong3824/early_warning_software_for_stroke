import 'package:flutter/material.dart';

class ScreenStrokeResult extends StatelessWidget {
  const ScreenStrokeResult({super.key});

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: bgLight,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Kết quả Đánh giá',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share, color: textPrimary),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Result Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6)],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Circular Progress
                SizedBox(
                  width: 192,
                  height: 192,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 192,
                        height: 192,
                        child: CircularProgressIndicator(
                          value: 0.85,
                          strokeWidth: 10,
                          backgroundColor: Colors.red[100],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                        ),
                      ),
                      const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '85%',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.red,
                            ),
                          ),
                          Text(
                            'Nguy cơ',
                            style: TextStyle(fontSize: 14, color: textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Nguy cơ cao',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kết quả dựa trên dữ liệu bạn đã cung cấp ngày 26/07/2024.',
                  style: TextStyle(color: textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // CTA Buttons
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {},
            icon: const Icon(Icons.call),
            label: const Text('Gọi cấp cứu (115)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {},
            icon: const Icon(Icons.map),
            label: const Text('Tìm cơ sở y tế gần nhất', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 32),
          // Recommendations
          const Text(
            'Các bước tiếp theo được đề xuất',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 16),
          _RecommendationCard(
            icon: Icons.health_and_safety,
            title: 'Liên hệ bác sĩ ngay',
            subtitle: 'Thảo luận về kết quả này và các bước chẩn đoán tiếp theo.',
          ),
          const SizedBox(height: 12),
          _RecommendationCard(
            icon: Icons.monitor_heart,
            title: 'Theo dõi huyết áp hàng ngày',
            subtitle: 'Ghi lại chỉ số huyết áp của bạn 2 lần mỗi ngày.',
          ),
          const SizedBox(height: 12),
          _RecommendationCard(
            icon: Icons.restaurant_menu,
            title: 'Cải thiện chế độ ăn uống',
            subtitle: 'Giảm muối, đường và chất béo bão hòa.',
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {},
            icon: const Icon(Icons.edit_document),
            label: const Text('Xem lại Dữ liệu đã nhập', style: TextStyle(fontWeight: FontWeight.bold, color: primary)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tuyên bố miễn trừ trách nhiệm: Ứng dụng này là công cụ hỗ trợ sàng lọc và không thay thế cho chẩn đoán y tế chuyên nghiệp. Vui lòng tham khảo ý kiến bác sĩ để có lời khuyên y tế chính xác.',
            style: TextStyle(fontSize: 12, color: textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _RecommendationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF6B7280);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4)],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: textMuted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: textMuted),
        ],
      ),
    );
  }
}