import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../services/auth_service.dart';

class ScreenChangePassword extends StatefulWidget {
  const ScreenChangePassword({super.key});

  @override
  State<ScreenChangePassword> createState() => _ScreenChangePasswordState();
}

class _ScreenChangePasswordState extends State<ScreenChangePassword> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;
  String? _lastPasswordChange;

  @override
  void initState() {
    super.initState();
    _loadLastPasswordChange();
  }

  Future<void> _loadLastPasswordChange() async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return;

      final database = FirebaseDatabase.instance.ref();
      final snapshot = await database.child('users').child(userId).get();

      if (snapshot.exists) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        final timestamp = userData['lastPasswordChange'];
        
        if (timestamp != null) {
          final date = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
          setState(() {
            _lastPasswordChange = _formatDate(date);
          });
        }
      }
    } catch (e) {
      print('Error loading last password change: $e');
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hôm nay';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} tuần trước';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} tháng trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateCurrentPassword(String value) {
    if (value.isEmpty) {
      return 'Vui lòng nhập mật khẩu hiện tại';
    }
    return null;
  }

  String? _validateNewPassword(String value) {
    if (value.isEmpty) {
      return 'Vui lòng nhập mật khẩu mới';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    if (value == _currentPasswordController.text) {
      return 'Mật khẩu mới phải khác mật khẩu hiện tại';
    }
    return null;
  }

  String? _validateConfirmPassword(String value) {
    if (value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu mới';
    }
    if (value != _newPasswordController.text) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }

  bool _validateForm() {
    setState(() {
      _currentPasswordError = _validateCurrentPassword(_currentPasswordController.text);
      _newPasswordError = _validateNewPassword(_newPasswordController.text);
      _confirmPasswordError = _validateConfirmPassword(_confirmPasswordController.text);
    });

    return _currentPasswordError == null &&
        _newPasswordError == null &&
        _confirmPasswordError == null;
  }

  Future<void> _changePassword() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    final result = await _authService.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const borderColor = Color(0xFFDBDFE6);
    const textPrimary = Color(0xFF111318);
    const textSecondary = Color(0xFF616F89);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text('Đổi mật khẩu'),
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
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mật khẩu mới phải có ít nhất 6 ký tự và khác với mật khẩu hiện tại.',
                      style: TextStyle(color: Colors.blue, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_lastPasswordChange != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: textSecondary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Lần cuối đổi: $_lastPasswordChange',
                      style: const TextStyle(color: textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'Mật khẩu hiện tại',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _currentPasswordError != null ? Colors.red : borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrent,
                      onChanged: (value) {
                        if (_currentPasswordError != null) {
                          setState(() {
                            _currentPasswordError = _validateCurrentPassword(value);
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        hintText: 'Nhập mật khẩu hiện tại',
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      ),
                      style: const TextStyle(color: textPrimary, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                    icon: Icon(
                      _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (_currentPasswordError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  _currentPasswordError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'Mật khẩu mới',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _newPasswordError != null ? Colors.red : borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      onChanged: (value) {
                        if (_newPasswordError != null) {
                          setState(() {
                            _newPasswordError = _validateNewPassword(value);
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        hintText: 'Nhập mật khẩu mới',
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      ),
                      style: const TextStyle(color: textPrimary, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    icon: Icon(
                      _obscureNew ? Icons.visibility_off : Icons.visibility,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (_newPasswordError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  _newPasswordError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'Xác nhận mật khẩu mới',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _confirmPasswordError != null ? Colors.red : borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      onChanged: (value) {
                        if (_confirmPasswordError != null) {
                          setState(() {
                            _confirmPasswordError = _validateConfirmPassword(value);
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        hintText: 'Nhập lại mật khẩu mới',
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      ),
                      style: const TextStyle(color: textPrimary, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (_confirmPasswordError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  _confirmPasswordError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: !_isLoading ? _changePassword : null,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Đổi mật khẩu',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
