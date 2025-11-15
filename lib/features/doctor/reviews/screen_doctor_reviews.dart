import 'package:flutter/material.dart';

class ScreenDoctorReviews extends StatelessWidget {
  const ScreenDoctorReviews({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF6B7280);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đánh giá của tôi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tổng quan đánh giá
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF135BEC), Color(0xFF1E88E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  '4.8',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Icon(
                      index < 4 ? Icons.star : Icons.star_half,
                      color: Colors.amber,
                      size: 24,
                    );
                  }),
                ),
                const SizedBox(height: 8),
                const Text(
                  '156 đánh giá',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Phân bố đánh giá
          _buildRatingDistribution(),
          const SizedBox(height: 24),

          // Danh sách đánh giá
          const Text(
            'Đánh giá gần đây',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 12),
          
          _buildReviewCard(
            'Lê Văn C',
            5,
            'Bác sĩ tận tâm, nhiệt tình. Giải thích rất kỹ về bệnh tình.',
            '10/11/2024',
          ),
          _buildReviewCard(
            'Phạm Thị D',
            5,
            'Khám rất kỹ càng, tư vấn chi tiết. Rất hài lòng!',
            '08/11/2024',
          ),
          _buildReviewCard(
            'Hoàng Văn E',
            4,
            'Bác sĩ giỏi, nhưng thời gian chờ hơi lâu.',
            '05/11/2024',
          ),
          _buildReviewCard(
            'Nguyễn Thị F',
            5,
            'Rất chuyên nghiệp và chu đáo. Cảm ơn bác sĩ!',
            '02/11/2024',
          ),
          _buildReviewCard(
            'Trần Văn G',
            4,
            'Tư vấn tốt, giải thích dễ hiểu.',
            '30/10/2024',
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDistribution() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phân bố đánh giá',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildRatingBar(5, 120, 156),
          _buildRatingBar(4, 25, 156),
          _buildRatingBar(3, 8, 156),
          _buildRatingBar(2, 2, 156),
          _buildRatingBar(1, 1, 156),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, int count, int total) {
    final percentage = (count / total * 100).toInt();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Row(
              children: [
                Text('$stars', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                const Icon(Icons.star, size: 16, color: Colors.amber),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: count / total,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 50,
            child: Text(
              '$count ($percentage%)',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(String name, int rating, String comment, String date) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF135BEC).withOpacity(0.1),
                  child: Text(
                    name[0],
                    style: const TextStyle(
                      color: Color(0xFF135BEC),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            date,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              comment,
              style: const TextStyle(
                color: Color(0xFF111318),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
