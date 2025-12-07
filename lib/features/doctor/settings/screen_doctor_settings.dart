import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/doctor_bottom_nav.dart';
import '../../../services/auth_service.dart';
import '../../../services/doctor_service.dart';
import '../../../services/notification_service.dart';
import '../../../data/models/doctor_models.dart';
import 'screen_edit_doctor_profile.dart';

class ScreenDoctorSettings extends StatefulWidget {
  const ScreenDoctorSettings({super.key});

  @override
  State<ScreenDoctorSettings> createState() => _ScreenDoctorSettingsState();
}

class _ScreenDoctorSettingsState extends State<ScreenDoctorSettings> {
  final _authService = AuthService();
  final _doctorService = DoctorService();
  final _notificationService = NotificationService();
  final _db = FirebaseDatabase.instance.ref();
  
  String? _doctorId;
  DoctorModel? _doctor;
  bool _isLoading = true;
  
  // Notification settings
  bool _sosNotification = true;
  bool _appointmentNotification = true;
  bool _chatNotification = true;
  bool _biometricAuth = false;
  bool _autoLogout = true;

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
    _loadNotificationSettings();
  }

  Future<void> _loadDoctorData() async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return;
      
      setState(() {
        _doctorId = userId;
        _isLoading = true;
      });
      
      final doctor = await _doctorService.getDoctor(userId);
      
      if (mounted) {
        setState(() {
          _doctor = doctor;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading doctor data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _sosNotification = prefs.getBool('doctor_sos_notification') ?? true;
          _appointmentNotification = prefs.getBool('doctor_appointment_notification') ?? true;
          _chatNotification = prefs.getBool('doctor_chat_notification') ?? true;
          _biometricAuth = prefs.getBool('doctor_biometric_auth') ?? false;
          _autoLogout = prefs.getBool('doctor_auto_logout') ?? true;
        });
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
  }

  Future<void> _saveNotificationSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
      
      // Update Firebase for server-side notification filtering
      if (_doctorId != null) {
        await _db.child('users').child(_doctorId!).child('notificationSettings').update({
          key.replaceFirst('doctor_', ''): value,
          'updatedAt': ServerValue.timestamp,
        });
      }
      
      // Subscribe/unsubscribe from FCM topics
      if (key == 'doctor_sos_notification') {
        if (value) {
          await _notificationService.subscribeToTopic('doctor_sos');
        } else {
          await _notificationService.unsubscribeFromTopic('doctor_sos');
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu cài đặt'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving notification setting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi lưu cài đặt'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Đổi mật khẩu'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu hiện tại',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới',
                    border: const OutlineInputBorder(),
                    helperText: 'Tối thiểu 6 ký tự',
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu mới',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      // Validate
                      if (currentPasswordController.text.isEmpty ||
                          newPasswordController.text.isEmpty ||
                          confirmPasswordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng nhập đầy đủ thông tin'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (newPasswordController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mật khẩu mới phải có ít nhất 6 ký tự'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (newPasswordController.text != confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mật khẩu xác nhận không khớp'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      final result = await _authService.changePassword(
                        currentPassword: currentPasswordController.text,
                        newPassword: newPasswordController.text,
                      );

                      setDialogState(() => isLoading = false);

                      if (result['success'] == true) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đổi mật khẩu thành công!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message'] ?? 'Đổi mật khẩu thất bại'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF135BEC),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Đổi mật khẩu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
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

    if (confirmed == true && mounted) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Clear notification subscriptions
        await _notificationService.unsubscribeFromTopic('doctor_sos');
        await _notificationService.unsubscribeFromTopic('doctor_appointments');
        
        // Logout
        await _authService.logout();
        
        if (mounted) {
          Navigator.pop(context); // Close loading
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/doctor/login',
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi đăng xuất: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToEditProfile() async {
    if (_doctor == null || _doctorId == null) return;
    
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ScreenEditDoctorProfile(
          doctorId: _doctorId!,
          doctor: _doctor!,
        ),
      ),
    );
    
    if (result == true) {
      _loadDoctorData();
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    const bgLight = Color(0xFFF6F6F8);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text('Cài đặt'),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDoctorData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Thông tin cá nhân
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: primary.withOpacity(0.1),
                          backgroundImage: _doctor?.photoURL != null
                              ? NetworkImage(_doctor!.photoURL!)
                              : null,
                          child: _doctor?.photoURL == null
                              ? const Icon(Icons.person, size: 40, color: primary)
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _doctor?.name ?? 'Bác sĩ',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _doctor?.specialization ?? 'Chưa cập nhật chuyên khoa',
                          style: const TextStyle(color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _doctor?.licenseNumber ?? 'Chưa có mã giấy phép',
                          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _navigateToEditProfile,
                          icon: const Icon(Icons.edit),
                          label: const Text('Chỉnh sửa hồ sơ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Cài đặt tài khoản
                  _buildSection('Tài khoản', [
                    _buildSettingItem(
                      icon: Icons.email,
                      title: 'Email',
                      subtitle: _doctor?.email ?? 'Chưa cập nhật',
                      onTap: () {},
                    ),
                    _buildSettingItem(
                      icon: Icons.phone,
                      title: 'Số điện thoại',
                      subtitle: _doctor?.phone ?? 'Chưa cập nhật',
                      onTap: () {},
                    ),
                    _buildSettingItem(
                      icon: Icons.lock,
                      title: 'Đổi mật khẩu',
                      onTap: _showChangePasswordDialog,
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Cài đặt lịch làm việc
                  _buildSection('Lịch làm việc', [
                    _buildSettingItem(
                      icon: Icons.calendar_today,
                      title: 'Lịch trực',
                      subtitle: 'Quản lý ca trực',
                      onTap: () {
                        Navigator.pushNamed(context, '/doctor/schedule');
                      },
                    ),
                    _buildSwitchItem(
                      icon: Icons.event_available,
                      title: 'Trạng thái sẵn sàng',
                      subtitle: _doctor?.isAvailable == true ? 'Đang nhận bệnh nhân' : 'Tạm nghỉ',
                      value: _doctor?.isAvailable ?? true,
                      onChanged: (value) async {
                        if (_doctorId != null) {
                          await _doctorService.updateAvailability(_doctorId!, value);
                          _loadDoctorData();
                        }
                      },
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Thông báo
                  _buildSection('Thông báo', [
                    _buildSwitchItem(
                      icon: Icons.notifications,
                      title: 'Thông báo SOS',
                      subtitle: 'Nhận thông báo khẩn cấp',
                      value: _sosNotification,
                      onChanged: (value) {
                        setState(() => _sosNotification = value);
                        _saveNotificationSetting('doctor_sos_notification', value);
                      },
                    ),
                    _buildSwitchItem(
                      icon: Icons.calendar_month,
                      title: 'Thông báo lịch hẹn',
                      subtitle: 'Nhắc nhở lịch hẹn sắp tới',
                      value: _appointmentNotification,
                      onChanged: (value) {
                        setState(() => _appointmentNotification = value);
                        _saveNotificationSetting('doctor_appointment_notification', value);
                      },
                    ),
                    _buildSwitchItem(
                      icon: Icons.chat,
                      title: 'Thông báo tin nhắn',
                      subtitle: 'Tin nhắn mới từ bệnh nhân',
                      value: _chatNotification,
                      onChanged: (value) {
                        setState(() => _chatNotification = value);
                        _saveNotificationSetting('doctor_chat_notification', value);
                      },
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Bảo mật
                  _buildSection('Bảo mật', [
                    _buildSwitchItem(
                      icon: Icons.fingerprint,
                      title: 'Xác thực sinh trắc học',
                      subtitle: 'Vân tay hoặc Face ID',
                      value: _biometricAuth,
                      onChanged: (value) {
                        setState(() => _biometricAuth = value);
                        _saveNotificationSetting('doctor_biometric_auth', value);
                      },
                    ),
                    _buildSwitchItem(
                      icon: Icons.lock_clock,
                      title: 'Tự động đăng xuất',
                      subtitle: 'Sau 30 phút không hoạt động',
                      value: _autoLogout,
                      onChanged: (value) {
                        setState(() => _autoLogout = value);
                        _saveNotificationSetting('doctor_auto_logout', value);
                      },
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Hỗ trợ
                  _buildSection('Hỗ trợ', [
                    _buildSettingItem(
                      icon: Icons.help,
                      title: 'Trung tâm trợ giúp',
                      onTap: () {
                        Navigator.pushNamed(context, '/help-support');
                      },
                    ),
                    _buildSettingItem(
                      icon: Icons.privacy_tip,
                      title: 'Chính sách bảo mật',
                      onTap: () {
                        Navigator.pushNamed(context, '/privacy-policy');
                      },
                    ),
                    _buildSettingItem(
                      icon: Icons.description,
                      title: 'Điều khoản sử dụng',
                      onTap: () {
                        Navigator.pushNamed(context, '/terms-of-service');
                      },
                    ),
                    _buildSettingItem(
                      icon: Icons.info,
                      title: 'Về ứng dụng',
                      subtitle: 'Phiên bản 1.0.0',
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'SEWS Doctor',
                          applicationVersion: '1.0.0',
                          applicationLegalese: '© 2024 SEWS Team',
                        );
                      },
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Đăng xuất
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text(
                        'Đăng xuất',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                      onTap: _handleLogout,
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      bottomNavigationBar: const DoctorBottomNav(currentIndex: 3),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  const Divider(height: 1, indent: 56),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF135BEC).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF135BEC), size: 20),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF135BEC).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF135BEC), size: 20),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF135BEC),
      ),
    );
  }
}
