import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/knowledge_article_model.dart';
import '../../../services/knowledge_service.dart';
import '../../../widgets/app_bottom_nav.dart';
import '../../../utils/pagination_utils.dart';
import '../../../utils/image_utils.dart';
import 'screen_article_detail.dart';

/// User Knowledge Screen with search functionality, updated badge, and pagination
/// Requirements: 9.4, 9.5, 10.3
class ScreenKnowledge extends StatefulWidget {
  const ScreenKnowledge({super.key});

  @override
  State<ScreenKnowledge> createState() => _ScreenKnowledgeState();
}

class _ScreenKnowledgeState extends State<ScreenKnowledge> {
  int activeChip = 0;
  bool _isSearching = false;
  final _searchController = TextEditingController();
  final _knowledgeService = KnowledgeService();
  final _scrollController = ScrollController();
  
  // Search state
  List<KnowledgeArticleModel>? _searchResults;
  bool _isLoadingSearch = false;
  
  // Pagination state - Requirements: 10.3
  PaginationState<KnowledgeArticleModel> _paginationState = PaginationState.initial();

  final chips = [
    'Tất cả',
    'Phòng ngừa Đột quỵ',
    'Sức khỏe Tim mạch',
    'Tiểu đường',
    'Dinh dưỡng',
    'Lối sống',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadArticles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.isNearBottom &&
        !_paginationState.isLoading &&
        _paginationState.hasMore &&
        !_isSearching) {
      _loadMoreArticles();
    }
  }

  Future<void> _loadArticles() async {
    setState(() {
      _paginationState = PaginationState<KnowledgeArticleModel>.initial().loading();
    });

    try {
      final selectedCategory = chips[activeChip];
      final result = await _knowledgeService.getArticlesPaginated(
        category: selectedCategory,
      );
      
      setState(() {
        _paginationState = _paginationState.success(
          result.items,
          newLastKey: result.lastKey,
          hasMoreItems: result.hasMore,
        );
      });
    } catch (e) {
      setState(() {
        _paginationState = _paginationState.failure('Không thể tải bài viết');
      });
    }
  }

  Future<void> _loadMoreArticles() async {
    if (_paginationState.isLoading || !_paginationState.hasMore) return;

    setState(() {
      _paginationState = _paginationState.loading();
    });

    try {
      final selectedCategory = chips[activeChip];
      final result = await _knowledgeService.getArticlesPaginated(
        category: selectedCategory,
        lastKey: _paginationState.lastKey,
      );
      
      setState(() {
        _paginationState = _paginationState.success(
          result.items,
          newLastKey: result.lastKey,
          hasMoreItems: result.hasMore,
        );
      });
    } catch (e) {
      setState(() {
        _paginationState = _paginationState.failure('Không thể tải thêm bài viết');
      });
    }
  }

  void _onCategoryChanged(int index) {
    setState(() {
      activeChip = index;
      _paginationState = PaginationState<KnowledgeArticleModel>.initial();
    });
    _loadArticles();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = null;
        _isLoadingSearch = false;
      });
      return;
    }

    setState(() => _isLoadingSearch = true);
    try {
      final results = await _knowledgeService.searchArticles(query);
      setState(() {
        _searchResults = results;
        _isLoadingSearch = false;
      });
    } catch (e) {
      setState(() => _isLoadingSearch = false);
    }
  }

  void _trackView(String articleId) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _knowledgeService.trackView(articleId, userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: _isSearching
            ? _buildSearchField()
            : const Text('Thư viện Kiến thức', 
                style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchResults = null;
                }
              });
            },
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: textPrimary),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isSearching) _buildCategoryChips(primary, textPrimary),
          Expanded(
            child: _isSearching 
                ? _buildSearchResults()
                : _buildArticlesList(),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Tìm kiếm bài viết...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey),
      ),
      onChanged: (value) {
        // Debounce search
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_searchController.text == value) {
            _performSearch(value);
          }
        });
      },
      onSubmitted: _performSearch,
    );
  }

  Widget _buildCategoryChips(Color primary, Color textPrimary) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final active = index == activeChip;
          return GestureDetector(
            onTap: () => _onCategoryChanged(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: active ? primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? primary : const Color(0xFFE5E7EB)),
              ),
              alignment: Alignment.center,
              child: Text(
                chips[index],
                style: TextStyle(
                  color: active ? Colors.white : textPrimary, 
                  fontSize: 13, 
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: chips.length,
      ),
    );
  }


  Widget _buildSearchResults() {
    if (_isLoadingSearch) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nhập từ khóa để tìm kiếm',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_searchResults!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy kết quả',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử tìm kiếm với từ khóa khác',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _searchResults!.length,
      separatorBuilder: (context, index) => const Divider(color: Color(0xFFE5E7EB)),
      itemBuilder: (context, index) {
        final article = _searchResults![index];
        return _KnowledgeCard(
          article: article,
          onTap: () => _openArticle(article),
        );
      },
    );
  }

  /// Build paginated articles list with infinite scroll
  /// Requirements: 10.3
  Widget _buildArticlesList() {
    final state = _paginationState;

    // Show error state
    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadArticles,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    // Show initial loading
    if (state.items.isEmpty && state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show empty state
    if (state.items.isEmpty && !state.isLoading) {
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
            const SizedBox(height: 8),
            Text(
              'Các bài viết mới sẽ sớm được cập nhật',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Build paginated list with infinite scroll
    final itemCount = state.items.length + (state.hasMore ? 1 : 0);

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: itemCount,
      separatorBuilder: (context, index) => const Divider(color: Color(0xFFE5E7EB)),
      itemBuilder: (context, index) {
        // Show loading indicator at the bottom
        if (index >= state.items.length) {
          return _buildLoadingIndicator();
        }

        final article = state.items[index];
        return _KnowledgeCard(
          article: article,
          onTap: () => _openArticle(article),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    if (!_paginationState.isLoading) {
      return const SizedBox.shrink();
    }

    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  void _openArticle(KnowledgeArticleModel article) {
    _trackView(article.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScreenArticleDetail(article: article),
      ),
    );
  }
}

class _KnowledgeCard extends StatelessWidget {
  final KnowledgeArticleModel article;
  final VoidCallback onTap;

  const _KnowledgeCard({
    required this.article,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF6B7280);
    
    // Check if article was updated recently (within 7 days)
    final isRecentlyUpdated = article is KnowledgeArticleExtended && 
        (article as KnowledgeArticleExtended).updatedAt != null &&
        DateTime.now().difference((article as KnowledgeArticleExtended).updatedAt!).inDays < 7;

    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        article.meta, 
                        style: const TextStyle(color: textMuted, fontSize: 13),
                      ),
                    ),
                    // Updated badge - Requirements 9.5
                    if (isRecentlyUpdated)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.update, size: 12, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              'Cập nhật ${_formatUpdateDate((article as KnowledgeArticleExtended).updatedAt!)}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  article.title, 
                  style: const TextStyle(
                    color: textPrimary, 
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  article.description, 
                  style: const TextStyle(color: textMuted, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: Stack(
              children: [
                OptimizedNetworkImage(
                  imageUrl: article.imageUrl,
                  width: 112,
                  height: 112,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(8),
                  errorWidget: Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
                if (article.type == 'video')
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.play_circle, color: Colors.white, size: 36),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatUpdateDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'hôm nay';
    } else if (diff.inDays == 1) {
      return 'hôm qua';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}
