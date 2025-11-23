import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/family_forum_service.dart';
import '../../../services/auth_service.dart';
import '../../../data/models/family_forum_models.dart';
import '../../../widgets/app_bottom_nav.dart';

class ScreenForum extends StatefulWidget {
  const ScreenForum({super.key});

  @override
  State<ScreenForum> createState() => _ScreenForumState();
}

class _ScreenForumState extends State<ScreenForum> {
  final _forumService = ForumService();
  final _authService = AuthService();
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const textPrimary = Color(0xFF111318);

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
            child: Row(children: [
              _Tab(
                label: 'Tất cả',
                active: _selectedCategory == 'all',
                onTap: () => setState(() => _selectedCategory = 'all'),
              ),
              _Tab(
                label: 'Hỏi đáp',
                active: _selectedCategory == 'questions',
                onTap: () => setState(() => _selectedCategory = 'questions'),
              ),
              _Tab(
                label: 'Chia sẻ',
                active: _selectedCategory == 'sharing',
                onTap: () => setState(() => _selectedCategory = 'sharing'),
              ),
            ]),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ForumThreadModel>>(
            stream: _forumService.getForumThreads(
              category: _selectedCategory == 'all' ? null : _selectedCategory,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Lỗi: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final threads = snapshot.data ?? [];

              if (threads.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.forum_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có bài viết nào',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: threads.length,
                itemBuilder: (context, index) {
                  final thread = threads[index];
                  return _PostCard(thread: thread);
                },
              );
            },
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateThreadDialog(context),
        backgroundColor: const Color(0xFF135BEC),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  Future<void> _showCreateThreadDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String category = 'questions';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tạo bài viết mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Nội dung',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(
                    labelText: 'Danh mục',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'questions', child: Text('Hỏi đáp')),
                    DropdownMenuItem(value: 'sharing', child: Text('Chia sẻ')),
                    DropdownMenuItem(value: 'general', child: Text('Chung')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => category = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || contentController.text.isEmpty) return;

                final userId = await _authService.getUserId();
                final userName = await _authService.getUserName(); // Need to implement getUserName in AuthService or fetch profile

                if (userId != null) {
                  await _forumService.createThread(
                    userId: userId,
                    userName: userName ?? 'Người dùng',
                    title: titleController.text,
                    content: contentController.text,
                    category: category,
                  );
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Đăng'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Tab({required this.label, this.active = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    final color = active ? primary : const Color(0xFF6B7280);
    final border = active ? Border(bottom: BorderSide(color: primary, width: 3)) : const Border(bottom: BorderSide(color: Colors.transparent, width: 3));
    
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(border: border),
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final ForumThreadModel thread;

  const _PostCard({required this.thread});

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
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/topic-detail',
          arguments: {'threadId': thread.threadId, 'title': thread.title},
        );
      },
      child: Container(
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Đăng bởi ${thread.userName} - ${_getTimeAgo(thread.createdAt)}',
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            thread.title,
            style: const TextStyle(color: Color(0xFF111318), fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            thread.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF4B5563), fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.remove_red_eye, size: 16, color: Color(0xFF6B7280)),
            const SizedBox(width: 4),
            Text('${thread.viewCount}', style: const TextStyle(color: Color(0xFF6B7280))),
            const SizedBox(width: 12),
            const Icon(Icons.chat_bubble, size: 16, color: Color(0xFF6B7280)),
            const SizedBox(width: 4),
            Text('${thread.replyCount}', style: const TextStyle(color: Color(0xFF6B7280))),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                thread.category == 'questions' ? 'Hỏi đáp' : 
                thread.category == 'sharing' ? 'Chia sẻ' : 'Chung',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}