# Cấu trúc Dữ liệu và State Management

## Tổng quan

Ứng dụng sử dụng **Provider** để quản lý state tập trung và **JSON file** để mô phỏng dữ liệu từ Firebase.

## Cấu trúc thư mục

```
lib/
├── data/
│   ├── models/           # Các model classes
│   │   ├── user_model.dart
│   │   ├── patient_model.dart
│   │   ├── alert_model.dart
│   │   ├── forum_post_model.dart
│   │   ├── knowledge_article_model.dart
│   │   └── prediction_result_model.dart
│   └── providers/        # State management
│       └── app_data_provider.dart
└── features/             # Các màn hình
    ├── dashboard/
    ├── community/
    ├── knowledge/
    └── profile/

assets/
└── data/
    └── app_data.json     # Big JSON data (mô phỏng Firebase)
```

## Models

### 1. UserModel
Đại diện cho thông tin người dùng hiện tại.

**Properties:**
- `id`: String - ID người dùng
- `name`: String - Tên người dùng
- `email`: String - Email
- `phone`: String - Số điện thoại
- `avatarUrl`: String - URL ảnh đại diện
- `role`: String - Vai trò ('patient', 'doctor', 'admin')
- `createdAt`: DateTime - Ngày tạo tài khoản

### 2. PatientModel
Đại diện cho thông tin bệnh nhân.

**Properties:**
- `id`: String - ID bệnh nhân
- `name`: String - Tên bệnh nhân
- `status`: String - Trạng thái ('high_risk', 'warning', 'stable')
- `mainValue`: String - Giá trị chính (VD: "145/95")
- `unit`: String - Đơn vị (VD: "mmHg")
- `lastUpdate`: DateTime - Lần cập nhật cuối

### 3. AlertModel
Đại diện cho cảnh báo.

**Properties:**
- `id`: String - ID cảnh báo
- `patientId`: String - ID bệnh nhân liên quan
- `patientName`: String - Tên bệnh nhân
- `level`: String - Mức độ ('high', 'medium', 'low')
- `message`: String - Nội dung cảnh báo
- `createdAt`: DateTime - Thời gian tạo
- `isRead`: bool - Đã đọc chưa

### 4. ForumPostModel
Đại diện cho bài viết trong diễn đàn.

**Properties:**
- `id`: String - ID bài viết
- `authorId`: String - ID tác giả
- `authorName`: String - Tên tác giả
- `title`: String - Tiêu đề
- `content`: String - Nội dung
- `likes`: int - Số lượt thích
- `comments`: int - Số bình luận
- `createdAt`: DateTime - Thời gian tạo
- `tags`: List<String> - Các tag

### 5. KnowledgeArticleModel
Đại diện cho bài viết kiến thức.

**Properties:**
- `id`: String - ID bài viết
- `type`: String - Loại ('article', 'video')
- `title`: String - Tiêu đề
- `description`: String - Mô tả
- `imageUrl`: String - URL hình ảnh
- `meta`: String - Metadata (VD: "Bài viết • 5 phút đọc")
- `videoUrl`: String? - URL video (nếu có)
- `categories`: List<String> - Danh mục
- `publishedAt`: DateTime - Ngày xuất bản

### 6. PredictionResultModel
Đại diện cho kết quả dự đoán.

**Properties:**
- `id`: String - ID kết quả
- `userId`: String - ID người dùng
- `type`: String - Loại dự đoán ('stroke', 'diabetes')
- `riskScore`: double - Điểm nguy cơ (0.0 - 1.0)
- `riskLevel`: String - Mức độ nguy cơ ('low', 'medium', 'high')
- `inputData`: Map<String, dynamic> - Dữ liệu đầu vào
- `createdAt`: DateTime - Thời gian tạo

## AppDataProvider

Provider chính quản lý toàn bộ state của ứng dụng.

### Properties

```dart
// Current User
UserModel? currentUser

// Patients
List<PatientModel> patients

// Alerts
List<AlertModel> alerts
int unreadAlertsCount

// Dashboard Stats
Map<String, int> dashboardStats

// Forum Posts
List<ForumPostModel> forumPosts

// Knowledge Articles
List<KnowledgeArticleModel> knowledgeArticles

// Prediction Results
List<PredictionResultModel> predictionResults

// Loading state
bool isLoading
```

### Methods

#### Load Data
```dart
Future<void> loadData()
```
Load dữ liệu từ JSON file (mô phỏng Firebase).

