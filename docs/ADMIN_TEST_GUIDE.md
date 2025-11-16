# 🧪 Admin Test Panel - Hướng dẫn

## 🔐 **Đăng nhập Test**

```
Username: test
Password: 123456
Route: /admin/test
```

---

## 📱 **Admin Test Panel**

### **Tính năng:**

#### **1. Test Connection**
- Kiểm tra kết nối Firebase
- Test read/write operations
- Hiển thị kết quả real-time

#### **2. Insert User Data**
- Load dữ liệu từ `assets/data/app_data.json`
- Insert vào Firebase collections:
  - `user_patients`
  - `user_alerts`
  - `user_forumPosts`
  - `user_knowledgeArticles`
  - `user_predictionResults`
  - `user_dashboardStats`
  - `user_currentUser`

#### **3. Insert Doctor Data**
- Load dữ liệu từ `assets/data/doctor_data.json`
- Insert vào Firebase collections:
  - `doctor_currentDoctor`
  - `doctor_doctorSchedule`
  - `doctor_doctorStats`
  - `doctor_todayAppointments`
  - `doctor_appointmentRequests`
  - `doctor_activeSOS`
  - `doctor_recentPrescriptions`
  - `doctor_doctorReviews`
  - `doctor_notifications`

#### **4. Read All Data**
- Đọc tất cả collections
- Hiển thị số lượng documents
- Verify data integrity

#### **5. Clear All Data**
- ⚠️ **Cẩn thận!** Xóa toàn bộ dữ liệu
- Yêu cầu xác nhận
- Không thể hoàn tác

---

## 🗂️ **Backend Service**

### **File:** `test/backend/firebase_service.dart`

### **Singleton Pattern:**
```dart
final service = FirebaseService();
```

### **Methods:**

#### **User Operations:**
```dart
// Get all patients
List<Map<String, dynamic>> patients = await service.getPatients();

// Get patient by ID
Map<String, dynamic>? patient = await service.getPatientById('patient_001');

// Add patient
bool success = await service.addPatient(patientData);

// Update patient
bool success = await service.updatePatient('patient_001', updates);
```

#### **Alert Operations:**
```dart
// Get all alerts
List<Map<String, dynamic>> alerts = await service.getAlerts();

// Get unread alerts
List<Map<String, dynamic>> unread = await service.getAlerts(isRead: false);

// Mark as read
bool success = await service.markAlertAsRead('alert_001');
```

#### **Forum Operations:**
```dart
// Get forum posts
List<Map<String, dynamic>> posts = await service.getForumPosts();

// Get limited posts
List<Map<String, dynamic>> posts = await service.getForumPosts(limit: 10);

// Add post
bool success = await service.addForumPost(postData);
```

#### **Knowledge Operations:**
```dart
// Get articles
List<Map<String, dynamic>> articles = await service.getKnowledgeArticles();

// Get by category
List<Map<String, dynamic>> articles = await service.getKnowledgeArticles(
  category: 'Sức khỏe Tim mạch',
);

// Get limited
List<Map<String, dynamic>> articles = await service.getKnowledgeArticles(
  limit: 10,
);
```

#### **Doctor Operations:**
```dart
// Get appointments
List<Map<String, dynamic>> appointments = 
  await service.getDoctorAppointments('doctor_001');

// Get active SOS
List<Map<String, dynamic>> sosCalls = await service.getActiveSOS();

// Update SOS status
bool success = await service.updateSOSStatus('sos_001', 'resolved');

// Add prescription
bool success = await service.addPrescription(prescriptionData);

// Get patient prescriptions
List<Map<String, dynamic>> prescriptions = 
  await service.getPatientPrescriptions('patient_001');

// Get reviews
List<Map<String, dynamic>> reviews = 
  await service.getDoctorReviews('doctor_001');
```

#### **Utility Operations:**
```dart
// Test connection
bool connected = await service.testConnection();

// Batch insert
bool success = await service.batchInsert('collection_name', dataList);

// Clear collection
bool success = await service.clearCollection('collection_name');

// Get count
int count = await service.getCollectionCount('collection_name');

// Real-time listener
Stream<List<Map<String, dynamic>>> stream = 
  service.listenToCollection('collection_name');
```

---

## 🧪 **Unit Tests**

### **File:** `test/backend/firebase_service_test.dart`

### **Run tests:**
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/backend/firebase_service_test.dart

