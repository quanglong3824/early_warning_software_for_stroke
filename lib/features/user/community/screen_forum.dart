import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/app_data_provider.dart';
import '../../../widgets/app_bottom_nav.dart';

class ScreenForum extends StatelessWidget {
  const ScreenForum({super.key});

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF6B7280);

    final appData = Provider.of<AppDataProvider>(context);
    final forumPosts = appData.forumPosts;

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: const Text('Diễn đàn', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.search, color: textPrimary))],
      ),
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: const [
              _Tab(label: 'Mới nhất', active: true),
              _Tab(label: 'Phổ biến nhất'),
              _Tab(label: 'Chủ đề của tôi'),
            ]),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: forumPosts.length,
            itemBuilder: (context, index) {
              final post = forumPosts[index];
              final timeAgo = _getTimeAgo(post.createdAt);
              return _PostCard(
                postId: post.id,
                author: post.authorName,
                time: timeAgo,
                title: post.title,
                likes: post.likes,
                comments: post.comments,
              );
            },
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/create_post'),
        backgroundColor: const Color(0xFF135BEC),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  static String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  const _Tab({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    final color = active ? primary : const Color(0xFF6B7280);
    final border = active ? Border(bottom: BorderSide(color: primary, width: 3)) : const Border(bottom: BorderSide(color: Colors.transparent, width: 3));
    return Expanded(
      child: Container(
        decoration: BoxDecoration(border: border),
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final String postId;
  final String author;
  final String time;
  final String title;
  final int likes;
  final int comments;
  const _PostCard({required this.postId, required this.author, required this.time, required this.title, required this.likes, required this.comments});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/topic-detail'),
      child: Container(
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Đăng bởi $author - $time', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(color: Color(0xFF111318), fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.thumb_up, size: 16, color: Color(0xFF6B7280)),
            const SizedBox(width: 4),
            Text('$likes', style: const TextStyle(color: Color(0xFF6B7280))),
            const SizedBox(width: 12),
            const Icon(Icons.chat_bubble, size: 16, color: Color(0xFF6B7280)),
            const SizedBox(width: 4),
            Text('$comments', style: const TextStyle(color: Color(0xFF6B7280))),
          ]),
        ]),
      ),
    );
  }
}