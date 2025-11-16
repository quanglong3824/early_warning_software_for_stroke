import 'package:flutter/material.dart';
import '../../../services/stroke_prediction_service.dart';

class ScreenStrokeResult extends StatelessWidget {
  const ScreenStrokeResult({super.key});

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF6B7280);

    // Nhận kết quả từ arguments
    final result = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lỗi')),
        body: const Center(child: Text('Không tìm thấy kết quả dự đoán')),
      );
    }

    final riskScore = result['riskScore'] as int;
    final riskLevel = result['riskLevel'] as String;
    final riskLevelVi = result['riskLevelVi'] as String;
    final bmi = result['bmi'] as String;
    final bmiCategory = result['bmiCategory'] as String;
    final bpCategory = result['bpCategory'] as String;
    final cholesterolCategory = result['cholesterolCategory'] as String;

    // Xác định màu sắc dựa trên mức độ nguy cơ
    Color riskColor;
    if (riskLevel == 'high') {
      riskColor = Colors.red;
    } else if (riskLevel == 'medium') {
      riskColor = Colors.orange;
    } else {
      riskColor = Colors.green;
    }

    final predictionService = StrokePredictionService();
    final recommendations = predictionService.getRecommendations(riskLevel);

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
          'Kết Quả Nguy Cơ Đột Quỵ',
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
                          value: riskScore / 100,
                          strokeWidth: 10,
                          backgroundColor: riskColor.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$riskScore%',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: riskColor,
                            ),
                          ),
                          const Text(
                            'Nguy cơ',
                            style: TextStyle(fontSize: 14, color: textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  riskLevelVi,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: riskColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  riskLevel == 'high'
                      ? 'Bạn có nguy cơ cao bị đột quỵ. Cần gặp bác sĩ ngay.'
                      : riskLevel == 'medium'
                          ? 'Bạn có nguy cơ trung bình. Cần theo dõi và cải thiện lối sống.'
                          : 'Bạn có nguy cơ thấp. Hãy duy trì lối sống lành mạnh.',
                  style: const TextStyle(color: textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Health Indicators
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _HealthChip(
                      icon: Icons.monitor_weight,
                      label: 'BMI: $bmi',
                      sublabel: bmiCategory,
                      color: Colors.blue,
                    ),
                    _HealthChip(
                      icon: Icons.favorite,
                      label: 'Huyết áp',
                      sublabel: bpCategory,
                      color: Colors.red,
                    ),
                    _HealthChip(
                      icon: Icons.water_drop,
                      label: 'Cholesterol',
                      sublabel: cholesterolCategory,
                      color: Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // CTA Buttons
          if (riskLevel == 'high') ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                // TODO: Implement emergency call
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chức năng gọi cấp cứu đang được phát triển')),
                );
              },
              icon: const Icon(Icons.call),
              label: const Text('Gọi cấp cứu (115)', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
          ],
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/doctors');
            },
            icon: const Icon(Icons.medical_services),
            label: const Text('Tìm Bác Sĩ Tư Vấn', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/hospitals');
            },
            icon: const Icon(Icons.local_hospital),
            label: const Text('Tìm cơ sở y tế gần nhất', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 32),
          // Recommendations
          const Text(
            'Khuyến nghị cho bạn',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 16),
          _RecommendationSection(
            icon: Icons.self_improvement,
            iconColor: Colors.purple,
            title: 'Lối sống',
            items: recommendations['lifestyle']!,
          ),
          const SizedBox(height: 16),
          _RecommendationSection(
            icon: Icons.restaurant,
            iconColor: Colors.green,
            title: 'Chế độ ăn',
            items: recommendations['diet']!,
          ),
          const SizedBox(height: 16),
          _RecommendationSection(
            icon: Icons.directions_run,
            iconColor: Colors.blue,
            title: 'Vận động',
            items: recommendations['exercise']!,
          ),
          const SizedBox(height: 16),
          _RecommendationSection(
            icon: Icons.monitor_heart,
            iconColor: Colors.red,
            title: 'Theo dõi sức khỏe',
            items: recommendations['monitoring']!,
          ),
          const SizedBox(height: 24),
          const Text(
            'Lưu ý: Kết quả dự đoán chỉ mang tính chất tham khảo và không thay thế cho chẩn đoán y tế từ chuyên gia. Vui lòng tham khảo ý kiến bác sĩ để có lời khuyên y tế chính xác.',
            style: TextStyle(fontSize: 12, color: textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HealthChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;

  const _HealthChip({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
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