# Run with coverage
flutter test --coverage
```

### **Test Groups:**
1. ✅ Patient Operations (4 tests)
2. ✅ Alert Operations (3 tests)
3. ✅ Forum Operations (3 tests)
4. ✅ Knowledge Operations (3 tests)
5. ✅ Doctor Operations (6 tests)
6. ✅ Utility Operations (5 tests)

**Total:** 24 unit tests

---

## 📊 **Firebase Collections**

### **User Collections:**
| Collection | Description | Documents |
|------------|-------------|-----------|
| `user_patients` | Bệnh nhân | 6 |
| `user_alerts` | Cảnh báo | 3 |
| `user_forumPosts` | Bài viết diễn đàn | 5 |
| `user_knowledgeArticles` | Bài viết kiến thức | 10 |
| `user_predictionResults` | Kết quả dự đoán | 5 |
| `user_dashboardStats` | Thống kê | 1 |
| `user_currentUser` | User hiện tại | 1 |

### **Doctor Collections:**
| Collection | Description | Documents |
|------------|-------------|-----------|
| `doctor_currentDoctor` | Bác sĩ hiện tại | 1 |
| `doctor_doctorSchedule` | Lịch trực | 1 |
| `doctor_doctorStats` | Thống kê | 1 |
| `doctor_todayAppointments` | Lịch hẹn hôm nay | 3 |
| `doctor_appointmentRequests` | Yêu cầu lịch hẹn | 2 |
| `doctor_activeSOS` | SOS đang hoạt động | 2 |
| `doctor_recentPrescriptions` | Đơn thuốc gần đây | 1 |
| `doctor_doctorReviews` | Đánh giá | 3 |
| `doctor_notifications` | Thông báo | 3 |

---

## 🔄 **Workflow**

### **1. Setup Firebase**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Init project
firebase init firestore
```

### **2. Test Connection**
1. Login với `test/123456`
2. Click "Test Connection"
3. Verify success message

### **3. Insert Data**
1. Click "Insert User Data"
2. Wait for completion
3. Click "Insert Doctor Data"
4. Wait for completion
5. Click "Read All Data" to verify

### **4. Verify in Firebase Console**
1. Go to Firebase Console
2. Navigate to Firestore Database
3. Check collections and documents

---

## 🎯 **Use Cases**

### **Development:**
```dart
// In your screen
final service = FirebaseService();

// Get patients
final patients = await service.getPatients();
setState(() {
  _patients = patients;
});

// Listen to real-time updates
service.listenToCollection('user_patients').listen((patients) {
  setState(() {
    _patients = patients;
  });
});
```

### **Testing:**
```dart
// In test file
test('Get patients should return list', () async {
  final service = FirebaseService();
  final patients = await service.getPatients();
  expect(patients, isA<List<Map<String, dynamic>>>());
});
```

---

## 📝 **Logs**

### **Activity Logs Panel:**
- Real-time logs
- Timestamp for each action
- Color-coded messages
- Max 50 logs (auto-cleanup)

### **Log Format:**
```
[HH:MM:SS] Message
```

### **Example:**
```
[14:23:45] Testing Firebase connection...
[14:23:46] ✓ Write test successful
[14:23:46] ✓ Read test successful
[14:23:46] Data: {timestamp: ..., message: ...}
```

---

## ⚠️ **Important Notes**

### **Security:**
- ⚠️ Admin panel chỉ dùng cho testing
- ⚠️ Không deploy lên production với hardcoded credentials
- ⚠️ Implement proper authentication trước khi production

### **Data:**
- ⚠️ Clear All Data không thể hoàn tác
- ⚠️ Luôn backup data trước khi clear
- ⚠️ Test trên Firebase project riêng

### **Performance:**
- ⚠️ Batch operations tốt hơn individual writes
- ⚠️ Use pagination cho large datasets
- ⚠️ Implement caching khi cần

---

## ✅ **Checklist**

- [x] Admin Test Panel screen
- [x] FirebaseService backend
- [x] Unit tests (24 tests)
- [x] Login integration (test/123456)
- [x] Routes configuration
- [x] Documentation
- [ ] Firebase project setup
- [ ] Security rules
- [ ] Production deployment

---

## 🚀 **Quick Start**

```bash
# 1. Run app
flutter run

# 2. Login
Username: test
Password: 123456

# 3. Test Connection
Click "Test Connection"

# 4. Insert Data
Click "Insert User Data"
Click "Insert Doctor Data"

# 5. Verify
Click "Read All Data"

# 6. Run Tests
flutter test test/backend/firebase_service_test.dart
```

---

## 📊 **Summary**

✅ **Admin Test Panel** - Full-featured testing interface
✅ **Firebase Backend** - Separated, reusable service
✅ **Unit Tests** - 24 comprehensive tests
✅ **Role-based Access** - test/123456 login
✅ **Real-time Logs** - Activity monitoring
✅ **Data Operations** - CRUD + batch operations

**Ready for testing! 🎉**
