# 🚀 ROADMAP: CHUYỂN ĐỔI TỪ TĨNH SANG ĐỘNG

**Mục tiêu:** Chuyển các màn hình giao diện tĩnh sang tính năng động với Firebase  
**Thời gian ước tính:** 8-12 tuần  
**Loại trừ:** AI/ML Prediction (sẽ làm riêng khi có model .pkl)

---

## 📋 NGUYÊN TẮC THỰC HIỆN

1. **Ưu tiên theo giá trị người dùng** - Tính năng nào người dùng cần nhất làm trước
2. **Từ đơn giản đến phức tạp** - CRUD cơ bản → Real-time → Advanced features
3. **Test từng bước** - Mỗi tính năng phải test kỹ trước khi sang tính năng khác
4. **Tái sử dụng code** - Tạo services và widgets chung

---

## 🎯 PHASE 1: CORE FEATURES (Tuần 1-3)

### Week 1: SOS & Emergency System

**Mục tiêu:** Hệ thống SOS hoạt động real-time

#### 1.1. Setup Firebase Structure
```json
sos_requests/{requestId}/
  - userId, patientId, userLocation
  - status: pending/acknowledged/dispatched/resolved
  - createdAt, acknowledgedAt, resolvedAt
  - assignedHospitalId, assignedDoctorId
```

#### 1.2. Implement Features
- [ ] **SOSService** - Tạo/cập nhật/lắng nghe SOS requests
- [ ] **LocationService** - Lấy GPS location (geolocator package)
- [ ] **screen_sos.dart** - Gửi SOS với location thực
- [ ] **screen_sos_status.dart** - Hiển thị trạng thái real-time
- [ ] **FCM Notifications** - Thông báo cho người thân khi SOS

#### 1.3. Dependencies cần thêm
```yaml
geolocator: ^10.1.0
geocoding: ^2.1.1
firebase_messaging: ^14.7.9
```

#### 1.4. Deliverables
- ✅ User bấm SOS → Gửi location + thông báo
- ✅ Người thân nhận notification
- ✅ Màn hình status cập nhật real-time
- ✅ Bác sĩ thấy SOS trong queue

---

### Week 2: Chat System

**Mục tiêu:** Chat real-time giữa user và bác sĩ


#### 2.1. Setup Firebase Structure
```json
chat_sessions/{sessionId}/
  - userId, doctorId, patientId
  - lastMessage, lastMessageAt
  - userUnreadCount, doctorUnreadCount

chat_sessions/{sessionId}/messages/{messageId}/
  - senderId, senderType (user/doctor)
  - text, imageUrl, fileUrl
  - createdAt, isRead
```

#### 2.2. Implement Features
- [ ] **ChatService** - CRUD messages, upload images
- [ ] **screen_chat_list.dart** - Load danh sách từ Firebase
- [ ] **screen_chat_detail.dart** - Gửi/nhận tin nhắn real-time
- [ ] **screen_doctor_chat.dart** - Bác sĩ trả lời
- [ ] **Typing indicator** - Hiển thị "đang gõ..."
- [ ] **Image upload** - Firebase Storage

#### 2.3. Dependencies cần thêm
```yaml
firebase_storage: ^11.5.6
image_picker: ^1.0.5
cached_network_image: ^3.3.0
```

#### 2.4. Deliverables
- ✅ User gửi tin nhắn cho bác sĩ
- ✅ Bác sĩ nhận và trả lời real-time
- ✅ Upload/hiển thị hình ảnh
- ✅ Badge tin nhắn chưa đọc
- ✅ Notification khi có tin nhắn mới

---

### Week 3: Appointments System

**Mục tiêu:** Đặt lịch hẹn và quản lý

#### 3.1. Setup Firebase Structure
```json
appointments/{appointmentId}/
  - userId, patientId, doctorId, hospitalId
  - type: consultation/video_call/in_person
  - status: pending/confirmed/cancelled/completed
  - requestedAt, appointmentTime
  - reason, notes
  - reportUrl (nếu có)
```

