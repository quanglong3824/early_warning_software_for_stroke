import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'data/providers/app_data_provider.dart';
import 'services/notification_service.dart';
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
import 'features/user/legal/screen_terms_of_service.dart';
import 'features/user/legal/screen_privacy_policy.dart';
import 'features/user/support/screen_help_support.dart';
import 'features/user/chat/screen_chat_list.dart';
import 'features/user/chat/screen_chat_detail.dart';
import 'features/user/knowledge/screen_knowledge.dart';
import 'features/user/knowledge/screen_article_detail.dart';
import 'features/user/profile/screen_profile.dart';
import 'features/user/profile/screen_edit_profile.dart';
import 'features/user/pharmacy/screen_pharmacy.dart';
import 'features/user/pharmacy/screen_checkout.dart';
import 'features/user/family/screen_family.dart';
import 'features/user/appointments/screen_appointments.dart';
import 'features/user/prescriptions/screen_prescriptions.dart';
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
import 'features/user/telemedicine/screen_video_call.dart';
import 'features/user/reminders/screen_reminders.dart';
import 'features/user/reminders/screen_reminders_list.dart';
import 'features/user/reminders/screen_add_reminder.dart';
import 'features/user/reminders/screen_edit_reminder.dart';
import 'features/user/family/screen_family_management.dart';
import 'features/user/notifications/screen_notifications.dart';
import 'features/user/hospital/screen_report_appointment.dart';
import 'features/user/prevention/screen_healthy_plan.dart';

// ===== ADMIN/TEST FEATURES =====
import 'features/admin/screen_admin_login.dart';
import 'features/admin/screen_admin_test.dart';

// ===== DOCTOR FEATURES =====
import 'features/doctor/dashboard/screen_doctor_dashboard.dart';
import 'features/doctor/patients/screen_patient_list.dart';
import 'features/doctor/patients/screen_patient_profile.dart';
import 'features/doctor/appointments/screen_appointment_management.dart';
import 'features/doctor/appointments/screen_appointment_request_detail.dart';
import 'features/doctor/emergency/screen_sos_queue.dart';
import 'features/doctor/emergency/screen_sos_case_detail.dart';
import 'features/doctor/communication/screen_doctor_chat.dart';
import 'features/doctor/communication/screen_doctor_video_call.dart';
import 'features/doctor/prescriptions/screen_create_prescription.dart';
import 'features/doctor/reviews/screen_doctor_reviews.dart';
import 'features/doctor/settings/screen_doctor_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize notification service
  await NotificationService().initialize();
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppDataProvider()..loadData(),
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SEWS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF135BEC)),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.light,
      home: const ScreenSplash(),
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

        // ===== EMERGENCY =====
        '/sos': (_) => const ScreenSOS(),
        '/sos-status': (_) => const ScreenSOSStatus(),

        // ===== COMMUNICATION =====
        '/chat': (_) => const ScreenChatList(),
        '/chat-detail': (_) => const ScreenChatDetail(),
        '/video-call': (_) => const ScreenVideoCall(),
        '/reminders': (_) => const ScreenReminders(),
        '/reminders-list': (_) => const ScreenRemindersList(),
        '/add-reminder': (_) => const ScreenAddReminder(),
        '/edit-reminder': (context) {
          final reminder = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ScreenEditReminder(reminder: reminder);
        },

        // ===== MANAGEMENT =====
        '/appointments': (_) => const ScreenAppointments(),
        '/report-appointment': (_) => const ScreenReportAppointment(),
        '/patient-management': (_) => const ScreenPatientManagement(),
        '/family': (_) => const ScreenFamily(),
        '/family-management': (_) => const ScreenFamilyManagement(),
        '/notifications': (_) => const ScreenNotifications(),
        '/prescriptions': (_) => const ScreenPrescriptions(),

        // ===== PHARMACY =====
        '/pharmacy': (_) => const ScreenPharmacy(),
        '/checkout': (_) => const ScreenCheckout(),

        // ===== KNOWLEDGE & COMMUNITY =====
        '/article-detail': (_) => const ScreenArticleDetail(),
        '/topic-detail': (_) => const ScreenTopicDetail(),
        '/rate-doctor': (_) => const ScreenRateDoctor(),

        // ===== SETTINGS & OTHERS =====
        '/settings': (_) => const ScreenSettings(),
        '/change-password': (_) => const ScreenChangePassword(),
        '/healthy-plan': (_) => const ScreenHealthyPlan(),
        '/terms-of-service': (_) => const ScreenTermsOfService(),
        '/privacy-policy': (_) => const ScreenPrivacyPolicy(),
        '/help-support': (_) => const ScreenHelpSupport(),

        // ===== ADMIN/TEST FEATURES =====
        '/admin/login': (_) => const ScreenAdminLogin(),
        '/admin/test': (_) => const ScreenAdminTest(),

        // ===== DOCTOR FEATURES =====
        '/doctor/dashboard': (_) => const ScreenDoctorDashboard(),
        '/doctor/patients': (_) => const ScreenPatientList(),
        '/doctor/patient-profile': (_) => const ScreenPatientProfile(),
        '/doctor/appointments': (_) => const ScreenAppointmentManagement(),
        '/doctor/appointment-request': (_) => const ScreenAppointmentRequestDetail(),
        '/doctor/sos-queue': (_) => const ScreenSOSQueue(),
        '/doctor/sos-case': (_) => const ScreenSOSCaseDetail(),
        '/doctor/chat': (_) => const ScreenDoctorChat(),
        '/doctor/video-call': (_) => const ScreenDoctorVideoCall(),
        '/doctor/create-prescription': (_) => const ScreenCreatePrescription(),
        '/doctor/reviews': (_) => const ScreenDoctorReviews(),
        '/doctor/settings': (_) => const ScreenDoctorSettings(),
      },
    );
  }
}