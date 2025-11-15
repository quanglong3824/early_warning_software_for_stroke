import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/app_data_provider.dart';
import '../../../widgets/app_bottom_nav.dart';

class ScreenKnowledge extends StatefulWidget {
  const ScreenKnowledge({super.key});

  @override
  State<ScreenKnowledge> createState() => _ScreenKnowledgeState();
}

class _ScreenKnowledgeState extends State<ScreenKnowledge> {
  int activeChip = 0;

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF6B7280);
    final chips = [
      'Tất cả',
      'Phòng ngừa Đột quỵ',
      'Sức khỏe Tim mạch',
      'Tiểu đường',
      'Dinh dưỡng',
      'Lối sống',
    ];

    final appData = Provider.of<AppDataProvider>(context);
    final articles = appData.getArticlesByCategory(chips[activeChip]);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text('Thư viện Kiến thức', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.search, color: textPrimary))],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final active = index == activeChip;
                return GestureDetector(
                  onTap: () => setState(() => activeChip = index),
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
                      style: TextStyle(color: active ? Colors.white : textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: chips.length,
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: articles.length,
              separatorBuilder: (context, index) => const Divider(color: Color(0xFFE5E7EB)),
              itemBuilder: (context, index) {
                final article = articles[index];
                return _KnowledgeCard(
                  meta: article.meta,
                  title: article.title,
                  desc: article.description,
                  imageUrl: article.imageUrl,
                  overlayIcon: article.type == 'video' ? Icons.play_circle : null,
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }
}

class _KnowledgeCard extends StatelessWidget {
  final String meta;
  final String title;
  final String desc;
  final String imageUrl;
  final IconData? overlayIcon;
  const _KnowledgeCard({
    required this.meta,
    required this.title,
    required this.desc,
    required this.imageUrl,
    this.overlayIcon,
  });

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF6B7280);
    return InkWell(
      onTap: () {},
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(meta, style: const TextStyle(color: textMuted, fontSize: 13)),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(color: textMuted, fontSize: 13)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(imageUrl, width: 112, height: 112, fit: BoxFit.cover),
              ),
              if (overlayIcon != null)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                    alignment: Alignment.center,
                    child: Icon(overlayIcon, color: Colors.white, size: 36),
                  ),
                ),
            ]),
          ),
        ],
      ),
    );
  }
}