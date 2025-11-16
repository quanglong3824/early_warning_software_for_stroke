import 'package:flutter/material.dart';

class SOSFloatingButton extends StatelessWidget {
  const SOSFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onLongPress: () {
          // Giữ 3 giây để kích hoạt SOS
          _showSOSConfirmation(context);
        },
        onTap: () {
          // Tap nhanh để xem hướng dẫn
          _showSOSInfo(context);
        },
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDC2626).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.emergency,
            color: Colors.white,
            size: 32,
          ),
        ),
    );
  }

  void _showSOSInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Nút SOS Khẩn Cấp'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cách sử dụng:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text('• Nhấn giữ 3 giây để kích hoạt cảnh báo khẩn cấp'),
            SizedBox(height: 4),
            Text('• Hệ thống sẽ tự động gửi thông báo đến:'),
            SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('- Người thân đã đăng ký'),
                  Text('- Bác sĩ phụ trách'),
                  Text('- Dịch vụ cấp cứu 115'),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              '⚠️ Chỉ sử dụng trong trường hợp khẩn cấp thực sự!',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/sos');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Thiết lập SOS'),
          ),
        ],
      ),
    );
  }

  void _showSOSConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 32),
            SizedBox(width: 8),
            Text('Xác nhận SOS'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bạn có chắc chắn muốn kích hoạt cảnh báo khẩn cấp?',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Hệ thống sẽ gửi thông báo đến tất cả người thân và dịch vụ cấp cứu.',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/sos-status');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Kích hoạt SOS'),
          ),
        ],
      ),
    );
  }
}
