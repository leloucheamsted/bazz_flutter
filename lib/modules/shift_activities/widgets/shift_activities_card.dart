import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/modules/home_module/widgets/bordered_icon_button.dart';
import 'package:bazz_flutter/modules/media_uploading/media_upload_service.dart';
import 'package:bazz_flutter/modules/shift_activities/models/reporting_point.dart';
import 'package:bazz_flutter/modules/shift_activities/models/shift_activity_result.dart';
import 'package:bazz_flutter/modules/shift_activities/models/shift_activity_task.dart';
import 'package:bazz_flutter/modules/shift_activities/shift_activities_service.dart';
import 'package:bazz_flutter/shared_widgets/circular_icon_button.dart';
import 'package:bazz_flutter/shared_widgets/media_upload_button.dart';
import 'package:bazz_flutter/shared_widgets/primary_button.dart';
import 'package:bazz_flutter/shared_widgets/system_dialog.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_multi_formatter/utils/unfocuser.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class ShiftActivitiesCard extends StatefulWidget {
  const ShiftActivitiesCard({
    Key? key,
    required this.activities,
    required this.rPoint,
  }) : super(key: key);

  final List<ShiftActivityTask> activities;
  final ReportingPoint rPoint;

  @override
  _ShiftActivitiesCardState createState() => _ShiftActivitiesCardState();
}