#### 3.2. Implement Features
- [ ] **AppointmentService** - CRUD appointments
- [ ] **screen_report_appointment.dart** - Gửi báo cáo + đặt lịch
- [ ] **screen_appointments.dart** - Danh sách lịch hẹn
- [ ] **screen_appointment_management.dart** (Doctor) - Duyệt yêu cầu
- [ ] **Notification** - Nhắc lịch hẹn trước 1 ngày/1 giờ

#### 3.3. Deliverables
- ✅ User đặt lịch hẹn với bác sĩ
- ✅ Bác sĩ duyệt/từ chối
- ✅ Notification nhắc lịch
- ✅ Hiển thị lịch theo ngày/tuần

---

## 🎯 PHASE 2: MANAGEMENT FEATURES (Tuần 4-6)

### Week 4: Patient Management

**Mục tiêu:** Quản lý hồ sơ bệnh nhân đầy đủ

#### 4.1. Setup Firebase Structure
```json
patients/{patientId}/
  - fullName, dateOfBirth, gender, cccd
  - primaryUserId, registeredHospitalId
  - medicalHistory: {hypertension, heartDisease, diabetes...}
  - createdAt, updatedAt

health_records/{patientId}/records/{recordId}/
  - recordedByUserId, recordedAt
  - bloodPressure, heartRate, glucose, bmi
  - notes, symptoms
```

#### 4.2. Implement Features
- [ ] **PatientService** - CRUD patients
- [ ] **HealthRecordService** - CRUD health records
- [ ] **screen_patient_management.dart** - Danh sách + thêm/sửa/xóa
- [ ] **screen_health_history.dart** - Lịch sử + biểu đồ
- [ ] **Charts** - Biểu đồ xu hướng sức khỏe

#### 4.3. Dependencies cần thêm
```yaml
fl_chart: ^0.65.0
```

#### 4.4. Deliverables
- ✅ CRUD hồ sơ bệnh nhân
- ✅ Lưu chỉ số sức khỏe
- ✅ Biểu đồ xu hướng (huyết áp, đường huyết, BMI)
- ✅ Export data (CSV/JSON)

---

### Week 5: Prescriptions & Reminders Enhancement

**Mục tiêu:** Đơn thuốc điện tử và nhắc nhở nâng cao

#### 5.1. Setup Firebase Structure
```json
prescriptions/{prescriptionId}/
  - patientId, doctorId, appointmentId
  - createdAt, validUntil
  - drugs: [{name, dose, quantity, instructions}]
  - notes, diagnosis

prescription_history/{patientId}/history/{historyId}/
  - prescriptionId, takenAt
  - status: taken/missed/skipped
```

#### 5.2. Implement Features
- [ ] **PrescriptionService** - CRUD prescriptions
- [ ] **screen_prescriptions.dart** - Danh sách đơn thuốc
- [ ] **screen_create_prescription.dart** (Doctor) - Tạo đơn thuốc
- [ ] **Link Reminders ↔ Prescriptions** - Tự động tạo reminder từ đơn thuốc
- [ ] **Tracking** - Đánh dấu đã uống thuốc

#### 5.3. Deliverables
- ✅ Bác sĩ kê đơn thuốc điện tử
- ✅ User xem đơn thuốc
- ✅ Tự động tạo reminder từ đơn thuốc
- ✅ Tracking việc uống thuốc
- ✅ Thống kê tuân thủ điều trị

---

### Week 6: Knowledge & Community

**Mục tiêu:** Thư viện kiến thức và diễn đàn tương tác

#### 6.1. Setup Firebase Structure
```json
knowledge_articles/{articleId}/
  - title, content, imageUrl, videoUrl
  - authorId, authorType (doctor/admin)
  - category, tags
  - views, likes
  - publishedAt

forum_threads/{threadId}/
  - title, content, createdByUserId
  - category, tags
  - views, likes, replyCount
  - createdAt, lastReplyAt

forum_threads/{threadId}/replies/{replyId}/
  - content, createdByUserId
  - likes, createdAt
```

