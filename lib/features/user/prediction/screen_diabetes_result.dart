import 'package:flutter/material.dart';
import '../../../services/diabetes_prediction_service.dart';

class ScreenDiabetesResult extends StatelessWidget {
  const ScreenDiabetesResult({super.key});

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

    // Xác định màu sắc dựa trên mức độ nguy cơ
    Color riskColor;
    if (riskLevel == 'high') {
      riskColor = Colors.red;
    } else if (riskLevel == 'medium') {
      riskColor = Colors.orange;
    } else {
      riskColor = Colors.green;
    }

    final predictionService = DiabetesPredictionService();
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
                      ? 'Bạn có nguy cơ cao mắc bệnh tiểu đường loại 2.'
                      : riskLevel == 'medium'
                          ? 'Bạn có nguy cơ trung bình mắc bệnh tiểu đường loại 2.'
                          : 'Bạn có nguy cơ thấp mắc bệnh tiểu đường loại 2.',
                  style: const TextStyle(color: textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.monitor_weight, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'BMI: $bmi ($bmiCategory)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Điểm số nguy cơ', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text(
                          '$riskScore/100',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: riskColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: riskScore / 100,
                        minHeight: 10,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(riskColor),
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
            items: recommendations['nutrition']!,
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
            iconColor: Colors.purple,
            title: 'Theo dõi sức khỏe',
            items: recommendations['monitoring']!,
          ),
          const SizedBox(height: 24),
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
            label: const Text('Tìm cơ sở y tế', style: TextStyle(fontWeight: FontWeight.bold, color: primary)),
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