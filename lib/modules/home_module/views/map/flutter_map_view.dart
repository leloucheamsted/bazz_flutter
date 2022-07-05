// import 'package:bazz_flutter/app_theme.dart';
// import 'package:bazz_flutter/modules/home_module/views/map/flutter_map_controller.dart';
// import 'package:bazz_flutter/modules/home_module/views/map/flutter_map_helper.dart';
// import 'package:bazz_flutter/modules/home_module/widgets/history_audio_player.dart';
// import 'package:bazz_flutter/modules/home_module/widgets/bordered_icon_button.dart';
// import 'package:bazz_flutter/modules/home_module/widgets/big_round_ptt_button.dart';
// import 'package:bazz_flutter/modules/home_module/widgets/big_round_sos_button.dart';
// import 'package:bazz_flutter/shared_widgets/circular_icon_button.dart';
// import 'package:bazz_flutter/utils/flutter_custom_info_window.dart';
// import 'package:bazz_flutter/utils/utils.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// class FlutterMapView extends GetView<FlutterMapController> {
//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         Positioned.fill(
//           child: Stack(
//             children: [
//               GetBuilder<FlutterMapController>(
//                   builder: (_) {
//                     return FutureBuilder(
//                         future: controller.zoneInit.future,
//                         builder: (context, snapshot) {
//                           final Widget map =
//                               FlutterMapHelper.createFlutterMapWidget(
//                             context: context,
//                             controller: controller,
//                             zoneBounds: controller.zoneBounds,
//                           );
//
//                           return map;
//                         });
//                   },
//                   initState: (_) {},
//                   dispose: (_) {}),
//               FlutterCustomInfoWindow(
//                 key: UniqueKey(),
//                 controller: controller.customInfoWindowController,
//                 offsetLeft: GeneralUtils.isSmallScreen() ? 10 : 50,
//                 offsetTop: GeneralUtils.isSmallScreen() ? 10 : 50,
//                 height: 200,
//                 width: 250,
//               ),
//             ],
//           ),
//         ),
//         /*Positioned(
//           top: 10,
//           right: 10,
//           child: CircularIconButton(
//             color: AppColors.brightBackground,
//             onTap: controller.onFullscreenPressed,
//             buttonSize: 45,
//             child: const Icon(
//               Icons.fullscreen,
//               size: 25,
//               color: AppColors.primaryButton,
//             ),
//           ),
//         ),*/
//         Positioned(
//           top: 5,
//           left: 10,
//           child: Obx(() => SizedBox(
//                 width: 50,
//                 child: BorderedIconButton(
//                     fillColor: controller.mapType.value == "s"
//                         ? AppTheme().colors.primaryButton
//                         : AppTheme().colors.popupBg,
//                     onPressed: () {
//                       controller.onSwitchMapType('s');
//                     },
//                     child: controller.mapType.value == "s"
//                         ? const Icon(
//                             Icons.satellite_outlined,
//                             size: 25,
//                             color: AppColors.brightText,
//                           )
//                         : Icon(
//                             Icons.satellite_outlined,
//                             size: 25,
//                             color: AppTheme().colors.bgText,
//                           )),
//               )),
//         ),
//         Positioned(
//           top: 5,
//           left: 70,
//           child: Obx(() => SizedBox(
//                 width: 50,
//                 child: BorderedIconButton(
//                     fillColor: controller.mapType.value == "m"
//                         ? AppTheme().colors.primaryButton
//                         : AppColors.brightBackground,
//                     onPressed: () {
//                       controller.onSwitchMapType("m");
//                     },
//                     child: controller.mapType.value == "m"
//                         ? const Icon(
//                             Icons.map_outlined,
//                             size: 25,
//                             color: AppColors.brightBackground,
//                           )
//                         : Icon(
//                             Icons.map_outlined,
//                             size: 25,
//                             color: AppTheme().colors.primaryButton,
//                           )),
//               )),
//         ),
//         Positioned(
//           top: 5,
//           left: 130,
//           child: Obx(() => SizedBox(
//                 width: 50,
//                 child: BorderedIconButton(
//                     fillColor: AppColors.secondaryButton,
//                     onPressed: () {
//                       controller.showPerimeterTolerance$.value =
//                           !controller.showPerimeterTolerance;
//                     },
//                     child: controller.showPerimeterTolerance
//                         ? const Icon(
//                             Icons.blur_circular,
//                             size: 25,
//                             color: AppColors.brightText,
//                           )
//                         : const Icon(
//                             Icons.blur_off,
//                             size: 25,
//                             color: AppColors.brightText,
//                           )),
//               )),
//         ),
//         Obx(() => Positioned(
//               top: 5,
//               left: 190,
//               child: SizedBox(
//                   width: 50,
//                   child: BorderedIconButton(
//                       fillColor: AppColors.secondaryButton,
//                       onPressed: () {
//                         controller.showCoordinateStatus$.value =
//                             !controller.showCoordinateStatus;
//                       },
//                       child: controller.showCoordinateStatus
//                           ? const Icon(
//                               Icons.location_searching,
//                               size: 25,
//                               color: AppColors.brightText,
//                             )
//                           : const Icon(
//                               Icons.location_disabled,
//                               size: 25,
//                               color: AppColors.brightText,
//                             ))),
//             )),
//         Obx(() => Positioned(
//               bottom: controller.showPlayer ? 150 : 100,
//               right: 10,
//               child: CircularIconButton(
//                 color: AppTheme().colors.popupBg,
//                 onTap: controller.showCurrentLocation,
//                 buttonSize: 45,
//                 child: Icon(
//                   Icons.gps_fixed,
//                   size: 25,
//                   color: AppTheme().colors.bgText,
//                 ),
//               ),
//             )),
//         Obx(() => Positioned(
//               bottom: controller.showPlayer ? 150 : 100,
//               left: 10,
//               child: CircularIconButton(
//                 color: AppTheme().colors.popupBg,
//                 onTap: controller.showCurrentZone,
//                 buttonSize: 45,
//                 child: Icon(
//                   Icons.panorama_horizontal,
//                   size: 25,
//                   color: AppTheme().colors.bgText,
//                 ),
//               ),
//             )),
//         Obx(() => controller.showPlayer
//             ? Positioned(
//                 bottom: 75,
//                 left: 10,
//                 right: 10,
//                 child: HistoryAudioPlayer(
//                   onPlayerReady: controller.onPlayerReadyHandler,
//                   onClose: controller.onCloseHandler,
//                 ))
//             : Container()),
//         Positioned(
//           bottom: 20,
//           left: 10,
//           right: 10,
//           child: Row(
//             children: [
//               Expanded(
//                 child: RectPttButton(),
//               ),
//               const SizedBox(width: 15),
//               RectSosButton(),
//             ],
//           ),
//         ),
//         Obx(() => controller.showCoordinateStatus
//             ? FlutterMapHelper.createCoordinateStatus(context, controller)
//             : Container()),
//       ],
//     );
//   }
// }
