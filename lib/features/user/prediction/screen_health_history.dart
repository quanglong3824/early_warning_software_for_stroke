import 'package:flutter/material.dart';
import '../../../services/diabetes_prediction_service.dart';
import '../../../services/stroke_prediction_service.dart';
import '../../../services/auth_service.dart';
import 'package:intl/intl.dart';

class ScreenHealthHistory extends StatefulWidget {
  const ScreenHealthHistory({super.key});

  @override
  State<ScreenHealthHistory> createState() => _ScreenHealthHistoryState();
}

class _ScreenHealthHistoryState extends State<ScreenHealthHistory> {
  final _diabetesService = DiabetesPredictionService();
  final _strokeService = StrokePredictionService();
  final _authService = AuthService();

  List<Map<String, dynamic>> _allPredictions = [];
  bool _isLoading = true;
  String _filterType = 'all'; // 'all', 'diabetes', 'stroke'

  @override
  void initState() {
    super.initState();
    _loadPredictions();
  }

  Future<void> _loadPredictions() async {
    setState(() => _isLoading = true);

    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Vui lòng đăng nhập');
      }

      // Lấy cả 2 loại dự đoán
      final diabetesPredictions = await _diabetesService.getUserPredictions(userId);
      final strokePredictions = await _strokeService.getUserPredictions(userId);

      // Gộp và sắp xếp theo thời gian
      final allPredictions = [...diabetesPredictions, ...strokePredictions];
      allPredictions.sort((a, b) {
        final aTime = a['createdAt'] as int? ?? 0;
        final bTime = b['createdAt'] as int? ?? 0;
        return bTime.compareTo(aTime);
      });

      setState(() {
        _allPredictions = allPredictions;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Lỗi tải lịch sử: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải lịch sử: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredPredictions {
    if (_filterType == 'all') return _allPredictions;
    return _allPredictions.where((p) => p['type'] == _filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Lịch sử Sức khỏe',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: textPrimary),
            onPressed: _loadPredictions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _FilterChip(
                    label: 'Tất cả',
                    isSelected: _filterType == 'all',
                    onTap: () => setState(() => _filterType = 'all'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterChip(
                    label: 'Đột quỵ',
                    isSelected: _filterType == 'stroke',
                    onTap: () => setState(() => _filterType = 'stroke'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterChip(
                    label: 'Tiểu đường',
                    isSelected: _filterType == 'diabetes',
                    onTap: () => setState(() => _filterType = 'diabetes'),
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPredictions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có lịch sử dự đoán',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/prediction-hub');
                              },
                              child: const Text('Thực hiện dự đoán ngay'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPredictions,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredPredictions.length,
                          itemBuilder: (context, index) {
                            final prediction = _filteredPredictions[index];
                            return _PredictionCard(
                              prediction: prediction,
                              onTap: () => _viewPredictionDetail(prediction),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _viewPredictionDetail(Map<String, dynamic> prediction) {
    final type = prediction['type'] as String;
    
    // Tạo result object để truyền sang màn hình result
    final result = {
      'riskScore': prediction['riskScore'],
      'riskLevel': prediction['riskLevel'],
      'riskLevelVi': prediction['riskLevelVi'],
      'bmi': prediction['bmi'],
      'bmiCategory': prediction['bmiCategory'],
    };

    if (type == 'stroke') {
      result['bpCategory'] = prediction['bpCategory'];
      result['cholesterolCategory'] = prediction['cholesterolCategory'];
      Navigator.pushNamed(context, '/stroke-result', arguments: result);
    } else {
      Navigator.pushNamed(context, '/diabetes-result', arguments: result);
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primary : const Color(0xFFE5E7EB),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _PredictionCard extends StatelessWidget {
  final Map<String, dynamic> prediction;
  final VoidCallback onTap;

  const _PredictionCard({
    required this.prediction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final type = prediction['type'] as String;
    final riskLevel = prediction['riskLevel'] as String;
    final riskScore = prediction['riskScore'] as int;
    final createdAt = prediction['createdAt'] as int?;

    // Xác định màu sắc và icon
    Color riskColor;
    IconData icon;
    String title;

    if (type == 'stroke') {
      icon = Icons.favorite;
      title = 'Dự đoán Đột quỵ';
    } else {
      icon = Icons.water_drop;
      title = 'Dự đoán Tiểu đường';
    }

    if (riskLevel == 'high') {
      riskColor = Colors.red;
    } else if (riskLevel == 'medium') {
      riskColor = Colors.orange;
    } else {
      riskColor = Colors.green;
    }

    // Format date
    String dateStr = 'Không rõ';
    if (createdAt != null) {
      final date = DateTime.fromMillisecondsSinceEpoch(createdAt);
      dateStr = DateFormat('dd/MM/yyyy HH:mm').format(date);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: riskColor.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: riskColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111318),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: riskColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              prediction['riskLevelVi'] ?? 'N/A',
                              style: TextStyle(
                                color: riskColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$riskScore/100',
                            style: TextStyle(
                              color: riskColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
