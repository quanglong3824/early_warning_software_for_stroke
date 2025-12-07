# 🏗️ KIẾN TRÚC HỆ THỐNG SEWS

## 1. Tổng quan kiến trúc

SEWS được xây dựng theo kiến trúc **Clean Architecture** với các layer rõ ràng:

```
┌────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                    Screens (UI)                       │  │
│  │  • User Features (54 screens)                         │  │
│  │  • Doctor Features (17 screens)                       │  │
│  │  • Admin Features (20 screens)                        │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                    Widgets                            │  │
│  │  • Shared components                                  │  │
│  │  • Custom UI elements                                 │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────┐
│                    Business Logic Layer                     │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                    Services (34)                      │  │
│  │  • AuthService          • SOSService                  │  │
│  │  • PatientService       • AppointmentService          │  │
│  │  • ChatService          • NotificationService         │  │
│  │  • PredictionService    • HealthRecordService         │  │
│  │  • FamilyService        • KnowledgeService            │  │
│  │  • DoctorService        • ReminderService             │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                    Providers                          │  │
│  │  • AppDataProvider (State Management)                 │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────┐
│                    Data Layer                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                    Models                             │  │
│  │  • UserModel           • DoctorModel                  │  │
│  │  • AppointmentModel    • HealthRecordModel            │  │
│  │  • PredictionModel     • MessageModel                 │  │
│  │  • SOSRequestModel     • ReminderModel                │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                    Data Sources                       │  │
│  │  • Firebase Realtime Database                         │  │
│  │  • Firebase Auth                                      │  │
│  │  • Firebase Storage                                   │  │
│  │  • Hive (Offline Cache)                               │  │
│  │  • Flask API (AI Prediction)                          │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘
```

---

## 2. Chi tiết các Layer

### 2.1 Presentation Layer

#### Screens Structure
```
lib/features/
├── user/                          # 54 screens
│   ├── auth/                      # Authentication
│   │   ├── screen_login.dart
│   │   ├── screen_register.dart
│   │   ├── screen_forgot_password.dart
│   │   ├── screen_reset_password.dart
│   │   └── screen_onboarding.dart
│   │
│   ├── dashboard/                 # Main dashboard
│   │   └── screen_dashboard.dart
│   │
│   ├── prediction/                # Health prediction
│   │   ├── screen_prediction_hub.dart
│   │   ├── screen_stroke_form.dart
│   │   ├── screen_stroke_result.dart
│   │   ├── screen_diabetes_form.dart
│   │   └── screen_diabetes_result.dart
│   │
│   ├── health/                    # Health tracking
│   │   ├── screen_health_hub.dart
│   │   ├── screen_health_history.dart
│   │   └── screen_add_health_record.dart
│   │
│   ├── emergency/                 # SOS features
│   │   ├── screen_sos.dart
│   │   └── screen_sos_status.dart
│   │
│   ├── appointments/              # Appointment booking
│   │   └── screen_appointments.dart
│   │
│   ├── chat/                      # Messaging
│   │   ├── screen_chat_list.dart
│   │   ├── screen_chat_detail.dart
│   │   └── screen_select_doctor_chat.dart
│   │
│   ├── family/                    # Family management
│   │   ├── screen_family.dart
│   │   ├── screen_family_management.dart
│   │   ├── screen_family_groups.dart
│   │   ├── screen_group_detail.dart
│   │   └── screen_invite_members.dart
│   │
│   ├── reminders/                 # Medication reminders
│   │   ├── screen_reminders.dart
│   │   ├── screen_reminders_list.dart
│   │   ├── screen_add_reminder.dart
│   │   └── screen_edit_reminder.dart
│   │
│   ├── doctors/                   # Doctor listing
│   │   ├── screen_doctors_hub.dart
│   │   ├── screen_doctor_list.dart
│   │   └── screen_doctor_detail.dart
│   │
│   ├── knowledge/                 # Health articles
│   │   ├── screen_knowledge.dart
│   │   └── screen_article_detail.dart
│   │
│   ├── community/                 # Forum
│   │   ├── screen_forum.dart
│   │   └── screen_topic_detail.dart
│   │
│   ├── profile/                   # User profile
│   │   ├── screen_profile.dart
│   │   └── screen_edit_profile.dart
│   │
│   └── settings/                  # App settings
│       ├── screen_settings.dart
│       ├── screen_change_password.dart
│       └── screen_notification_settings.dart
│
├── doctor/                        # 17 screens
│   ├── auth/
│   │   └── screen_doctor_login.dart
│   ├── dashboard/
│   │   └── screen_doctor_dashboard.dart
│   ├── patients/
│   │   ├── screen_patient_list.dart
│   │   └── screen_patient_profile.dart
│   ├── appointments/
│   │   ├── screen_appointment_management.dart
│   │   └── screen_appointment_request_detail.dart
│   ├── emergency/
│   │   ├── screen_sos_queue.dart
│   │   └── screen_sos_case_detail.dart
│   ├── communication/
│   │   ├── screen_doctor_chat.dart
│   │   ├── screen_doctor_chat_detail.dart
│   │   └── screen_select_patient_chat.dart
│   ├── schedule/
│   │   └── screen_schedule_management.dart
│   ├── reviews/
│   │   └── screen_doctor_reviews.dart
│   └── settings/
│       └── screen_doctor_settings.dart
│
└── admin/                         # 20 screens
    ├── auth/
    │   ├── screen_admin_splash.dart
    │   ├── screen_admin_login.dart
    │   └── screen_admin_forgot_password.dart
    ├── dashboard/
    │   └── screen_admin_dashboard.dart
    ├── users/
    │   └── screen_user_management.dart
    ├── doctors/
    │   └── screen_doctor_management.dart
    ├── patients/
    │   └── screen_patient_management.dart
    ├── sos/
    │   └── screen_sos_management.dart
    ├── predictions/
    │   └── screen_prediction_management.dart
    ├── appointments/
    │   └── screen_appointment_management.dart
    ├── knowledge/
    │   └── screen_knowledge_management.dart
    └── community/
        └── screen_community_management.dart
```

