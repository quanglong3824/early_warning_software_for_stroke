import 'package:flutter/material.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/app_bottom_nav.dart';
import '../../../services/diabetes_prediction_service.dart';
import '../../../services/stroke_prediction_service.dart';
import '../../../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';

class ScreenPredictionHub extends StatefulWidget {
  const ScreenPredictionHub({super.key});

  @override
  State<ScreenPredictionHub> createState() => _ScreenPredictionHubState();
}

class _ScreenPredictionHubState extends State<ScreenPredictionHub> {
  final _diabetesService = DiabetesPredictionService();
  final _strokeService = StrokePredictionService();
  final _authService = AuthService();
  final _database = FirebaseDatabase.instance.ref();

  Map<String, dynamic>? _latestDiabetes;
  Map<String, dynamic>? _latestStroke;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLatestPredictions();
  }

  Future<void> _loadLatestPredictions() async {
    setState(() => _isLoading = true);

    try {
      final userId = await _authService.getUserId();
      if (userId != null && !userId.startsWith('guest_')) {
        // Lấy tất cả predictions và filter
        final allPredictions = <Map<String, dynamic>>[];
        final predictionsSnapshot = await _database.child('predictions').get();
        
        if (predictionsSnapshot.exists) {
          final data = Map<String, dynamic>.from(predictionsSnapshot.value as Map);
          
          data.forEach((key, value) {
            final prediction = Map<String, dynamic>.from(value as Map);
            if (prediction['userId'] == userId) {
              allPredictions.add(prediction);
            }
          });
          
          // Tìm mới nhất cho mỗi loại
          Map<String, dynamic>? latestDiabetes;
          Map<String, dynamic>? latestStroke;
          int latestDiabetesTime = 0;
          int latestStrokeTime = 0;
          
          for (var pred in allPredictions) {
            final type = pred['type'] as String?;
            final createdAt = pred['createdAt'] as int? ?? 0;
            
            if (type == 'diabetes' && createdAt > latestDiabetesTime) {
              latestDiabetesTime = createdAt;
              latestDiabetes = pred;
            }
            
            if (type == 'stroke' && createdAt > latestStrokeTime) {
              latestStrokeTime = createdAt;
              latestStroke = pred;
            }
          }
          
          setState(() {
            _latestDiabetes = latestDiabetes;
            _latestStroke = latestStroke;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Lỗi tải dự đoán: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);

    return Scaffold(
      drawer: const AppDrawer(userName: 'Admin'),
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        centerTitle: true,
        title: const Text('Dự đoán Sức khỏe', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Công cụ dự đoán',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sử dụng AI để đánh giá nguy cơ sức khỏe của bạn',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _PredictionCard(
            title: 'Dự đoán Đột quỵ',
            description: 'Đánh giá nguy cơ đột quỵ dựa trên các chỉ số sức khỏe',
            icon: Icons.favorite,
            color: Colors.red,
            onTap: () => Navigator.pushNamed(context, '/stroke-form'),
          ),
          const SizedBox(height: 16),
          _PredictionCard(
            title: 'Dự đoán Tiểu đường',
            description: 'Phân tích nguy cơ mắc bệnh tiểu đường type 2',
            icon: Icons.water_drop,
            color: Colors.blue,
            onTap: () => Navigator.pushNamed(context, '/diabetes-form'),
          ),
          const SizedBox(height: 32),
          const Text(
            'Lịch sử & Kết quả',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            _HistoryCard(
              title: 'Kết quả Đột quỵ',
              subtitle: _latestStroke != null
                  ? _formatPredictionSubtitle(_latestStroke!)
                  : 'Chưa có kết quả dự đoán',
              icon: Icons.insights,
              hasData: _latestStroke != null,
              riskLevel: _latestStroke?['riskLevel'],
              onTap: () {
                if (_latestStroke != null) {
                  _viewStrokeResult(_latestStroke!);
                } else {
                  Navigator.pushNamed(context, '/stroke-form');
                }
              },
            ),
            const SizedBox(height: 12),
            _HistoryCard(
              title: 'Kết quả Tiểu đường',
              subtitle: _latestDiabetes != null
                  ? _formatPredictionSubtitle(_latestDiabetes!)
                  : 'Chưa có kết quả dự đoán',
              icon: Icons.query_stats,
              hasData: _latestDiabetes != null,
              riskLevel: _latestDiabetes?['riskLevel'],
              onTap: () {
                if (_latestDiabetes != null) {
                  _viewDiabetesResult(_latestDiabetes!);
                } else {
                  Navigator.pushNamed(context, '/diabetes-form');
                }
              },
            ),
            const SizedBox(height: 12),
            _HistoryCard(
              title: 'Lịch sử Sức khỏe',
              subtitle: 'Xem tất cả kết quả dự đoán',
              icon: Icons.timeline,
              hasData: true,
              onTap: () => Navigator.pushNamed(context, '/health-history'),
            ),
          ],
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  String _formatPredictionSubtitle(Map<String, dynamic> prediction) {
    final riskLevelVi = prediction['riskLevelVi'] as String? ?? 'N/A';
    final createdAt = prediction['createdAt'] as int?;
    
    if (createdAt != null) {
      final date = DateTime.fromMillisecondsSinceEpoch(createdAt);
      final dateStr = DateFormat('dd/MM/yyyy').format(date);
      return '$riskLevelVi - $dateStr';
    }
    
    return riskLevelVi;
  }

  void _viewStrokeResult(Map<String, dynamic> prediction) {
    final result = {
      'riskScore': prediction['riskScore'],
      'riskLevel': prediction['riskLevel'],
      'riskLevelVi': prediction['riskLevelVi'],
      'bmi': prediction['bmi'],
      'bmiCategory': prediction['bmiCategory'],
      'bpCategory': prediction['bpCategory'],
      'cholesterolCategory': prediction['cholesterolCategory'],
    };
    Navigator.pushNamed(context, '/stroke-result', arguments: result);
  }

  void _viewDiabetesResult(Map<String, dynamic> prediction) {
    final result = {
      'riskScore': prediction['riskScore'],
      'riskLevel': prediction['riskLevel'],
      'riskLevelVi': prediction['riskLevelVi'],
      'bmi': prediction['bmi'],
      'bmiCategory': prediction['bmiCategory'],
    };
    Navigator.pushNamed(context, '/diabetes-result', arguments: result);
  }
}

class _PredictionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PredictionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: color, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool hasData;
  final String? riskLevel;

  const _HistoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.hasData = false,
    this.riskLevel,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    
    // Xác định màu dựa trên risk level
    Color iconColor = primary;
    if (riskLevel != null) {
      if (riskLevel == 'high') {
        iconColor = Colors.red;
      } else if (riskLevel == 'medium') {
        iconColor = Colors.orange;
      } else if (riskLevel == 'low') {
        iconColor = Colors.green;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: riskLevel != null 
              ? iconColor.withOpacity(0.3)
              : const Color(0xFFE5E7EB),
        ),
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: hasData && riskLevel != null
                              ? iconColor
                              : Colors.grey,
                          fontWeight: hasData && riskLevel != null
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}