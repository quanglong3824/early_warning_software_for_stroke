import 'package:flutter/material.dart';

class ScreenArticleDetail extends StatelessWidget {
  const ScreenArticleDetail({super.key});

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1505751172876-fa1923c5c528?w=800'),
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
                onPressed: () {},
                icon: const Icon(Icons.bookmark_border),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.share),
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
                        child: const Text(
                          'Sức khỏe tim mạch',
                          style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.access_time, size: 16, color: textMuted),
                      const SizedBox(width: 4),
                      const Text('5 phút đọc', style: TextStyle(fontSize: 12, color: textMuted)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '10 Dấu hiệu cảnh báo đột quỵ bạn không nên bỏ qua',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary, height: 1.2),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=1'),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('BS. Nguyễn Văn A', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('Chuyên khoa Tim mạch', style: TextStyle(fontSize: 12, color: textMuted)),
                        ],
                      ),
                      const Spacer(),
                      const Text('15/10/2024', style: TextStyle(fontSize: 12, color: textMuted)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Đột quỵ là một trong những nguyên nhân hàng đầu gây tử vong và tàn tật ở Việt Nam. Việc nhận biết sớm các dấu hiệu cảnh báo có thể cứu sống bạn hoặc người thân.',
                    style: TextStyle(fontSize: 16, color: textPrimary, height: 1.6),
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
                      _ActionButton(Icons.thumb_up_outlined, '245'),
                      _ActionButton(Icons.comment_outlined, '32'),
                      _ActionButton(Icons.share_outlined, 'Chia sẻ'),
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

  const _ActionButton(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
    );
  }
}