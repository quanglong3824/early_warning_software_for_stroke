import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/notification_service.dart';

/// Notification settings keys for SharedPreferences
class NotificationSettingsKeys {
  static const String pushEnabled = 'notification_push_enabled';
  static const String prescriptionEnabled = 'notification_prescription_enabled';
  static const String appointmentEnabled = 'notification_appointment_enabled';
  static const String sosEnabled = 'notification_sos_enabled';
  static const String chatEnabled = 'notification_chat_enabled';
  static const String medicationReminderEnabled = 'notification_medication_reminder_enabled';
  static const String healthAlertEnabled = 'notification_health_alert_enabled';
  static const String familyAlertEnabled = 'notification_family_alert_enabled';
  static const String paymentEnabled = 'notification_payment_enabled';
  static const String soundEnabled = 'notification_sound_enabled';
  static const String vibrationEnabled = 'notification_vibration_enabled';
}

class ScreenNotificationSettings extends StatefulWidget {
  const ScreenNotificationSettings({super.key});

  @override
  State<ScreenNotificationSettings> createState() => _ScreenNotificationSettingsState();
}

class _ScreenNotificationSettingsState extends State<ScreenNotificationSettings> {
  final NotificationService _notificationService = NotificationService();
  
  // Notification settings state
  bool _pushEnabled = true;
  bool _prescriptionEnabled = true;
  bool _appointmentEnabled = true;
  bool _sosEnabled = true;
  bool _chatEnabled = true;
  bool _medicationReminderEnabled = true;
  bool _healthAlertEnabled = true;
  bool _familyAlertEnabled = true;
  bool _paymentEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  
  bool _hasPermission = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPermission = await _notificationService.hasPermission();
    
    setState(() {
      _hasPermission = hasPermission;
      _pushEnabled = prefs.getBool(NotificationSettingsKeys.pushEnabled) ?? true;
      _prescriptionEnabled = prefs.getBool(NotificationSettingsKeys.prescriptionEnabled) ?? true;
      _appointmentEnabled = prefs.getBool(NotificationSettingsKeys.appointmentEnabled) ?? true;
      _sosEnabled = prefs.getBool(NotificationSettingsKeys.sosEnabled) ?? true;
      _chatEnabled = prefs.getBool(NotificationSettingsKeys.chatEnabled) ?? true;
      _medicationReminderEnabled = prefs.getBool(NotificationSettingsKeys.medicationReminderEnabled) ?? true;
      _healthAlertEnabled = prefs.getBool(NotificationSettingsKeys.healthAlertEnabled) ?? true;
      _familyAlertEnabled = prefs.getBool(NotificationSettingsKeys.familyAlertEnabled) ?? true;
      _paymentEnabled = prefs.getBool(NotificationSettingsKeys.paymentEnabled) ?? true;
      _soundEnabled = prefs.getBool(NotificationSettingsKeys.soundEnabled) ?? true;
      _vibrationEnabled = prefs.getBool(NotificationSettingsKeys.vibrationEnabled) ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _requestPermission() async {
    final granted = await _notificationService.requestPermission();
    setState(() {
      _hasPermission = granted;
    });
    
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng cấp quyền thông báo trong cài đặt hệ thống'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgLight,
        appBar: AppBar(
          title: const Text('Cài đặt thông báo'),
          backgroundColor: Colors.white,
          elevation: 0.5,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text('Cài đặt thông báo'),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Permission status card
            if (!_hasPermission)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chưa cấp quyền thông báo',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bạn cần cấp quyền để nhận thông báo',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _requestPermission,
                      child: const Text('Cấp quyền'),
                    ),
                  ],
                ),
              ),

            // Master toggle
            _sectionTitle('Tổng quan'),
            _card([
              SwitchListTile(
                secondary: _iconBox(Icons.notifications, primary),
                title: const Text('Bật thông báo đẩy'),
                subtitle: const Text('Nhận thông báo từ ứng dụng'),
                value: _pushEnabled && _hasPermission,
                activeColor: primary,
                onChanged: _hasPermission
                    ? (value) {
                        setState(() => _pushEnabled = value);
                        _saveSetting(NotificationSettingsKeys.pushEnabled, value);
                      }
                    : null,
              ),
            ]),

