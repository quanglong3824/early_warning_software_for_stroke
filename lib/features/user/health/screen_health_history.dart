import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/health_record_service.dart';
import '../../../services/health_chart_service.dart';
import '../../../services/auth_service.dart';
import '../../../data/models/health_record_model.dart';

class ScreenHealthHistory extends StatefulWidget {
  const ScreenHealthHistory({super.key});

  @override
  State<ScreenHealthHistory> createState() => _ScreenHealthHistoryState();
}

class _ScreenHealthHistoryState extends State<ScreenHealthHistory>
    with SingleTickerProviderStateMixin {
  final _healthService = HealthRecordService();
  final _chartService = HealthChartService();
  final _authService = AuthService();
  
  late TabController _tabController;
  String? _userId;
  Map<String, dynamic> _stats = {};
  
  // Chart data
  List<BloodPressureDataPoint> _bpData = [];
  List<ChartDataPoint> _strokeData = [];
  List<ChartDataPoint> _diabetesData = [];
  
  // Date range filter
  DateRange _selectedRange = DateRange.lastMonth();
  String _selectedRangeLabel = '30 ngày';
  
  bool _isLoadingCharts = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserAndStats();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndStats() async {
    final userId = await _authService.getUserId();
    if (userId != null) {
      setState(() {
        _userId = userId;
        _isLoadingCharts = true;
      });
      
      final stats = await _healthService.getHealthStats(userId);
      await _loadChartData(userId);
      
      setState(() {
        _stats = stats;
        _isLoadingCharts = false;
      });
    }
  }
  
  Future<void> _loadChartData(String userId) async {
    try {
      final bpData = await _chartService.getBloodPressureDataComplete(
        userId, 
        _selectedRange,
      );
      final strokeData = await _chartService.getPredictionHistory(
        userId, 
        'stroke',
      );
      final diabetesData = await _chartService.getPredictionHistory(
        userId, 
        'diabetes',
      );
      
      setState(() {
        _bpData = bpData;
        _strokeData = strokeData;
        _diabetesData = diabetesData;
      });
    } catch (e) {
      debugPrint('Error loading chart data: $e');
    }
  }
  
  void _onDateRangeChanged(String label, DateRange range) {
    setState(() {
      _selectedRangeLabel = label;
      _selectedRange = range;
      _isLoadingCharts = true;
    });
    
    if (_userId != null) {
      _loadChartData(_userId!).then((_) {
        setState(() => _isLoadingCharts = false);
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'high':
        return Colors.red;
      case 'low':
        return Colors.orange;
      case 'normal':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Hôm nay, ${DateFormat('HH:mm').format(date)}';
    } else if (diff.inDays == 1) {
      return 'Hôm qua, ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('dd/MM/yyyy, HH:mm').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F6F8),
        appBar: AppBar(title: const Text('Lịch sử Sức khỏe')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: const Text('Lịch sử Sức khỏe'),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.pushNamed(context, '/add-health-record');
              _loadUserAndStats();
            },
            icon: const Icon(Icons.add),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tổng quan'),
            Tab(text: 'Biểu đồ'),
            Tab(text: 'Lịch sử'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildChartsTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }
  
  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadUserAndStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  'Huyết áp TB',
                  _stats['avgSystolic'] != null && _stats['avgDiastolic'] != null
                      ? '${_stats['avgSystolic']}/${_stats['avgDiastolic']}'
                      : 'N/A',
                  'mmHg',
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  'Nhịp tim TB',
                  _stats['avgHeartRate']?.toString() ?? 'N/A',
                  'bpm',
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  'Cân nặng',
                  _stats['latestWeight']?.toStringAsFixed(1) ?? 'N/A',
                  'kg',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  'Số bản ghi',
                  _stats['recordCount']?.toString() ?? '0',
                  '',
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildChartsTab() {
    return RefreshIndicator(
      onRefresh: _loadUserAndStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Date range filter
          _buildDateRangeFilter(),
          const SizedBox(height: 16),
          
          // Blood Pressure Chart
          _buildChartCard(
            title: 'Huyết áp',
            subtitle: 'Xu hướng huyết áp theo thời gian',
            child: _isLoadingCharts
                ? const Center(child: CircularProgressIndicator())
                : _bpData.isEmpty
                    ? _buildEmptyChartState('huyết áp')
                    : _buildBloodPressureChart(),
          ),
          const SizedBox(height: 16),
          
          // Prediction History Chart
          _buildChartCard(
            title: 'Lịch sử dự đoán',
            subtitle: 'Nguy cơ đột quỵ và tiểu đường',
            child: _isLoadingCharts
                ? const Center(child: CircularProgressIndicator())
                : (_strokeData.isEmpty && _diabetesData.isEmpty)
                    ? _buildEmptyChartState('dự đoán')
                    : _buildPredictionChart(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDateRangeFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range, color: Colors.grey),
          const SizedBox(width: 8),
          const Text('Khoảng thời gian:', style: TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDateRangeChip('7 ngày', DateRange.lastWeek()),
                  _buildDateRangeChip('30 ngày', DateRange.lastMonth()),
                  _buildDateRangeChip('90 ngày', DateRange.last3Months()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDateRangeChip(String label, DateRange range) {
    final isSelected = _selectedRangeLabel == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _onDateRangeChanged(label, range),
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      ),
    );
  }
  
  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 200, child: child),
        ],
      ),
    );
  }
  
  Widget _buildEmptyChartState(String dataType) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Chưa có dữ liệu $dataType',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/add-health-record'),
            icon: const Icon(Icons.add),
            label: const Text('Thêm bản ghi'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBloodPressureChart() {
    if (_bpData.isEmpty) return _buildEmptyChartState('huyết áp');
    
    final systolicSpots = <FlSpot>[];
    final diastolicSpots = <FlSpot>[];
    
    for (int i = 0; i < _bpData.length; i++) {
      systolicSpots.add(FlSpot(i.toDouble(), _bpData[i].systolic));
      diastolicSpots.add(FlSpot(i.toDouble(), _bpData[i].diastolic));
    }
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _bpData.length > 7 ? (_bpData.length / 5).ceil().toDouble() : 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= _bpData.length) return const SizedBox();
                return Text(
                  DateFormat('dd/MM').format(_bpData[index].date),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Systolic line (red)
          LineChartBarData(
            spots: systolicSpots,
            isCurved: true,
            color: Colors.red,
            barWidth: 2,
            dotData: FlDotData(
              show: _bpData.length <= 10,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(radius: 3, color: Colors.red),
            ),
            belowBarData: BarAreaData(show: false),
          ),
          // Diastolic line (blue)
          LineChartBarData(
            spots: diastolicSpots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 2,
            dotData: FlDotData(
              show: _bpData.length <= 10,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(radius: 3, color: Colors.blue),
            ),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final isSystolic = spot.barIndex == 0;
                return LineTooltipItem(
                  '${isSystolic ? "Tâm thu" : "Tâm trương"}: ${spot.y.toInt()} mmHg',
                  TextStyle(
                    color: isSystolic ? Colors.red : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        minY: 40,
        maxY: 200,
      ),
    );
  }
  
  Widget _buildPredictionChart() {
    final allData = [..._strokeData, ..._diabetesData];
    if (allData.isEmpty) return _buildEmptyChartState('dự đoán');
    
    // Create bar groups
    final barGroups = <BarChartGroupData>[];
    final maxLength = _strokeData.length > _diabetesData.length 
        ? _strokeData.length 
        : _diabetesData.length;
    
    for (int i = 0; i < maxLength; i++) {
      final rods = <BarChartRodData>[];
      
      if (i < _strokeData.length) {
        rods.add(BarChartRodData(
          toY: _strokeData[i].value,
          color: Colors.red.withOpacity(0.8),
          width: 8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ));
      }
      
      if (i < _diabetesData.length) {
        rods.add(BarChartRodData(
          toY: _diabetesData[i].value,
          color: Colors.orange.withOpacity(0.8),
          width: 8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ));
      }
      
      barGroups.add(BarChartGroupData(x: i, barRods: rods));
    }
    
    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}%',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                final data = _strokeData.isNotEmpty ? _strokeData : _diabetesData;
                if (index < 0 || index >= data.length) return const SizedBox();
                return Text(
                  DateFormat('dd/MM').format(data[index].date),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final isStroke = rodIndex == 0 && _strokeData.isNotEmpty;
              return BarTooltipItem(
                '${isStroke ? "Đột quỵ" : "Tiểu đường"}: ${rod.toY.toStringAsFixed(1)}%',
                TextStyle(
                  color: isStroke ? Colors.red : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        maxY: 100,
      ),
    );
  }
  
  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _loadUserAndStats,
      child: StreamBuilder<List<HealthRecordModel>>(
        stream: _healthService.getHealthRecords(_userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final records = snapshot.data ?? [];

          if (records.isEmpty) {
            return _buildEmptyHistoryState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final bpStatus = record.getBPStatus();
              final statusColor = _getStatusColor(bpStatus);

              String dataText = '';
              if (record.systolicBP != null && record.diastolicBP != null) {
                dataText += 'HA: ${record.bloodPressure}';
              }
              if (record.heartRate != null) {
                if (dataText.isNotEmpty) dataText += ', ';
                dataText += 'Nhịp tim: ${record.heartRate}';
              }
              if (record.bloodSugar != null) {
                if (dataText.isNotEmpty) dataText += ', ';
                dataText += 'Đường huyết: ${record.bloodSugar}';
              }
              if (dataText.isEmpty) {
                dataText = 'Không có dữ liệu';
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _HistoryItem(
                  _formatDateTime(record.recordedAt),
                  dataText,
                  statusColor,
                  onTap: () {
                    // TODO: Navigate to detail screen
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  Widget _buildEmptyHistoryState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.health_and_safety_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có bản ghi sức khỏe',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Theo dõi sức khỏe của bạn bằng cách thêm các chỉ số như huyết áp, nhịp tim, đường huyết.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/add-health-record'),
              icon: const Icon(Icons.add),
              label: const Text('Thêm bản ghi đầu tiên'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value, unit;
  final Color color;
  const _StatCard(this.title, this.value, this.unit, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            unit.isNotEmpty ? '$value $unit' : value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String date, data;
  final Color color;
  final VoidCallback? onTap;
  
  const _HistoryItem(this.date, this.data, this.color, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(data, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
