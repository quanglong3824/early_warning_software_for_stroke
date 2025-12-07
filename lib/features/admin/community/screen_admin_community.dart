import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class ScreenAdminCommunity extends StatefulWidget {
  const ScreenAdminCommunity({super.key});

  @override
  State<ScreenAdminCommunity> createState() => _ScreenAdminCommunityState();
}

class _ScreenAdminCommunityState extends State<ScreenAdminCommunity> {
  final _db = FirebaseDatabase.instance.ref();
  String _selectedTab = 'forum';
  bool _isLoading = true;
  List<Map<String, dynamic>> _forumTopics = [];
  List<Map<String, dynamic>> _reviews = [];
  Map<String, dynamic> _forumStats = {'topics': 0, 'comments': 0, 'members': 0};
  Map<String, dynamic> _reviewStats = {'total': 0, 'avgRating': 0.0};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadForumData(),
      _loadReviewsData(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadForumData() async {
    try {
      final snapshot = await _db.child('forum_threads').get();
      
      if (!snapshot.exists || snapshot.value == null) {
        setState(() {
          _forumTopics = [];
          _forumStats = {'topics': 0, 'comments': 0, 'members': 0};
        });
        return;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final topics = <Map<String, dynamic>>[];
      int totalComments = 0;
      final members = <String>{};

      for (var entry in data.entries) {
        final topicData = Map<String, dynamic>.from(entry.value as Map);
        final commentsCount = topicData['commentsCount'] as int? ?? 0;
        totalComments += commentsCount;
        
        final authorId = topicData['authorId'] as String?;
        if (authorId != null) members.add(authorId);

        // Get author name
        String authorName = 'Người dùng';
        if (authorId != null) {
          try {
            final userSnapshot = await _db.child('users/$authorId/name').get();
            if (userSnapshot.exists) {
              authorName = userSnapshot.value as String? ?? 'Người dùng';
            }
          } catch (e) {
            // Use default
          }
        }

        topics.add({
          'id': entry.key,
          'title': topicData['title'] ?? 'Chủ đề',
          'content': topicData['content'] ?? '',
          'authorName': authorName,
          'commentsCount': commentsCount,
          'createdAt': topicData['createdAt'] ?? 0,
        });
      }

      // Sort by createdAt descending
      topics.sort((a, b) => (b['createdAt'] as int).compareTo(a['createdAt'] as int));

      setState(() {
        _forumTopics = topics;
        _forumStats = {
          'topics': topics.length,
          'comments': totalComments,
          'members': members.length,
        };
      });
    } catch (e) {
      debugPrint('Error loading forum data: $e');
    }
  }

  Future<void> _loadReviewsData() async {
    try {
      final snapshot = await _db.child('reviews').get();
      
      if (!snapshot.exists || snapshot.value == null) {
        setState(() {
          _reviews = [];
          _reviewStats = {'total': 0, 'avgRating': 0.0};
        });
        return;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final reviews = <Map<String, dynamic>>[];
      double totalRating = 0;

      for (var entry in data.entries) {
        final reviewData = Map<String, dynamic>.from(entry.value as Map);
        final rating = (reviewData['rating'] as num?)?.toDouble() ?? 0;
        totalRating += rating;

        // Get names
        String userName = 'Người dùng';
        String doctorName = 'Bác sĩ';
        
        final userId = reviewData['userId'] as String?;
        final doctorId = reviewData['doctorId'] as String?;

        if (userId != null) {
          try {
            final userSnapshot = await _db.child('users/$userId/name').get();
            if (userSnapshot.exists) {
              userName = userSnapshot.value as String? ?? 'Người dùng';
            }
          } catch (e) {
            // Use default
          }
        }

        if (doctorId != null) {
          try {
            final doctorSnapshot = await _db.child('users/$doctorId/name').get();
            if (doctorSnapshot.exists) {
              doctorName = doctorSnapshot.value as String? ?? 'Bác sĩ';
            }
          } catch (e) {
            // Use default
          }
        }

        reviews.add({
          'id': entry.key,
          'userName': userName,
          'doctorName': doctorName,
          'rating': rating.toInt(),
          'comment': reviewData['comment'] ?? '',
          'createdAt': reviewData['createdAt'] ?? 0,
        });
      }

      // Sort by createdAt descending
      reviews.sort((a, b) => (b['createdAt'] as int).compareTo(a['createdAt'] as int));

      setState(() {
        _reviews = reviews;
        _reviewStats = {
          'total': reviews.length,
          'avgRating': reviews.isEmpty ? 0.0 : totalRating / reviews.length,
        };
      });
    } catch (e) {
      debugPrint('Error loading reviews data: $e');
    }
  }

  String _formatTimeAgo(int timestamp) {
    if (timestamp == 0) return 'N/A';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final diff = DateTime.now().difference(dt);
    
    if (diff.inMinutes < 60) return '${diff.inMinutes}ph trước';
    if (diff.inHours < 24) return '${diff.inHours}h trước';
    return '${diff.inDays}d trước';
  }

  Future<void> _deleteTopic(String topicId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa chủ đề này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _db.child('forum_threads/$topicId').remove();
        _loadForumData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa chủ đề')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa đánh giá này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _db.child('reviews/$reviewId').remove();
        _loadReviewsData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa đánh giá')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: const Text('Tổng hợp Cộng đồng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedTab == 'forum'
                    ? _buildForum()
                    : _buildReviews(),
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
              _StatCard(
                title: 'Tổng chủ đề',
                value: '${_forumStats['topics']}',
                color: Colors.blue,
              ),
              const SizedBox(width: 16),
              _StatCard(
                title: 'Bình luận',
                value: '${_forumStats['comments']}',
                color: Colors.green,
              ),
              const SizedBox(width: 16),
              _StatCard(
                title: 'Thành viên',
                value: '${_forumStats['members']}',
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _forumTopics.isEmpty
                  ? const Center(child: Text('Chưa có chủ đề nào'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _forumTopics.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final topic = _forumTopics[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            child: const Icon(Icons.forum, color: Colors.blue),
                          ),
                          title: Text(
                            topic['title'] ?? 'Chủ đề',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'Bởi ${topic['authorName']} • ${_formatTimeAgo(topic['createdAt'])} • ${topic['commentsCount']} bình luận',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility, size: 20),
                                onPressed: () {
                                  // TODO: Navigate to topic detail
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                onPressed: () => _deleteTopic(topic['id']),
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
              _StatCard(
                title: 'Tổng đánh giá',
                value: '${_reviewStats['total']}',
                color: Colors.amber,
              ),
              const SizedBox(width: 16),
              _StatCard(
                title: 'Điểm TB',
                value: (_reviewStats['avgRating'] as double).toStringAsFixed(1),
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _reviews.isEmpty
                  ? const Center(child: Text('Chưa có đánh giá nào'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _reviews.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final review = _reviews[index];
                        final rating = review['rating'] as int;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.amber.withOpacity(0.1),
                            child: const Icon(Icons.star, color: Colors.amber),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${review['userName']} → ${review['doctorName']}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
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
                          subtitle: Text(
                            review['comment'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                            onPressed: () => _deleteReview(review['id']),
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
