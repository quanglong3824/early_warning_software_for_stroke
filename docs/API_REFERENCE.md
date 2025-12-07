# 🔌 API REFERENCE - SEWS

## 1. Flask AI Prediction API

### Base URL
- **Development**: `http://localhost:5001`
- **Production**: Configure in `AIStrokePredictionService`

---

### 1.1 Health Check

Kiểm tra trạng thái server và model.

```http
GET /health
```

**Response**
```json
{
  "status": "healthy",
  "model_loaded": true,
  "preprocessor_loaded": true,
  "version": "1.0.0"
}
```

**Status Codes**
| Code | Description |
|------|-------------|
| 200 | Server healthy |
| 500 | Server error |

---

### 1.2 Stroke Risk Prediction

Dự đoán nguy cơ đột quỵ dựa trên các chỉ số sức khỏe.

```http
POST /predict
Content-Type: application/json
```

**Request Body**
```json
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

**Parameters**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| age | integer | ✅ | Tuổi (18-120) |
| gender | string | ✅ | "male" hoặc "female" |
| heightCm | number | ✅ | Chiều cao (cm) |
| weightKg | number | ✅ | Cân nặng (kg) |
| systolicBP | integer | ✅ | Huyết áp tâm thu (mmHg) |
| diastolicBP | integer | ✅ | Huyết áp tâm trương (mmHg) |
| cholesterol | integer | ✅ | Cholesterol (mg/dL) |
| glucose | integer | ✅ | Đường huyết (mg/dL) |
| hypertension | boolean | ✅ | Tiền sử tăng huyết áp |
| heartDisease | boolean | ✅ | Tiền sử bệnh tim |
| smoking | boolean | ✅ | Hút thuốc |
| workType | string | ✅ | "sedentary", "moderate", "active" |

**Response**
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
  "cholesterolCategory": "Biên cao",
  "glucoseCategory": "Bình thường",
  "predictionMethod": "AI",
  "recommendations": [
    "Kiểm soát huyết áp",
    "Giảm cholesterol",
    "Tập thể dục đều đặn"
  ]
}
```

**Risk Levels**
| Score | Level | Vietnamese |
|-------|-------|------------|
| 0-20 | low | Nguy cơ thấp |
| 21-40 | moderate | Nguy cơ trung bình thấp |
| 41-60 | medium | Nguy cơ trung bình |
| 61-80 | high | Nguy cơ cao |
| 81-100 | very_high | Nguy cơ rất cao |

**Error Response**
```json
{
  "success": false,
  "error": "Missing required field: age"
}
```

---

## 2. Firebase Realtime Database API

### 2.1 Authentication

#### Register User
```dart
// AuthService.register()
FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: email,
  password: password,
);
```

#### Login
```dart
// AuthService.login()
FirebaseAuth.instance.signInWithEmailAndPassword(
  email: email,
  password: password,
);
```

#### Google Sign-In
```dart
// AuthService.signInWithGoogle()
final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
final credential = GoogleAuthProvider.credential(
  accessToken: googleAuth.accessToken,
  idToken: googleAuth.idToken,
);
await FirebaseAuth.instance.signInWithCredential(credential);
```

---

### 2.2 User Operations

#### Get User Profile
```dart
// Path: users/{userId}
final ref = FirebaseDatabase.instance.ref('users/$userId');
final snapshot = await ref.get();
```

#### Update User Profile
```dart
await ref.update({
  'fullName': 'New Name',
  'phone': '0123456789',
  'updatedAt': ServerValue.timestamp,
});
```

---

### 2.3 Health Records

#### Add Health Record
```dart
// Path: healthRecords/{userId}/{recordId}
final ref = FirebaseDatabase.instance.ref('healthRecords/$userId').push();
await ref.set({
  'systolicBP': 120,
  'diastolicBP': 80,
  'heartRate': 72,
  'glucose': 95,
  'weight': 70,
  'height': 170,
  'recordedAt': ServerValue.timestamp,
});
```

#### Get Health History
```dart
final ref = FirebaseDatabase.instance
  .ref('healthRecords/$userId')
  .orderByChild('recordedAt')
  .limitToLast(30);
final snapshot = await ref.get();
```

---

### 2.4 Predictions

#### Save Prediction
```dart
// Path: predictions/{userId}/{predictionId}
final ref = FirebaseDatabase.instance.ref('predictions/$userId').push();
await ref.set({
  'type': 'stroke',
  'riskScore': 45,
  'riskLevel': 'medium',
  'inputData': {...},
  'createdAt': ServerValue.timestamp,
});
```

---

### 2.5 Appointments

