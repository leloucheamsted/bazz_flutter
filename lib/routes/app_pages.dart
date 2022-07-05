import 'package:bazz_flutter/modules/alert_check/alert_check_binding.dart';
import 'package:bazz_flutter/modules/alert_check/alert_check_page.dart';
import 'package:bazz_flutter/modules/auth_module/change_password/change_password_binding.dart';
import 'package:bazz_flutter/modules/auth_module/change_password/change_password_page.dart';
import 'package:bazz_flutter/modules/auth_module/domain_module/domain_binding.dart';
import 'package:bazz_flutter/modules/auth_module/domain_module/domain_page.dart';
import 'package:bazz_flutter/modules/auth_module/face_auth_module/face_auth_binding.dart';
import 'package:bazz_flutter/modules/auth_module/face_auth_module/face_auth_page.dart';
import 'package:bazz_flutter/modules/auth_module/login_page.dart';
import 'package:bazz_flutter/modules/auth_module/sup_approval_module/sup_auth_binding.dart';
import 'package:bazz_flutter/modules/auth_module/sup_approval_module/sup_auth_page.dart';
import 'package:bazz_flutter/modules/gnss_module/gnss_binding.dart';
import 'package:bazz_flutter/modules/gnss_module/gnss_page.dart';
import 'package:bazz_flutter/modules/home_module/home_binding.dart';
import 'package:bazz_flutter/modules/home_module/home_page.dart';
import 'package:bazz_flutter/modules/auth_module/auth_binding.dart';
import 'package:bazz_flutter/modules/home_module/views/map/flutter_map_fullscreen_page.dart';
import 'package:bazz_flutter/modules/media_uploading/choose_media/choose_media_binding.dart';
import 'package:bazz_flutter/modules/media_uploading/choose_media/choose_media_page.dart';
import 'package:bazz_flutter/modules/media_uploading/preview_media/preview_media_binding.dart';
import 'package:bazz_flutter/modules/media_uploading/preview_media/preview_media_page.dart';
import 'package:bazz_flutter/modules/settings_module/settings_page.dart';
import 'package:bazz_flutter/modules/message_history/message_history_page.dart';
import 'package:bazz_flutter/modules/shift_activities/shift_activities_page.dart';
import 'package:bazz_flutter/modules/shift_activities/shift_activities_stats/shift_activities_stats_binding.dart';
import 'package:bazz_flutter/modules/shift_activities/shift_activities_stats/shift_activities_stats_page.dart';
import 'package:bazz_flutter/modules/shift_module/shift_end/shift_summary_page.dart';
import 'package:bazz_flutter/modules/shift_module/shift_start/shift_profile_binding.dart';
import 'package:bazz_flutter/modules/shift_module/shift_start/shift_profile_page.dart';
import 'package:bazz_flutter/modules/shift_module/shift_start/shift_profile_position_binding.dart';
import 'package:bazz_flutter/modules/shift_module/shift_start/shift_profile_position_page.dart';
import 'package:bazz_flutter/modules/user_profile_module/user_profile_binding.dart';
import 'package:bazz_flutter/modules/user_profile_module/user_profile_page.dart';
import 'package:bazz_flutter/modules/device_outputs_module/device_outputs_page.dart';
import 'package:bazz_flutter/modules/device_outputs_module/device_outputs_binding.dart';
import 'package:bazz_flutter/modules/statistics_module/statistics_page.dart';
import 'package:bazz_flutter/modules/statistics_module/statistics_binding.dart';
import 'package:get/get.dart';

part './app_routes.dart';

// ignore: avoid_classes_with_only_static_members
class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.settings,
      page: () => SettingsPage(),
    ),
    GetPage(
      name: AppRoutes.userProfile,
      page: () => UserProfilePage(),
      binding: UserProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.deviceOutputs,
      page: () => DeviceOutputsPage(),
      binding: DeviceOutputsBinding(),
    ),
    GetPage(
      name: AppRoutes.statistics,
      page: () => StatisticsPage(),
      binding: StatisticsBinding(),
    ),
    GetPage(
      name: AppRoutes.gnss,
      page: () => GnssPage(),
      binding: GnssBinding(),
    ),
    GetPage(
      name: AppRoutes.domain,
      page: () => DomainPage(),
      binding: DomainBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => LoginPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.faceAuth,
      page: () => FaceAuthPage(),
      binding: FaceAuthBinding(),
    ),
    GetPage(
      name: AppRoutes.shiftProfile,
      page: () => ShiftProfilePage(),
      binding: ShiftProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.shiftPositionProfile,
      page: () => ShiftProfilePositionPage(),
      binding: ShiftProfilePositionBinding(),
    ),
    GetPage(
      name: AppRoutes.shiftSummary,
      page: () => ShiftSummaryPage(),
    ),
    GetPage(
      name: AppRoutes.supervisorAuth,
      page: () => SupervisorAuthPage(),
      binding: SupervisorAuthBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => HomePage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.alertCheck,
      page: () => AlertCheckPage(),
      binding: AlertCheckBinding(),
    ),
    GetPage(
      name: AppRoutes.mapTabFullscreen,
      page: () => FlutterMapFullscreenPage(
        showBack: false,
      ),
    ),
    GetPage(
      name: AppRoutes.messageHistory,
      page: () => MessageHistoryPage(),
      // binding: MessageHistoryBinding(),
    ),
    GetPage(
      name: AppRoutes.changePassword,
      page: () => ChangePasswordPage(),
      binding: ChangePasswordBinding(),
    ),
    GetPage(
      name: AppRoutes.chooseMedia,
      page: () => ChooseMediaPage(),
      binding: ChooseMediaBinding(),
    ),
    GetPage(
      name: AppRoutes.previewMedia,
      page: () => PreviewMediaPage(),
      binding: PreviewMediaBinding(),
    ),
    GetPage(
      name: AppRoutes.shiftActivities,
      page: () => ShiftActivitiesPage(),
    ),
    GetPage(
      name: AppRoutes.shiftActivitiesStats,
      page: () => ShiftActivitiesStatsPage(),
      binding: ShiftActivitiesStatsBinding(),
    ),
  ];
}
