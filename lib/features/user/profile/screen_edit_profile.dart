import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../services/auth_service.dart';

class ScreenEditProfile extends StatefulWidget {
  const ScreenEditProfile({super.key});

  @override
  State<ScreenEditProfile> createState() => _ScreenEditProfileState();
}

class _ScreenEditProfileState extends State<ScreenEditProfile> {
  final _authService = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  
  bool _isLoading = false;
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _gender;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        if (!mounted) return;
        Navigator.of(context).pop();
        return;
      }

      final database = FirebaseDatabase.instance.ref();
      final snapshot = await database.child('users').child(userId).get();

      if (snapshot.exists) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          _nameController.text = userData['name'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _addressController.text = userData['address'] ?? '';
          _gender = userData['gender'];
          
          // Format date of birth
          if (userData['dateOfBirth'] != null) {
            _selectedDate = DateTime.fromMillisecondsSinceEpoch(userData['dateOfBirth'] as int);
            _dateOfBirthController.text = _formatDate(_selectedDate!);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải dữ liệu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateOfBirthController.text = _formatDate(picked);
      });
    }
  }

  String? _validateName(String value) {
    if (value.trim().isEmpty) {
      return 'Vui lòng nhập họ và tên';
    }
    if (value.trim().length < 2) {
      return 'Họ tên phải có ít nhất 2 ký tự';
    }
    return null;
  }

  String? _validateEmail(String value) {
    if (value.trim().isEmpty) {
      return null; // Email có thể để trống
    }
    if (!_authService.isValidEmail(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  String? _validatePhone(String value) {
    if (value.trim().isEmpty) {
      return null; // Phone có thể để trống
    }
    if (!_authService.isValidPhone(value)) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }

  bool _validateForm() {
    setState(() {
      _nameError = _validateName(_nameController.text);
      _emailError = _validateEmail(_emailController.text);
      _phoneError = _validatePhone(_phoneController.text);
    });

    return _nameError == null && _emailError == null && _phoneError == null;
  }

  Future<void> _saveProfile() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }

      final database = FirebaseDatabase.instance.ref();
      
      // Cập nhật thông tin trong Realtime Database
      final updateData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        'gender': _gender,
        'dateOfBirth': _selectedDate?.millisecondsSinceEpoch,
        'updatedAt': ServerValue.timestamp,
      };
      
      await database.child('users').child(userId).update(updateData);

      // Cập nhật session
      await _authService.updateUserSession(
        userName: _nameController.text.trim(),
        userEmail: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật thông tin thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      // Pop với result = true để profile reload
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        title: const Text('Chỉnh sửa thông tin'),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: _isLoading && _nameController.text.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                            'Cập nhật thông tin cá nhân của bạn. Email và số điện thoại có thể để trống.',
                            style: TextStyle(color: Colors.blue, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Họ và tên *',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _nameError != null ? Colors.red : borderColor),
                    ),
                    child: TextField(
                      controller: _nameController,
                      onChanged: (value) {
                        if (_nameError != null) {
                          setState(() {
                            _nameError = _validateName(value);
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        hintText: 'Nhập họ và tên',
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      ),
                      style: const TextStyle(color: textPrimary, fontSize: 16),
                    ),
                  ),
                  if (_nameError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(
                        _nameError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Email',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _emailError != null ? Colors.red : borderColor),
                    ),
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) {
                        if (_emailError != null) {
                          setState(() {
                            _emailError = _validateEmail(value);
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        hintText: 'Nhập email (tùy chọn)',
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      ),
                      style: const TextStyle(color: textPrimary, fontSize: 16),
                    ),
                  ),
                  if (_emailError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(
                        _emailError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Số điện thoại',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _phoneError != null ? Colors.red : borderColor),
                    ),
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      onChanged: (value) {
                        if (_phoneError != null) {
                          setState(() {
                            _phoneError = _validatePhone(value);
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        hintText: 'Nhập số điện thoại (tùy chọn)',
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      ),
                      style: const TextStyle(color: textPrimary, fontSize: 16),
                    ),
                  ),
                  if (_phoneError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(
                        _phoneError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Địa chỉ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        hintText: 'Nhập địa chỉ (tùy chọn)',
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      ),
                      style: const TextStyle(color: textPrimary, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ngày sinh',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _dateOfBirthController.text.isEmpty ? 'Chọn ngày sinh (tùy chọn)' : _dateOfBirthController.text,
                              style: TextStyle(
                                color: _dateOfBirthController.text.isEmpty ? Colors.grey : textPrimary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Giới tính',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _gender,
                        hint: const Text('Chọn giới tính (tùy chọn)'),
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Nam')),
                          DropdownMenuItem(value: 'female', child: Text('Nữ')),
                          DropdownMenuItem(value: 'other', child: Text('Khác')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _gender = value;
                          });
                        },
                      ),
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
                      onPressed: !_isLoading ? _saveProfile : null,
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
                              'Lưu thay đổi',
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
