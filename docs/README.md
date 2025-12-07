# 📚 TÀI LIỆU DỰ ÁN SEWS

## Stroke Early Warning System - Hệ thống Cảnh báo Sớm Đột quỵ

---

## 📋 Mục lục

1. [Tổng quan dự án](#1-tổng-quan-dự-án)
2. [Kiến trúc hệ thống](#2-kiến-trúc-hệ-thống)
3. [Cấu trúc thư mục](#3-cấu-trúc-thư-mục)
4. [Tính năng chi tiết](#4-tính-năng-chi-tiết)
5. [Công nghệ sử dụng](#5-công-nghệ-sử-dụng)
6. [Hướng dẫn cài đặt](#6-hướng-dẫn-cài-đặt)
7. [API Backend](#7-api-backend)
8. [Database Schema](#8-database-schema)
9. [Hướng dẫn sử dụng](#9-hướng-dẫn-sử-dụng)

---

## 1. Tổng quan dự án

### 1.1 Giới thiệu
**SEWS (Stroke Early Warning System)** là ứng dụng di động hỗ trợ cảnh báo sớm nguy cơ đột quỵ và tiểu đường, kết nối người dùng với bác sĩ và gia đình để theo dõi sức khỏe toàn diện.

### 1.2 Mục tiêu
- Dự đoán nguy cơ đột quỵ và tiểu đường dựa trên AI/ML
- Theo dõi và quản lý sức khỏe cá nhân
- Kết nối bệnh nhân - bác sĩ - gia đình
- Hỗ trợ khẩn cấp SOS
- Nhắc nhở uống thuốc và lịch khám

### 1.3 Đối tượng sử dụng
| Vai trò | Mô tả |
|---------|-------|
| **User (Người dùng)** | Bệnh nhân, người theo dõi sức khỏe |
| **Doctor (Bác sĩ)** | Bác sĩ tư vấn, theo dõi bệnh nhân |
| **Admin (Quản trị)** | Quản lý hệ thống, người dùng, nội dung |

### 1.4 Thông tin phiên bản
- **Phiên bản**: 1.0.0
- **Platform**: Android (API 23+), Web
- **Framework**: Flutter 3.5.4+
- **Backend**: Firebase + Flask API

---

## 2. Kiến trúc hệ thống

### 2.1 Sơ đồ kiến trúc

```
┌─────────────────────────────────────────────────────────────┐
│                    SEWS Application                          │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   User App  │  │ Doctor App  │  │  Admin App  │         │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘         │
│         │                │                │                 │
│         └────────────────┼────────────────┘                 │
│                          │                                  │
│  ┌───────────────────────┴───────────────────────┐         │
│  │              Flutter Framework                 │         │
│  │  • Provider State Management                   │         │
│  │  • Material Design 3                           │         │
│  │  • Offline Cache (Hive)                        │         │
│  └───────────────────────┬───────────────────────┘         │
└──────────────────────────┼──────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│   Firebase    │  │   Flask API   │  │   External    │
│  • Auth       │  │  • AI Model   │  │  • FCM        │
│  • Realtime   │  │  • Prediction │  │  • Geocoding  │
│  • Storage    │  │               │  │               │
└───────────────┘  └───────────────┘  └───────────────┘
```

### 2.2 Luồng dữ liệu

```
User Input → Validation → Service Layer → Firebase/API → Response → UI Update
                              ↓
                        Offline Cache (Hive)
```

---

## 3. Cấu trúc thư mục

```
early_warning_software_for_stroke/
├── 📁 android/                    # Android native code
│   ├── app/
│   │   ├── src/main/
│   │   │   └── AndroidManifest.xml
│   │   ├── build.gradle
│   │   └── google-services.json   # Firebase config
│   └── build.gradle
│
├── 📁 assets/                     # Static assets
│   ├── data/
│   │   ├── app_data.json          # App configuration
│   │   └── doctor_data.json       # Doctor list data
│   ├── img/
│   │   ├── SEWS_2D.png            # App logo
│   │   └── giao diện */           # UI screenshots
│   └── models/
│       ├── app.py                 # Flask API server
│       ├── moHinhDotQuy_final.pkl # AI model
│       ├── preprocessor.pkl       # Data preprocessor
│       └── requirements.txt       # Python dependencies
│
├── 📁 lib/                        # Flutter source code
│   ├── data/
│   │   ├── models/                # Data models
│   │   └── providers/             # State providers
│   ├── features/
│   │   ├── admin/                 # Admin features (20 files)
│   │   ├── doctor/                # Doctor features (17 files)
│   │   └── user/                  # User features (54 files)
│   ├── services/                  # Business logic (34 services)
│   ├── utils/                     # Utilities
│   ├── widgets/                   # Shared widgets
│   ├── main.dart                  # App entry point
│   └── firebase_options.dart      # Firebase config
│
├── 📁 test/                       # Test files
│   ├── backend/                   # Integration tests
│   └── services/                  # Unit tests
│
├── 📁 web/                        # Web platform
│
├── 📁 docs/                       # Documentation
│
├── 📁 release/                    # Release APK
│   ├── SEWS_v1.0.0.apk
│   └── HUONG_DAN_CAI_DAT.md
│
├── pubspec.yaml                   # Flutter dependencies
├── firebase.json                  # Firebase config
└── start.sh                       # Dev startup script
```

---

## 4. Tính năng chi tiết

### 4.1 Tính năng Người dùng (User)

#### 🔐 Xác thực
| Tính năng | Mô tả |
|-----------|-------|
| Đăng ký | Email/Password, xác thực email |
| Đăng nhập | Email/Password, Google Sign-In |
| Quên mật khẩu | Reset qua email |
| Onboarding | Hướng dẫn sử dụng lần đầu |

#### 📊 Dashboard
- Tổng quan sức khỏe
- Biểu đồ theo dõi (huyết áp, đường huyết, BMI)
- Lịch hẹn sắp tới
- Nhắc nhở uống thuốc
- Truy cập nhanh các tính năng

#### 🧠 Dự đoán sức khỏe
| Tính năng | Mô tả |
|-----------|-------|
| Dự đoán đột quỵ | AI model với 12 chỉ số đầu vào |
| Dự đoán tiểu đường | Rule-based + AI hybrid |
| Lịch sử dự đoán | Xem lại các lần dự đoán |
| Khuyến nghị | Gợi ý cải thiện sức khỏe |

#### 👨‍👩‍👧‍👦 Quản lý gia đình
- Tạo nhóm gia đình
- Mời thành viên
- Theo dõi sức khỏe người thân
- Nhận thông báo SOS từ người thân

#### 📅 Lịch hẹn
- Đặt lịch khám với bác sĩ
- Xem lịch làm việc bác sĩ
- Nhận nhắc nhở lịch hẹn
- Đánh giá bác sĩ sau khám

#### 💬 Chat
- Nhắn tin với bác sĩ
- Gửi hình ảnh
- Real-time messaging

#### 🆘 SOS Khẩn cấp
- Gửi yêu cầu SOS
- Tự động gửi vị trí GPS
- Thông báo đến bác sĩ trực
- Thông báo đến gia đình

#### 💊 Nhắc nhở thuốc
- Tạo lịch uống thuốc
- Thông báo đúng giờ
- Theo dõi tuân thủ

#### 📚 Kiến thức & Cộng đồng
- Bài viết sức khỏe
- Diễn đàn thảo luận
- Chia sẻ kinh nghiệm

---

### 4.2 Tính năng Bác sĩ (Doctor)

#### 📋 Dashboard
- Thống kê ca trực
- Danh sách bệnh nhân
- SOS chờ xử lý
- Lịch hẹn hôm nay

#### 👥 Quản lý bệnh nhân
- Danh sách bệnh nhân
- Hồ sơ chi tiết
- Lịch sử sức khỏe
- Kê đơn thuốc

#### 📅 Quản lý lịch hẹn
- Xem/Duyệt yêu cầu hẹn
- Quản lý lịch làm việc
- Cài đặt slot khám

#### 🆘 Xử lý SOS
- Hàng đợi SOS
- Chi tiết ca khẩn cấp
- Cập nhật trạng thái

#### 💬 Giao tiếp
- Chat với bệnh nhân
- Gửi thông báo
- Tư vấn online

---

### 4.3 Tính năng Quản trị (Admin)

| Module | Chức năng |
|--------|-----------|
| Dashboard | Thống kê tổng quan hệ thống |
| Users | Quản lý tài khoản người dùng |
| Doctors | Quản lý bác sĩ, xác thực |
| Patients | Quản lý hồ sơ bệnh nhân |
| SOS | Giám sát ca khẩn cấp |
| Predictions | Thống kê dự đoán |
| Appointments | Quản lý lịch hẹn |
| Knowledge | Quản lý bài viết |
| Community | Quản lý diễn đàn |

---

## 5. Công nghệ sử dụng

### 5.1 Frontend (Flutter)

| Package | Version | Mục đích |
|---------|---------|----------|
| flutter | 3.5.4+ | Framework chính |
| provider | 6.1.1 | State management |
| firebase_core | 4.2.1 | Firebase SDK |
| firebase_auth | 6.1.2 | Authentication |
| firebase_database | 12.0.4 | Realtime Database |
| cloud_firestore | 6.1.0 | Firestore |
| firebase_messaging | 16.0.4 | Push notifications |
| firebase_storage | 13.0.4 | File storage |
| google_sign_in | 6.2.2 | Google OAuth |
| fl_chart | 0.69.0 | Charts/Graphs |
| hive | 2.2.3 | Offline cache |
| connectivity_plus | 6.0.5 | Network monitoring |
| geolocator | 10.1.0 | GPS location |
| flutter_local_notifications | 17.0.0 | Local notifications |
| cached_network_image | 3.3.1 | Image caching |

### 5.2 Backend

| Technology | Mục đích |
|------------|----------|
| Firebase Realtime Database | Primary database |
| Firebase Authentication | User auth |
| Firebase Cloud Messaging | Push notifications |
| Firebase Storage | File storage |
| Flask (Python) | AI prediction API |
| scikit-learn | ML model |

### 5.3 AI/ML Model

- **Model**: Random Forest Classifier
- **Input features**: 12 health indicators
- **Output**: Stroke risk probability (0-100%)
- **File**: `moHinhDotQuy_final.pkl`

---

## 6. Hướng dẫn cài đặt

### 6.1 Yêu cầu hệ thống

**Development:**
- Flutter SDK >= 3.5.4
- Dart SDK >= 3.5.4
- Android Studio / VS Code
- Python 3.8+ (cho Flask API)

**Runtime:**
- Android 6.0+ (API 23)
- Kết nối Internet

### 6.2 Cài đặt Development

```bash
# 1. Clone repository
git clone https://github.com/quanglong3824/early_warning_software_for_stroke.git
cd early_warning_software_for_stroke

# 2. Install Flutter dependencies
flutter pub get

# 3. Install Python dependencies (cho AI API)
cd assets/models
pip3 install -r requirements.txt
cd ../..

# 4. Run app
./start.sh
# Hoặc chạy riêng:
# flutter run -d chrome (web)
# flutter run (mobile)
```

### 6.3 Build Release

```bash
# Build APK
flutter build apk --release

# Output: build/app/outputs/apk/release/app-release.apk
```

### 6.4 Cài đặt APK

Xem file `release/HUONG_DAN_CAI_DAT.md`

---

## 7. API Backend

### 7.1 Flask API Endpoints

**Base URL**: `http://localhost:5001`

#### Health Check
```http
GET /health
```
Response:
```json
{
  "status": "healthy",
  "model_loaded": true,
  "preprocessor_loaded": true
}
```

#### Predict Stroke Risk
```http
POST /predict
Content-Type: application/json

{
  "age": 50,
  "gender": "male",
  "heightCm": 170,
  "weightKg": 70,
  "systolicBP": 140,
  "diastolicBP": 90,
  "cholesterol": 200,
  "glucose": 100,
  "hypertension": true,
  "heartDisease": false,
  "smoking": false,
  "workType": "moderate"
}
```
Response:
```json
{
  "success": true,
  "riskScore": 45,
  "riskLevel": "medium",
  "riskLevelVi": "Nguy cơ trung bình",
  "strokeProbability": 0.45,
  "bmi": "24.2",
  "bmiCategory": "Bình thường",
  "bpCategory": "Tăng huyết áp độ 1",
  "predictionMethod": "AI"
}
```

---

## 8. Database Schema

### 8.1 Firebase Realtime Database Structure

```
root/
├── users/
│   └── {userId}/
│       ├── email: string
│       ├── fullName: string
│       ├── phone: string
│       ├── dateOfBirth: string
│       ├── gender: string
│       ├── address: string
│       ├── avatarUrl: string
│       ├── role: "user" | "doctor" | "admin"
│       ├── status: "active" | "inactive" | "banned"
│       └── createdAt: timestamp
│
├── doctors/
│   └── {doctorId}/
│       ├── userId: string
│       ├── specialization: string
│       ├── hospital: string
│       ├── experience: number
│       ├── rating: number
│       ├── isVerified: boolean
│       └── schedule: object
│
├── healthRecords/
│   └── {userId}/
│       └── {recordId}/
│           ├── systolicBP: number
│           ├── diastolicBP: number
│           ├── heartRate: number
│           ├── glucose: number
│           ├── weight: number
│           ├── height: number
│           └── recordedAt: timestamp
│
├── predictions/
│   └── {userId}/
│       └── {predictionId}/
│           ├── type: "stroke" | "diabetes"
│           ├── riskScore: number
│           ├── riskLevel: string
│           ├── inputData: object
│           └── createdAt: timestamp
│
├── appointments/
│   └── {appointmentId}/
│       ├── userId: string
│       ├── doctorId: string
│       ├── dateTime: timestamp
│       ├── status: "pending" | "confirmed" | "completed" | "cancelled"
│       ├── notes: string
│       └── createdAt: timestamp
│
├── sosRequests/
│   └── {sosId}/
│       ├── userId: string
│       ├── location: { lat, lng }
│       ├── status: "pending" | "responding" | "resolved"
│       ├── assignedDoctor: string
│       └── createdAt: timestamp
│
├── conversations/
│   └── {conversationId}/
│       ├── participants: array
│       ├── lastMessage: string
│       ├── lastMessageAt: timestamp
│       └── messages/
│           └── {messageId}/
│               ├── senderId: string
│               ├── content: string
│               ├── type: "text" | "image"
│               └── sentAt: timestamp
│
├── familyGroups/
│   └── {groupId}/
│       ├── name: string
│       ├── ownerId: string
│       ├── members: array
│       └── createdAt: timestamp
│
├── reminders/
│   └── {userId}/
│       └── {reminderId}/
│           ├── title: string
│           ├── time: string
│           ├── frequency: string
│           ├── isActive: boolean
│           └── createdAt: timestamp
│
├── articles/
│   └── {articleId}/
│       ├── title: string
│       ├── content: string
│       ├── category: string
│       ├── imageUrl: string
│       ├── authorId: string
│       └── createdAt: timestamp
│
└── forumThreads/
    └── {threadId}/
        ├── title: string
        ├── content: string
        ├── authorId: string
        ├── likes: number
        ├── comments: array
        └── createdAt: timestamp
```

---

## 9. Hướng dẫn sử dụng

### 9.1 Người dùng mới

1. **Đăng ký tài khoản** với email và mật khẩu
2. **Xác thực email** qua link được gửi
3. **Hoàn thành hồ sơ** cá nhân
4. **Nhập chỉ số sức khỏe** ban đầu
5. **Thực hiện dự đoán** nguy cơ đột quỵ

### 9.2 Dự đoán nguy cơ đột quỵ

1. Vào **Prediction Hub** từ Dashboard
2. Chọn **Dự đoán đột quỵ**
3. Nhập các chỉ số:
   - Tuổi, giới tính
   - Chiều cao, cân nặng
   - Huyết áp (tâm thu/tâm trương)
   - Cholesterol, đường huyết
   - Tiền sử bệnh
4. Nhấn **Dự đoán**
5. Xem kết quả và khuyến nghị

### 9.3 Gửi SOS khẩn cấp

1. Nhấn nút **SOS** trên Dashboard
2. Xác nhận gửi yêu cầu
3. Ứng dụng tự động:
   - Gửi vị trí GPS
   - Thông báo bác sĩ trực
   - Thông báo gia đình
4. Theo dõi trạng thái xử lý

### 9.4 Đặt lịch hẹn bác sĩ

1. Vào **Doctors Hub**
2. Chọn bác sĩ phù hợp
3. Xem lịch làm việc
4. Chọn ngày giờ khám
5. Nhập lý do khám
6. Xác nhận đặt lịch
7. Đợi bác sĩ duyệt

---

## 📞 Liên hệ

- **Developer**: Quang Long
- **Email**: quanglong3824@gmail.com
- **GitHub**: https://github.com/quanglong3824/early_warning_software_for_stroke

---

*Tài liệu được cập nhật: Tháng 12/2024*
