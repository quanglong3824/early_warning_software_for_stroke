import 'package:flutter/material.dart';
import 'screen_chat_detail.dart';

class ScreenChatList extends StatelessWidget {
  const ScreenChatList({super.key});

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF777777);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text('Trò chuyện', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: textPrimary), onPressed: () {}),
        ],
      ),
      body: ListView(
        children: [
          _ConversationItem(
            title: 'BS. Trần Thị B',
            subtitle: 'Bạn thấy sao rồi?',
            time: '10:30',
            unread: 2,
            avatarUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCq1UWssOPNhUUbEfPbCDeoESDBU3c94oNp9FpfaQ-gBssE2yX4PXjtGJEq4BCCmrn5n_9pzeyfOTnfH-J9T8nvenCFwY9bVdmpiXOyJIIkc5P4lO4c6y_vg15GUuaTE4fI5O8LDBuhfpmX7PVpdjQx_UkJaOcJYORTFrm9GeH3H3BODXdYK2jRxVE0k2Mdkwm9DCbdP5nUwC3V0RRHzCQEslDirmGx-ktEktXHA6NlKhyWRZo5ATqTRCE8BhngdM9JcmgwmYJ3jH4',
          ),
          _ConversationItem(
            title: 'BS. Nguyễn Văn A',
            subtitle: 'Dòng cuối cùng của cuộc trò chuyện...',
            time: '9:45',
            avatarUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCHL4zeqxZDRCA4tBnAVI5snFLwszKHiBeUR5zzs2ywstMtQL76-shgEkZqK0unpvmYJSHJbqDXXXAYCiyo3bA7fr003A6FmYDcO-AXD6m6ZKB8sHKTLfTMY0RORUNLUtmpHy9jEktoO9Uw3NliS1ITppzkYVQnCxxDOWUT0jcASWbqk3XiiiPX5g810M4Uxn9itKKHQDSY6J3RnxCXox82qcUhqbxMTDxBdf9K1shwX6YCkRp_edM6lbU6rt40O6FLvflhUn3bjsw',
          ),
          _ConversationItem(
            title: 'Hỗ trợ SEWS',
            subtitle: 'Chào mừng bạn đến với SEWS!',
            time: 'Hôm qua',
            avatarColor: const Color(0xFF4A90E2),
            avatarIcon: Icons.support_agent,
          ),
        ],
      ),
    );
  }
}

class _ConversationItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final int unread;
  final String? avatarUrl;
  final Color? avatarColor;
  final IconData? avatarIcon;
  const _ConversationItem({
    required this.title,
    required this.subtitle,
    required this.time,
    this.unread = 0,
    this.avatarUrl,
    this.avatarColor,
    this.avatarIcon,
  });

  @override
  Widget build(BuildContext context) {
    const divider = Color(0xFFE5E7EB);
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF777777);
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ScreenChatDetail(
              title: title,
              avatarUrl: avatarUrl,
              avatarColor: avatarColor,
              avatarIcon: avatarIcon,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: divider))),
        child: Row(
          children: [
            _Avatar(avatarUrl: avatarUrl, color: avatarColor, icon: avatarIcon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
              ]),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(time, style: const TextStyle(color: textMuted, fontSize: 12)),
                if (unread > 0)
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Color(0xFFFF6B6B), shape: BoxShape.circle),
                    child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final Color? color;
  final IconData? icon;
  const _Avatar({this.avatarUrl, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.network(avatarUrl!, width: 56, height: 56, fit: BoxFit.cover),
      );
    }
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: (color ?? Colors.blue).withOpacity(0.15), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon ?? Icons.person, color: color ?? Colors.blue),
    );
  }
}