import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'data/providers/app_data_provider.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'services/offline_cache_service.dart';
import 'utils/navigation_utils.dart';
// ===== USER FEATURES =====
import 'features/user/splash/screen_splash.dart';
import 'features/user/auth/screen_login.dart';
import 'features/user/auth/screen_register.dart';
import 'features/user/auth/screen_forgot_password.dart';
import 'features/user/auth/screen_reset_password.dart';
import 'features/user/auth/screen_onboarding.dart';
import 'features/user/dashboard/screen_dashboard.dart';
import 'features/user/settings/screen_settings.dart';
import 'features/user/settings/screen_change_password.dart';
import 'features/user/settings/screen_notification_settings.dart';
import 'features/user/legal/screen_terms_of_service.dart';
import 'features/user/legal/screen_privacy_policy.dart';
import 'features/user/support/screen_help_support.dart';
import 'features/user/chat/screen_chat_list.dart';
import 'features/user/chat/screen_chat_detail.dart';
import 'features/user/knowledge/screen_knowledge.dart';
import 'features/user/knowledge/screen_article_detail.dart';
import 'features/user/profile/screen_profile.dart';
import 'features/user/profile/screen_edit_profile.dart';
import 'features/doctor/medications/screen_add_medication.dart';
import 'features/user/family/screen_family.dart';
import 'features/user/appointments/screen_appointments.dart';
import 'features/user/community/screen_forum.dart';
import 'features/user/community/screen_topic_detail.dart';
import 'features/user/reviews/screen_rate_doctor.dart';
import 'features/user/prediction/screen_prediction_hub.dart';
import 'features/user/prediction/screen_stroke_form.dart';
import 'features/user/prediction/screen_diabetes_form.dart';
import 'features/user/prediction/screen_stroke_result.dart';
import 'features/user/prediction/screen_diabetes_result.dart';
import 'features/user/emergency/screen_sos.dart';
import 'features/user/emergency/screen_sos_status.dart';
import 'features/user/patients/screen_patient_management.dart';
import 'features/user/health/screen_health_history.dart';
import 'features/user/health/screen_add_health_record.dart';
import 'features/user/health/screen_health_hub.dart';
import 'features/user/reminders/screen_reminders.dart';
import 'features/user/reminders/screen_reminders_list.dart';
import 'features/user/reminders/screen_add_reminder.dart';
import 'features/user/reminders/screen_edit_reminder.dart';
import 'features/user/family/screen_family_management.dart';
import 'features/user/family/screen_family_groups.dart';
import 'features/user/family/screen_group_detail.dart';
import 'features/user/family/screen_invite_members.dart';
import 'features/user/notifications/screen_notifications.dart';
import 'features/user/hospital/screen_report_appointment.dart';
import 'features/user/prevention/screen_healthy_plan.dart';
import 'features/user/doctors/screen_doctor_list.dart';
import 'features/user/doctors/screen_doctor_detail.dart';
import 'features/user/doctors/screen_doctors_hub.dart';
import 'data/models/doctor_models.dart';

// ===== ADMIN FEATURES =====
import 'features/admin/auth/screen_admin_splash.dart';
import 'features/admin/auth/screen_admin_login.dart';
import 'features/admin/auth/screen_admin_forgot_password.dart';
import 'features/admin/screen_admin_main.dart';
import 'features/admin/users/screen_test_firebase.dart';

// ===== DOCTOR FEATURES =====
import 'features/doctor/auth/screen_doctor_login.dart';
import 'features/doctor/dashboard/screen_doctor_dashboard.dart';
import 'features/doctor/patients/screen_patient_list.dart';
import 'features/doctor/patients/screen_patient_profile.dart';
import 'features/doctor/appointments/screen_appointment_management.dart';
import 'features/doctor/appointments/screen_appointment_request_detail.dart';
import 'features/doctor/emergency/screen_sos_queue.dart';
import 'features/doctor/emergency/screen_sos_case_detail.dart';
import 'features/doctor/communication/screen_doctor_chat.dart';
import 'features/doctor/communication/screen_doctor_chat_detail.dart';
import 'features/doctor/communication/screen_select_patient_chat.dart';
import 'features/user/chat/screen_select_doctor_chat.dart';
import 'features/doctor/reviews/screen_doctor_reviews.dart';
import 'features/doctor/settings/screen_doctor_settings.dart';
import 'features/doctor/schedule/screen_schedule_management.dart';
import 'features/doctor/notifications/screen_doctor_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize notification service with FCM
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // Initialize offline cache service (Requirement 5.1)
  final offlineCacheService = OfflineCacheService();
  await offlineCacheService.initialize();
  
  // Initialize connectivity service (Requirement 5.3)
  await ConnectivityServiceSingleton.initialize();
  
  // Clear session on web refresh (for web platform)
  // This ensures users must login again after refresh
  if (kIsWeb) {
    await AuthService().logout();
  }
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppDataProvider()..loadData(),
      child: App(notificationService: notificationService),
    ),
  );
}

