import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScreenTestFirebase extends StatefulWidget {
  const ScreenTestFirebase({super.key});

  @override
  State<ScreenTestFirebase> createState() => _ScreenTestFirebaseState();
}

class _ScreenTestFirebaseState extends State<ScreenTestFirebase> {
  String _result = 'Chưa test';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _result = '🔐 Thông tin Authentication:\n\n';
      if (user != null) {
        _result += '✅ Đã đăng nhập\n';
        _result += 'UID: ${user.uid}\n';
        _result += 'Email: ${user.email}\n';
        _result += 'Display Name: ${user.displayName}\n';
      } else {
        _result += '❌ CHƯA ĐĂNG NHẬP!\n';
        _result += '\nĐây là nguyên nhân gây lỗi Permission Denied.\n';
        _result += 'Vui lòng đăng nhập trước khi test.';
      }
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _result = 'Đang kiểm tra...\n\n';
    });

    try {
      // Check auth first
      final user = FirebaseAuth.instance.currentUser;
      setState(() {
        _result += '🔐 Authentication:\n';
        if (user != null) {
          _result += '✅ Đã đăng nhập: ${user.email}\n';
          _result += 'UID: ${user.uid}\n\n';
        } else {
          _result += '❌ CHƯA ĐĂNG NHẬP!\n\n';
          _result += 'Lỗi: Bạn cần đăng nhập để đọc dữ liệu.\n';
          _result += 'Firebase Rules yêu cầu authentication.\n';
          _isLoading = false;
          return;
        }
      });

      final database = FirebaseDatabase.instance.ref();
      
      // Test 1: Read all users
      print('🔍 Test 1: Reading all users...');
      setState(() {
        _result += '📊 Đang đọc dữ liệu từ /users...\n';
      });
      
      final snapshot = await database.child('users').get();
      
      if (snapshot.exists) {
        final usersMap = Map<String, dynamic>.from(snapshot.value as Map);
        print('✅ Found ${usersMap.length} users');
        
        setState(() {
          _result += '\n✅ THÀNH CÔNG!\n\n';
          _result += '📦 Tổng số users: ${usersMap.length}\n\n';
          
          usersMap.forEach((key, value) {
            final userData = Map<String, dynamic>.from(value as Map);
            _result += '━━━━━━━━━━━━━━━━━━━━\n';
            _result += '👤 ${userData['name'] ?? 'N/A'}\n';
            _result += '   UID: $key\n';
            _result += '   Email: ${userData['email'] ?? 'N/A'}\n';
            _result += '   Role: ${userData['role'] ?? 'N/A'}\n';
            _result += '   Status: ${(userData['isBlocked'] ?? false) ? '🔒 Blocked' : '✅ Active'}\n';
          });
        });
      } else {
        setState(() {
          _result += '\n⚠️ Không có dữ liệu trong Firebase!\n';
          _result += '\nCó thể:\n';
          _result += '1. Database chưa có dữ liệu\n';
          _result += '2. Rules không cho phép đọc\n';
          _result += '3. Path không đúng\n';
        });
      }
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _result += '\n❌ LỖI: $e\n\n';
        
        if (e.toString().contains('permission') || e.toString().contains('PERMISSION_DENIED')) {
          _result += '🔒 LỖI PERMISSION DENIED!\n\n';
          _result += 'Nguyên nhân:\n';
          _result += '• Firebase Realtime Database Rules chưa được cấu hình\n';
          _result += '• Rules không cho phép đọc dữ liệu\n\n';
          _result += 'Giải pháp:\n';
          _result += '1. Mở Firebase Console\n';
          _result += '2. Vào Realtime Database → Rules\n';
          _result += '3. Thêm rules:\n';
          _result += '   {\n';
          _result += '     "rules": {\n';
          _result += '       ".read": "auth != null",\n';
          _result += '       ".write": "auth != null"\n';
          _result += '     }\n';
          _result += '   }\n';
          _result += '4. Nhấn Publish\n\n';
          _result += 'Xem chi tiết: docs/FIREBASE_SETUP.md\n';
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Firebase Connection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Hướng dẫn sửa lỗi'),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('🔒 Lỗi Permission Denied\n',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Nguyên nhân:\n'
                            '• Firebase Rules chưa được cấu hình\n\n'
                            'Giải pháp:\n'
                            '1. Mở Firebase Console\n'
                            '2. Vào Realtime Database → Rules\n'
                            '3. Cập nhật rules:\n\n'),
                        Text(
                          '{\n'
                          '  "rules": {\n'
                          '    ".read": "auth != null",\n'
                          '    ".write": "auth != null"\n'
                          '  }\n'
                          '}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            backgroundColor: Color(0xFFF5F5F5),
                          ),
                        ),
                        Text('\n\n4. Nhấn Publish\n'
                            '5. Đợi vài giây\n'
                            '6. Test lại\n\n'
                            'Xem chi tiết: docs/FIREBASE_SETUP.md'),
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
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testConnection,
                    icon: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: const Text('Test Kết nối Firebase'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _checkAuth,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Kiểm tra Auth'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nếu gặp lỗi Permission Denied, nhấn icon ? để xem hướng dẫn',
                      style: TextStyle(color: Colors.blue[900], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _result,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
