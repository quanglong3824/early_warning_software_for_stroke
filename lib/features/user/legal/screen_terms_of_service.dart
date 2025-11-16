import 'package:flutter/material.dart';

class ScreenTermsOfService extends StatelessWidget {
  const ScreenTermsOfService({super.key});

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const textPrimary = Color(0xFF111318);
    const textSecondary = Color(0xFF616F89);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text('Điều khoản sử dụng'),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Điều khoản sử dụng dịch vụ SEWS',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cập nhật lần cuối: 15/11/2024',
              style: TextStyle(fontSize: 14, color: textSecondary),
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              '1. Chấp nhận điều khoản',
              'Bằng việc truy cập và sử dụng ứng dụng SEWS (Stroke Early Warning Software), bạn đồng ý tuân thủ và bị ràng buộc bởi các điều khoản và điều kiện sau đây. Nếu bạn không đồng ý với bất kỳ phần nào của các điều khoản này, vui lòng không sử dụng dịch vụ của chúng tôi.',
            ),
            
            _buildSection(
              '2. Mục đích sử dụng',
              'SEWS là ứng dụng hỗ trợ cảnh báo sớm nguy cơ đột quỵ, cung cấp thông tin y tế và kết nối với bác sĩ. Ứng dụng KHÔNG thay thế cho việc khám bệnh trực tiếp và chẩn đoán y tế chuyên nghiệp. Mọi quyết định về sức khỏe cần được tham khảo ý kiến bác sĩ.',
            ),
            
            _buildSection(
              '3. Tài khoản người dùng',
              '• Bạn có trách nhiệm duy trì tính bảo mật của tài khoản và mật khẩu\n'
              '• Bạn chịu trách nhiệm về tất cả hoạt động diễn ra dưới tài khoản của mình\n'
              '• Thông tin đăng ký phải chính xác và đầy đủ\n'
              '• Không chia sẻ tài khoản cho người khác sử dụng',
            ),
            
            _buildSection(
              '4. Quyền riêng tư và bảo mật',
              'Chúng tôi cam kết bảo vệ thông tin cá nhân và dữ liệu sức khỏe của bạn. Vui lòng xem Chính sách bảo mật để biết chi tiết về cách chúng tôi thu thập, sử dụng và bảo vệ thông tin của bạn.',
            ),
            
            _buildSection(
              '5. Nội dung người dùng',
              'Bạn giữ quyền sở hữu đối với nội dung bạn tạo ra trong ứng dụng. Tuy nhiên, bằng việc sử dụng dịch vụ, bạn cấp cho chúng tôi quyền sử dụng nội dung đó để cung cấp và cải thiện dịch vụ.',
            ),
            
            _buildSection(
              '6. Hành vi cấm',
              'Người dùng không được:\n'
              '• Sử dụng dịch vụ cho mục đích bất hợp pháp\n'
              '• Tải lên nội dung vi phạm pháp luật hoặc quyền của người khác\n'
              '• Can thiệp vào hoạt động bình thường của hệ thống\n'
              '• Cố gắng truy cập trái phép vào hệ thống\n'
              '• Sử dụng bot, script hoặc công cụ tự động không được phép',
            ),
            
            _buildSection(
              '7. Tính năng y tế',
              'CẢNH BÁO QUAN TRỌNG:\n'
              '• Kết quả dự đoán chỉ mang tính chất tham khảo\n'
              '• KHÔNG tự chẩn đoán hoặc tự điều trị dựa trên kết quả từ ứng dụng\n'
              '• Luôn tham khảo ý kiến bác sĩ chuyên khoa\n'
              '• Trong trường hợp khẩn cấp, hãy gọi 115 hoặc đến cơ sở y tế ngay lập tức',
            ),
            
            _buildSection(
              '8. Giới hạn trách nhiệm',
              'SEWS và các bên liên quan không chịu trách nhiệm về:\n'
              '• Bất kỳ tổn thất hoặc thiệt hại nào phát sinh từ việc sử dụng dịch vụ\n'
              '• Độ chính xác, đầy đủ hoặc hữu ích của thông tin y tế\n'
              '• Hành vi của người dùng khác\n'
              '• Gián đoạn dịch vụ hoặc lỗi kỹ thuật',
            ),
            
            _buildSection(
              '9. Thay đổi điều khoản',
              'Chúng tôi có quyền sửa đổi các điều khoản này bất kỳ lúc nào. Những thay đổi sẽ có hiệu lực ngay khi được đăng tải. Việc bạn tiếp tục sử dụng dịch vụ sau khi có thay đổi đồng nghĩa với việc bạn chấp nhận các điều khoản mới.',
            ),
            
            _buildSection(
              '10. Chấm dứt dịch vụ',
              'Chúng tôi có quyền tạm ngưng hoặc chấm dứt quyền truy cập của bạn vào dịch vụ nếu bạn vi phạm các điều khoản này, mà không cần thông báo trước.',
            ),
            
            _buildSection(
              '11. Luật áp dụng',
              'Các điều khoản này được điều chỉnh bởi pháp luật Việt Nam. Mọi tranh chấp phát sinh sẽ được giải quyết tại tòa án có thẩm quyền tại Việt Nam.',
            ),
            
            _buildSection(
              '12. Liên hệ',
              'Nếu bạn có bất kỳ câu hỏi nào về các điều khoản này, vui lòng liên hệ:\n\n'
              'Email: support@sews.vn\n'
              'Hotline: 1900-xxxx\n'
              'Địa chỉ: [Địa chỉ công ty]',
            ),
            
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bằng việc sử dụng SEWS, bạn xác nhận rằng đã đọc, hiểu và đồng ý với các điều khoản sử dụng này.',
                      style: TextStyle(color: Colors.blue, fontSize: 13),
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
