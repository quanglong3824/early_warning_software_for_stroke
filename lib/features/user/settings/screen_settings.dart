import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/auth_service.dart';

class ScreenSettings extends StatefulWidget {
  const ScreenSettings({super.key});

  @override
  State<ScreenSettings> createState() => _ScreenSettingsState();
}

class _ScreenSettingsState extends State<ScreenSettings> {
  bool darkMode = false;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'vi';
  String _selectedUnit = 'mmHg';
  final _authService = AuthService();
  final _database = FirebaseDatabase.instance.ref();
  String _userName = 'User';
  String? _userId;
  List<Map<String, dynamic>> _emergencyContacts = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSettings();
  }

  Future<void> _loadUserData() async {
    final name = await _authService.getUserName();
    final userId = await _authService.getUserId();
    setState(() {
      _userName = name;
      _userId = userId;
    });
    if (userId != null) {
      _loadEmergencyContacts(userId);
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      darkMode = prefs.getBool('darkMode') ?? false;
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _selectedLanguage = prefs.getString('language') ?? 'vi';
      _selectedUnit = prefs.getString('unit') ?? 'mmHg';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', darkMode);
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setString('language', _selectedLanguage);
    await prefs.setString('unit', _selectedUnit);
  }

  Future<void> _loadEmergencyContacts(String userId) async {
    try {
      final snapshot = await _database.child('emergency_contacts/$userId').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          _emergencyContacts = data.entries.map((e) => {
            'id': e.key,
            ...Map<String, dynamic>.from(e.value as Map),
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading emergency contacts: $e');
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  // Privacy Settings Dialog
  Future<void> _showPrivacySettings() async {
    bool shareHealthData = true;
    bool showOnlineStatus = true;
    
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.privacy_tip, color: Color(0xFF135BEC)),
              SizedBox(width: 8),
              Text('Cài đặt quyền riêng tư'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Chia sẻ dữ liệu sức khỏe với bác sĩ'),
                subtitle: const Text('Cho phép bác sĩ xem lịch sử sức khỏe'),
                value: shareHealthData,
                onChanged: (v) => setDialogState(() => shareHealthData = v),
              ),
              SwitchListTile(
                title: const Text('Hiển thị trạng thái online'),
                subtitle: const Text('Cho phép người khác thấy bạn đang online'),
                value: showOnlineStatus,
                onChanged: (v) => setDialogState(() => showOnlineStatus = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
            ElevatedButton(
              onPressed: () {
                // Save privacy settings
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã lưu cài đặt quyền riêng tư'), backgroundColor: Colors.green),
                );
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  // Emergency Contacts Dialog
  Future<void> _showEmergencyContacts() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.contacts, color: Color(0xFF135BEC)),
              SizedBox(width: 8),
              Text('Liên hệ khẩn cấp'),
            ],
          ),
          content: SizedBox(
            width: 400,
            height: 400,
            child: Column(
              children: [
                // Add new contact form
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên', prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Số điện thoại', prefixIcon: Icon(Icons.phone)),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: relationController,
                  decoration: const InputDecoration(labelText: 'Quan hệ (VD: Bố, Mẹ...)', prefixIcon: Icon(Icons.family_restroom)),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (nameController.text.isEmpty || phoneController.text.isEmpty) return;
                    if (_userId == null) return;
                    
                    final newRef = _database.child('emergency_contacts/$_userId').push();
                    await newRef.set({
                      'name': nameController.text,
                      'phone': phoneController.text,
                      'relation': relationController.text,
                      'createdAt': DateTime.now().millisecondsSinceEpoch,
                    });
                    
                    nameController.clear();
                    phoneController.clear();
                    relationController.clear();
                    
                    await _loadEmergencyContacts(_userId!);
                    setDialogState(() {});
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm liên hệ'),
                ),
                const Divider(),
                // List of contacts
                Expanded(
                  child: _emergencyContacts.isEmpty
                      ? const Center(child: Text('Chưa có liên hệ khẩn cấp'))
                      : ListView.builder(
                          itemCount: _emergencyContacts.length,
                          itemBuilder: (ctx, i) {
                            final contact = _emergencyContacts[i];
                            return ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(contact['name'] ?? ''),
                              subtitle: Text('${contact['phone']} - ${contact['relation'] ?? ''}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  await _database.child('emergency_contacts/$_userId/${contact['id']}').remove();
                                  await _loadEmergencyContacts(_userId!);
                                  setDialogState(() {});
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
          ],
        ),
      ),
    );
  }

  // Language Selection Dialog
  Future<void> _showLanguageSelection() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chọn ngôn ngữ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Tiếng Việt'),
              value: 'vi',
              groupValue: _selectedLanguage,
              onChanged: (v) => Navigator.pop(ctx, v),
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: _selectedLanguage,
              onChanged: (v) => Navigator.pop(ctx, v),
            ),
          ],
        ),
      ),
    );
    
    if (result != null) {
      setState(() => _selectedLanguage = result);
      await _saveSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thay đổi ngôn ngữ. Khởi động lại ứng dụng để áp dụng.'), backgroundColor: Colors.blue),
        );
      }
    }
  }

  // Unit Selection Dialog
  Future<void> _showUnitSelection() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chọn đơn vị đo lường'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('mmHg (Huyết áp)'),
              subtitle: const Text('Đơn vị phổ biến'),
              value: 'mmHg',
              groupValue: _selectedUnit,
              onChanged: (v) => Navigator.pop(ctx, v),
            ),
            RadioListTile<String>(
              title: const Text('kPa'),
              subtitle: const Text('Đơn vị quốc tế'),
              value: 'kPa',
              groupValue: _selectedUnit,
              onChanged: (v) => Navigator.pop(ctx, v),
            ),
          ],
        ),
      ),
    );
    
    if (result != null) {
      setState(() => _selectedUnit = result);
      await _saveSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã chọn đơn vị: $result'), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    var shield_person = Icons.privacy_tip;
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text('Cài đặt'),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF135BEC).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF135BEC),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111318),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Người dùng',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF616F89),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _sectionTitle('Tài khoản & Bảo mật'),
            _card([
              ListTile(
                leading: _iconBox(Icons.person),
                title: const Text('Thông tin cá nhân'),
                trailing: const Icon(Icons.chevron_right, color: Colors.black45),
                onTap: () {
                  Navigator.of(context).pushNamed('/edit-profile');
                },
              ),
              _divider(),
              ListTile(
                leading: _iconBox(Icons.lock),
                title: const Text('Thay đổi mật khẩu'),
                trailing: const Icon(Icons.chevron_right, color: Colors.black45),
                onTap: () {
                  Navigator.of(context).pushNamed('/change-password');
                },
              ),
              _divider(),
              ListTile(
                leading: _iconBox(shield_person),
                title: const Text('Cài đặt quyền riêng tư'),
                trailing: const Icon(Icons.chevron_right, color: Colors.black45),
                onTap: _showPrivacySettings,
              ),
              _divider(),
              ListTile(
                leading: _iconBox(Icons.contacts),
                title: const Text('Liên kết danh bạ khẩn cấp'),
                subtitle: Text('${_emergencyContacts.length} liên hệ', style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.black45),
                onTap: _showEmergencyContacts,
              ),
            ]),

            _sectionTitle('Thông báo'),
            _card([
              ListTile(
                leading: _iconBox(Icons.notifications),
                title: const Text('Cài đặt thông báo'),
                trailing: const Icon(Icons.chevron_right, color: Colors.black45),
                onTap: () {
                  Navigator.of(context).pushNamed('/settings/notifications');
                },
              ),
              _divider(),
              ListTile(
                leading: _iconBox(Icons.medication),
                title: const Text('Nhắc nhở uống thuốc'),
                trailing: const Icon(Icons.chevron_right, color: Colors.black45),
                onTap: () {
                  Navigator.of(context).pushNamed('/reminders-list');
                },
              ),
            ]),

            _sectionTitle('Cài đặt chung'),
            _card([
              ListTile(
                leading: _iconBox(Icons.language),
                title: const Text('Ngôn ngữ'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_selectedLanguage == 'vi' ? 'Tiếng Việt' : 'English', style: const TextStyle(color: Colors.black54)),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: Colors.black45),
                  ],
                ),
                onTap: _showLanguageSelection,
              ),
              _divider(),
              ListTile(
                leading: _iconBox(Icons.dark_mode),
                title: const Text('Chế độ nền tối'),
                trailing: Switch(
                  value: darkMode,
                  activeColor: primary,
                  onChanged: (v) async {
                    setState(() => darkMode = v);
                    await _saveSettings();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(v ? 'Đã bật chế độ tối' : 'Đã tắt chế độ tối'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }
                  },
                ),
              ),
              _divider(),
              ListTile(
                leading: _iconBox(Icons.straighten),
                title: const Text('Đơn vị đo lường'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_selectedUnit, style: const TextStyle(color: Colors.black54)),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: Colors.black45),
                  ],
                ),
                onTap: _showUnitSelection,
              ),
            ]),

            _sectionTitle('Hỗ trợ & Pháp lý'),
            _card([
              ListTile(
                leading: _iconBox(Icons.help),
                title: const Text('Trợ giúp & Hỗ trợ'),
                trailing: const Icon(Icons.chevron_right, color: Colors.black45),
                onTap: () {
                  Navigator.of(context).pushNamed('/help-support');
                },
              ),
              _divider(),
              ListTile(
                leading: _iconBox(Icons.privacy_tip),
                title: const Text('Chính sách bảo mật'),
                trailing: const Icon(Icons.chevron_right, color: Colors.black45),
                onTap: () {
                  Navigator.of(context).pushNamed('/privacy-policy');
                },
              ),
              _divider(),
              ListTile(
                leading: _iconBox(Icons.gavel),
                title: const Text('Điều khoản sử dụng'),
                trailing: const Icon(Icons.chevron_right, color: Colors.black45),
                onTap: () {
                  Navigator.of(context).pushNamed('/terms-of-service');
                },
              ),
            ]),

            const SizedBox(height: 16),
            _card([
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  alignment: Alignment.center,
                  child: const Icon(Icons.logout, color: Colors.red),
                ),
                title: const Text('Đăng xuất', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                onTap: _logout,
              ),
            ]),

            const SizedBox(height: 12),
            const Center(
              child: Text('Phiên bản ứng dụng 1.0.0', style: TextStyle(color: Colors.black45, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: const Color(0xFF135BEC).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      alignment: Alignment.center,
      child: Icon(icon, color: const Color(0xFF135BEC)),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(title.toUpperCase(), style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(children: children),
    );
  }

  Widget _divider() => const Divider(height: 1);

  Widget _tile({required IconData icon, required String label}) {
    return ListTile(
      leading: _iconBox(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, color: Colors.black45),
      onTap: () {},
    );
  }
}