import 'package:flutter/material.dart';
import '../../../services/admin_prediction_service.dart';
import 'package:intl/intl.dart';

class ScreenAdminPredictions extends StatefulWidget {
  const ScreenAdminPredictions({super.key});

  @override
  State<ScreenAdminPredictions> createState() => _ScreenAdminPredictionsState();
}

class _ScreenAdminPredictionsState extends State<ScreenAdminPredictions> {
  final _predictionService = AdminPredictionService();
  
  String _selectedType = 'all'; // 'all', 'stroke', 'diabetes'
  List<Map<String, dynamic>> _predictions = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final predictions = await _predictionService.getAllPredictions();
      final stats = await _predictionService.getPredictionStats();

      setState(() {
        _predictions = predictions;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Lỗi load data: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredPredictions {
    if (_selectedType == 'all') return _predictions;
    return _predictions.where((p) => p['type'] == _selectedType).toList();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6B46C1);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: const Text('Tổng hợp Dự đoán'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                _TypeButton(
                  label: 'Tất cả',
                  isSelected: _selectedType == 'all',
                  onTap: () => setState(() => _selectedType = 'all'),
                ),
                const SizedBox(width: 8),
                _TypeButton(
                  label: 'Đột quỵ',
                  isSelected: _selectedType == 'stroke',
                  onTap: () => setState(() => _selectedType = 'stroke'),
                ),
                const SizedBox(width: 8),
                _TypeButton(
                  label: 'Tiểu đường',
                  isSelected: _selectedType == 'diabetes',
                  onTap: () => setState(() => _selectedType = 'diabetes'),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadData,
                  tooltip: 'Làm mới',
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Stats
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Tổng dự đoán',
                      value: '${_stats['total'] ?? 0}',
                      icon: Icons.analytics,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Nguy cơ cao',
                      value: '${_stats['highRisk'] ?? 0}',
                      icon: Icons.warning,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Nguy cơ trung bình',
                      value: '${_stats['mediumRisk'] ?? 0}',
                      icon: Icons.info,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Nguy cơ thấp',
                      value: '${_stats['lowRisk'] ?? 0}',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                      ),
                      child: Row(
                        children: const [
                          Expanded(flex: 2, child: Text('Người dùng', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(child: Text('Loại', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(child: Text('Nguy cơ', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(child: Text('Điểm số', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(child: Text('Thời gian', style: TextStyle(fontWeight: FontWeight.bold))),
                          SizedBox(width: 80, child: Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredPredictions.isEmpty
                              ? const Center(
                                  child: Text('Chưa có dữ liệu dự đoán'),
                                )
                              : ListView.builder(
                                  itemCount: _filteredPredictions.length,
                                  itemBuilder: (context, index) {
                                    final prediction = _filteredPredictions[index];
                                    final riskLevel = prediction['riskLevel'] as String? ?? 'low';
                                    final riskScore = prediction['riskScore'] as int? ?? 0;
                                    final type = prediction['type'] as String? ?? '';
                                    final userName = prediction['userName'] as String? ?? 'Unknown';
                                    final userEmail = prediction['userEmail'] as String? ?? '';
                                    final createdAt = prediction['createdAt'] as int?;

                                    String riskText;
                                    Color riskColor;
                                    if (riskLevel == 'high') {
                                      riskText = 'Cao';
                                      riskColor = Colors.red;
                                    } else if (riskLevel == 'medium') {
                                      riskText = 'Trung bình';
                                      riskColor = Colors.orange;
                                    } else {
                                      riskText = 'Thấp';
                                      riskColor = Colors.green;
                                    }

                                    String typeText = type == 'stroke' ? 'Đột quỵ' : 'Tiểu đường';
                                    
                                    String timeText = 'N/A';
                                    if (createdAt != null) {
                                      final date = DateTime.fromMillisecondsSinceEpoch(createdAt);
                                      timeText = DateFormat('dd/MM HH:mm').format(date);
                                    }

                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  userName,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                if (userEmail.isNotEmpty)
                                                  Text(
                                                    userEmail,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Expanded(child: Text(typeText)),
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: riskColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                riskText,
                                                style: TextStyle(color: riskColor, fontSize: 12),
                                              ),
                                            ),
                                          ),
                                          Expanded(child: Text('$riskScore/100')),
                                          Expanded(child: Text(timeText, style: const TextStyle(fontSize: 13))),
                                          SizedBox(
                                            width: 80,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.visibility, size: 20),
                                                  onPressed: () => _showPredictionDetail(prediction),
                                                  tooltip: 'Xem chi tiết',
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPredictionDetail(Map<String, dynamic> prediction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết Dự đoán ${prediction['type'] == 'stroke' ? 'Đột quỵ' : 'Tiểu đường'}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow('User ID', prediction['userId'] ?? 'N/A'),
              _DetailRow('Loại', prediction['type'] == 'stroke' ? 'Đột quỵ' : 'Tiểu đường'),
              _DetailRow('Mức độ nguy cơ', prediction['riskLevelVi'] ?? 'N/A'),
              _DetailRow('Điểm số', '${prediction['riskScore'] ?? 0}/100'),
              _DetailRow('BMI', prediction['bmi'] ?? 'N/A'),
              _DetailRow('Phân loại BMI', prediction['bmiCategory'] ?? 'N/A'),
              if (prediction['type'] == 'stroke') ...[
                _DetailRow('Huyết áp', prediction['bpCategory'] ?? 'N/A'),
                _DetailRow('Cholesterol', prediction['cholesterolCategory'] ?? 'N/A'),
              ],
              if (prediction['createdAt'] != null)
                _DetailRow(
                  'Thời gian',
                  DateFormat('dd/MM/yyyy HH:mm').format(
                    DateTime.fromMillisecondsSinceEpoch(prediction['createdAt']),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6B46C1);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }
}
