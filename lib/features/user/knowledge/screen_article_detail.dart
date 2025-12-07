import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/knowledge_article_model.dart';

class ScreenArticleDetail extends StatefulWidget {
  final KnowledgeArticleModel? article;
  
  const ScreenArticleDetail({super.key, this.article});

  @override
  State<ScreenArticleDetail> createState() => _ScreenArticleDetailState();
}

class _ScreenArticleDetailState extends State<ScreenArticleDetail> {
  bool _isBookmarked = false;
  int _likeCount = 245;
  bool _isLiked = false;

  void _toggleBookmark() {
    setState(() => _isBookmarked = !_isBookmarked);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isBookmarked ? 'Đã lưu bài viết' : 'Đã bỏ lưu bài viết'),
        backgroundColor: _isBookmarked ? Colors.green : Colors.grey,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _shareArticle() {
    final title = widget.article?.title ?? '10 Dấu hiệu cảnh báo đột quỵ bạn không nên bỏ qua';
    final shareText = 'Đọc bài viết: $title\n\nTừ ứng dụng SEWS - Cảnh báo sớm đột quỵ';
    
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép liên kết bài viết'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF6B7280);

    // Use article data if available, otherwise use default
    final title = widget.article?.title ?? '10 Dấu hiệu cảnh báo đột quỵ bạn không nên bỏ qua';
    final category = widget.article?.meta ?? 'Sức khỏe tim mạch';
    final imageUrl = widget.article?.imageUrl ?? 'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?w=800';
    final description = widget.article?.description ?? 'Đột quỵ là một trong những nguyên nhân hàng đầu gây tử vong và tàn tật ở Việt Nam.';

    return Scaffold(
      backgroundColor: bgLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: _toggleBookmark,
                icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                tooltip: _isBookmarked ? 'Bỏ lưu' : 'Lưu bài viết',
              ),
              IconButton(
                onPressed: _shareArticle,
                icon: const Icon(Icons.share),
                tooltip: 'Chia sẻ',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.access_time, size: 16, color: textMuted),
                      const SizedBox(width: 4),
                      const Text('5 phút đọc', style: TextStyle(fontSize: 12, color: textMuted)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary, height: 1.2),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=1'),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('BS. Nguyễn Văn A', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('Chuyên khoa Tim mạch', style: TextStyle(fontSize: 12, color: textMuted)),
                        ],
                      ),
                      const Spacer(),
                      const Text('15/10/2024', style: TextStyle(fontSize: 12, color: textMuted)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 16, color: textPrimary, height: 1.6),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '1. Tê liệt hoặc yếu đột ngột',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cảm giác tê hoặc yếu đột ngột ở mặt, tay hoặc chân, đặc biệt là một bên cơ thể. Đây là dấu hiệu phổ biến nhất của đột quỵ.',
                    style: TextStyle(fontSize: 16, color: textPrimary, height: 1.6),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '2. Khó nói hoặc hiểu lời nói',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Nói ngọng, khó nói hoặc không hiểu được người khác đang nói gì. Có thể bị lú lẫn hoặc khó diễn đạt ý tưởng.',
                    style: TextStyle(fontSize: 16, color: textPrimary, height: 1.6),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '3. Rối loạn thị giác',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mất thị lực đột ngột ở một hoặc cả hai mắt, hoặc nhìn đôi. Đây là dấu hiệu nghiêm trọng cần được xử lý ngay lập tức.',
                    style: TextStyle(fontSize: 16, color: textPrimary, height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.amber[700], size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Nếu bạn hoặc người thân có bất kỳ dấu hiệu nào trên, hãy gọi cấp cứu 115 ngay lập tức!',
                            style: TextStyle(fontSize: 14, color: Colors.amber[900], fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ActionButton(
                        icon: _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                        label: '$_likeCount',
                        isActive: _isLiked,
                        onPressed: _toggleLike,
                      ),
                      _ActionButton(
                        icon: Icons.comment_outlined,
                        label: '32',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tính năng bình luận đang phát triển')),
                          );
                        },
                      ),
                      _ActionButton(
                        icon: Icons.share_outlined,
                        label: 'Chia sẻ',
                        onPressed: _shareArticle,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: isActive ? const Color(0xFF135BEC) : Colors.grey[700]),
      label: Text(label, style: TextStyle(color: isActive ? const Color(0xFF135BEC) : Colors.grey[700])),
      style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
    );
  }
}