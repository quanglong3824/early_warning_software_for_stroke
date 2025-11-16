import 'package:flutter/material.dart';
import 'dart:async';
import '../../../services/sos_service.dart';
import '../../../services/location_service.dart';

class ScreenSOSStatus extends StatefulWidget {
  const ScreenSOSStatus({super.key});

  @override
  State<ScreenSOSStatus> createState() => _ScreenSOSStatusState();
}

class _ScreenSOSStatusState extends State<ScreenSOSStatus> {
  final _sosService = SOSService();
  final _locationService = LocationService();
  
  String? _sosId;
  StreamSubscription? _sosSubscription;
  Map<String, dynamic>? _sosData;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['sosId'] != null) {
        setState(() {
          _sosId = args['sosId'];
        });
        _listenToSOSUpdates();
      }
    });
  }
  
  @override
  void dispose() {
    _sosSubscription?.cancel();
    super.dispose();
  }
  
  void _listenToSOSUpdates() {
    if (_sosId == null) return;
    
    _sosSubscription = _sosService.listenToSOSRequest(_sosId!).listen((data) {
      if (mounted) {
        setState(() {
          _sosData = data;
        });
      }
    });
  }
  
  Future<void> _cancelSOS() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy SOS'),
        content: const Text('Bạn có chắc muốn hủy yêu cầu SOS?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hủy SOS'),
          ),
        ],
      ),
    );
    
    if (confirm == true && _sosId != null) {
      await _sosService.cancelSOSRequest(_sosId!);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF8F6F6);
    const primary = Color(0xFFEC1313);
    const textPrimary = Color(0xFF181111);
    const textMuted = Color(0xFF71717A);

    if (_sosData == null) {
      return Scaffold(
        backgroundColor: bgLight,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          centerTitle: true,
          title: const Text('Trạng thái SOS', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final status = _sosData!['status'] as String;
    final location = _sosData!['userLocation'] as Map<String, dynamic>;
    final address = location['address'] as String;
    final createdAt = DateTime.parse(_sosData!['createdAt'] as String);
    final timePassed = DateTime.now().difference(createdAt);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Text('Trạng thái SOS', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emergency, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getStatusText(status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStatusDescription(status),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Timeline
            _TimelineSection(status: status, createdAt: createdAt),
            
            const SizedBox(height: 24),
            
            // Location Info
            _InfoCard(
              icon: Icons.location_on,
              title: 'Vị trí của bạn',
              content: address,
              color: Colors.blue,
            ),
            
            const SizedBox(height: 12),
            
            // Time Info
            _InfoCard(
              icon: Icons.access_time,
              title: 'Thời gian đã gửi',
              content: _formatDuration(timePassed),
              color: Colors.orange,
            ),
            
            const SizedBox(height: 12),
            
            // Hospital Info
            _InfoCard(
              icon: Icons.local_hospital,
              title: 'Bệnh viện được chỉ định',
              content: 'Bệnh viện Chợ Rẫy\n201B Nguyễn Chí Thanh, Q.5',
              color: Colors.green,
            ),
            
            const SizedBox(height: 24),
            
            // Actions
            if (status == 'pending' || status == 'acknowledged') ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _cancelSOS,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Hủy yêu cầu SOS'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            
            if (status == 'resolved') ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Hoàn tất'),
                ),
              ),
            ],
            
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Đang chờ xử lý';
      case 'acknowledged':
        return 'Đã tiếp nhận';
      case 'dispatched':
        return 'Xe cấp cứu đang đến';
      case 'resolved':
        return 'Đã hoàn tất';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }
  
  String _getStatusDescription(String status) {
    switch (status) {
      case 'pending':
        return 'Yêu cầu của bạn đang được xử lý';
      case 'acknowledged':
        return 'Bệnh viện đã tiếp nhận yêu cầu';
      case 'dispatched':
        return 'Xe cấp cứu đang trên đường đến';
      case 'resolved':
        return 'Yêu cầu đã được xử lý thành công';
      case 'cancelled':
        return 'Yêu cầu đã bị hủy';
      default:
        return '';
    }
  }
  
  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 1) {
      return 'Vừa xong';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes} phút trước';
    } else {
      return '${duration.inHours} giờ ${duration.inMinutes % 60} phút trước';
    }
  }
}

class _TimelineSection extends StatelessWidget {
  final String status;
  final DateTime createdAt;
  
  const _TimelineSection({required this.status, required this.createdAt});

  @override
  Widget build(BuildContext context) {
    final steps = [
      {'status': 'pending', 'title': 'Yêu cầu đã gửi', 'icon': Icons.send},
      {'status': 'acknowledged', 'title': 'Đã tiếp nhận', 'icon': Icons.check_circle},
      {'status': 'dispatched', 'title': 'Xe đang đến', 'icon': Icons.local_shipping},
      {'status': 'resolved', 'title': 'Hoàn tất', 'icon': Icons.done_all},
    ];
    
    final currentIndex = steps.indexWhere((s) => s['status'] == status);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiến trình',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final isActive = index <= currentIndex;
            final isLast = index == steps.length - 1;
            
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        step['icon'] as IconData,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 40,
                        color: isActive ? Colors.green : Colors.grey.shade300,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      step['title'] as String,
                      style: TextStyle(
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        color: isActive ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color color;
  
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.content,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