### 2.2 Business Logic Layer

#### Services (34 files)
```
lib/services/
├── auth_service.dart              # Authentication logic
├── patient_service.dart           # Patient management
├── doctor_service.dart            # Doctor operations
├── appointment_service.dart       # Appointment booking
├── chat_service.dart              # Real-time messaging
├── sos_service.dart               # Emergency handling
├── notification_service.dart      # Push notifications
├── stroke_prediction_service.dart # Stroke risk calculation
├── diabetes_prediction_service.dart # Diabetes prediction
├── ai_stroke_prediction_service.dart # AI model integration
├── health_record_service.dart     # Health data management
├── health_chart_service.dart      # Chart data processing
├── family_service.dart            # Family connections
├── family_group_service.dart      # Family groups
├── reminder_service.dart          # Medication reminders
├── medication_service.dart        # Medication management
├── knowledge_service.dart         # Articles & content
├── doctor_review_service.dart     # Doctor ratings
├── doctor_schedule_service.dart   # Schedule management
├── doctor_dashboard_service.dart  # Doctor stats
├── doctor_notification_service.dart # Doctor notifications
├── location_service.dart          # GPS & geocoding
├── connectivity_service.dart      # Network monitoring
├── offline_cache_service.dart     # Hive cache
├── admin_user_service.dart        # Admin user management
├── admin_doctor_service.dart      # Admin doctor management
├── admin_prediction_service.dart  # Admin prediction stats
└── user_dashboard_service.dart    # User dashboard data
```

### 2.3 Data Layer

#### Models
```
lib/data/models/
├── user_model.dart
├── doctor_models.dart
├── appointment_model.dart
├── health_record_model.dart
├── prediction_model.dart
├── message_model.dart
├── sos_request_model.dart
├── reminder_model.dart
├── article_model.dart
└── forum_thread_model.dart
```

---

## 3. State Management