#### 6.2. Implement Features
- [ ] **KnowledgeService** - CRUD articles
- [ ] **ForumService** - CRUD threads & replies
- [ ] **screen_knowledge.dart** - Load từ Firebase, search, filter
- [ ] **screen_article_detail.dart** - Hiển thị + like + share
- [ ] **screen_forum.dart** - Danh sách threads
- [ ] **screen_topic_detail.dart** - Đọc + comment
- [ ] **Rich text editor** - Cho việc viết bài

#### 6.3. Dependencies cần thêm
```yaml
flutter_quill: ^9.0.0  # Rich text editor
share_plus: ^7.2.1     # Share articles
```

#### 6.4. Deliverables
- ✅ Đọc bài viết từ Firebase
- ✅ Like, share, comment
- ✅ Đăng thread mới trong forum
- ✅ Reply và like
- ✅ Search và filter

---

## 🎯 PHASE 3: ADVANCED FEATURES (Tuần 7-9)

### Week 7: Pharmacy E-commerce

**Mục tiêu:** Mua thuốc online

#### 7.1. Setup Firebase Structure
```json
pharmacies/{pharmacyId}/
  - name, address, location, phone
  - rating, reviewCount
  - isActive

drugs/{drugId}/
  - name, description, price, unit
  - category, requiresPrescription
  - imageUrl, stock

orders/{orderId}/
  - userId, pharmacyId, prescriptionId
  - items: [{drugId, quantity, price}]
  - totalPrice, shippingAddress
  - status: pending/confirmed/shipped/delivered
  - createdAt, deliveredAt
```

#### 7.2. Implement Features
- [ ] **PharmacyService** - CRUD pharmacies & drugs
- [ ] **OrderService** - CRUD orders
- [ ] **screen_pharmacy.dart** - Search, filter, add to cart
- [ ] **screen_checkout.dart** - Giỏ hàng + thanh toán
- [ ] **Cart management** - Local storage + sync Firebase
- [ ] **Order tracking** - Theo dõi đơn hàng

#### 7.3. Deliverables
- ✅ Tìm kiếm thuốc
- ✅ Thêm vào giỏ hàng
- ✅ Đặt hàng (COD)
- ✅ Tracking đơn hàng
- ✅ Lịch sử đơn hàng

---

### Week 8: Doctor Features Backend

**Mục tiêu:** Hoàn thiện tính năng cho bác sĩ

#### 8.1. Implement Features
- [ ] **DoctorDataProvider** - Quản lý data bác sĩ
- [ ] **screen_doctor_dashboard.dart** - Load stats real-time
- [ ] **screen_patient_list.dart** - Danh sách bệnh nhân được gán
- [ ] **screen_patient_profile.dart** - Xem hồ sơ chi tiết
- [ ] **screen_sos_queue.dart** - Hàng đợi SOS real-time
- [ ] **screen_doctor_reviews.dart** - Load đánh giá từ Firebase

#### 8.2. Setup Firebase Structure
```json
doctors/{doctorId}/
  - fullName, email, phone, specialty
  - hospitalId, experience, rating
  - schedule: {monday: [...], tuesday: [...]}
  - isOnDuty, currentShift

doctor_stats/{doctorId}/
  - today: {appointments, consultations, prescriptions}
  - thisWeek: {...}
  - thisMonth: {...}
```

#### 8.3. Deliverables
- ✅ Dashboard bác sĩ với stats real-time
- ✅ Quản lý bệnh nhân
- ✅ Xử lý SOS
- ✅ Xem đánh giá

---

### Week 9: Reviews & Ratings

**Mục tiêu:** Đánh giá bác sĩ và dịch vụ

