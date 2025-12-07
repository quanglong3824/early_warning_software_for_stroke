import 'package:flutter/material.dart';
import '../../../services/knowledge_service.dart';

/// Admin Knowledge Article Editor Screen
/// Requirements: 9.1 - CRUD for articles with media support
class ScreenAdminKnowledgeEditor extends StatefulWidget {
  final String? articleId; // null for new article

  const ScreenAdminKnowledgeEditor({super.key, this.articleId});

  @override
  State<ScreenAdminKnowledgeEditor> createState() => _ScreenAdminKnowledgeEditorState();
}

class _ScreenAdminKnowledgeEditorState extends State<ScreenAdminKnowledgeEditor> {
  final _formKey = GlobalKey<FormState>();
  final _knowledgeService = KnowledgeService();
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();
  
  String _selectedType = 'article';
  List<String> _selectedCategories = [];
  bool _isPublished = false;
  bool _isLoading = false;
  bool _isSaving = false;
  KnowledgeArticleExtended? _existingArticle;

  final List<String> _availableCategories = [
    'Phòng ngừa Đột quỵ',
    'Sức khỏe Tim mạch',
    'Tiểu đường',
    'Dinh dưỡng',
    'Lối sống',
    'Sức khỏe Tâm thần',
    'Thuốc & Điều trị',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.articleId != null) {
      _loadArticle();
    }
  }

  Future<void> _loadArticle() async {
    setState(() => _isLoading = true);
    try {
      final article = await _knowledgeService.getArticle(widget.articleId!);
      if (article != null && article is KnowledgeArticleExtended) {
        _existingArticle = article;
        _titleController.text = article.title;
        _descriptionController.text = article.description;
        _contentController.text = article.content ?? '';
        _imageUrlController.text = article.imageUrl;
        _videoUrlController.text = article.videoUrl ?? '';
        _selectedType = article.type;
        _selectedCategories = List.from(article.categories);
        _isPublished = article.isPublished;
      }
    } catch (e) {
      _showError('Không thể tải bài viết: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<void> _saveArticle() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategories.isEmpty) {
      _showError('Vui lòng chọn ít nhất một danh mục');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final readingTime = _estimateReadingTime(_contentController.text);
      final meta = _selectedType == 'video' 
          ? 'Video' 
          : 'Bài viết • $readingTime phút đọc';

      final article = KnowledgeArticleExtended(
        id: widget.articleId ?? '',
        type: _selectedType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        content: _contentController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        videoUrl: _selectedType == 'video' ? _videoUrlController.text.trim() : null,
        meta: meta,
        categories: _selectedCategories,
        publishedAt: _existingArticle?.publishedAt ?? DateTime.now(),
        authorId: _existingArticle?.authorId ?? 'admin',
        isPublished: _isPublished,
        viewCount: _existingArticle?.viewCount ?? 0,
        totalReadingTimeSeconds: _existingArticle?.totalReadingTimeSeconds ?? 0,
        updatedAt: DateTime.now(),
        mediaUrls: _existingArticle?.mediaUrls ?? [],
      );

      if (widget.articleId != null) {
        await _knowledgeService.updateArticle(widget.articleId!, article);
        _showSuccess('Đã cập nhật bài viết');
      } else {
        await _knowledgeService.createArticle(article);
        _showSuccess('Đã tạo bài viết mới');
      }
      
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showError('Lỗi khi lưu: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  int _estimateReadingTime(String content) {
    final wordCount = content.split(RegExp(r'\s+')).length;
    return (wordCount / 200).ceil().clamp(1, 60);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    _imageUrlController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.articleId != null;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: Text(isEditing ? 'Chỉnh sửa bài viết' : 'Tạo bài viết mới'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfoSection(),
                    const SizedBox(height: 24),
                    _buildContentSection(),
                    const SizedBox(height: 24),
                    _buildMediaSection(),
                    const SizedBox(height: 24),
                    _buildCategoriesSection(),
                    const SizedBox(height: 24),
                    _buildPublishSection(),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildCard(
      title: 'Thông tin cơ bản',
      child: Column(
        children: [
          _buildTypeSelector(),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Tiêu đề *',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v?.trim().isEmpty == true ? 'Vui lòng nhập tiêu đề' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Mô tả ngắn *',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (v) => v?.trim().isEmpty == true ? 'Vui lòng nhập mô tả' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        const Text('Loại: ', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(width: 16),
        ChoiceChip(
          label: const Text('Bài viết'),
          selected: _selectedType == 'article',
          onSelected: (selected) {
            if (selected) setState(() => _selectedType = 'article');
          },
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('Video'),
          selected: _selectedType == 'video',
          onSelected: (selected) {
            if (selected) setState(() => _selectedType = 'video');
          },
        ),
      ],
    );
  }

  Widget _buildContentSection() {
    return _buildCard(
      title: 'Nội dung',
      child: TextFormField(
        controller: _contentController,
        decoration: const InputDecoration(
          labelText: 'Nội dung bài viết *',
          border: OutlineInputBorder(),
          alignLabelWithHint: true,
        ),
        maxLines: 15,
        validator: (v) => v?.trim().isEmpty == true ? 'Vui lòng nhập nội dung' : null,
      ),
    );
  }

  Widget _buildMediaSection() {
    return _buildCard(
      title: 'Media',
      child: Column(
        children: [
          TextFormField(
            controller: _imageUrlController,
            decoration: const InputDecoration(
              labelText: 'URL hình ảnh đại diện *',
              border: OutlineInputBorder(),
              hintText: 'https://example.com/image.jpg',
            ),
            validator: (v) => v?.trim().isEmpty == true ? 'Vui lòng nhập URL hình ảnh' : null,
          ),
          if (_imageUrlController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _imageUrlController.text,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: const Center(child: Text('Không thể tải hình ảnh')),
                ),
              ),
            ),
          ],
          if (_selectedType == 'video') ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _videoUrlController,
              decoration: const InputDecoration(
                labelText: 'URL Video *',
                border: OutlineInputBorder(),
                hintText: 'https://youtube.com/watch?v=...',
              ),
              validator: (v) {
                if (_selectedType == 'video' && (v?.trim().isEmpty == true)) {
                  return 'Vui lòng nhập URL video';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildCategoriesSection() {
    return _buildCard(
      title: 'Danh mục',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _availableCategories.map((category) {
          final isSelected = _selectedCategories.contains(category);
          return FilterChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedCategories.add(category);
                } else {
                  _selectedCategories.remove(category);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPublishSection() {
    return _buildCard(
      title: 'Xuất bản',
      child: SwitchListTile(
        title: const Text('Xuất bản ngay'),
        subtitle: Text(
          _isPublished 
              ? 'Bài viết sẽ hiển thị cho người dùng' 
              : 'Bài viết sẽ được lưu nháp',
        ),
        value: _isPublished,
        onChanged: (value) => setState(() => _isPublished = value),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Hủy'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveArticle,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B46C1),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    widget.articleId != null ? 'Cập nhật' : 'Tạo bài viết',
                    style: const TextStyle(color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa bài viết này? Hành động này không thể hoàn tác.'),
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

    if (confirmed == true && widget.articleId != null) {
      try {
        await _knowledgeService.deleteArticle(widget.articleId!);
        _showSuccess('Đã xóa bài viết');
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        _showError('Lỗi khi xóa: $e');
      }
    }
  }
}
