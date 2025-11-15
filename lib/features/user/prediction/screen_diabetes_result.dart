import 'package:flutter/material.dart';

class ScreenDiabetesResult extends StatelessWidget {
  const ScreenDiabetesResult({super.key});

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
          'Kết Quả Nguy Cơ Tiểu Đường',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
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
                const Text(
                  'Nguy Cơ Cao',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bạn có nguy cơ cao mắc bệnh tiểu đường loại 2.',
                  style: TextStyle(color: textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Điểm số nguy cơ', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text('75/100', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: 0.75,
                        minHeight: 10,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Khuyến nghị cho bạn',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 16),
          _RecommendationSection(
            icon: Icons.restaurant,
            iconColor: Colors.green,
            title: 'Dinh dưỡng',
            items: const [
              'Cắt giảm đồ uống có đường và thực phẩm chế biến sẵn.',
              'Tăng cường ăn rau xanh, trái cây và ngũ cốc nguyên hạt.',
              'Uống đủ 2 lít nước mỗi ngày.',
            ],
          ),
          const SizedBox(height: 16),
          _RecommendationSection(
            icon: Icons.directions_run,
            iconColor: Colors.blue,
            title: 'Vận động',
            items: const [
              'Tập thể dục ít nhất 150 phút mỗi tuần với cường độ vừa phải.',
              'Kết hợp các bài tập cardio (đi bộ, chạy) và sức mạnh.',
              'Hạn chế ngồi một chỗ quá lâu, đứng dậy đi lại sau mỗi 30 phút.',
            ],
          ),
          const SizedBox(height: 16),
          _RecommendationSection(
            icon: Icons.monitor_heart,
            iconColor: Colors.purple,
            title: 'Theo dõi sức khỏe',
            items: const [
              'Thường xuyên kiểm tra đường huyết theo chỉ dẫn của bác sĩ.',
              'Thực hiện các xét nghiệm định kỳ để theo dõi tình trạng sức khỏe.',
              'Tham khảo ý kiến bác sĩ chuyên khoa để được tư vấn cụ thể.',
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {},
            child: const Text('Tìm Bác Sĩ Tư Vấn', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {},
            child: const Text('Xem Chi Tiết Dữ Liệu', style: TextStyle(fontWeight: FontWeight.bold, color: primary)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Lưu ý: Kết quả dự đoán chỉ mang tính chất tham khảo và không thay thế cho chẩn đoán y tế từ chuyên gia.',
            style: TextStyle(fontSize: 12, color: textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RecommendationSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> items;

  const _RecommendationSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF6B7280);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
                ),
              ),
              const Icon(Icons.expand_more, color: textMuted),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: textMuted)),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 14, color: textMuted),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}