#### 9.1. Setup Firebase Structure
```json
reviews/{reviewId}/
  - doctorId, userId, appointmentId
  - rating (1-5), comment
  - createdAt

doctor_ratings/{doctorId}/
  - averageRating, totalReviews
  - ratingDistribution: {5: 50, 4: 30, 3: 15, 2: 3, 1: 2}
```

#### 9.2. Implement Features
- [ ] **ReviewService** - CRUD reviews
- [ ] **screen_rate_doctor.dart** - Đánh giá sau appointment
- [ ] **screen_doctor_reviews.dart** - Hiển thị đánh giá
- [ ] **Auto-calculate** - Tính rating trung bình

#### 9.3. Deliverables
- ✅ Đánh giá bác sĩ sau khám
- ✅ Hiển thị rating trên profile bác sĩ
- ✅ Filter bác sĩ theo rating

---

## 🎯 PHASE 4: POLISH & OPTIMIZATION (Tuần 10-12)

### Week 10: Notifications & Real-time Updates

**Mục tiêu:** Hoàn thiện hệ thống thông báo

#### 10.1. Implement Features
- [ ] **FCM Setup** - Push notifications
- [ ] **Notification types:**
  - SOS alerts
  - New messages
  - Appointment reminders
  - Prescription reminders
  - Family requests
  - Doctor replies
- [ ] **In-app notifications** - Badge + list
- [ ] **Notification settings** - Bật/tắt từng loại

#### 10.2. Deliverables
- ✅ Push notifications cho tất cả events
- ✅ Badge hiển thị số lượng
- ✅ Notification center
- ✅ Settings để quản lý

---

### Week 11: Performance & Offline Mode

**Mục tiêu:** Tối ưu hiệu suất

#### 11.1. Implement Features
- [ ] **Caching** - Cache images, data
- [ ] **Pagination** - Load data theo trang
- [ ] **Lazy loading** - Load khi cần
- [ ] **Offline mode** - Lưu data local, sync khi online
- [ ] **Error handling** - Retry logic, fallback UI

#### 11.2. Dependencies cần thêm
```yaml
connectivity_plus: ^5.0.2
hive: ^2.2.3  # Local database
```

#### 11.3. Deliverables
- ✅ App hoạt động mượt mà
- ✅ Offline mode cơ bản
- ✅ Error handling tốt

---

### Week 12: Testing & Bug Fixes

**Mục tiêu:** Đảm bảo chất lượng

#### 12.1. Testing
- [ ] **Unit tests** - Services
- [ ] **Widget tests** - Screens
- [ ] **Integration tests** - User flows
- [ ] **Manual testing** - Tất cả tính năng

#### 12.2. Bug Fixes
- [ ] Fix bugs phát hiện trong testing
- [ ] Optimize performance
- [ ] Polish UI/UX

#### 12.3. Deliverables
- ✅ Test coverage > 70%
- ✅ Không có critical bugs
- ✅ App sẵn sàng deploy

---

## 📦 DEPENDENCIES TỔNG HỢP

```yaml
# Đã có
firebase_core: ^4.2.1
firebase_database: ^12.0.4
firebase_auth: ^6.1.2
google_sign_in: ^6.2.2
provider: ^6.1.1
shared_preferences: ^2.2.2
crypto: ^3.0.3
url_launcher: ^6.2.2
flutter_local_notifications: ^17.0.0
permission_handler: ^11.0.1
timezone: ^0.9.2
intl: ^0.18.1

# Cần thêm
geolocator: ^10.1.0                    # GPS location
geocoding: ^2.1.1                      # Address from GPS
firebase_messaging: ^14.7.9            # Push notifications
firebase_storage: ^11.5.6              # Upload files
image_picker: ^1.0.5                   # Pick images
cached_network_image: ^3.3.0           # Cache images
fl_chart: ^0.65.0                      # Charts
flutter_quill: ^9.0.0                  # Rich text editor
share_plus: ^7.2.1                     # Share content
connectivity_plus: ^5.0.2              # Check internet
hive: ^2.2.3                           # Local database
hive_flutter: ^1.1.0
```