#### Get Methods
```dart
PatientModel? getPatientById(String id)
ForumPostModel? getForumPostById(String id)
KnowledgeArticleModel? getKnowledgeArticleById(String id)
List<KnowledgeArticleModel> getArticlesByCategory(String category)
List<PatientModel> getPatientsByStatus(String status)
PredictionResultModel? getLatestPrediction(String type)
```

#### Update Methods
```dart
void markAlertAsRead(String alertId)
void addForumPost(ForumPostModel post)
void toggleLikePost(String postId)
void addPredictionResult(PredictionResultModel result)
void updateUserProfile(UserModel updatedUser)
```

## Cách sử dụng trong màn hình

### 1. Import Provider
```dart
import 'package:provider/provider.dart';
import '../../data/providers/app_data_provider.dart';
```

### 2. Lấy dữ liệu
```dart
@override
Widget build(BuildContext context) {
  final appData = Provider.of<AppDataProvider>(context);
  final currentUser = appData.currentUser;
  final patients = appData.patients;
  
  // Sử dụng dữ liệu...
}
```

### 3. Cập nhật dữ liệu
```dart
// Mark alert as read
appData.markAlertAsRead(alertId);

// Like a post
appData.toggleLikePost(postId);

// Add new prediction
appData.addPredictionResult(newResult);
```

## JSON Data Structure

File `assets/data/app_data.json` chứa toàn bộ dữ liệu mô phỏng:

```json
{
  "currentUser": { /* UserModel */ },
  "patients": [ /* List<PatientModel> */ ],
  "alerts": [ /* List<AlertModel> */ ],
  "dashboardStats": {
    "totalPatients": 42,
    "alertsLast24h": 8,
    "stablePatients": 34
  },
  "forumPosts": [ /* List<ForumPostModel> */ ],
  "knowledgeArticles": [ /* List<KnowledgeArticleModel> */ ],
  "predictionResults": [ /* List<PredictionResultModel> */ ]
}
```

## Quan hệ giữa các màn hình

### Dashboard (Trang chủ)
- **Dữ liệu sử dụng:**
  - `currentUser` - Hiển thị tên trong drawer
  - `patients` - Danh sách bệnh nhân
  - `alerts` - Cảnh báo khẩn cấp
  - `dashboardStats` - Thống kê tổng quan
  - `unreadAlertsCount` - Badge thông báo

- **Props truyền xuống:** Không có (sử dụng Provider)

### Forum (Cộng đồng)
- **Dữ liệu sử dụng:**
  - `forumPosts` - Danh sách bài viết

- **Props truyền xuống:**
  - `postId` → Topic Detail Screen

### Knowledge (Kiến thức)
- **Dữ liệu sử dụng:**
  - `knowledgeArticles` - Danh sách bài viết
  - `getArticlesByCategory()` - Lọc theo danh mục

- **Props truyền xuống:**
  - `articleId` → Article Detail Screen

### Profile (Cá nhân)
- **Dữ liệu sử dụng:**
  - `currentUser` - Thông tin người dùng

- **Props truyền xuống:** Không có

### Prediction Hub (Dự đoán)
- **Dữ liệu sử dụng:**
  - `predictionResults` - Lịch sử dự đoán
  - `getLatestPrediction()` - Kết quả mới nhất

- **Props truyền xuống:**
  - `predictionId` → Result Screen

## Migration sang Firebase

Khi chuyển sang Firebase, chỉ cần:

1. Thay đổi `loadData()` trong `AppDataProvider`:
```dart
Future<void> loadData() async {
  _isLoading = true;
  notifyListeners();

  try {
    // Thay vì load từ JSON
    // final String jsonString = await rootBundle.loadString('assets/data/app_data.json');
    
    // Load từ Firebase
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    _currentUser = UserModel.fromJson(userDoc.data()!);
    
    // Tương tự cho các collection khác...
  } catch (e) {
    print('Error loading data: $e');
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

2. Các method update cũng sẽ gọi Firebase thay vì chỉ update local state.

## Best Practices

1. **Luôn kiểm tra null:** Dữ liệu có thể null khi đang load
```dart
final userName = currentUser?.name ?? 'Guest';
```

2. **Sử dụng Consumer cho performance:** Chỉ rebuild widget cần thiết
```dart
Consumer<AppDataProvider>(
  builder: (context, appData, child) {
    return Text(appData.currentUser?.name ?? '');
  },
)
```

3. **Tách logic ra khỏi UI:** Sử dụng helper methods
```dart
static String _getStatusText(String status) {
  switch (status) {
    case 'high_risk': return 'Nguy cơ cao';
    case 'warning': return 'Cảnh báo';
    default: return status;
  }
}
```

4. **Xử lý loading state:**
```dart
if (appData.isLoading) {
  return CircularProgressIndicator();
}
```
