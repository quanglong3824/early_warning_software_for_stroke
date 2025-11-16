import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/family_service.dart';

class ScreenFamilyManagement extends StatefulWidget {
  const ScreenFamilyManagement({super.key});

  @override
  State<ScreenFamilyManagement> createState() => _ScreenFamilyManagementState();
}

class _ScreenFamilyManagementState extends State<ScreenFamilyManagement> {
  final _authService = AuthService();
  final _familyService = FamilyService();
  
  List<Map<String, dynamic>> _familyMembers = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _sentRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await _authService.getUserId();
      if (userId == null) return;

      final members = await _familyService.getFamilyMembers(userId);
      final requests = await _familyService.getPendingRequests(userId);
      final sentRequests = await _familyService.getSentRequests(userId);

      setState(() {
        _familyMembers = members;
        _pendingRequests = requests;
        _sentRequests = sentRequests;
      });
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddMemberDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const _AddMemberDialog(),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _acceptRequest(String requestId) async {
    final success = await _familyService.acceptFamilyRequest(requestId);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã chấp nhận yêu cầu!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Có lỗi xảy ra!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    final success = await _familyService.rejectFamilyRequest(requestId);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã từ chối yêu cầu!'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadData();
    }
  }

  Future<void> _removeMember(String memberId, String memberName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa $memberName khỏi danh sách gia đình?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final userId = await _authService.getUserId();
    if (userId == null) return;

    final success = await _familyService.removeFamilyMember(userId, memberId);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa thành viên!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    }
  }

  Future<void> _cancelSentRequest(String requestId, String toUserName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy yêu cầu'),
        content: Text('Bạn có chắc muốn hủy yêu cầu gửi đến $toUserName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Hủy yêu cầu'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _familyService.cancelSentRequest(requestId);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã hủy yêu cầu!'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Gia đình của bạn',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _showAddMemberDialog,
            icon: const Icon(Icons.person_add, color: primary),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Yêu cầu đang chờ (nhận được)
                  if (_pendingRequests.isNotEmpty) ...[
                    const Text(
                      'Yêu cầu đang chờ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._pendingRequests.map((request) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RequestCard(
                            request: request,
                            onAccept: () => _acceptRequest(request['id']),
                            onReject: () => _rejectRequest(request['id']),
                          ),
                        )),
                    const SizedBox(height: 24),
                  ],

                  // Yêu cầu đã gửi đi
                  if (_sentRequests.isNotEmpty) ...[
                    const Text(
                      'Yêu cầu đã gửi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._sentRequests.map((request) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SentRequestCard(
                            request: request,
                            onCancel: () => _cancelSentRequest(
                              request['id'],
                              request['toUserName'],
                            ),
                          ),
                        )),
                    const SizedBox(height: 24),
                  ],

                  // Danh sách gia đình
                  const Text(
                    'Thành viên gia đình',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (_familyMembers.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.family_restroom, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có thành viên nào',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Nhấn nút + để thêm thành viên',
                              style: TextStyle(color: Colors.grey[500], fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._familyMembers.map((member) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _MemberCard(
                            member: member,
                            onRemove: () => _removeMember(member['id'], member['memberName']),
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}

// Card yêu cầu
class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_add, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['fromUserName'] ?? 'Người dùng',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Muốn thêm bạn vào gia đình',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Từ chối'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Chấp nhận'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Card yêu cầu đã gửi
class _SentRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onCancel;

  const _SentRequestCard({
    required this.request,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.schedule, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request['toUserName'] ?? 'Người dùng',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Đang chờ phản hồi',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: const Text(
              'Đang chờ',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: const Icon(Icons.cancel, color: Colors.orange),
            tooltip: 'Hủy yêu cầu',
          ),
        ],
      ),
    );
  }
}

// Card thành viên
class _MemberCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final VoidCallback onRemove;

  const _MemberCard({
    required this.member,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF135BEC).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Color(0xFF135BEC), size: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['memberName'] ?? 'Không rõ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  member['relationship'] ?? 'Người thân',
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE7F6ED),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: const Text(
              'Đã kết nối',
              style: TextStyle(
                color: Color(0xFF07883B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    );
  }
}

// Dialog thêm thành viên
class _AddMemberDialog extends StatefulWidget {
  const _AddMemberDialog();

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final _authService = AuthService();
  final _familyService = FamilyService();
  final _searchController = TextEditingController();
  
  String _selectedRelationship = 'Người thân';
  Map<String, dynamic>? _foundUser;
  bool _isSearching = false;
  bool _isSending = false;

  final List<String> _relationships = [
    'Bố/Mẹ',
    'Con',
    'Anh/Chị',
    'Em',
    'Vợ/Chồng',
    'Người thân',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    if (_searchController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập email hoặc số điện thoại'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _foundUser = null;
    });

    try {
      final user = await _familyService.findUserByEmailOrPhone(
        _searchController.text.trim(),
      );

      setState(() {
        _foundUser = user;
      });

      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tìm thấy người dùng'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _sendRequest() async {
    if (_foundUser == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      final currentUserId = await _authService.getUserId();
      final currentUserName = await _authService.getUserName();
      
      if (currentUserId == null || currentUserName == null) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }

      if (currentUserId == _foundUser!['id']) {
        throw Exception('Không thể thêm chính mình');
      }

      final success = await _familyService.sendFamilyRequest(
        fromUserId: currentUserId,
        fromUserName: currentUserName,
        toUserId: _foundUser!['id'],
        toUserName: _foundUser!['name'],
        relationship: _selectedRelationship,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi yêu cầu!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yêu cầu đã tồn tại hoặc đã là thành viên'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thêm thành viên',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Email hoặc số điện thoại',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  onPressed: _isSearching ? null : _searchUser,
                  icon: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            if (_foundUser != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _foundUser!['name'] ?? 'Không rõ',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            _foundUser!['email'] ?? _foundUser!['phone'] ?? '',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Mối quan hệ',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRelationship,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _relationships.map((rel) {
                  return DropdownMenuItem(value: rel, child: Text(rel));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedRelationship = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                const SizedBox(width: 8),
                if (_foundUser != null)
                  ElevatedButton(
                    onPressed: _isSending ? null : _sendRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Gửi yêu cầu'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