#### Create Appointment
```dart
// Path: appointments/{appointmentId}
final ref = FirebaseDatabase.instance.ref('appointments').push();
await ref.set({
  'userId': userId,
  'doctorId': doctorId,
  'dateTime': dateTime.millisecondsSinceEpoch,
  'status': 'pending',
  'notes': 'Khám tổng quát',
  'createdAt': ServerValue.timestamp,
});
```

#### Update Appointment Status
```dart
await ref.update({
  'status': 'confirmed', // pending, confirmed, completed, cancelled
  'updatedAt': ServerValue.timestamp,
});
```

---

### 2.6 SOS Requests

#### Create SOS
```dart
// Path: sosRequests/{sosId}
final ref = FirebaseDatabase.instance.ref('sosRequests').push();
await ref.set({
  'userId': userId,
  'location': {
    'latitude': 10.762622,
    'longitude': 106.660172,
    'address': '123 Nguyen Hue, Q1, HCM',
  },
  'status': 'pending',
  'createdAt': ServerValue.timestamp,
});
```

#### Listen to SOS Updates
```dart
FirebaseDatabase.instance
  .ref('sosRequests/$sosId')
  .onValue
  .listen((event) {
    final data = event.snapshot.value as Map;
    // Update UI
  });
```

---

### 2.7 Chat/Messaging

#### Send Message
```dart
// Path: conversations/{conversationId}/messages/{messageId}
final ref = FirebaseDatabase.instance
  .ref('conversations/$conversationId/messages')
  .push();
await ref.set({
  'senderId': userId,
  'content': 'Hello',
  'type': 'text', // text, image
  'sentAt': ServerValue.timestamp,
});

// Update conversation metadata
await FirebaseDatabase.instance
  .ref('conversations/$conversationId')
  .update({
    'lastMessage': 'Hello',
    'lastMessageAt': ServerValue.timestamp,
  });
```

#### Listen to Messages
```dart
FirebaseDatabase.instance
  .ref('conversations/$conversationId/messages')
  .orderByChild('sentAt')
  .onChildAdded
  .listen((event) {
    final message = event.snapshot.value as Map;
    // Add to message list
  });
```

---

### 2.8 Family Groups

#### Create Family Group
```dart
// Path: familyGroups/{groupId}
final ref = FirebaseDatabase.instance.ref('familyGroups').push();
await ref.set({
  'name': 'Gia đình tôi',
  'ownerId': userId,
  'members': [userId],
  'createdAt': ServerValue.timestamp,
});
```

#### Invite Member
```dart
// Path: familyInvites/{inviteId}
final ref = FirebaseDatabase.instance.ref('familyInvites').push();
await ref.set({
  'groupId': groupId,
  'invitedEmail': 'member@email.com',
  'invitedBy': userId,
  'status': 'pending',
  'createdAt': ServerValue.timestamp,
});
```

---

### 2.9 Reminders

#### Create Reminder
```dart
// Path: reminders/{userId}/{reminderId}
final ref = FirebaseDatabase.instance.ref('reminders/$userId').push();
await ref.set({
  'title': 'Uống thuốc huyết áp',
  'time': '08:00',
  'frequency': 'daily', // daily, weekly, custom
  'days': [1, 2, 3, 4, 5], // for weekly
  'isActive': true,
  'createdAt': ServerValue.timestamp,
});
```

---

## 3. Firebase Cloud Messaging

### Send Notification (Server-side)
```dart
// NotificationService.sendPushNotification()
await http.post(
  Uri.parse('https://fcm.googleapis.com/fcm/send'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'key=$serverKey',
  },
  body: jsonEncode({
    'to': fcmToken,
    'notification': {
      'title': 'SEWS Alert',
      'body': 'You have a new appointment',
    },
    'data': {
      'type': 'appointment',
      'appointmentId': 'abc123',
    },
  }),
);
```

---

## 4. Error Codes

### Firebase Auth Errors
| Code | Description |
|------|-------------|
| invalid-email | Email không hợp lệ |
| user-disabled | Tài khoản bị vô hiệu hóa |
| user-not-found | Không tìm thấy tài khoản |
| wrong-password | Mật khẩu không đúng |
| email-already-in-use | Email đã được sử dụng |
| weak-password | Mật khẩu quá yếu |

### Firebase Database Errors
| Code | Description |
|------|-------------|
| permission-denied | Không có quyền truy cập |
| disconnected | Mất kết nối |

---

## 5. Rate Limits

### Firebase
- **Realtime Database**: 100 concurrent connections (free tier)
- **Authentication**: 100 sign-ups/hour (free tier)
- **Storage**: 1GB storage, 5GB/day download (free tier)

### Flask API
- **Prediction**: No limit (self-hosted)
- **Recommended**: Implement rate limiting for production

---

*API Reference - SEWS v1.0.0*
