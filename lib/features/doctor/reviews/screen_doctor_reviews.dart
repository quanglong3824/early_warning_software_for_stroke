import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/doctor_review_service.dart';

class ScreenDoctorReviews extends StatefulWidget {
  const ScreenDoctorReviews({super.key});

  @override
  State<ScreenDoctorReviews> createState() => _ScreenDoctorReviewsState();
}

class _ScreenDoctorReviewsState extends State<ScreenDoctorReviews> {
  final _authService = AuthService();
  final _reviewService = DoctorReviewService();
  String? _doctorId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctorId();
  }

  Future<void> _loadDoctorId() async {
    final id = await _authService.getUserId();
    if (mounted) {
      setState(() {
        _doctorId = id;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF111318);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Đánh giá của tôi')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_doctorId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Đánh giá của tôi')),
        body: const Center(
          child: Text('Không thể tải thông tin bác sĩ'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đánh giá của tôi'),
      ),
      body: StreamBuilder<ReviewStats>(
        stream: _reviewService.getReviewStats(_doctorId!),
        builder: (context, statsSnapshot) {
          return StreamBuilder<List<ReviewModel>>(
            stream: _reviewService.getReviews(_doctorId!),
            builder: (context, reviewsSnapshot) {
              if (statsSnapshot.connectionState == ConnectionState.waiting &&
                  reviewsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (statsSnapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Lỗi: ${statsSnapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                );
              }

              final stats = statsSnapshot.data ?? ReviewStats.empty();
              final reviews = reviewsSnapshot.data ?? [];

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Tổng quan đánh giá
                  _buildRatingOverview(stats),
                  const SizedBox(height: 24),

                  // Phân bố đánh giá
                  _buildRatingDistribution(stats),
                  const SizedBox(height: 24),

                  // Danh sách đánh giá
                  const Text(
                    'Đánh giá gần đây',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (reviews.isEmpty)
                    _buildEmptyReviews()
                  else
                    ...reviews.map((review) => _buildReviewCard(review)),
                ],
              );
            },
          );
        },
      ),
    );
  }


  Widget _buildRatingOverview(ReviewStats stats) {
    return Container(
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
          Text(
            stats.averageRating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _buildStarRating(stats.averageRating),
          ),
          const SizedBox(height: 8),
          Text(
            '${stats.totalReviews} đánh giá',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStarRating(double rating) {
    final stars = <Widget>[];
    for (int i = 1; i <= 5; i++) {
      if (i <= rating.floor()) {
        stars.add(const Icon(Icons.star, color: Colors.amber, size: 24));
      } else if (i - rating < 1 && i - rating > 0) {
        stars.add(const Icon(Icons.star_half, color: Colors.amber, size: 24));
      } else {
        stars.add(const Icon(Icons.star_border, color: Colors.amber, size: 24));
      }
    }
    return stars;
  }

  Widget _buildRatingDistribution(ReviewStats stats) {
    final total = stats.totalReviews;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
          for (int star = 5; star >= 1; star--)
            _buildRatingBar(star, stats.distribution[star] ?? 0, total),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, int count, int total) {
    final percentage = total > 0 ? (count / total * 100).toInt() : 0;
    final fraction = total > 0 ? count / total : 0.0;

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
                  widthFactor: fraction,
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
            width: 60,
            child: Text(
              '$count ($percentage%)',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEmptyReviews() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có đánh giá nào',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đánh giá từ bệnh nhân sẽ xuất hiện ở đây',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    final dateStr = _formatDate(review.createdAt);

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
                  backgroundColor: const Color(0xFF135BEC).withValues(alpha: 0.1),
                  backgroundImage: review.userAvatar != null && !review.isAnonymous
                      ? NetworkImage(review.userAvatar!)
                      : null,
                  child: review.userAvatar == null || review.isAnonymous
                      ? Text(
                          review.displayName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF135BEC),
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.displayName,
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
                              index < review.rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            dateStr,
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
                if (!review.hasResponse)
                  IconButton(
                    icon: const Icon(Icons.reply, color: Color(0xFF135BEC)),
                    onPressed: () => _showResponseDialog(review),
                    tooltip: 'Phản hồi',
                  ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                review.comment!,
                style: const TextStyle(
                  color: Color(0xFF111318),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
            if (review.hasResponse) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF135BEC).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF135BEC).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.reply,
                          size: 16,
                          color: Color(0xFF135BEC),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Phản hồi của bạn',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF135BEC),
                          ),
                        ),
                        const Spacer(),
                        if (review.responseAt != null)
                          Text(
                            _formatDate(review.responseAt!),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      review.doctorResponse!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF111318),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showResponseDialog(ReviewModel review) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Phản hồi đánh giá'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show original review
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        review.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      ...List.generate(5, (index) {
                        return Icon(
                          index < review.rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 14,
                        );
                      }),
                    ],
                  ),
                  if (review.comment != null && review.comment!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      review.comment!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Nhập phản hồi của bạn...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập nội dung phản hồi')),
                );
                return;
              }

              Navigator.pop(context);
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              final success = await _reviewService.respondToReview(
                _doctorId!,
                review.reviewId,
                controller.text.trim(),
              );

              if (mounted) {
                Navigator.pop(context); // Close loading
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Đã gửi phản hồi thành công'
                          : 'Không thể gửi phản hồi. Vui lòng thử lại.',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Gửi phản hồi'),
          ),
        ],
      ),
    );
  }
}
