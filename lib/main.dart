import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'data/providers/app_data_provider.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
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
import 'features/user/pharmacy/screen_prescription_lookup.dart';
import 'features/user/pharmacy/screen_prescription_pharmacy.dart';
import 'features/user/pharmacy/screen_order_history.dart';
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
import 'features/user/health/screen_add_health_record.dart';
import 'features/user/telemedicine/screen_video_call.dart';
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
import 'data/models/doctor_models.dart';

// ===== ADMIN FEATURES =====
import 'features/admin/auth/screen_admin_splash.dart';
import 'features/admin/auth/screen_admin_login.dart';
import 'features/admin/auth/screen_admin_forgot_password.dart';
import 'features/admin/dashboard/screen_admin_dashboard.dart';
import 'features/admin/users/screen_admin_users.dart';
import 'features/admin/users/screen_test_firebase.dart';
import 'features/admin/doctors/screen_admin_doctors.dart';
import 'features/admin/patients/screen_admin_patients.dart';
import 'features/admin/sos/screen_admin_sos.dart';
import 'features/admin/predictions/screen_admin_predictions.dart';
import 'features/admin/appointments/screen_admin_appointments.dart';
import 'features/admin/pharmacy/screen_admin_pharmacy.dart';
import 'features/admin/medications/screen_admin_medications.dart';
import 'features/admin/knowledge/screen_admin_knowledge.dart';
import 'features/admin/community/screen_admin_community.dart';

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
  
  // Clear session on web refresh (for web platform)
  // This ensures users must login again after refresh
  if (kIsWeb) {
    await AuthService().logout();
  }
  
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
        '/add-health-record': (_) => ScreenAddHealthRecord(),

        // ===== EMERGENCY =====
        '/sos': (_) => const ScreenSOS(),
        '/sos-status': (_) => const ScreenSOSStatus(),

        // ===== COMMUNICATION =====
        '/chat': (_) => const ScreenChatList(),
        '/chat-detail': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return ScreenChatDetail(
            conversationId: args?['conversationId'] ?? '',
            title: args?['title'] ?? 'Chat',
          );
        },
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
        '/prescriptions': (_) => const ScreenPrescriptions(),

        // ===== PHARMACY =====
        '/pharmacy': (_) => const ScreenPharmacy(),
        '/checkout': (_) => const ScreenCheckout(),
        '/pharmacy/prescription-lookup': (_) => const ScreenPrescriptionLookup(),
        '/pharmacy/prescription-detail': (context) {
          final prescription = ModalRoute.of(context)!.settings.arguments;
          return ScreenPrescriptionPharmacy(prescription: prescription as dynamic);
        },
        '/pharmacy/order-history': (_) => const ScreenOrderHistory(),

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
        '/change-password': (_) => const ScreenChangePassword(),
        '/healthy-plan': (_) => const ScreenHealthyPlan(),
        '/terms-of-service': (_) => const ScreenTermsOfService(),
        '/privacy-policy': (_) => const ScreenPrivacyPolicy(),
        '/help-support': (_) => const ScreenHelpSupport(),

        // ===== ADMIN FEATURES =====
        '/admin': (_) => const ScreenAdminSplash(),
        '/admin/login': (_) => const ScreenAdminLogin(),
        '/admin/forgot-password': (_) => const ScreenAdminForgotPassword(),
        '/admin/dashboard': (_) => const ScreenAdminDashboard(),
        '/admin/users': (_) => const ScreenAdminUsers(),
        '/admin/test-firebase': (_) => const ScreenTestFirebase(),
        '/admin/doctors': (_) => const ScreenAdminDoctors(),
        '/admin/patients': (_) => const ScreenAdminPatients(),
        '/admin/sos': (_) => const ScreenAdminSOS(),
        '/admin/predictions': (_) => const ScreenAdminPredictions(),
        '/admin/appointments': (_) => const ScreenAdminAppointments(),
        '/admin/pharmacy': (_) => const ScreenAdminPharmacy(),
        '/admin/medications': (_) => const ScreenAdminMedications(),
        '/admin/knowledge': (_) => const ScreenAdminKnowledge(),
        '/admin/community': (_) => const ScreenAdminCommunity(),

        // ===== DOCTOR FEATURES =====
        '/doctor/login': (_) => const ScreenDoctorLogin(),
        '/doctor/dashboard': (_) => const ScreenDoctorDashboard(),
        '/doctor/patients': (_) => const ScreenPatientList(),
        '/doctor/patient-profile': (_) => const ScreenPatientProfile(),
        '/doctor/appointments': (_) => const ScreenAppointmentManagement(),
        '/doctor/appointment-request': (_) => const ScreenAppointmentRequestDetail(),
        '/doctor/sos-queue': (_) => const ScreenSOSQueue(),
        '/doctor/sos-case': (_) => const ScreenSOSCaseDetail(),
        '/doctor/chat': (_) => const ScreenDoctorChat(),
        '/doctor/chat-detail': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return ScreenDoctorChatDetail(
            conversationId: args?['conversationId'] ?? '',
            patientName: args?['patientName'] ?? 'Bệnh nhân',
            userId: args?['userId'] ?? '',
          );
        },
        '/doctor/video-call': (_) => const ScreenDoctorVideoCall(),
        '/doctor/create-prescription': (_) => const ScreenCreatePrescription(),
        '/doctor/reviews': (_) => const ScreenDoctorReviews(),
        '/doctor/settings': (_) => const ScreenDoctorSettings(),
      },
    );
  }
}