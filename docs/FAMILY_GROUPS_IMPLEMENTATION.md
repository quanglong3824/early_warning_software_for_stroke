# 👨‍👩‍👧‍👦 FAMILY GROUPS - 1:N RELATIONSHIPS

**Ngày thực hiện:** 16/11/2025  
**Trạng thái:** ✅ HOÀN THÀNH

---

## 🎯 MỤC TIÊU

Phát triển từ **1:1** (một người kết nối với một người) sang **1:N** (một nhóm với nhiều thành viên).

### Vấn đề cũ:
- ❌ User X kết nối với 4 người
- ❌ 4 người chỉ thấy User X
- ❌ 4 người không thấy nhau
- ❌ Phải tạo nhiều kết nối 1:1

### Giải pháp mới:
- ✅ Tạo Family Group
- ✅ Tất cả thành viên thấy nhau
- ✅ Quản lý tập trung
- ✅ Dễ dàng thêm/xóa thành viên

---

## 📊 DATABASE STRUCTURE

### 1. family_groups (Thông tin nhóm)
```json
{
  "family_groups": {
    "group_001": {
      "id": "group_001",
      "name": "Gia đình Nguyễn Văn A",
      "description": "Nhóm gia đình của chúng tôi",
      "creatorId": "user_001",
      "memberCount": 5,
      "createdAt": 1700000000000,
      "updatedAt": 1700000000000
    }
  }
}
```

### 2. family_group_members (Thành viên trong nhóm)
```json
{
  "family_group_members": {
    "group_001": {
      "user_001": {
        "userId": "user_001",
        "userName": "Nguyễn Văn A",
        "role": "admin",
        "addedBy": "user_001",
        "joinedAt": 1700000000000
      },
      "user_002": {
        "userId": "user_002",
        "userName": "Trần Thị B",
        "role": "member",
        "addedBy": "user_001",
        "joinedAt": 1700000100000
      }
    }
  }
}
```

### 3. user_family_groups (Nhóm của user)
```json
{
  "user_family_groups": {
    "user_001": {
      "group_001": {
        "groupId": "group_001",
        "role": "admin",
        "joinedAt": 1700000000000
      },
      "group_002": {
        "groupId": "group_002",
        "role": "member",
        "joinedAt": 1700000200000
      }
    }
  }
}
```

### 4. family_group_invitations (Lời mời vào nhóm)
```json
{
  "family_group_invitations": {
    "invitation_001": {
      "id": "invitation_001",
      "groupId": "group_001",
      "groupName": "Gia đình Nguyễn Văn A",
      "fromUserId": "user_001",
      "fromUserName": "Nguyễn Văn A",
      "toUserId": "user_003",
      "toUserName": "Lê Văn C",
      "status": "pending",
      "createdAt": 1700000000000
    }
  }
}
```

---

## 🔧 TÍNH NĂNG

### 1. ✅ Tạo nhóm gia đình
```dart
final groupId = await FamilyGroupService().createFamilyGroup(
  creatorId: userId,
  creatorName: userName,
  groupName: 'Gia đình của tôi',
  description: 'Nhóm gia đình yêu thương',
);
```

### 2. ✅ Gửi lời mời vào nhóm
```dart
await FamilyGroupService().sendGroupInvitation(
  groupId: groupId,
  groupName: groupName,
  fromUserId: currentUserId,
  fromUserName: currentUserName,
  toUserId: targetUserId,
  toUserName: targetUserName,
);
```

### 3. ✅ Chấp nhận/Từ chối lời mời
```dart
// Chấp nhận
await FamilyGroupService().acceptGroupInvitation(invitationId);

// Từ chối
await FamilyGroupService().rejectGroupInvitation(invitationId);
```

### 4. ✅ Thêm thành viên trực tiếp (admin only)
```dart
await FamilyGroupService().addMemberToGroup(
  groupId: groupId,
  userId: userId,
  userName: userName,
  role: 'member',
  addedBy: adminUserId,
);
```

### 5. ✅ Xóa thành viên (admin only)
```dart
await FamilyGroupService().removeMemberFromGroup(
  groupId: groupId,
  userId: userId,
  removedBy: adminUserId,
);
```

### 6. ✅ Rời khỏi nhóm
```dart
await FamilyGroupService().leaveGroup(groupId, userId);
```

### 7. ✅ Xóa nhóm (admin only)
```dart
await FamilyGroupService().deleteGroup(groupId);
```

### 8. ✅ Lấy danh sách nhóm
```dart
// Get once
final groups = await FamilyGroupService().getUserGroups(userId);

// Stream real-time
FamilyGroupService().streamUserGroups(userId).listen((groups) {
  // Update UI
});
```

### 9. ✅ Lấy thành viên nhóm
```dart
// Get once
final members = await FamilyGroupService().getGroupMembers(groupId);

// Stream real-time
FamilyGroupService().streamGroupMembers(groupId).listen((members) {
  // Update UI
});
```

