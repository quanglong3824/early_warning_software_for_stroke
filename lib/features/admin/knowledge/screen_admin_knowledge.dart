import 'package:flutter/material.dart';
import '../../../services/knowledge_service.dart';
import 'screen_admin_knowledge_editor.dart';

class ScreenAdminKnowledge extends StatefulWidget {
  const ScreenAdminKnowledge({super.key});

  @override
  State<ScreenAdminKnowledge> createState() => _ScreenAdminKnowledgeState();
}

class _ScreenAdminKnowledgeState extends State<ScreenAdminKnowledge> {
  String _selectedTab = 'articles';
  final _knowledgeService = KnowledgeService();
  Map<String, dynamic> _stats = {};
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _knowledgeService.getArticleStats();
      setState(() {
        _stats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() => _isLoadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: const Text('Quản lý Kiến thức'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openEditor(null),
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
                  label: 'Kiến thức',
                  isSelected: _selectedTab == 'articles',
                  onTap: () => setState(() => _selectedTab = 'articles'),
                ),
                const SizedBox(width: 8),
                _TabButton(
                  label: 'Nhắc nhở',
                  isSelected: _selectedTab == 'reminders',
                  onTap: () => setState(() => _selectedTab = 'reminders'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedTab == 'articles' ? _buildArticles() : _buildReminders(),
          ),
        ],
      ),
    );
  }

  void _openEditor(String? articleId) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ScreenAdminKnowledgeEditor(articleId: articleId),
      ),
    );
    if (result == true) {
      _loadStats();
    }
  }

  Widget _buildArticles() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildStatsRow(),
          const SizedBox(height: 24),
          Expanded(child: _buildArticlesList()),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    if (_isLoadingStats) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Row(
      children: [
        _StatCard(
          title: 'Tổng bài viết',
          value: '${_stats['totalArticles'] ?? 0}',
          color: Colors.blue,
        ),
        const SizedBox(width: 16),
        _StatCard(
          title: 'Đã xuất bản',
          value: '${_stats['publishedArticles'] ?? 0}',
          color: Colors.green,
        ),
        const SizedBox(width: 16),
        _StatCard(
          title: 'Video',
          value: '${_stats['totalVideos'] ?? 0}',
          color: Colors.red,
        ),
        const SizedBox(width: 16),
        _StatCard(
          title: 'Lượt xem',
          value: _formatNumber(_stats['totalViews'] ?? 0),
          color: Colors.orange,
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }


  Widget _buildArticlesList() {
    return StreamBuilder<List<KnowledgeArticleExtended>>(
      stream: _knowledgeService.allArticlesStreamForAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final articles = snapshot.data ?? [];
        
        if (articles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Chưa có bài viết nào',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _openEditor(null),
                  icon: const Icon(Icons.add),
                  label: const Text('Tạo bài viết đầu tiên'),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemCount: articles.length,
          itemBuilder: (context, index) {
            final article = articles[index];
            return _ArticleCard(
              article: article,
              onEdit: () => _openEditor(article.id),
              onDelete: () => _confirmDelete(article),
              onTogglePublish: () => _togglePublish(article),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(KnowledgeArticleExtended article) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa "${article.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _knowledgeService.deleteArticle(article.id);
        _loadStats();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa bài viết'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _togglePublish(KnowledgeArticleExtended article) async {
    try {
      if (article.isPublished) {
        await _knowledgeService.unpublishArticle(article.id);
      } else {
        await _knowledgeService.publishArticle(article.id);
      }
      _loadStats();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildReminders() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              _StatCard(title: 'Tổng nhắc nhở', value: '234', color: Colors.orange),
              const SizedBox(width: 16),
              _StatCard(title: 'Đang hoạt động', value: '189', color: Colors.green),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: 15,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications, color: Colors.orange),
                    ),
                    title: Text('Nhắc nhở ${index + 1}'),
                    subtitle: Text('User ${index + 1} • Uống thuốc • 08:00 hàng ngày'),
                    trailing: Switch(value: index % 3 != 0, onChanged: (value) {}),
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

class _ArticleCard extends StatelessWidget {
  final KnowledgeArticleExtended article;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePublish;

  const _ArticleCard({
    required this.article,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePublish,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  image: article.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(article.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: article.imageUrl.isEmpty
                    ? Center(
                        child: Icon(
                          article.type == 'video' ? Icons.play_circle : Icons.article,
                          size: 48,
                          color: Colors.grey[600],
                        ),
                      )
                    : null,
              ),
              // Status badge
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: article.isPublished ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    article.isPublished ? 'Đã xuất bản' : 'Nháp',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
              // Type badge
              if (article.type == 'video')
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${article.viewCount} lượt xem',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  if (article.updatedAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Cập nhật: ${_formatDate(article.updatedAt!)}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 10),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          article.isPublished ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                          color: article.isPublished ? Colors.orange : Colors.green,
                        ),
                        onPressed: onTogglePublish,
                        tooltip: article.isPublished ? 'Ẩn bài viết' : 'Xuất bản',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: onEdit,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: onDelete,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
