import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/group_model.dart';
import 'package:bazz_flutter/modules/chat/chat_controller.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/home_module/widgets/big_round_ptt_button.dart';
import 'package:bazz_flutter/modules/home_module/widgets/big_round_sos_button.dart';
import 'package:bazz_flutter/modules/home_module/widgets/group_member.dart';
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/shared_widgets/badge_counter.dart';
import 'package:bazz_flutter/shared_widgets/material_bazz_text_input.dart';
import 'package:bazz_flutter/shared_widgets/section_divider.dart';
import 'package:bazz_flutter/shared_widgets/tello_divider.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';

class GroupsView extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          BazzMaterialTextInput(
            controller: controller.searchInputCtrl,
            placeholder: "AppLocalizations.of(context).filter",
            height: 45,
            prefixIcon: const Icon(Icons.search_rounded),
          ),
          const TelloDivider(),
          if (HomeController.to.groups.length == 1)
            Expanded(
              child: SingleChildScrollView(
                  child: Column(
                children: [
                  ExpandableGroup(
                      controller: controller, group: controller.activeGroup),
                  const SizedBox(
                      height: LayoutConstants.pttSosBottomPanelHeight + 0.5),
                ],
              )),
            )
          else
            Expanded(
              child: Obx(() {
                return ListView.separated(
                  padding: const EdgeInsets.only(
                      bottom: LayoutConstants.pttSosBottomPanelHeight),
                  itemBuilder: (_, i) => Column(
                    children: [
                      ExpandableGroup(
                          controller: controller,
                          index: i,
                          group: controller.groups[i]),
                      if (i + 1 == controller.groups.length)
                        const TelloDivider(),
                    ],
                  ),
                  separatorBuilder: (_, __) => const TelloDivider(),
                  itemCount: controller.groups.length,
                );
              }),
            )
        ]),
        //const SizedBox(height: 2),
        Positioned(
            bottom: 0, left: 0, right: 0, child: _buildPttSosBottomPanel())
      ],
    );
  }

  Widget _buildPttSosBottomPanel() {
    return Container(
      height: LayoutConstants.pttSosBottomPanelHeight,
      decoration: BoxDecoration(
        color: AppTheme().colors.newEventDrawer.withOpacity(0.7),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            spreadRadius: 2,
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          BigRoundPttButton(
            semiTransparent: true,
          ),
          BigRoundSosButton(
            semiTransparent: true,
          ),
        ],
      ),
    );
  }

  static Widget buildChatUnseenCounter(String groupId) {
    return Get.isRegistered<ChatController>()
        ? Obx(() {
            final totalUnseen = ChatController.to.getUnseenForGroup(groupId);
            if (totalUnseen == 0) return const SizedBox();

            return Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Stack(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 4, top: 2),
                    child: Icon(
                      Icons.mail_outline_rounded,
                      color: AppColors.primaryAccent,
                      size: 22,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: BadgeCounter(totalUnseen.toString()),
                  ),
                ],
              ),
            );
          })
        : const SizedBox();
  }

  static Widget buildSOSWarning(RxGroup group) {
    return Obx(() {
      return group.hasSos
          ? Container(
              margin: const EdgeInsets.only(right: 5),
              alignment: Alignment.center,
              height: 20,
              width: 20,
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              child: Text('SOS',
                  style: AppTypography.badgeCounterTextStyle
                      .copyWith(fontSize: 8)),
            )
          : const SizedBox();
    });
  }
}

class ExpandableGroup extends StatelessWidget {
  ExpandableGroup({
    Key? key,
    required this.controller,
    required this.group,
    this.index,
  }) : super(key: key);

  final HomeController controller;
  final int? index;
  final RxGroup group;
  final _expandableController = ExpandableController();

  final _membersRowHeight = 65.0;
  final _verticalCaptionWidth = 15.0;

