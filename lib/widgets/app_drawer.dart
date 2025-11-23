import 'package:flutter/material.dart';
import '../features/user/common/screen_placeholder.dart';

class AppDrawer extends StatelessWidget {
  final String userName;
  const AppDrawer({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    const bgLight = Color(0xFFF6F6F8);
    
    return Drawer(
      backgroundColor: bgLight,
      child: Column(
        children: [
          // Modern Header with Gradient
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primary, primary.withOpacity(0.8)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                      ),
                      child: const CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 32, color: primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'SEWS - Stroke Early Warning',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _section('KHÁM PHÁ', [
                  _item(context, 'Cộng đồng', Icons.forum_rounded, () => Navigator.pushNamed(context, '/forum')),
                  _item(context, 'Kiến thức', Icons.library_books_rounded, () => Navigator.pushNamed(context, '/knowledge')),
                  _item(context, 'Phòng ngừa', Icons.health_and_safety_rounded, () => Navigator.pushNamed(context, '/healthy-plan')),
                ]),

                _section('HỖ TRỢ', [
                  _item(context, 'Trung tâm Hỗ trợ', Icons.help_outline_rounded, () => Navigator.pushNamed(context, '/help-support')),
                  _item(context, 'Điều khoản Dịch vụ', Icons.description_outlined, () => Navigator.pushNamed(context, '/terms-of-service')),
                  _item(context, 'Chính sách Bảo mật', Icons.privacy_tip_outlined, () => Navigator.pushNamed(context, '/privacy-policy')),
                ]),

                _section('CÀI ĐẶT', [
                  _item(context, 'Cài đặt', Icons.settings_rounded, () => Navigator.pushNamed(context, '/settings')),
                  _item(context, 'Đổi mật khẩu', Icons.lock_outline_rounded, () => Navigator.pushNamed(context, '/change-password')),
                ]),
              ],
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'SEWS v1.0.0',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tính năng chính đã chuyển vào Bottom Navigation',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _item(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF6B7280);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openPlaceholder(BuildContext context, String title) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ScreenPlaceholder(title: title)));
  }
}