            // Notification types
            _sectionTitle('Loại thông báo'),
            _card([
              _notificationToggle(
                icon: Icons.medical_services,
                title: 'Đơn thuốc mới',
                subtitle: 'Thông báo khi có đơn thuốc mới',
                value: _prescriptionEnabled,
                onChanged: (value) {
                  setState(() => _prescriptionEnabled = value);
                  _saveSetting(NotificationSettingsKeys.prescriptionEnabled, value);
                },
              ),
              _divider(),
              _notificationToggle(
                icon: Icons.calendar_today,
                title: 'Lịch hẹn',
                subtitle: 'Thông báo xác nhận, hủy, đổi lịch hẹn',
                value: _appointmentEnabled,
                onChanged: (value) {
                  setState(() => _appointmentEnabled = value);
                  _saveSetting(NotificationSettingsKeys.appointmentEnabled, value);
                },
              ),
              _divider(),
              _notificationToggle(
                icon: Icons.emergency,
                title: 'Cảnh báo SOS',
                subtitle: 'Thông báo khi có SOS từ người thân',
                value: _sosEnabled,
                onChanged: (value) {
                  setState(() => _sosEnabled = value);
                  _saveSetting(NotificationSettingsKeys.sosEnabled, value);
                },
              ),
              _divider(),
              _notificationToggle(
                icon: Icons.chat,
                title: 'Tin nhắn',
                subtitle: 'Thông báo tin nhắn mới từ bác sĩ',
                value: _chatEnabled,
                onChanged: (value) {
                  setState(() => _chatEnabled = value);
                  _saveSetting(NotificationSettingsKeys.chatEnabled, value);
                },
              ),
              _divider(),
              _notificationToggle(
                icon: Icons.medication,
                title: 'Nhắc nhở uống thuốc',
                subtitle: 'Nhắc nhở theo lịch uống thuốc',
                value: _medicationReminderEnabled,
                onChanged: (value) {
                  setState(() => _medicationReminderEnabled = value);
                  _saveSetting(NotificationSettingsKeys.medicationReminderEnabled, value);
                },
              ),
              _divider(),
              _notificationToggle(
                icon: Icons.favorite,
                title: 'Cảnh báo sức khỏe',
                subtitle: 'Thông báo khi có nguy cơ cao',
                value: _healthAlertEnabled,
                onChanged: (value) {
                  setState(() => _healthAlertEnabled = value);
                  _saveSetting(NotificationSettingsKeys.healthAlertEnabled, value);
                },
              ),
              _divider(),
              _notificationToggle(
                icon: Icons.family_restroom,
                title: 'Cảnh báo gia đình',
                subtitle: 'Thông báo sức khỏe người thân',
                value: _familyAlertEnabled,
                onChanged: (value) {
                  setState(() => _familyAlertEnabled = value);
                  _saveSetting(NotificationSettingsKeys.familyAlertEnabled, value);
                },
              ),
              _divider(),
              _notificationToggle(
                icon: Icons.payment,
                title: 'Thanh toán',
                subtitle: 'Thông báo trạng thái thanh toán',
                value: _paymentEnabled,
                onChanged: (value) {
                  setState(() => _paymentEnabled = value);
                  _saveSetting(NotificationSettingsKeys.paymentEnabled, value);
                },
              ),
            ]),

            // Sound and vibration
            _sectionTitle('Âm thanh & Rung'),
            _card([
              SwitchListTile(
                secondary: _iconBox(Icons.volume_up, primary),
                title: const Text('Âm thanh'),
                subtitle: const Text('Phát âm thanh khi có thông báo'),
                value: _soundEnabled,
                activeColor: primary,
                onChanged: (value) {
                  setState(() => _soundEnabled = value);
                  _saveSetting(NotificationSettingsKeys.soundEnabled, value);
                },
              ),
              _divider(),
              SwitchListTile(
                secondary: _iconBox(Icons.vibration, primary),
                title: const Text('Rung'),
                subtitle: const Text('Rung khi có thông báo'),
                value: _vibrationEnabled,
                activeColor: primary,
                onChanged: (value) {
                  setState(() => _vibrationEnabled = value);
                  _saveSetting(NotificationSettingsKeys.vibrationEnabled, value);
                },
              ),
            ]),

            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _hasPermission ? _sendTestNotification : null,
                      icon: const Icon(Icons.send),
                      label: const Text('Thử ngay'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _hasPermission ? _sendScheduledTestNotification : null,
                      icon: const Icon(Icons.timer),
                      label: const Text('Hẹn 5s'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _notificationToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    const primary = Color(0xFF135BEC);
    final enabled = _pushEnabled && _hasPermission;
    
    return SwitchListTile(
      secondary: _iconBox(icon, enabled ? primary : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? Colors.black87 : Colors.grey,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: enabled ? Colors.black54 : Colors.grey.shade400,
        ),
      ),
      value: value && enabled,
      activeColor: primary,
      onChanged: enabled ? onChanged : null,
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(children: children),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 72);

  Future<void> _sendTestNotification() async {
    await _notificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Thông báo thử',
      body: 'Đây là thông báo thử từ SEWS. Nếu bạn thấy thông báo này, cài đặt đã hoạt động!',
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi thông báo thử'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _sendScheduledTestNotification() async {
    final now = DateTime.now().add(const Duration(seconds: 5));
    
    await _notificationService.scheduleLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Hẹn giờ thành công',
      body: 'Thông báo này xuất hiện sau 5 giây.',
      scheduledTime: now,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã hẹn thông báo trong 5 giây....'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }
}