### Provider Pattern
```dart
// main.dart
runApp(
  ChangeNotifierProvider(
    create: (_) => AppDataProvider()..loadData(),
    child: App(),
  ),
);

// Usage in widgets
final appData = Provider.of<AppDataProvider>(context);
```

### AppDataProvider
```dart
class AppDataProvider extends ChangeNotifier {
  Map<String, dynamic>? _appData;
  List<Map<String, dynamic>>? _doctors;
  
  Future<void> loadData() async {
    // Load from assets/data/
    _appData = await loadAppData();
    _doctors = await loadDoctorData();
    notifyListeners();
  }
  
  // Getters for UI
  List<String> get specializations => ...;
  List<Map<String, dynamic>> get doctors => ...;
}
```

---

## 4. Navigation

### Route Configuration
```dart
// main.dart - Named Routes
routes: {
  '/splash': (_) => const ScreenSplash(),
  '/login': (_) => const ScreenLogin(),
  '/dashboard': (_) => const ScreenDashboard(),
  '/prediction-hub': (_) => const ScreenPredictionHub(),
  // ... 90+ routes
}
```

### Navigation Utils
```dart
// lib/utils/navigation_utils.dart
class NavigationUtils {
  static void pushNamed(BuildContext context, String route);
  static void pushReplacementNamed(BuildContext context, String route);
  static void popUntil(BuildContext context, String route);
}
```

---

## 5. Offline Support

### Hive Cache
```dart
// lib/services/offline_cache_service.dart
class OfflineCacheService {
  late Box _cacheBox;
  
  Future<void> initialize() async {
    await Hive.initFlutter();
    _cacheBox = await Hive.openBox('offline_cache');
  }
  
  Future<void> cacheData(String key, dynamic data);
  Future<dynamic> getCachedData(String key);
  Future<void> clearCache();
}
```

### Connectivity Monitoring
```dart
// lib/services/connectivity_service.dart
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  
  Stream<ConnectivityResult> get onConnectivityChanged;
  Future<bool> get isConnected;
}
```

---

## 6. Firebase Integration

### Authentication Flow
```
User Input → AuthService → Firebase Auth → Session Storage
                              ↓
                        Firebase RTDB (user profile)
```

### Real-time Data Sync
```dart
// Example: Chat messages
FirebaseDatabase.instance
  .ref('conversations/$conversationId/messages')
  .onValue
  .listen((event) {
    // Update UI with new messages
  });
```

---

## 7. AI Prediction Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  User Input │────▶│   Flutter   │────▶│  Flask API  │
│  (12 params)│     │   Service   │     │  /predict   │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
                    ┌─────────────┐     ┌──────▼──────┐
                    │   Result    │◀────│  ML Model   │
                    │   Screen    │     │  (sklearn)  │
                    └─────────────┘     └─────────────┘
```

### Fallback Strategy
```dart
Future<PredictionResult> predict(HealthData data) async {
  try {
    // Try AI prediction first
    return await aiPredictionService.predict(data);
  } catch (e) {
    // Fallback to rule-based
    return ruleBased Prediction(data);
  }
}
```

---

## 8. Security

### Authentication
- Firebase Authentication
- Email verification required
- Password hashing (Firebase managed)
- Session management

### Data Protection
- Firebase Security Rules
- Role-based access control
- Sensitive data encryption
- API key protection

### Firebase Rules Example
```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    },
    "healthRecords": {
      "$uid": {
        ".read": "$uid === auth.uid || root.child('doctors').child(auth.uid).exists()",
        ".write": "$uid === auth.uid"
      }
    }
  }
}
```

---

## 9. Performance Optimization

### Image Optimization
- `cached_network_image` for caching
- `flutter_image_compress` for uploads
- Lazy loading for lists

### Data Loading
- Pagination for large lists
- Debouncing for search
- Optimistic UI updates

### Transition Optimization
```dart
// Cupertino transitions for smooth navigation
pageTransitionsTheme: const PageTransitionsTheme(
  builders: {
    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
  },
),
```

---

*Tài liệu kiến trúc - SEWS v1.0.0*