class App extends StatefulWidget {
  final NotificationService notificationService;
  
  const App({super.key, required this.notificationService});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    widget.notificationService.onNotificationTap.listen((payload) {
      _handleNotificationNavigation(payload);
    });
  }

  void _handleNotificationNavigation(NotificationPayload payload) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    final route = payload.route;
    if (route != null && route.isNotEmpty) {
      // Navigate based on notification type
      switch (payload.type) {
        case 'appointment':
          navigator.pushNamed('/appointments');
          break;
        case 'sos':
          navigator.pushNamed('/sos-status');
          break;
        case 'chat':
          if (payload.data != null && payload.data!['conversationId'] != null) {
            navigator.pushNamed('/chat-detail', arguments: {
              'conversationId': payload.data!['conversationId'],
              'title': 'Chat',
            });
          } else {
            navigator.pushNamed('/chat');
          }
          break;
        case 'reminder':
          navigator.pushNamed('/reminders');
          break;
        default:
          navigator.pushNamed(route);
      }
    }
  }

  /// Custom route generator for optimized transitions
  /// Requirements: 10.2 - Complete transition within 300ms
  Route<dynamic>? _generateRoute(RouteSettings settings) {
    // Return null to let the routes map handle it
    // This is called for routes not in the routes map
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'SEWS - Cảnh báo sớm đột quỵ',
      debugShowCheckedModeBanner: false, // Tắt nhãn DEBUG
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF135BEC)),
        useMaterial3: true,
        // Optimized page transitions - Requirements: 10.2
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      themeMode: ThemeMode.light,
      home: const ScreenSplash(),
      // Custom route generator for optimized transitions
      onGenerateRoute: _generateRoute,
      routes: {
        // ===== AUTHENTICATION =====
        '/splash': (_) => const ScreenSplash(),
        '/onboarding': (_) => const ScreenOnboarding(),
        '/login': (_) => const ScreenLogin(),
        '/register': (_) => const ScreenRegister(),
        '/forgot-password': (_) => const ScreenForgotPassword(),
        '/reset-password': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return ScreenResetPassword(code: args?['code']);
        },

        // ===== MAIN SCREENS (Bottom Nav) =====
        '/dashboard': (_) => const ScreenDashboard(),
        '/health-hub': (_) => const ScreenHealthHub(),
        '/doctors-hub': (_) => const ScreenDoctorsHub(),
        '/doctor-hub': (_) => const ScreenDoctorsHub(), // Alias for new 4-tab nav
        '/prediction-hub': (_) => const ScreenPredictionHub(),
        '/forum': (_) => const ScreenForum(),
        '/knowledge': (_) => const ScreenKnowledge(),
        '/profile': (_) => const ScreenProfile(),
        '/edit-profile': (_) => const ScreenEditProfile(),

        // ===== PREDICTION & HEALTH =====
        '/stroke-form': (_) => const ScreenStrokeForm(),
        '/stroke-result': (_) => const ScreenStrokeResult(),
        '/diabetes-form': (_) => const ScreenDiabetesForm(),
        '/diabetes-result': (_) => const ScreenDiabetesResult(),
        '/health-history': (_) => const ScreenHealthHistory(),
        '/add-health-record': (_) => ScreenAddHealthRecord(),

        // ===== EMERGENCY =====
        '/sos': (_) => const ScreenSOS(),
        '/sos-status': (_) => const ScreenSOSStatus(),

        // ===== COMMUNICATION =====
        '/chat': (_) => const ScreenChatList(),
        '/chat/select-doctor': (_) => const ScreenSelectDoctorChat(),
        '/chat-detail': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return ScreenChatDetail(
            conversationId: args?['conversationId'] ?? '',
            title: args?['title'] ?? 'Chat',
          );
        },
        '/reminders': (_) => const ScreenReminders(),
        '/reminders-list': (_) => const ScreenRemindersList(),
        '/add-reminder': (_) => const ScreenAddReminder(),
        '/edit-reminder': (context) {
          final reminder = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ScreenEditReminder(reminder: reminder);
        },

        // ===== MANAGEMENT =====
        '/appointments': (_) => const ScreenAppointments(),
        '/doctor-list': (_) => const ScreenDoctorList(),
        '/doctor-detail': (context) {
          final doctor = ModalRoute.of(context)!.settings.arguments as DoctorModel;
          return ScreenDoctorDetail(doctor: doctor);
        },
        '/rate-doctor': (context) {
          final doctor = ModalRoute.of(context)!.settings.arguments as DoctorModel;
          return ScreenRateDoctor(doctor: doctor);
        },
        '/report-appointment': (_) => const ScreenReportAppointment(),
        '/patient-management': (_) => const ScreenPatientManagement(),
        '/family': (_) => const ScreenFamily(),
        '/family-management': (_) => const ScreenFamilyManagement(),
        '/family-groups': (_) => const ScreenFamilyGroups(),
        '/group-detail': (_) => const ScreenGroupDetail(),
        '/invite-members': (_) => const ScreenInviteMembers(),
        '/notifications': (_) => const ScreenNotifications(),
        '/doctor/add-medication': (_) => ScreenAddMedication(),

        // ===== KNOWLEDGE & COMMUNITY =====
        '/article-detail': (_) => const ScreenArticleDetail(),
        '/topic-detail': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return ScreenTopicDetail(
            threadId: args?['threadId'] ?? '',
            title: args?['title'] ?? 'Chi tiết bài viết',
          );
        },


        // ===== SETTINGS & OTHERS =====
        '/settings': (_) => const ScreenSettings(),
        '/settings/notifications': (_) => const ScreenNotificationSettings(),
        '/change-password': (_) => const ScreenChangePassword(),
        '/healthy-plan': (_) => const ScreenHealthyPlan(),
        '/terms-of-service': (_) => const ScreenTermsOfService(),
        '/privacy-policy': (_) => const ScreenPrivacyPolicy(),
        '/help-support': (_) => const ScreenHelpSupport(),

        // ===== ADMIN FEATURES =====
        '/admin': (_) => const ScreenAdminSplash(),
        '/admin/login': (_) => const ScreenAdminLogin(),
        '/admin/forgot-password': (_) => const ScreenAdminForgotPassword(),
        '/admin/dashboard': (_) => const ScreenAdminMain(initialIndex: 0),
        '/admin/users': (_) => const ScreenAdminMain(initialIndex: 1),
        '/admin/test-firebase': (_) => const ScreenTestFirebase(),
        '/admin/doctors': (_) => const ScreenAdminMain(initialIndex: 2),
        '/admin/patients': (_) => const ScreenAdminMain(initialIndex: 3),
        '/admin/sos': (_) => const ScreenAdminMain(initialIndex: 4),
        '/admin/predictions': (_) => const ScreenAdminMain(initialIndex: 5),
        '/admin/appointments': (_) => const ScreenAdminMain(initialIndex: 6),
        '/admin/knowledge': (_) => const ScreenAdminMain(initialIndex: 7),
        '/admin/community': (_) => const ScreenAdminMain(initialIndex: 8),

        // ===== DOCTOR FEATURES =====
        '/doctor/login': (_) => const ScreenDoctorLogin(),
        '/doctor/dashboard': (_) => const ScreenDoctorDashboard(),
        '/doctor/patients': (_) => const ScreenPatientList(),
        '/doctor/patient-profile': (_) => const ScreenPatientProfile(),
        '/doctor/appointments': (_) => const ScreenAppointmentManagement(),
        '/doctor/appointment-request': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return ScreenAppointmentRequestDetail(
            appointmentId: args?['appointmentId'] ?? '',
          );
        },
        '/doctor/sos-queue': (_) => const ScreenSOSQueue(),
        '/doctor/sos-case': (_) => const ScreenSOSCaseDetail(),
        '/doctor/chat': (_) => const ScreenDoctorChat(),
        '/doctor/chat/select-patient': (_) => const ScreenSelectPatientChat(),
        '/doctor/chat-detail': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return ScreenDoctorChatDetail(
            conversationId: args?['conversationId'] ?? '',
            patientName: args?['patientName'] ?? 'Bệnh nhân',
            userId: args?['userId'] ?? '',
          );
        },
        '/doctor/reviews': (_) => const ScreenDoctorReviews(),
        '/doctor/settings': (_) => const ScreenDoctorSettings(),
        '/doctor/schedule': (_) => const ScreenScheduleManagement(),
        '/doctor/notifications': (_) => const ScreenDoctorNotifications(),
      },
    );
  }
}