  @override
  Widget build(BuildContext context) {
    _expandableController.expanded = HomeController.to.groups.length == 1 ||
        group.id == HomeController.to.activeGroup.id;
    return ExpandableNotifier(
      controller: _expandableController,
      child: ScrollOnExpand(
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 5, 0, 5),
          color: AppTheme().colors.listItemBackground,
          child: Expandable(
            collapsed: buildGroupHeader(),
            expanded: Column(
              children: [
                buildGroupHeader(),
                GetBuilder<HomeController>(
                    id: 'groupMembersOf${group.id}',
                    builder: (_) {
                      return Column(
                        children: [
                          TitledDivider(
                            indent: 0,
                            text: LocalizationService().of().active.capitalize,
                            textColor: AppColors.online,
                            dividerColor: Colors.black,
                            dividerTitleBg: Colors.white,
                          ),
                          ..._buildActiveSection(),
                          TitledDivider(
                            indent: 0,
                            text:
                                LocalizationService().of().notActive.capitalize,
                            textColor: AppColors.offline,
                            dividerColor: Colors.black,
                            dividerTitleBg: Colors.white,
                          ),
                          ..._buildInactiveSection(),
                          TitledDivider(
                            indent: 0,
                            text: LocalizationService()
                                .of()
                                .outOfRange
                                .capitalize,
                            textColor: AppColors.outOfRange,
                            dividerColor: Colors.black,
                            dividerTitleBg: Colors.white,
                          ),
                          _buildOutOfRangeSection(),
                          TitledDivider(
                            indent: 0,
                            text: LocalizationService()
                                .of()
                                .alertnessFailed
                                .capitalize,
                            textColor: AppColors.alertnessFailed,
                            dividerColor: Colors.black,
                            dividerTitleBg: Colors.white,
                          ),
                          _buildAlertnessFailedSection(),
                          TitledDivider(
                            indent: 0,
                            text:
                                LocalizationService().of().operators.capitalize,
                            textColor: AppColors.white,
                            dividerColor: Colors.black,
                            dividerTitleBg: Colors.white,
                          ),
                          _buildOperatorsSection(),
                        ],
                      );
                    }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActiveSection() {
    return [
      Row(
        crossAxisAlignment: group.members.activeFilteredUsers.isEmpty
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          RotatedBox(
              quarterTurns: 1,
              child: SizedBox(
                height: _verticalCaptionWidth,
                child: Text(
                  LocalizationService().of().users.toUpperCase(),
                  style: AppTheme().typography.verticalCaptionStyle,
                ),
              )),
          Expanded(
            child: group.members.activeFilteredUsers.isEmpty
                ? Padding(
                    padding: EdgeInsets.only(right: _verticalCaptionWidth),
                    child: Center(
                      child: Text(
                        LocalizationService()
                            .of()
                            .noActiveUsers
                            .capitalizeFirst,
                        style: AppTypography.bodyText2TextStyle,
                      ),
                    ),
                  )
                : SizedBox(
                    height: _membersRowHeight,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (_, i) {
                        final user = group.members.activeFilteredUsers[i];
                        return GroupMember.buildUser(
                          user: user,
                          onTap: () => HomeController.to.showUserInfo(user),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 5),
                      itemCount: group.members.activeFilteredUsers.length,
                    ),
                  ),
          ),
        ],
      ),
      Divider(indent: 15, endIndent: 25, color: AppTheme().colors.divider),
      Row(
        crossAxisAlignment: group.members.activeFilteredPositions.isEmpty
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          RotatedBox(
              quarterTurns: 1,
              child: Text(
                LocalizationService().of().positions.toUpperCase(),
                style: AppTheme().typography.verticalCaptionStyle,
              )),
          Expanded(
            child: group.members.activeFilteredPositions.isEmpty
                ? Padding(
                    padding: EdgeInsets.only(right: _verticalCaptionWidth),
                    child: Center(
                      child: Text(
                        LocalizationService()
                            .of()
                            .noActivePositions
                            .capitalizeFirst,
                        style: AppTheme()
                            .typography
                            .emptyGroupSectionPlaceholderStyle,
                      ),
                    ),
                  )
                : SizedBox(
                    height: _membersRowHeight,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (_, i) {
                        final position =
                            group.members.activeFilteredPositions[i];
                        return GroupMember.buildPosition(
                          position: position,
                          onTap: () =>
                              HomeController.to.showPositionInfo(position),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 5),
                      itemCount: group.members.activeFilteredPositions.length,
                    ),
                  ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildInactiveSection() {
    return [
      Row(
        crossAxisAlignment: group.members.notActiveFilteredUsers.isEmpty
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          RotatedBox(
              quarterTurns: 1,
              child: Text(
                LocalizationService().of().users.toUpperCase(),
                style: AppTheme().typography.verticalCaptionStyle,
              )),
          Expanded(
            child: group.members.notActiveFilteredUsers.isEmpty
                ? Padding(
                    padding: EdgeInsets.only(right: _verticalCaptionWidth),
                    child: Center(
                      child: Text(
                        LocalizationService()
                            .of()
                            .noInactiveUsers
                            .capitalizeFirst,
                        style: AppTheme()
                            .typography
                            .emptyGroupSectionPlaceholderStyle,
                      ),
                    ),
                  )
                : SizedBox(
                    height: _membersRowHeight,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (_, i) {
                        final user = group.members.notActiveFilteredUsers[i];
                        return GroupMember.buildUser(
                          user: user,
                          onTap: () => HomeController.to.showUserInfo(user),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 5),
                      itemCount: group.members.notActiveFilteredUsers.length,
                    ),
                  ),
          ),
        ],
      ),
      Divider(indent: 15, endIndent: 25, color: AppTheme().colors.divider),
      Row(
        crossAxisAlignment: group.members.notActiveFilteredPositions.isEmpty
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          RotatedBox(
              quarterTurns: 1,
              child: Text(
                LocalizationService().of().positions.toUpperCase(),
                style: AppTheme().typography.verticalCaptionStyle,
              )),
          Expanded(
            child: group.members.notActiveFilteredPositions.isEmpty
                ? Padding(
                    padding: EdgeInsets.only(right: _verticalCaptionWidth),
                    child: Center(
                      child: Text(
                        LocalizationService()
                            .of()
                            .noInactivePositions
                            .capitalizeFirst,
                        style: AppTheme()
                            .typography
                            .emptyGroupSectionPlaceholderStyle,
                      ),
                    ),
                  )
                : SizedBox(
                    height: _membersRowHeight,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (_, i) {
                        final position =
                            group.members.notActiveFilteredPositions[i];
                        return GroupMember.buildPosition(
                          position: position,
                          onTap: () =>
                              HomeController.to.showPositionInfo(position),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 5),
                      itemCount:
                          group.members.notActiveFilteredPositions.length,
                    ),
                  ),
          ),
        ],
      ),
    ];
  }

  Widget _buildAlertnessFailedSection() {
    return Row(
      crossAxisAlignment: group.members.alertnessFailedFiltered.isEmpty
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        RotatedBox(
            quarterTurns: 1,
            child: Text(
              LocalizationService().of().positions.toUpperCase(),
              style: AppTheme().typography.verticalCaptionStyle,
            )),
        Expanded(
          child: group.members.alertnessFailedFiltered.isEmpty
              ? Padding(
                  padding: EdgeInsets.only(right: _verticalCaptionWidth),
                  child: Center(
                    child: Text(
                      LocalizationService()
                          .of()
                          .noInattentivePositions
                          .capitalizeFirst,
                      style: AppTheme()
                          .typography
                          .emptyGroupSectionPlaceholderStyle,
                    ),
                  ),
                )
              : SizedBox(
                  height: _membersRowHeight,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (_, i) {
                      final position = group.members.alertnessFailedFiltered[i];
                      return GroupMember.buildPosition(
                        position: position,
                        onTap: () =>
                            HomeController.to.showPositionInfo(position),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 5),
                    itemCount: group.members.alertnessFailedFiltered.length,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildOperatorsSection() {
    return Row(
      crossAxisAlignment: group.members.alertnessFailedFiltered.isEmpty
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        RotatedBox(
            quarterTurns: 1,
            child: Text(
              LocalizationService().of().operators.toUpperCase(),
              style: AppTheme().typography.verticalCaptionStyle,
            )),
        Expanded(
          child: HomeController.to.adminUsers.isEmpty
              ? Padding(
                  padding: EdgeInsets.only(right: _verticalCaptionWidth),
                  child: Center(
                    child: Text(
                      LocalizationService()
                          .of()
                          .noInattentivePositions
                          .capitalizeFirst,
                      style: AppTheme()
                          .typography
                          .emptyGroupSectionPlaceholderStyle,
                    ),
                  ),
                )
              : SizedBox(
                  height: _membersRowHeight,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (_, i) {
                      final user = HomeController.to.adminUsers[i];
                      return GroupMember.buildUser(
                        user: user,
                        onTap: () => HomeController.to.showUserInfo(user),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 5),
                    itemCount: HomeController.to.adminUsers.length,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildOutOfRangeSection() {
    return Row(
      crossAxisAlignment: group.members.outOfRangeFiltered.isEmpty
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        RotatedBox(
            quarterTurns: 1,
            child: Text(
              LocalizationService().of().positions.toUpperCase(),
              style: AppTheme().typography.verticalCaptionStyle,
            )),
        Expanded(
          child: group.members.outOfRangeFiltered.isEmpty
              ? Padding(
                  padding: EdgeInsets.only(right: _verticalCaptionWidth),
                  child: Center(
                    child: Text(
                      LocalizationService()
                          .of()
                          .nobodyOutOfRange
                          .capitalizeFirst,
                      style: AppTheme()
                          .typography
                          .emptyGroupSectionPlaceholderStyle,
                    ),
                  ),
                )
              : SizedBox(
                  height: _membersRowHeight,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (_, i) {
                      final position = group.members.outOfRangeFiltered[i];
                      return GroupMember.buildPosition(
                        position: position,
                        onTap: () =>
                            HomeController.to.showPositionInfo(position),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 5),
                    itemCount: group.members.outOfRangeFiltered.length,
                  ),
                ),
        ),
      ],
    );
  }

  Widget buildGroupHeader() {
    if (HomeController.to.groups.length == 1) {
      return Container();
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Obx(() {
                      return Container(
                        height: 14,
                        width: 14,
                        decoration: BoxDecoration(
                          color: group.isReceiving()
                              ? AppColors.pttReceiving
                              : AppColors.pttIdle,
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          group.title!,
                          style: AppTheme().typography.bgTitle2Style,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
                Obx(() {
                  final timeAndUnit =
                      timeAndUnitFromSeconds(group.lastMessageAt!());
                  return timeAndUnit != null
                      ? Text(
                          'Last message ${timeAndUnit.time} ${timeAndUnit.unit} ago',
                          style: AppTypography.bodyText2TextStyle,
                        )
                      : const SizedBox();
                }),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  GroupsView.buildChatUnseenCounter(group.id!),
                  GroupsView.buildSOSWarning(group),
                  GestureDetector(
                    onTapUp: (_) {
                      if (index != null)
                        controller.setActiveGroup(controller.groups[index!]);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: ClipOval(
                        child: Obx(() {
                          final isSelected =
                              group.id == controller.activeGroup.id;
                          return Container(
                            height: 25,
                            width: 25,
                            color: isSelected
                                ? AppTheme().colors.primaryButton
                                : AppTheme()
                                    .colors
                                    .primaryButton
                                    .withOpacity(.2),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: AppColors.brightText,
                                  )
                                : null,
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.lightText),
            onPressed: () {
              _expandableController.expanded = !_expandableController.expanded;
            },
            splashColor: Colors.transparent,
            // onPressed: _expandableController.expanded(_expandableController.value),
          ),
        ],
      );
    }
  }
}
