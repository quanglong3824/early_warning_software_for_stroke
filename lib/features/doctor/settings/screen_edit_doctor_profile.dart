import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/doctor_models.dart';
import '../../../services/auth_service.dart';

class ScreenEditDoctorProfile extends StatefulWidget {
  final String doctorId;
  final DoctorModel doctor;

  const ScreenEditDoctorProfile({
    super.key,
    required this.doctorId,
    required this.doctor,
  });

  @override
  State<ScreenEditDoctorProfile> createState() => _ScreenEditDoctorProfileState();
}

class _ScreenEditDoctorProfileState extends State<ScreenEditDoctorProfile> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _db = FirebaseDatabase.instance.ref();
  final _storage = FirebaseStorage.instance;
  final _imagePicker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _specializationController;
  late TextEditingController _hospitalController;
  late TextEditingController _departmentController;
  late TextEditingController _bioController;
  late TextEditingController _yearsExpController;

  File? _selectedImage;
  String? _currentPhotoURL;
  bool _isLoading = false;
  bool _hasChanges = false;

  // List of common specializations
  final List<String> _specializations = [
    'Tim mạch',
    'Nội khoa',
    'Ngoại khoa',
    'Nhi khoa',
    'Sản phụ khoa',
    'Da liễu',
    'Thần kinh',
    'Tâm thần',
    'Mắt',
    'Tai mũi họng',
    'Răng hàm mặt',
    'Chấn thương chỉnh hình',
    'Ung bướu',
    'Hô hấp',
    'Tiêu hóa',
    'Thận - Tiết niệu',
    'Nội tiết',
    'Cơ xương khớp',
    'Y học cổ truyền',
    'Phục hồi chức năng',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.doctor.name);
    _phoneController = TextEditingController(text: widget.doctor.phone ?? '');
    _specializationController = TextEditingController(text: widget.doctor.specialization ?? '');
    _hospitalController = TextEditingController(text: widget.doctor.hospital ?? '');
    _departmentController = TextEditingController(text: widget.doctor.department ?? '');
    _bioController = TextEditingController(text: widget.doctor.bio ?? '');
    _yearsExpController = TextEditingController(
      text: widget.doctor.yearsOfExperience?.toString() ?? '',
    );
    _currentPhotoURL = widget.doctor.photoURL;

    // Listen for changes
    _nameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _specializationController.addListener(_onFieldChanged);
    _hospitalController.addListener(_onFieldChanged);
    _departmentController.addListener(_onFieldChanged);
    _bioController.addListener(_onFieldChanged);
    _yearsExpController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _hospitalController.dispose();
    _departmentController.dispose();
    _bioController.dispose();
    _yearsExpController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Chụp ảnh'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Chọn từ thư viện'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              if (_currentPhotoURL != null || _selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Xóa ảnh', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                      _currentPhotoURL = null;
                      _hasChanges = true;
                    });
                  },
                ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _hasChanges = true;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return _currentPhotoURL;

    try {
      final ref = _storage.ref().child('doctor_avatars/${widget.doctorId}.jpg');
      await ref.putFile(_selectedImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      throw Exception('Không thể tải ảnh lên');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Upload image if selected
      String? photoURL = _currentPhotoURL;
      if (_selectedImage != null) {
        photoURL = await _uploadImage();
      } else if (_currentPhotoURL == null && widget.doctor.photoURL != null) {
        // User removed the photo
        photoURL = null;
      }

      // Prepare update data
      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'specialization': _specializationController.text.trim().isEmpty 
            ? null 
            : _specializationController.text.trim(),
        'hospital': _hospitalController.text.trim().isEmpty 
            ? null 
            : _hospitalController.text.trim(),
        'department': _departmentController.text.trim().isEmpty 
            ? null 
            : _departmentController.text.trim(),
        'bio': _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        'yearsOfExperience': _yearsExpController.text.trim().isEmpty 
            ? null 
            : int.tryParse(_yearsExpController.text.trim()),
        'photoURL': photoURL,
        'updatedAt': ServerValue.timestamp,
      };

      // Update Firebase
      await _db.child('users').child(widget.doctorId).update(updates);

      // Update session name if changed
      if (_nameController.text.trim() != widget.doctor.name) {
        await _authService.updateUserSession(userName: _nameController.text.trim());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật hồ sơ thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy thay đổi?'),
        content: const Text('Bạn có thay đổi chưa lưu. Bạn có chắc muốn thoát?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tiếp tục chỉnh sửa'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hủy thay đổi'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _showSpecializationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Chọn chuyên khoa',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _specializations.length,
                itemBuilder: (context, index) {
                  final spec = _specializations[index];
                  final isSelected = _specializationController.text == spec;
                  return ListTile(
                    title: Text(spec),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Color(0xFF135BEC))
                        : null,
                    onTap: () {
                      _specializationController.text = spec;
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chỉnh sửa hồ sơ'),
          backgroundColor: Colors.white,
          elevation: 0.5,
          actions: [
            TextButton(
              onPressed: _isLoading || !_hasChanges ? null : _saveProfile,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Lưu',
                      style: TextStyle(
                        color: _hasChanges ? primary : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Avatar section
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: primary.withOpacity(0.1),
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (_currentPhotoURL != null
                                ? NetworkImage(_currentPhotoURL!)
                                : null) as ImageProvider?,
                        child: _selectedImage == null && _currentPhotoURL == null
                            ? const Icon(Icons.person, size: 60, color: primary)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _pickImage,
                  child: const Text('Thay đổi ảnh đại diện'),
                ),
              ),
              const SizedBox(height: 24),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone field
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                  hintText: '0987654321',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final phoneRegex = RegExp(r'^(0|\+84)[0-9]{9,10}$');
                    if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
                      return 'Số điện thoại không hợp lệ';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Specialization field
              TextFormField(
                controller: _specializationController,
                decoration: InputDecoration(
                  labelText: 'Chuyên khoa',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.medical_services),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_drop_down),
                    onPressed: _showSpecializationPicker,
                  ),
                ),
                readOnly: true,
                onTap: _showSpecializationPicker,
              ),
              const SizedBox(height: 16),

              // Hospital field
              TextFormField(
                controller: _hospitalController,
                decoration: const InputDecoration(
                  labelText: 'Bệnh viện / Phòng khám',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_hospital),
                ),
              ),
              const SizedBox(height: 16),

              // Department field
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Khoa / Phòng ban',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 16),

              // Years of experience field
              TextFormField(
                controller: _yearsExpController,
                decoration: const InputDecoration(
                  labelText: 'Số năm kinh nghiệm',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work_history),
                  suffixText: 'năm',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final years = int.tryParse(value);
                    if (years == null || years < 0 || years > 70) {
                      return 'Số năm kinh nghiệm không hợp lệ';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Bio field
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Giới thiệu bản thân',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info_outline),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                maxLength: 500,
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading || !_hasChanges ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text(
                          'Lưu thay đổi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // License info (read-only)
              if (widget.doctor.licenseNumber != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.badge, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mã giấy phép hành nghề',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              widget.doctor.licenseNumber!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.lock, color: Colors.grey, size: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mã giấy phép hành nghề không thể thay đổi. Liên hệ quản trị viên nếu cần cập nhật.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