---

## 🔥 FIREBASE RULES CẬP NHẬT

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "auth != null",
        ".write": "$uid === auth.uid"
      }
    },
    "patients": {
      "$patientId": {
        ".read": "auth != null",
        ".write": "auth != null"
      }
    },
    "health_records": {
      "$patientId": {
        ".read": "auth != null",
        ".write": "auth != null"
      }
    },
    "sos_requests": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "chat_sessions": {
      "$sessionId": {
        ".read": "auth != null",
        ".write": "auth != null"
      }
    },
    "appointments": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "prescriptions": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "knowledge_articles": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "forum_threads": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "pharmacies": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "orders": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "doctors": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "reviews": {
      ".read": "auth != null",
      ".write": "auth != null"
    }
  }
}
```

---

## 📊 TIẾN ĐỘ TRACKING

### Phase 1 (Tuần 1-3): Core Features
- [ ] Week 1: SOS & Emergency
- [ ] Week 2: Chat System
- [ ] Week 3: Appointments

### Phase 2 (Tuần 4-6): Management
- [ ] Week 4: Patient Management
- [ ] Week 5: Prescriptions
- [ ] Week 6: Knowledge & Community

### Phase 3 (Tuần 7-9): Advanced
- [ ] Week 7: Pharmacy
- [ ] Week 8: Doctor Features
- [ ] Week 9: Reviews

### Phase 4 (Tuần 10-12): Polish
- [ ] Week 10: Notifications
- [ ] Week 11: Performance
- [ ] Week 12: Testing

---

## 🎯 SUCCESS METRICS

### Technical Metrics:
- ✅ 100% màn hình kết nối Firebase
- ✅ Real-time sync < 1s
- ✅ App load time < 3s
- ✅ Test coverage > 70%
- ✅ Crash rate < 1%

### User Metrics:
- ✅ User có thể đặt lịch hẹn thành công
- ✅ Chat response time < 5s
- ✅ SOS notification < 10s
- ✅ Đơn thuốc được tạo và gửi thành công

---

## 💡 TIPS & BEST PRACTICES

### 1. Code Organization
```
lib/
├── services/          # Business logic
├── models/            # Data models
├── providers/         # State management
├── features/          # UI screens
├── widgets/           # Reusable widgets
└── utils/             # Helpers
```

### 2. Service Pattern
```dart
class ExampleService {
  final _db = FirebaseDatabase.instance;
  
  // CRUD operations
  Future<void> create() async {}
  Future<Map> read() async {}
  Future<void> update() async {}
  Future<void> delete() async {}
  
  // Real-time listeners
  Stream<List> listen() {}
}
```

### 3. Error Handling
```dart
try {
  await service.doSomething();
} on FirebaseException catch (e) {
  // Handle Firebase errors
} catch (e) {
  // Handle other errors
}
```

### 4. Loading States
```dart
bool _isLoading = false;

if (_isLoading) {
  return CircularProgressIndicator();
}
```

---

## 🚀 GETTING STARTED

### Bước 1: Setup Environment
```bash
flutter pub get
```

### Bước 2: Firebase Setup
1. Cập nhật Firebase Rules
2. Enable Firebase Storage
3. Enable Firebase Cloud Messaging

### Bước 3: Start với Week 1
1. Tạo SOSService
2. Implement screen_sos.dart
3. Test SOS flow
4. Deploy và test trên device thật

---

## 📝 NOTES

- **Không làm AI/ML** - Để riêng khi có model .pkl
- **Focus vào UX** - Mỗi tính năng phải smooth và intuitive
- **Test thường xuyên** - Đừng để bug tích lũy
- **Document code** - Để dễ maintain sau này
- **Git commits** - Commit nhỏ, thường xuyên

---

*Roadmap được tạo bởi Kiro AI - 16/11/2025*