### 10. ✅ Lấy lời mời đang chờ
```dart
final invitations = await FamilyGroupService().getPendingInvitations(userId);
```

---

## 🔄 USER FLOWS

### Flow 1: Tạo nhóm và mời thành viên

```
User A (Creator)
  ↓
1. Tạo nhóm "Gia đình của tôi"
  ↓
2. Gửi lời mời cho User B, C, D
  ↓
User B, C, D nhận notification
  ↓
3. User B chấp nhận → Thêm vào nhóm
4. User C chấp nhận → Thêm vào nhóm
5. User D từ chối → Không thêm
  ↓
Kết quả: Nhóm có 3 thành viên (A, B, C)
Tất cả 3 người đều thấy nhau
```

### Flow 2: Admin thêm thành viên trực tiếp

```
User A (Admin)
  ↓
1. Tìm User E
  ↓
2. Thêm trực tiếp vào nhóm (không cần chấp nhận)
  ↓
User E nhận notification "Đã được thêm vào nhóm"
  ↓
Kết quả: User E thấy tất cả thành viên (A, B, C, E)
```

### Flow 3: Thành viên rời nhóm

```
User C (Member)
  ↓
1. Click "Rời khỏi nhóm"
  ↓
2. Confirm
  ↓
- Xóa khỏi family_group_members
- Xóa khỏi user_family_groups
- Notify các thành viên còn lại
  ↓
Kết quả: Nhóm còn 3 thành viên (A, B, E)
```

### Flow 4: Admin xóa thành viên

```
User A (Admin)
  ↓
1. Click "Xóa" trên User B
  ↓
2. Confirm
  ↓
- Xóa User B khỏi nhóm
- Notify User B
- Notify các thành viên còn lại
  ↓
Kết quả: Nhóm còn 2 thành viên (A, E)
```

### Flow 5: Admin rời nhóm (transfer admin)

```
User A (Admin, Last admin)
  ↓
1. Click "Rời khỏi nhóm"
  ↓
2. System check: Có thành viên khác không?
  ↓
Yes → Transfer admin cho User E
  ↓
3. User A rời nhóm
  ↓
Kết quả: User E trở thành admin
```

### Flow 6: Xóa nhóm

```
User A (Admin)
  ↓
1. Click "Xóa nhóm"
  ↓
2. Confirm
  ↓
- Xóa tất cả thành viên
- Xóa nhóm
- Notify tất cả thành viên
  ↓
Kết quả: Nhóm bị xóa hoàn toàn
```

---

## 🎨 UI COMPONENTS CẦN TẠO

### 1. Screen: Family Groups List
```dart
// lib/features/user/family/screen_family_groups.dart
- Hiển thị danh sách nhóm của user
- Button "Tạo nhóm mới"
- Badge số lượng thành viên
- Role badge (Admin/Member)
```

### 2. Screen: Group Detail
```dart
// lib/features/user/family/screen_group_detail.dart
- Thông tin nhóm
- Danh sách thành viên
- Button "Mời thành viên" (admin only)
- Button "Rời nhóm"
- Button "Xóa nhóm" (admin only)
```

### 3. Screen: Create Group
```dart
// lib/features/user/family/screen_create_group.dart
- Input tên nhóm
- Input mô tả
- Button "Tạo nhóm"
```

### 4. Screen: Invite Members
```dart
// lib/features/user/family/screen_invite_members.dart
- Search user
- Danh sách user tìm được
- Button "Gửi lời mời"
```

### 5. Screen: Group Invitations
```dart
// lib/features/user/family/screen_group_invitations.dart
- Danh sách lời mời đang chờ
- Button "Chấp nhận"
- Button "Từ chối"
```

---

## 🔥 FIREBASE RULES

```json
{
  "rules": {
    "family_groups": {
      "$groupId": {
        ".read": "auth != null",
        ".write": "auth != null"
      }
    },
    "family_group_members": {
      "$groupId": {
        ".read": "auth != null",
        "$userId": {
          ".write": "auth != null"
        }
      }
    },
    "user_family_groups": {
      "$userId": {
        ".read": "$userId === auth.uid",
        ".write": "$userId === auth.uid"
      }
    },
    "family_group_invitations": {
      ".read": "auth != null",
      ".write": "auth != null",
      ".indexOn": ["toUserId", "groupId", "status"]
    }
  }
}
```

---

## 🔄 MIGRATION: 1:1 → 1:N

### Bước 1: Giữ nguyên Family Service cũ
- Không xóa FamilyService
- Vẫn support 1:1 relationships
- User có thể dùng cả 2 cách

### Bước 2: Thêm FamilyGroupService mới
- ✅ Đã tạo FamilyGroupService
- ✅ Hỗ trợ 1:N relationships
- ✅ Real-time streams

### Bước 3: UI cho phép chọn
```dart
// Trong màn hình Family Management
- Tab "Kết nối 1:1" (FamilyService)
- Tab "Nhóm gia đình" (FamilyGroupService)
```