class _ShiftActivitiesCardState extends State<ShiftActivitiesCard>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _commentController = TextEditingController();
  bool commentStarVisible = false;
  ShiftActivityTask? currentActivityTask;
  ShiftActivityResult? result;

  @override
  void initState() {
    currentActivityTask = widget.activities
        .firstWhere((act) => !act.isFinished, orElse: () => null!);
    commentStarVisible = currentActivityTask!.isCommentRequired;
    result = ShiftActivityResult(taskId: currentActivityTask!.id);
    _commentController.addListener(() {
      if (_commentController.text.isNotEmpty && commentStarVisible)
        setState(() => commentStarVisible = false);
      if (_commentController.text.isEmpty && !commentStarVisible)
        setState(() => commentStarVisible = true);
    });
    super.initState();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void setIsOk(bool val) {
    setState(() {
      result!.isOk = val;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    const inputBorder = OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.inputBorder),
      borderRadius: BorderRadius.all(Radius.circular(7)),
    );
    return Unfocuser(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              children: [
                CircularIconButton(
                  buttonSize: 40,
                  onTap: () => LayoutUtils.buildDescription(
                      currentActivityTask!.description),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: SvgPicture.asset(
                      'assets/images/rp_info_icon.svg',
                      color: AppColors.primaryAccent,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    currentActivityTask!.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme().typography.bgText3Style,
                  ),
                ),
                const SizedBox(width: 5),
                if (currentActivityTask!.isCheckable) ...[
                  BorderedIconButton(
                    visualDensity: VisualDensity.compact,
                    elevation: 0,
                    border: const BorderSide(
                        color: AppColors.primaryAccent, width: 2),
                    onTap: () => setIsOk(true),
                    fillColor: result!.isOk ?? false
                        ? AppColors.primaryAccent
                        : Colors.transparent,
                    child: Text(
                      " AppLocalizations.of(context).passed.capitalize",
                      style: AppTypography.text3BaseStyle.copyWith(
                        color: result!.isOk ?? false
                            ? AppColors.brightText
                            : AppTheme().colors.bgText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  BorderedIconButton(
                    visualDensity: VisualDensity.compact,
                    elevation: 0,
                    border: const BorderSide(color: AppColors.danger, width: 2),
                    onTap: () => setIsOk(false),
                    fillColor: result!.isOk ?? true
                        ? Colors.transparent
                        : AppColors.error,
                    child: Text(
                      "AppLocalizations.of(context).failed.capitalize",
                      style: AppTypography.text3BaseStyle.copyWith(
                        color: result!.isOk ?? true
                            ? AppTheme().colors.bgText
                            : AppColors.brightText,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(7)),
                    child: Stack(
                      children: [
                        TextField(
                          enabled: true,
                          controller: _commentController,
                          scrollPhysics: const AlwaysScrollableScrollPhysics(),
                          style: AppTheme().typography.inputTextStyle,
                          decoration: InputDecoration(
                            hintText: currentActivityTask!.isCommentRequired
                                ? "AppLocalizations.of(context).commentIsMandatory"
                                : "AppLocalizations.of(context).yourComment.capitalize",
                            hintStyle: AppTheme().typography.inputTextStyle,
                            enabledBorder: inputBorder,
                            focusedBorder: inputBorder,
                            fillColor: AppTheme().colors.inputBg,
                            filled: true,
                            contentPadding: const EdgeInsets.all(5),
                          ),
                          keyboardType: TextInputType.multiline,
                          minLines: 4,
                          maxLines: 4,
                        ),
                        if (commentStarVisible)
                          const Positioned(
                            top: 3,
                            right: 3,
                            child: Icon(FontAwesomeIcons.asterisk,
                                color: AppColors.danger, size: 10),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Column(
                  children: [
                    MediaUploadButton(
                      controller: MediaUploadService.to,
                      eventId: currentActivityTask!.id,
                      isMandatory: currentActivityTask!.isMediaRequired,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: widget.activities.length > 1
                        ? _buildStepper()
                        : const SizedBox()),
                const SizedBox(width: 10),
                PrimaryButton(
                  height: 35,
                  color: AppTheme().colors.primaryButton,
                  icon: Icon(
                    currentActivityTask!.id != widget.activities.last.id
                        ? LineAwesomeIcons.angle_right
                        : LineAwesomeIcons.check,
                    color: AppColors.brightText,
                    size: 22,
                  ),
                  onTap: _validateAndSubmit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    Widget buildInnerDot(Color color) => Container(
            decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ));

    final children = widget.activities.map((act) {
      return [
        Container(
          width: 20,
          height: 20,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            border: Border.all(
              color: act.isFinished ? AppColors.primaryAccent : Colors.grey,
              width: 2,
            ),
            shape: BoxShape.circle,
          ),
          child: act.isFinished
              ? buildInnerDot(AppColors.primaryAccent)
              : act.id == currentActivityTask!.id
                  ? buildInnerDot(AppColors.secondaryButton)
                  : null,
        ),
        if (act.id != widget.activities.last.id)
          Expanded(
            child: Container(
              height: 2,
              color: act.isFinished ? AppColors.primaryAccent : Colors.grey,
            ),
          )
      ];
    });

    return Row(
      children: [for (final el in children) ...el],
    );
  }

  void _validateAndSubmit() {
    final errors = <String>[];

    final allMedia =
        MediaUploadService.to.allMediaByEventId[currentActivityTask!.id];
    final noMediaAttached = allMedia?.isEmpty ?? true;
    final isUploadDeferred =
        allMedia?.any((m) => m.isUploadDeferred()) ?? false;
    final isAllMediaUploaded = allMedia?.every((m) => m.isUploaded) ?? false;
    final switchValid =
        !currentActivityTask!.isCheckable || result!.isOk != null;
    final commentValid = !currentActivityTask!.isCommentRequired ||
        _commentController.text.length > 10;
    final mediaValid = !currentActivityTask!.isMediaRequired ||
        isUploadDeferred ||
        isAllMediaUploaded;

    final canProceed = switchValid && commentValid && mediaValid;

    if (!canProceed) {
      if (!switchValid)
        errors.add("AppLocalizations.of(context).selectPassedOrFailed");
      if (!commentValid)
        errors.add("AppLocalizations.of(context).commentCantBeEmpty");
      if (currentActivityTask!.isMediaRequired) {
        if (noMediaAttached) {
          errors.add("AppLocalizations.of(context).attachMedia");
        } else if (!isUploadDeferred && !isAllMediaUploaded) {
          errors.add("AppLocalizations.of(context).waitForMediaUpload");
        }
      }

      for (var i = 0; i < errors.length; i++) {
        errors[i] = "${i + 1}. ${errors[i]}";
      }

      SystemDialog.showConfirmDialog(message: errors.join('\n'));
      return;
    }

    ShiftActivitiesService.to!.submitActivity(
      rPoint: widget.rPoint,
      activity: currentActivityTask,
      result: result!..comment = _commentController.text,
      context: context,
    );
  }

  @override
  bool get wantKeepAlive => true;
}
