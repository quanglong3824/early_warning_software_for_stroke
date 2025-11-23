import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/family_forum_service.dart';
import '../../../services/auth_service.dart';
import '../../../data/models/family_forum_models.dart';

class ScreenTopicDetail extends StatefulWidget {
  final String threadId;
  final String title;

  const ScreenTopicDetail({
    super.key,
    required this.threadId,
    required this.title,
  });

  @override
  State<ScreenTopicDetail> createState() => _ScreenTopicDetailState();
}

class _ScreenTopicDetailState extends State<ScreenTopicDetail> {
  final _forumService = ForumService();
  final _authService = AuthService();
  final _commentController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _forumService.incrementViewCount(widget.threadId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    try {
      final userId = await _authService.getUserId();
      final userName = await _authService.getUserName();

      if (userId != null) {
        await _forumService.createPost(
          threadId: widget.threadId,
          userId: userId,
          userName: userName ?? 'Người dùng',
          content: _commentController.text.trim(),
        );
        _commentController.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const textPrimary = Color(0xFF111318);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ForumPostModel>>(
              stream: _forumService.getThreadPosts(widget.threadId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final posts = snapshot.data ?? [];

                if (posts.isEmpty) {
                  return const Center(child: Text('Chưa có bình luận nào. Hãy là người đầu tiên!'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    // First post is usually the thread content, but here we treat all as posts
                    // You might want to fetch thread details separately to show as header
                    return _CommentItem(post: post);
                  },
                );
              },
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Viết bình luận...',
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            height: 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF135BEC),
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
              ),
              onPressed: _isSending ? null : _sendComment,
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final ForumPostModel post;

  const _CommentItem({required this.post});

  String _getTimeAgo(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              post.userName.isNotEmpty ? post.userName[0].toUpperCase() : '?',
              style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(post.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text(
                      _getTimeAgo(post.createdAt),
                      style: const TextStyle(color: Color(0xFF616F89), fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(post.content),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
