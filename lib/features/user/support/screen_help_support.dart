import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ScreenHelpSupport extends StatelessWidget {
  const ScreenHelpSupport({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@sews.vn',
      query: 'subject=Yêu cầu hỗ trợ SEWS',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchPhone() async {
    final uri = Uri(scheme: 'tel', path: '1900xxxx');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    const textSecondary = Color(0xFF616F89);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text('Trợ giúp & Hỗ trợ'),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chúng tôi luôn sẵn sàng hỗ trợ bạn',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 24),
            
            // Contact methods
            _buildContactCard(
              icon: Icons.email,
              title: 'Email',
              subtitle: 'support@sews.vn',
              color: Colors.blue,
              onTap: _launchEmail,
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              icon: Icons.phone,
              title: 'Hotline',
              subtitle: '1900-xxxx (8:00 - 20:00)',
              color: Colors.green,
              onTap: _launchPhone,
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              icon: Icons.chat,
              title: 'Chat trực tuyến',
              subtitle: 'Trò chuyện với nhân viên hỗ trợ',
              color: Colors.orange,
              onTap: () {
                // Navigate to chat
              },
            ),
            
            const SizedBox(height: 32),
            const Text(
              'Câu hỏi thường gặp',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 16),
            
            _buildFAQ(
              'Làm thế nào để đăng ký tài khoản?',
              'Bạn có thể đăng ký bằng email/số điện thoại hoặc đăng nhập nhanh qua Google. Chọn "Đăng ký" trên màn hình đăng nhập và làm theo hướng dẫn.',
            ),
            _buildFAQ(
              'Tôi quên mật khẩu, phải làm sao?',
              'Nhấn "Quên mật khẩu?" trên màn hình đăng nhập, nhập email đã đăng ký. Chúng tôi sẽ gửi link đặt lại mật khẩu đến email của bạn.',
            ),
            _buildFAQ(
              'Kết quả dự đoán có chính xác không?',
              'Kết quả chỉ mang tính tham khảo, dựa trên thuật toán AI. KHÔNG tự chẩn đoán. Luôn tham khảo ý kiến bác sĩ chuyên khoa.',
            ),
            _buildFAQ(
              'Làm thế nào để đặt lịch khám với bác sĩ?',
              'Vào mục "Đặt lịch khám", chọn chuyên khoa, bác sĩ và thời gian phù hợp. Xác nhận thông tin và chờ phản hồi từ phòng khám.',
            ),
            _buildFAQ(
              'Thông tin của tôi có được bảo mật không?',
              'Có. Chúng tôi áp dụng mã hóa SSL/TLS, tuân thủ tiêu chuẩn bảo mật quốc tế. Xem "Chính sách bảo mật" để biết thêm chi tiết.',
            ),
            _buildFAQ(
              'Làm thế nào để xóa tài khoản?',
              'Vào Cài đặt → Tài khoản & Bảo mật → Xóa tài khoản. Lưu ý: Hành động này không thể hoàn tác.',
            ),
            
            const SizedBox(height: 32),
            const Text(
              'Hướng dẫn sử dụng',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 16),
            
            _buildGuideCard(
              icon: Icons.person_add,
              title: 'Đăng ký & Đăng nhập',
              description: 'Hướng dẫn tạo tài khoản và đăng nhập',
              onTap: () {},
            ),
            _buildGuideCard(
              icon: Icons.health_and_safety,
              title: 'Dự đoán nguy cơ',
              description: 'Cách sử dụng tính năng dự đoán đột quỵ',
              onTap: () {},
            ),
            _buildGuideCard(
              icon: Icons.calendar_today,
              title: 'Đặt lịch khám',
              description: 'Hướng dẫn đặt lịch với bác sĩ',
              onTap: () {},
            ),
            _buildGuideCard(
              icon: Icons.notifications,
              title: 'Nhắc nhở uống thuốc',
              description: 'Thiết lập lịch nhắc nhở',
              onTap: () {},
            ),
            
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.help_outline, color: primary, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'Không tìm thấy câu trả lời?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Liên hệ với chúng tôi qua email hoặc hotline. Đội ngũ hỗ trợ sẵn sàng giúp bạn!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _launchEmail,
                      child: const Text('Gửi yêu cầu hỗ trợ'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQ(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildGuideCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF135BEC)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(description, style: const TextStyle(fontSize: 13)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
