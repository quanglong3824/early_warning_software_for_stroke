import 'package:flutter/material.dart';

class ScreenPrivacyPolicy extends StatelessWidget {
  const ScreenPrivacyPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const textPrimary = Color(0xFF111318);
    const textSecondary = Color(0xFF616F89);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text('Chính sách bảo mật'),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chính sách bảo mật SEWS',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cập nhật: 15/11/2024',
              style: TextStyle(fontSize: 14, color: textSecondary),
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              '1. Thu thập thông tin',
              'Chúng tôi thu thập các thông tin sau:\n\n'
              '• Thông tin cá nhân: Họ tên, email, số điện thoại, ngày sinh, giới tính, địa chỉ\n'
              '• Thông tin sức khỏe: Chỉ số sinh tồn, lịch sử bệnh án, kết quả dự đoán\n'
              '• Thông tin thiết bị: IP address, loại thiết bị, hệ điều hành\n'
              '• Thông tin sử dụng: Lịch sử truy cập, tương tác với ứng dụng',
            ),
            
            _buildSection(
              '2. Mục đích sử dụng',
              'Thông tin được sử dụng để:\n\n'
              '• Cung cấp và cải thiện dịch vụ\n'
              '• Cảnh báo nguy cơ sức khỏe\n'
              '• Kết nối với bác sĩ và cơ sở y tế\n'
              '• Gửi thông báo quan trọng\n'
              '• Phân tích và nghiên cứu (dữ liệu ẩn danh)',
            ),
            
            _buildSection(
              '3. Bảo vệ thông tin',
              'Chúng tôi áp dụng các biện pháp bảo mật:\n\n'
              '• Mã hóa dữ liệu (SHA256, SSL/TLS)\n'
              '• Xác thực đa yếu tố\n'
              '• Kiểm soát truy cập nghiêm ngặt\n'
              '• Sao lưu dữ liệu định kỳ\n'
              '• Tuân thủ tiêu chuẩn bảo mật quốc tế',
            ),
            
            _buildSection(
              '4. Chia sẻ thông tin',
              'Chúng tôi KHÔNG bán thông tin cá nhân của bạn. Thông tin chỉ được chia sẻ với:\n\n'
              '• Bác sĩ và cơ sở y tế (với sự đồng ý của bạn)\n'
              '• Đối tác dịch vụ (bị ràng buộc bởi thỏa thuận bảo mật)\n'
              '• Cơ quan pháp luật (khi được yêu cầu hợp pháp)',
            ),
            
            _buildSection(
              '5. Quyền của bạn',
              'Bạn có quyền:\n\n'
              '• Truy cập và xem thông tin cá nhân\n'
              '• Chỉnh sửa hoặc cập nhật thông tin\n'
              '• Xóa tài khoản và dữ liệu\n'
              '• Từ chối nhận thông báo marketing\n'
              '• Yêu cầu sao lưu dữ liệu',
            ),
            
            _buildSection(
              '6. Cookies và công nghệ theo dõi',
              'Chúng tôi sử dụng cookies để:\n\n'
              '• Duy trì phiên đăng nhập\n'
              '• Ghi nhớ tùy chọn của bạn\n'
              '• Phân tích sử dụng ứng dụng\n'
              '• Cải thiện trải nghiệm người dùng',
            ),
            
            _buildSection(
              '7. Lưu trữ dữ liệu',
              'Dữ liệu được lưu trữ:\n\n'
              '• Tại Firebase Realtime Database (Google Cloud)\n'
              '• Máy chủ đặt tại: [Vị trí máy chủ]\n'
              '• Thời gian lưu trữ: Cho đến khi bạn xóa tài khoản\n'
              '• Sao lưu được mã hóa và bảo mật',
            ),
            
            _buildSection(
              '8. Trẻ em',
              'Dịch vụ không dành cho trẻ em dưới 13 tuổi. Chúng tôi không cố ý thu thập thông tin từ trẻ em. Nếu phát hiện, chúng tôi sẽ xóa ngay lập tức.',
            ),
            
            _buildSection(
              '9. Thay đổi chính sách',
              'Chúng tôi có thể cập nhật chính sách này. Thay đổi quan trọng sẽ được thông báo qua email hoặc thông báo trong ứng dụng.',
            ),
            
            _buildSection(
              '10. Liên hệ',
              'Câu hỏi về bảo mật? Liên hệ:\n\n'
              'Email: privacy@sews.vn\n'
              'Hotline: 1900-xxxx\n'
              'Địa chỉ: [Địa chỉ công ty]',
            ),
            
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.shield, color: Colors.green, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Chúng tôi cam kết bảo vệ quyền riêng tư và dữ liệu sức khỏe của bạn với các tiêu chuẩn bảo mật cao nhất.',
                      style: TextStyle(color: Colors.green, fontSize: 13),
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

  Widget _buildSection(String title, String content) {
    const textPrimary = Color(0xFF111318);
    const textSecondary = Color(0xFF616F89);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              color: textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
