import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/alert_check_config.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/alert_check/alert_check_controller.dart';
import 'package:bazz_flutter/modules/alert_check/alert_check_service.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/home_module/widgets/custom_app_bar.dart';
import 'package:bazz_flutter/modules/home_module/widgets/notifications_drawer.dart';
import 'package:bazz_flutter/shared_widgets/loader.dart';
import 'package:bazz_flutter/shared_widgets/primary_button.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

class AlertCheckPage extends GetView<AlertCheckController> {
  const AlertCheckPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isStandardCheck = Session.shift!.alertCheckConfig!.alertCheckType ==
        AlertCheckType.standard;
    return Scaffold(
      backgroundColor: AppTheme().colors.mainBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                CustomAppBar(withBackButton: true),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(LayoutConstants.compactPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(15),
                          color: AppTheme().colors.alertCheckHeader,
                          child: isStandardCheck
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        "AppLocalizations.of(context).chooseImagesWith",
                                        style:
                                            AppTypography.bodyText3TextStyle),
                                    Text("AppLocalizations.of(context).orange",
                                        style:
                                            AppTypography.subtitle1TextStyle),
                                    // Text('Traffic Lights', style: AppTypography.subtitle1TextStyle),
                                  ],
                                )
                              : Align(
                                  child: Text(
                                  'Scan the reporting points',
                                  style: AppTheme()
                                      .typography
                                      .alertCheckTitleStyle,
                                )),
                        ),
                        const SizedBox(height: 10),
                        if (isStandardCheck)
                          Expanded(
                            child: GridView.count(
                              padding: EdgeInsets.zero,
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              crossAxisCount: 3,
                              mainAxisSpacing: 5,
                              crossAxisSpacing: 5,
                              children: controller.quizItems.map((i) {
                                return Listener(
                                  onPointerDown: (_) {
                                    i.isSelected.toggle();
                                  },
                                  child: Obx(() {
                                    return Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: i.isCorrect
                                                    ? AppColors.primaryAccent
                                                    : AppColors.error,
                                                width: i.isSelected() ? 3 : 0),
                                            borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(
                                                    i.isSelected() ? 10 : 0)),
                                          ),
                                          child: i.image,
                                        ),
                                        if (i.isSelected())
                                          Positioned(
                                            child: Container(
                                              height: 17,
                                              width: 17,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: i.isCorrect
                                                    ? AppColors.primaryAccent
                                                    : AppColors.error,
                                              ),
                                              child: Icon(
                                                i.isCorrect
                                                    ? Icons.check
                                                    : Icons.close,
                                                size: 12,
                                                color: AppColors.brightText,
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  }),
                                );
                              }).toList()
                                ..shuffle(),
                            ),
                          )
                        else
                          Expanded(
                            child: GetBuilder<AlertCheckController>(
                              builder: (_) {
                                final rPointResults =
                                    AlertCheckService.to.alertCheckRPoints;
                                return GridView.count(
                                  crossAxisCount:
                                      rPointResults.length == 1 ? 1 : 2,
                                  mainAxisSpacing: 5,
                                  crossAxisSpacing: 5,
                                  children: rPointResults.map((res) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(5),
                                      child: Material(
                                        color: res.isCheckPassed
                                            ? AppColors.primaryAccent
                                            : AppColors.error,
                                        child: InkWell(
                                          onTap: () => controller
                                              .onReportingPointPressed(context),
                                          child: Container(
                                            padding: EdgeInsets.all(
                                                rPointResults.length == 1
                                                    ? 10
                                                    : 5),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: res.isCheckPassed
                                                    ? const Color(0xFF68a138)
                                                    : const Color(0xFFb30000),
                                                width: 3,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            child: Column(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    res.rPointName,
                                                    style: AppTypography
                                                        .subtitle3TextStyle
                                                        .copyWith(
                                                      color:
                                                          AppColors.brightText,
                                                      fontSize: rPointResults
                                                                  .length ==
                                                              1
                                                          ? 20
                                                          : 15,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                FaIcon(
                                                  Icons.qr_code_rounded,
                                                  color: AppColors.brightText,
                                                  size:
                                                      rPointResults.length == 1
                                                          ? 50
                                                          : 30,
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 30),
                        if (Session.shift!.alertCheckConfig!.useFaceDetection)
                          PrimaryButton(
                            text: "AppLocalizations.of(context).detectFace",
                            onTap: controller.onFaceDetection,
                            color: AppColors.secondaryButton,
                            icon: const Image(
                              image: AssetImage('assets/images/scan_ico.png'),
                              height: 15,
                              width: 15,
                            ),
                          )
                        else
                          PrimaryButton(
                            text: "AppLocalizations.of(context).send",
                            onTap: () {
                              controller.onSendPressed();
                            },
                            icon: null as Icon,
                          ),
                        Obx(() {
                          if (controller.loadingState == ViewState.loading) {
                            Loader.show(context, themeData: null as ThemeData);
                          } else {
                            Loader.hide();
                          }
                          return const SizedBox();
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            NotificationsDrawer(controller: HomeController.to),
          ],
        ),
      ),
    );
  }
}
