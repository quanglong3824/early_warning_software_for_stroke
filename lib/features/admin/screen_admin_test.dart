import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ScreenAdminTest extends StatefulWidget {
  const ScreenAdminTest({super.key});

  @override
  State<ScreenAdminTest> createState() => _ScreenAdminTestState();
}

class _ScreenAdminTestState extends State<ScreenAdminTest> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  bool _isLoading = false;
  String _status = 'Sẵn sàng để test Firebase Realtime Database';
  final List<String> _logs = [];

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    const bgLight = Color(0xFFF6F6F8);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text('Admin Test Panel'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
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
                gradient: const LinearGradient(
                  colors: [Colors.deepPurple, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: Colors.white, size: 32),
                      SizedBox(width: 12),
                      Text(
                        'Admin Test Panel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _status,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.white30,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Test Actions
            const Text(
              'Firebase Operations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              'Test Connection',
              'Kiểm tra kết nối Firebase',
              Icons.link,
              Colors.blue,
              _testConnection,
            ),
            _buildActionCard(
              'Insert User Data',
              'Thêm dữ liệu User từ app_data.json',
              Icons.person_add,
              Colors.green,
              () => _insertData('user'),
            ),
            _buildActionCard(
              'Insert Doctor Data',
              'Thêm dữ liệu Doctor từ doctor_data.json',
              Icons.medical_services,
              Colors.orange,
              () => _insertData('doctor'),
            ),
            _buildActionCard(
              'Read All Data',
              'Đọc tất cả dữ liệu từ Firebase',
              Icons.download,
              Colors.purple,
              _readAllData,
            ),
            _buildActionCard(
              'Clear All Data',
              'Xóa toàn bộ dữ liệu (Cẩn thận!)',
              Icons.delete_forever,
              Colors.red,
              _clearAllData,
            ),
            const SizedBox(height: 24),

            // Logs
            const Text(
              'Activity Logs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      _logs[index],
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _isLoading ? null : onTap,
      ),
    );
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '[${DateTime.now().toString().substring(11, 19)}] $message');
      if (_logs.length > 50) _logs.removeLast();
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Đang kiểm tra kết nối...';
    });
    _addLog('Testing Firebase Realtime Database connection...');

    try {
      // Test write
      await _database.child('test').child('connection').set({
        'timestamp': ServerValue.timestamp,
        'message': 'Connection test successful',
      });
      _addLog('✓ Write test successful');

      // Test read
      final snapshot = await _database.child('test').child('connection').get();
      if (snapshot.exists) {
        _addLog('✓ Read test successful');
        _addLog('Data: ${snapshot.value}');
      }

      setState(() {
        _status = '✓ Kết nối Firebase Realtime Database thành công!';
      });
      _showSuccess('Kết nối Firebase Realtime Database thành công!');
    } catch (e) {
      _addLog('✗ Error: $e');
      setState(() {
        _status = '✗ Lỗi kết nối: $e';
      });
      _showError('Lỗi kết nối: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _insertData(String type) async {
    setState(() {
      _isLoading = true;
      _status = 'Đang insert dữ liệu $type...';
    });
    _addLog('Starting data insertion for $type...');

    try {
      String jsonString;
      if (type == 'user') {
        jsonString = await rootBundle.loadString('assets/data/app_data.json');
      } else {
        jsonString = await rootBundle.loadString('assets/data/doctor_data.json');
      }

      final Map<String, dynamic> data = json.decode(jsonString);
      _addLog('Loaded JSON data: ${data.keys.length} collections');

      // Insert each collection
      for (var entry in data.entries) {
        final collectionName = '${type}_${entry.key}';
        final collectionData = entry.value;

        if (collectionData is List) {
          _addLog('Inserting ${collectionData.length} items to $collectionName...');
          for (var i = 0; i < collectionData.length; i++) {
            final item = collectionData[i];
            if (item is Map && item.containsKey('id')) {
              await _database
                  .child(collectionName)
                  .child(item['id'].toString())
                  .set(Map<String, dynamic>.from(item));
              _addLog('  ✓ Inserted ${item['id']}');
            }
          }
        } else if (collectionData is Map) {
          await _database
              .child(collectionName)
              .child('data')
              .set(Map<String, dynamic>.from(collectionData));
          _addLog('  ✓ Inserted $collectionName');
        }
      }

      setState(() {
        _status = '✓ Insert dữ liệu $type thành công!';
      });
      _showSuccess('Đã insert dữ liệu $type vào Realtime Database!');
    } catch (e) {
      _addLog('✗ Error: $e');
      setState(() {
        _status = '✗ Lỗi insert: $e';
      });
      _showError('Lỗi insert: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _readAllData() async {
    setState(() {
      _isLoading = true;
      _status = 'Đang đọc dữ liệu...';
    });
    _addLog('Reading all data nodes...');

    try {
      // Read test node
      final testSnapshot = await _database.child('test').get();
      if (testSnapshot.exists) {
        final testData = testSnapshot.value as Map?;
        _addLog('Found test node with ${testData?.keys.length ?? 0} entries');
      }

      // Read user collections
      final userCollections = ['user_patients', 'user_alerts', 'user_forumPosts'];
      for (var collName in userCollections) {
        final snapshot = await _database.child(collName).get();
        if (snapshot.exists) {
          final data = snapshot.value as Map?;
          _addLog('$collName: ${data?.keys.length ?? 0} items');
        } else {
          _addLog('$collName: 0 items');
        }
      }

      // Read doctor collections
      final doctorCollections = ['doctor_todayAppointments', 'doctor_activeSOS'];
      for (var collName in doctorCollections) {
        final snapshot = await _database.child(collName).get();
        if (snapshot.exists) {
          final data = snapshot.value as Map?;
          _addLog('$collName: ${data?.keys.length ?? 0} items');
        } else {
          _addLog('$collName: 0 items');
        }
      }

      // Read users node
      final usersSnapshot = await _database.child('users').get();
      if (usersSnapshot.exists) {
        final usersData = usersSnapshot.value as Map?;
        _addLog('users: ${usersData?.keys.length ?? 0} registered users');
      }

      setState(() {
        _status = '✓ Đọc dữ liệu thành công!';
      });
      _showSuccess('Đã đọc dữ liệu từ Realtime Database!');
    } catch (e) {
      _addLog('✗ Error: $e');
      setState(() {
        _status = '✗ Lỗi đọc: $e';
      });
      _showError('Lỗi đọc: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Cảnh báo'),
        content: const Text('Bạn có chắc chắn muốn xóa TẤT CẢ dữ liệu?\nHành động này không thể hoàn tác!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _status = 'Đang xóa dữ liệu...';
    });
    _addLog('Starting data deletion...');

    try {
      // Delete all nodes (except users for safety)
      final allNodes = [
        'test',
        'user_patients',
        'user_alerts',
        'user_forumPosts',
        'user_knowledgeArticles',
        'user_predictionResults',
        'doctor_todayAppointments',
        'doctor_activeSOS',
        'doctor_doctorReviews',
      ];

      for (var nodeName in allNodes) {
        final snapshot = await _database.child(nodeName).get();
        if (snapshot.exists) {
          final data = snapshot.value as Map?;
          final count = data?.keys.length ?? 0;
          await _database.child(nodeName).remove();
          _addLog('✓ Deleted node: $nodeName ($count items)');
        } else {
          _addLog('○ Node $nodeName is already empty');
        }
      }

      setState(() {
        _status = '✓ Đã xóa tất cả dữ liệu!';
      });
      _showSuccess('Đã xóa tất cả dữ liệu!');
    } catch (e) {
      _addLog('✗ Error: $e');
      setState(() {
        _status = '✗ Lỗi xóa: $e';
      });
      _showError('Lỗi xóa: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