### Bước 4: Migrate data (optional)
```dart
// Script để convert 1:1 → Group
Future<void> migrateToGroups(String userId) async {
  // 1. Get all 1:1 connections
  final connections = await FamilyService().getFamilyMembers(userId);
  
  // 2. Create a group
  final groupId = await FamilyGroupService().createFamilyGroup(
    creatorId: userId,
    creatorName: userName,
    groupName: 'Gia đình của tôi',
  );
  
  // 3. Add all connections to group
  for (var member in connections) {
    await FamilyGroupService().addMemberToGroup(
      groupId: groupId!,
      userId: member['memberId'],
      userName: member['memberName'],
      role: 'member',
      addedBy: userId,
    );
  }
}
```

---

## 📊 SO SÁNH: 1:1 vs 1:N

| Feature | 1:1 (FamilyService) | 1:N (FamilyGroupService) |
|---------|---------------------|--------------------------|
| Kết nối | Từng cặp | Nhóm |
| Thành viên thấy nhau | ❌ | ✅ |
| Quản lý | Phân tán | Tập trung |
| Admin role | ❌ | ✅ |
| Mời nhiều người | Phải gửi từng người | Gửi vào nhóm |
| Xóa thành viên | Xóa từng kết nối | Xóa khỏi nhóm |
| Notifications | Cho 2 người | Cho cả nhóm |
| Real-time | ✅ | ✅ |
| Use case | Kết nối đơn giản | Gia đình lớn |

---

## 🎯 USE CASES

### Use Case 1: Gia đình 5 người
```
Trước (1:1):
- User A kết nối với B, C, D, E (4 kết nối)
- B, C, D, E chỉ thấy A
- B, C, D, E không thấy nhau

Sau (1:N):
- Tạo nhóm "Gia đình"
- Thêm A, B, C, D, E vào nhóm
- Tất cả 5 người đều thấy nhau
```

### Use Case 2: Nhiều nhóm
```
User A có thể tham gia nhiều nhóm:
- Nhóm "Gia đình" (admin)
- Nhóm "Họ hàng" (member)
- Nhóm "Bạn bè thân" (member)
```

### Use Case 3: Chia sẻ thông tin sức khỏe
```
Trong nhóm gia đình:
- User A có vấn đề sức khỏe
- Tất cả thành viên nhóm nhận notification
- Tất cả có thể xem thông tin (nếu được chia sẻ)
```

---

## 🧪 TESTING CHECKLIST

### Group Management:
- [ ] Tạo nhóm mới
- [ ] Đổi tên nhóm
- [ ] Xóa nhóm
- [ ] Rời khỏi nhóm

### Member Management:
- [ ] Gửi lời mời
- [ ] Chấp nhận lời mời
- [ ] Từ chối lời mời
- [ ] Thêm thành viên trực tiếp
- [ ] Xóa thành viên
- [ ] Transfer admin

### Real-time:
- [ ] Stream groups updates
- [ ] Stream members updates
- [ ] Notifications real-time

### Edge Cases:
- [ ] Admin rời nhóm (transfer admin)
- [ ] Last member rời nhóm (delete group)
- [ ] Invite user đã trong nhóm
- [ ] Remove yourself (should use leaveGroup)

---

## 🚀 DEPLOYMENT

### 1. Update Firebase Rules:
```bash
# Copy rules từ section Firebase Rules
# Paste vào Firebase Console
# Click Publish
```

### 2. Test:
```bash
flutter run
# Test tất cả flows
```

### 3. Monitor:
```bash
# Check Firebase Console
# Monitor notifications
# Check member counts
```

---

## 💡 BEST PRACTICES

### 1. Always check permissions:
```dart
// Before admin actions
if (userRole != 'admin') {
  return error('Only admin can perform this action');
}
```

### 2. Use transactions for critical operations:
```dart
// When updating member count
await _database.runTransaction((transaction) async {
  // Atomic update
});
```

### 3. Notify all affected users:
```dart
// When member joins/leaves
await _notifyGroupMembers(...);
```

### 4. Clean up on delete:
```dart
// Delete from all related tables
- family_group_members
- user_family_groups
- family_groups
```

---

## ✅ CONCLUSION

**Đã hoàn thành:**
- ✅ FamilyGroupService với đầy đủ tính năng
- ✅ 1:N relationships
- ✅ Admin roles
- ✅ Real-time streams
- ✅ Notifications
- ✅ Database structure

**Lợi ích:**
- 👨‍👩‍👧‍👦 Tất cả thành viên thấy nhau
- 🎯 Quản lý tập trung
- 🔔 Notifications cho cả nhóm
- 🚀 Dễ dàng mở rộng

**Next Steps:**
1. Tạo UI screens
2. Test thoroughly
3. Deploy to production

---

*Document được tạo bởi Kiro AI - 16/11/2025*
