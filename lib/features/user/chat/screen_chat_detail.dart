import 'package:flutter/material.dart';

class ScreenChatDetail extends StatelessWidget {
  final String? title;
  final String? avatarUrl;
  final Color? avatarColor;
  final IconData? avatarIcon;
  const ScreenChatDetail({super.key, this.title, this.avatarUrl, this.avatarColor, this.avatarIcon});

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const calmBlue = Color(0xFF4A90E2);
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF777777);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: textPrimary), onPressed: () => Navigator.pop(context)),
        titleSpacing: 0,
        title: Row(
          children: [
            _Avatar(avatarUrl: avatarUrl, color: avatarColor, icon: avatarIcon, size: 32),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title ?? 'BS. Trần Thị B', style: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
              const Row(children: [
                Icon(Icons.circle, color: Colors.green, size: 8),
                SizedBox(width: 4),
                Text('Đang hoạt động', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500)),
              ]),
            ]),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call, color: textPrimary), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert, color: textPrimary), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Color(0xFFE5E7EB), borderRadius: BorderRadius.all(Radius.circular(12))),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Text('Hôm nay', style: TextStyle(color: textMuted, fontSize: 12)),
                      ),
                    ),
                  ),
                ),

                _DoctorBubble(text: 'Chào bạn, tôi có thể giúp gì cho bạn hôm nay?', time: '10:28'),
                _UserBubble(text: 'Chào bác sĩ, tôi cảm thấy hơi choáng váng và mệt mỏi mấy ngày nay.', time: '10:29'),
                _DoctorBubble(text: 'Bạn thấy sao rồi?', time: '10:30'),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _InputBar(),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final Color? color;
  final IconData? icon;
  final double size;
  const _Avatar({this.avatarUrl, this.color, this.icon, this.size = 40});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null) {
      return ClipRRect(borderRadius: BorderRadius.circular(size), child: Image.network(avatarUrl!, width: size, height: size, fit: BoxFit.cover));
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: (color ?? Colors.blue).withOpacity(0.15), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon ?? Icons.person, color: color ?? Colors.blue),
    );
  }
}

class _DoctorBubble extends StatelessWidget {
  final String text;
  final String time;
  const _DoctorBubble({required this.text, required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      const _Avatar(size: 24),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.all(12),
          child: Text(text),
        ),
        const SizedBox(height: 4),
        Text(time, style: const TextStyle(color: Color(0xFF777777), fontSize: 12)),
      ])
    ]);
  }
}

class _UserBubble extends StatelessWidget {
  final String text;
  final String time;
  const _UserBubble({required this.text, required this.time});

  @override
  Widget build(BuildContext context) {
    const calmBlue = Color(0xFF4A90E2);
    return Row(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.end, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          decoration: BoxDecoration(color: calmBlue, borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.all(12),
          child: const Text('Chào bác sĩ, tôi cảm thấy hơi choáng váng và mệt mỏi mấy ngày nay.', style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 4),
        const Text('10:29', style: TextStyle(color: Color(0xFF777777), fontSize: 12)),
      ])
    ]);
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar();

  @override
  Widget build(BuildContext context) {
    const calmBlue = Color(0xFF4A90E2);
    return Row(children: [
      IconButton(onPressed: () {}, icon: const Icon(Icons.add_circle, color: Colors.black87)),
      Expanded(
        child: Container(
          decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 44,
          alignment: Alignment.centerLeft,
          child: const Text('Nhập tin nhắn của bạn...', style: TextStyle(color: Colors.black54, fontSize: 14)),
        ),
      ),
      const SizedBox(width: 8),
      Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(color: calmBlue, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: const Icon(Icons.send, color: Colors.white),
      ),
    ]);
  }
}