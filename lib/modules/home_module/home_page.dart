import 'dart:ui';

import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/chat/chat_controller.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/home_module/views/groups_view.dart';
import 'package:bazz_flutter/modules/home_module/widgets/bottom_nav_bar.dart';
import 'package:bazz_flutter/modules/home_module/widgets/custom_app_bar.dart';
import 'package:bazz_flutter/modules/home_module/widgets/notifications_drawer.dart';
import 'package:bazz_flutter/modules/settings_module/settings_controller.dart';
import 'package:bazz_flutter/routes/app_pages.dart';
import 'package:bazz_flutter/services/entities_history_tracking.dart';
import 'package:bazz_flutter/services/event_handling_service.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/shared_widgets/circular_icon_button.dart';
import 'package:bazz_flutter/shared_widgets/loader.dart';
import 'package:bazz_flutter/shared_widgets/slide_to_act.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_multi_formatter/utils/unfocuser.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:get/route_manager.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Portal(
      child: MixinBuilder<HomeController>(
          id: 'homePageScaffold',
          builder: (controller) {
            var resizeToAvoidBottomInset = true;
            final isAddEventDrawerOpen =
                Get.isRegistered<EventHandlingService>() &&
                    EventHandlingService.to!.isAddEventDrawerOpen;

            if (isAddEventDrawerOpen ||
                HomeController.to.currentBottomNavTab == BottomNavTab.ptt) {
              resizeToAvoidBottomInset = false;
            }

            return Container(
                decoration: BoxDecoration(
                  border: EntitiesHistoryTracking().trackingIsOpened
                      ? Border.all(color: AppColors.error, width: 2)
                      : Border.all(color: AppColors.error, width: 0),
                ),
                child: Scaffold(
                  backgroundColor: AppTheme().colors.mainBackground,
                  drawer: _buildDrawer(context),
                  resizeToAvoidBottomInset: resizeToAvoidBottomInset,
                  // endDrawer: _buildEndDrawer(),
                  body: SafeArea(
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            CustomAppBar(),
                            _buildTabBar(context),
                            Expanded(
                              child: TabBarView(
                                physics: const NeverScrollableScrollPhysics(),
                                controller: controller.homeTabBarController,
                                children: [
                                  Obx(() => controller.bottomNavBarTabs[
                                      controller.bottomNavBarIndex]),
                                  GroupsView(),
                                ],
                              ),
                            ),
                            GetX(
                              builder: (_) {
                                if (controller.currentState == ViewState.lock) {
                                  return const SizedBox();
                                }
                                controller.currentState =
                                    controller.loadingState;
                                if (controller.loadingState ==
                                    ViewState.initialize) {
                                  Loader.hide();
                                  Loader.show(context,
                                      text:
                                          "AppLocalizations.of(context).initializingServices",
                                      progressIndicator:
                                          const SpinKitPouringHourGlass(
                                              color:
                                                  AppColors.loadingIndicator),
                                      themeData: null as ThemeData);
                                } else if (controller.loadingState ==
                                    ViewState.loading) {
                                  Loader.hide();
                                  Loader.show(context,
                                      text:
                                          "AppLocalizations.of(context).loading",
                                      themeData: null as ThemeData);
                                } else if (controller.loadingState ==
                                    ViewState.exit) {
                                  Loader.hide();
                                  Loader.show(context,
                                      text: "Logout",
                                      themeData: null as ThemeData,
                                      progressIndicator:
                                          const SpinKitPouringHourGlass(
                                              color:
                                                  AppColors.loadingIndicator));
                                } else if (controller.loadingState ==
                                    ViewState.lock) {
                                  Loader.hide();
                                  Loader.show(context,
                                      text:
                                          "AppLocalizations.of(context).deviceIsLocked",
                                      progressIndicator:
                                          createLockWidget(context),
                                      showLogo: true,
                                      screenKeeper: true,
                                      themeData: null as ThemeData,
                                      opacity: 1.0);
                                } else {
                                  Loader.hide();
                                }
                                return const SizedBox();
                              },
                              dispose: (_) => Loader.hide(),
                            ),
                          ],
                        ),
                        Obx(() {
                          if (EntitiesHistoryTracking().trackingIsOpened) {
                            return createPlaybackTopPanel(context);
                          } else {
                            return Container();
                          }
                        }),
                        Obx(() {
                          if (EntitiesHistoryTracking().trackingIsOpened) {
                            return createPlaybackPlayer(context);
                          } else {
                            return Container();
                          }
                        }),
                        NotificationsDrawer(controller: controller),
                      ],
                    ),
                  ),
                  bottomNavigationBar: BottomNavBar(
                    // key: controller.bottomNavBarKey,
                    primaryTabController: controller.bottomNavBarController!,
                    isPrimary: true,
                  ),
                ));
          }),
    );
  }

  Widget createLockWidget(BuildContext context) {
    final GlobalKey<SlideActionState> _key = GlobalKey();
    TelloLogger().i("createLockWidget ====> ");
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return Padding(
      padding: EdgeInsets.fromLTRB(10, Get.height - 170, 10, 20),
      child: SlideAction(
        key: _key,
        onSubmit: () {
          Future.delayed(const Duration(seconds: 1), () {
            _key.currentState!.reset();
            controller.currentState = ViewState.idle;
            controller.loadingState = ViewState.idle;
          });
          SystemChrome.setPreferredOrientations([]);
        },
        sliderButtonIcon:
            const Icon(FontAwesomeIcons.lock, color: AppColors.brightIcon),
        submittedIcon:
            const Icon(FontAwesomeIcons.unlock, color: AppColors.dark3),
        innerColor: AppColors.dark3,
        outerColor: AppColors.paleGray,
        textSize: 18,
        text: " AppLocalizations.of(context).slideToUnlock",
        child: null as Widget,
      ),
    );
  }

  static Widget createPlaybackTopPanel(BuildContext context) {
    return Positioned(
        top: 55,
        left: 3,
        right: 3,
        child: Stack(children: [
          Container(
              height: 40,
              margin: const EdgeInsets.only(
                  top: LayoutConstants.trackSeekerThumbRadius),
              padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
              decoration: const BoxDecoration(
                color: AppColors.overlayBarrier,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Center(
                  child: Text(
                "Playback Mode".toUpperCase(),
                style: AppTypography.subtitle1TextStyle,
              ))),
          Positioned(
            right: -3,
            top: 5,
            child: CircularIconButton(
              onTap: () {
                EntitiesHistoryTracking().trackingIsOpened$.value =
                    !EntitiesHistoryTracking().trackingIsOpened;
              },
              buttonSize: 25,
              child: const Icon(Icons.close,
                  color: AppColors.brightText, size: 15),
            ),
          ),
        ]));
  }

  static Widget createPlaybackPlayer(BuildContext context) {
    return Positioned(
      bottom: 1,
      left: 3,
      right: 3,
      child: Obx(() {
        return Container(
            height: 25,
            decoration: const BoxDecoration(
              color: AppColors.overlayBarrier,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 3,
                ),
              ],
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      EntitiesHistoryTracking().moveBack();
                    },
                    child: EntitiesHistoryTracking().canMoveBack$.value
                        ? Icon(
                            Icons.skip_previous,
                            size: 25,
                            color: AppTheme().colors.primaryButton,
                          )
                        : const SizedBox(
                            height: 1,
                            width: 25,
                          ),
                  ),
                  const SizedBox(
                    width: 3,
                  ),
                  if (EntitiesHistoryTracking().sliderMaxValue > 0 &&
                      EntitiesHistoryTracking().sliderDivisionsValue > 0)
                    Expanded(
                        child: Slider(
                      activeColor: AppTheme().colors.primaryButton,
                      inactiveColor: AppColors.brightText.withOpacity(0.5),
                      min: EntitiesHistoryTracking().sliderMinValue,
                      max: EntitiesHistoryTracking().sliderMaxValue,
                      divisions: EntitiesHistoryTracking().sliderDivisionsValue,
                      value: EntitiesHistoryTracking().sliderValue,
                      label: EntitiesHistoryTracking().displayedSliderValue,
                      onChangeStart: (_) {},
                      onChangeEnd: (val) {
                        EntitiesHistoryTracking()
                            .trackItemOnChangeEndTimeStamp(val);
                      },
                      onChanged: (val) {
                        EntitiesHistoryTracking()
                            .trackItemOnChangeTimeStamp(val);
                      },
                    ))
                  else
                    Container(),
                  const SizedBox(
                    width: 3,
                  ),
                  GestureDetector(
                    onTap: () {
                      EntitiesHistoryTracking().moveNext();
                    },
                    child: EntitiesHistoryTracking().canMoveNext$.value
                        ? Icon(
                            Icons.skip_next,
                            size: 25,
                            color: AppTheme().colors.primaryButton,
                          )
                        : const SizedBox(
                            height: 1,
                            width: 25,
                          ),
                  ),
                  const SizedBox(
                    width: 3,
                  ),
                ]));
      }),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Stack(
          children: [
            Container(
              color: AppTheme().colors.mainBackground,
              padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
              child: Column(
                children: [
                  ClipOval(
                    child: Container(
                      height: 80,
                      width: 80,
                      color: AppTheme().colors.mainBackground,
                      child: Session.user!.avatar != ""
                          ? CachedNetworkImage(imageUrl: Session.user!.avatar)
                          : const FittedBox(
                              child: Icon(
                              Icons.account_circle,
                              color: AppColors.primaryAccent,
                              size: 80,
                            )),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${Session.user!.firstName.capitalize} ${Session.user!.lastName.capitalize}',
                    style: AppTheme()
                        .typography
                        .drawerUserNameStyle
                        .copyWith(height: 1.0, fontSize: 20),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                  Divider(color: AppTheme().colors.divider),
                  SizedBox(
                      height: Get.height - 180,
                      child: SingleChildScrollView(
                        child: IntrinsicWidth(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDrawerMenuRow(
                              FontAwesomeIcons.userAlt,
                              "AppLocalizations.of(context).userProfile",
                              () => Get.toNamed(AppRoutes.userProfile),
                            ),
                            if (Session.isSupervisor)
                              _buildDrawerMenuRow(FontAwesomeIcons.cog,
                                  "AppLocalizations.of(context).settings", () {
                                SettingsController.to!.askForTechnicianCode(
                                    () => Get.toNamed(AppRoutes.settings)!);
                              }, showBadge: true),
                            _buildDrawerMenuRow(
                              FontAwesomeIcons.history,
                              "AppLocalizations.of(context).messageHistory",
                              () => Get.toNamed(AppRoutes.messageHistory),
                            ),
                            _buildDrawerMenuRow(
                              FontAwesomeIcons.volumeUp,
                              "AppLocalizations.of(context).deviceOutputs",
                              () => Get.toNamed(AppRoutes.deviceOutputs),
                            ),
                            _buildDrawerMenuRow(
                              FontAwesomeIcons.chartLine,
                              " AppLocalizations.of(context).statistic",
                              () => Get.toNamed(AppRoutes.statistics),
                            ),
                            Obx(() {
                              return controller.isOnline
                                  ? _buildDrawerMenuRow(
                                      FontAwesomeIcons.sync,
                                      "ppLocalizations.of(context).restart",
                                      controller.resetPtt)
                                  : const SizedBox();
                            }),
                            _buildDrawerMenuRow(
                                FontAwesomeIcons.signOutAlt,
                                Session.hasShiftStarted!
                                    ? "AppLocalizations.of(context).endShift"
                                    : "AppLocalizations.of(context).logout",
                                controller.logoutFromDevice),
                          ],
                        )),
                      )),
                  const Spacer(),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Image(
                      image: AssetImage('assets/images/tello_text_logo.png'),
                      height: 30,
                    ),
                  )
                ],
              ),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: Text(
                'V${AppSettings().appVersion}',
                style: AppTheme().typography.appVersionStyle,
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Image(
                image: CachedNetworkImageProvider(AppSettings().siteLogo),
                height: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerMenuRow(IconData icon, String title, VoidCallback onTap,
      {bool showBadge = false}) {
    return InkWell(
      onTap: () {
        Get.back();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 12, 10, 12),
        child: Row(
          children: [
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 3, 5, 0),
                  child: FaIcon(
                    icon,
                    color: AppTheme().colors.icon,
                    size: 20,
                  ),
                ),
                Obx(() {
                  if (AppSettings().updatesCounter > 0 && showBadge) {
                    return Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        alignment: Alignment.center,
                        height: 15,
                        width: 15,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${AppSettings().updatesCounter}',
                          style: AppTypography.badgeCounterTextStyle,
                        ),
                      ),
                    );
                  } else {
                    return const SizedBox();
                  }
                }),
              ],
            ),
            const SizedBox(width: 20),
            Text(
              title,
              style: AppTheme().typography.drawerListItemStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final pttTabHeader = Obx(() {
      final chatTitle = Text(
        'Chat: ${ChatController.to.currentChatGroupContainer$.currentChat$.title}',
        style: AppTheme()
            .typography
            .subtitle2Style
            .copyWith(color: AppColors.secondaryAccent),
      );
      final zoneTitle = Session.user!.isCustomer!
          ? const SizedBox()
          : Obx(() {
              return Text(
                controller.activeGroup.zone?.title ??
                    "AppLocalizations.of(context).noActiveZone",
                style: AppTheme().typography.subtitle2Style,
              );
            });
      return PortalTarget(
        visible: controller.isGroupsPopupOpen(),
        portalFollower: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => controller.isGroupsPopupOpen(false),
        ),
        child: Row(
          children: [
            PortalTarget(
              visible: controller.isGroupsPopupOpen(),
              portalFollower: _buildGroupsPopup(),
              anchor: Alignment.topLeft as Anchor,
              //: Alignment.bottomLeft,
              closeDuration: const Duration(milliseconds: 100),
              child: GestureDetector(
                onTap: () {
                  if (controller.groupsWoActive.isNotEmpty)
                    controller.isGroupsPopupOpen.toggle();
                },
                child: ObxValue<RxBool>(
                  (isPressed) {
                    return Listener(
                      onPointerDown: (_) {
                        isPressed(true);
                      },
                      onPointerUp: (_) {
                        isPressed(false);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          image:
                              controller.activeGroup.image?.isNotEmpty ?? false
                                  ? DecorationImage(
                                      image: CachedNetworkImageProvider(
                                          controller.activeGroup.image!),
                                    )
                                  : null,
                          color: AppTheme().colors.mainBackground,
                          shape: BoxShape.circle,
                          boxShadow: controller.groupsWoActive.isEmpty
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 2,
                                    spreadRadius: isPressed() ? 1 : 2,
                                  ),
                                ],
                          border: Border.all(
                              color: AppTheme().colors.mainBackground,
                              width: 2),
                        ),
                        height: 46,
                        width: 46,
                        child: controller.activeGroup.image?.isNotEmpty ?? false
                            ? null
                            : const FittedBox(
                                child: Icon(
                                  Icons.group,
                                  color: AppColors.primaryAccent,
                                ),
                              ),
                      ),
                    );
                  },
                  false.obs,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: GestureDetector(
                onTap: controller.groupsWoActive.isNotEmpty &&
                        controller.homeTabBarBarIndex$() == 0
                    ? controller.isGroupsPopupOpen.toggle
                    : null,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.activeGroup.title ??
                            (Session.user!.isCustomer!
                                ? "AppLocalizations.of(context).noActiveGroup"
                                : " AppLocalizations.of(context.noActivePositions.substring(0, AppLocalizations.of(context).noActivePositions.length - 1).capitalize)"),
                        style: AppTheme()
                            .typography
                            .tabTitleStyle
                            .copyWith(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if (Get.isRegistered<ChatController>())
                        Obx(() {
                          final shouldDisplayChatTitle =
                              ChatController.to.displayChatTitle$;
                          return AnimatedCrossFade(
                            duration: const Duration(milliseconds: 200),
                            firstChild: chatTitle,
                            secondChild: zoneTitle,
                            crossFadeState: shouldDisplayChatTitle
                                ? CrossFadeState.showFirst
                                : CrossFadeState.showSecond,
                          );
                        })
                      else
                        zoneTitle,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
    return Unfocuser(
      child: Container(
        height: 60,
        color: AppTheme().colors.tabBarBackground,
        child: Stack(
          fit: StackFit.passthrough,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          width: 2, color: Colors.black.withOpacity(.05)))),
            ),
            if (Session.isNotGuard)
              TabBar(
                labelPadding: const EdgeInsets.symmetric(horizontal: 5),
                controller: controller.homeTabBarController,
                indicatorColor: AppColors.primaryAccent,
                indicator: BoxDecoration(
                  color: AppTheme().colors.selectedTab,
                  border: const Border(
                      bottom:
                          BorderSide(width: 2, color: AppColors.primaryAccent)),
                ),
                tabs: [
                  Tab(
                    child: pttTabHeader,
                  ),
                  Obx(() => Tab(
                        child: HomeController.to.groups.length > 1
                            ? Text(
                                !Session.user!.isCustomer!
                                    ? 'AppLocalizations.of(context).groups'
                                    : " AppLocalizations.of(context).positions",
                                style: AppTypography.caption2TextStyle
                                    .copyWith(color: AppColors.lightText),
                              )
                            : Text(
                                !Session.user!.isCustomer!
                                    ? " AppLocalizations.of(context).groupMembers.capitalize"
                                    : "AppLocalizations.of(context).positionMembers.capitalize",
                                style: AppTypography.caption2TextStyle
                                    .copyWith(color: AppColors.lightText),
                              ),
                      )),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: pttTabHeader,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupsPopup() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: Get.height * 0.6,
        maxWidth: Get.width * 0.6,
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: controller.isGroupsPopupOpen() ? 1 : 0,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme().colors.popupBg,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                spreadRadius: 2,
                blurRadius: 3,
              ),
            ],
            borderRadius: const BorderRadius.all(Radius.circular(7)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            itemBuilder: (_, i) {
              final group = controller.groupsWoActive[i];
              return GestureDetector(
                onTap: () {
                  controller.setActiveGroup(group);
                  controller.isGroupsPopupOpen(false);
                },
                child: SizedBox(
                  height: 45,
                  child: Row(
                    children: [
                      ClipOval(
                        child: Container(
                          height: Get.height >
                                  AppSettings().highResolutionDeviceDensity
                              ? 44
                              : 40,
                          width: Get.height >
                                  AppSettings().highResolutionDeviceDensity
                              ? 44
                              : 40,
                          color: AppTheme().colors.mainBackground,
                          child: FittedBox(
                              child: group.image != null &&
                                      group.image!.isNotEmpty
                                  ? CachedNetworkImage(imageUrl: group.image!)
                                  : const Icon(
                                      Icons.group,
                                      color: AppColors.primaryAccent,
                                    )),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                group.title!,
                                style: AppTheme()
                                    .typography
                                    .listItemTitleStyle
                                    .copyWith(height: 1.2),
                                maxLines: 1,
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GroupsView.buildChatUnseenCounter(group.id!),
                                  GroupsView.buildSOSWarning(group),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const Divider(),
            itemCount: controller.groupsWoActive.length,
          ),
        ),
      ),
    );
  }
}
