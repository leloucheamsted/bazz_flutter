import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppTheme extends GetxService {
  static final AppTheme _instance = AppTheme._();

  factory AppTheme() => _instance;

  AppTheme._();

  late AppColors colors;
  late AppTypography typography;
  late bool isDarkTheme;

  bool get isLightTheme => !isDarkTheme;

  ///Colors should be set first!
  void setTheme({required bool isDark}) {
    isDarkTheme = isDark;
    colors = AppColors(isDarkTheme: isDarkTheme);
    typography = AppTypography(isDarkTheme: isDarkTheme);
  }
}

class AppColors {
  final Color mainBackground;
  final Color tabBarBackground;
  final Color checkboxBorder;
  final Color infoWindowBg;
  final Color newEventListBg;
  final Color bottomNavBarBackground;
  final Color bottomNavBarSelectedItem;
  final Color pttBackground;
  final Color listItemBackground;
  final Color listItemBackground2;
  final Color dividerTitleBg;
  final Color popupBg;
  final Color appBar;
  final Color inputBg;
  final Color inputCursor;
  static const inputBorder = coolGray;
  final Color icon;
  final Color divider;
  final Color dividerLight = coolGray;
  final Color sosBtnBorder;
  final Color playerBtnBorder;
  final Color inputText;
  final Color bgText;
  final Color primaryButton = primaryAccent;
  static const Color secondaryButton = secondaryAccent;
  static const Color jitterChartLine = secondaryAccent;
  static const Color latencyChartLine = Colors.redAccent;
  final Color progressBar = primaryAccent;
  static const Color danger = darkRed;
  static const Color warning = orange;
  final Color disabledButton;
  static const Color playActiveButton = primaryAccent;
  static const Color greyIcon = coolGray;
  static const Color brightText = white;
  static const Color darkText = dark0;
  static const Color lightText = coolGray;
  static const Color brightBackground = white;
  static const Color offline = coolGray;
  static const Color outOfRange = danger;
  static const Color online = primaryAccent;
  final Color bottomNavBarIconColor;
  static const Color selectedTabItemIconColor = brightText;
  static const Color rPointNotStarted = grayishBrown;
  static const Color rPointInProgress = sandyYellow;
  static const Color rPointFinished = primaryAccent;
  final Color outgoingChatMsg;
  final Color outgoingQuotedMsg;
  final Color incomingChatMsg;
  final Color incomingQuotedMsg;
  final Color alertCheckHeader;
  final Color listSeparator;
  final Color selectedLI;
  final Color selectedTab;
  final Color bottomNavBarSelectedTab;
  final Color newEventDrawer;

  AppColors({required bool isDarkTheme})
      : mainBackground = isDarkTheme ? dark1 : blueishWhite,
        tabBarBackground = isDarkTheme ? dark3 : blueishWhite,
        checkboxBorder = isDarkTheme ? blueishWhite : dark3,
        infoWindowBg = isDarkTheme ? dark3 : white,
        newEventListBg = isDarkTheme ? slate : white,
        alertCheckHeader = isDarkTheme ? dark3 : primaryAccent,
        outgoingChatMsg = isDarkTheme ? darkSage : washedOutGreen,
        outgoingQuotedMsg = isDarkTheme ? pine : paleGray,
        incomingChatMsg = isDarkTheme ? slate : white,
        incomingQuotedMsg = isDarkTheme ? dark4 : paleGray,
        bottomNavBarBackground = isDarkTheme ? dark4 : primaryAccent,
        bottomNavBarSelectedItem =
            isDarkTheme ? dark1 : primaryAccent.withOpacity(0.7),
        bottomNavBarIconColor = isDarkTheme ? coolGray : white,
        pttBackground = isDarkTheme ? dark3 : white,
        listItemBackground = isDarkTheme ? dark4 : Colors.transparent,
        listItemBackground2 = isDarkTheme ? dark4 : white,
        dividerTitleBg = isDarkTheme ? dark4 : blueishWhite,
        popupBg = isDarkTheme ? dark4 : white,
        appBar = isDarkTheme ? dark2 : primaryAccent,
        inputBg = isDarkTheme ? dark4 : white,
        inputText = isDarkTheme ? white : dark0,
        bgText = isDarkTheme ? white : dark0,
        icon = isDarkTheme ? coolGray : dark0,
        disabledButton = isDarkTheme ? charcoalGrey2 : coolGray2,
        divider = isDarkTheme ? coolGray : dark0,
        sosBtnBorder = isDarkTheme ? dark4 : white,
        newEventDrawer = isDarkTheme ? dark4 : paleGray,
        playerBtnBorder = isDarkTheme ? dark1 : white,
        listSeparator = isDarkTheme ? Colors.transparent : paleGray,
        selectedLI = primaryAccent.withOpacity(0.3),
        selectedTab = primaryAccent.withOpacity(0.3),
        bottomNavBarSelectedTab =
            isDarkTheme ? primaryAccent.withOpacity(0.3) : primaryAccentLight,
        inputCursor = isDarkTheme ? white : dark0;

  static const Color dark0 = Color(0xFF1d1d1d);
  static const Color dark1 = Color(0xFF19212e);
  static const Color dark2 = Color(0xFF1f2534);
  static const Color dark3 = Color(0xFF262d3d);
  static const Color dark4 = Color(0xFF2f3748);
  static const Color charcoalGrey = Color(0xFF36404e);
  static const Color charcoalGrey2 = Color(0xff404c56);
  static const Color slate = Color(0xff444e63);
  static const Color grayishBrown = Color(0xFF515151);
  static const Color pine = Color(0xff2f4830);
  static const Color darkSage = Color(0xff446346);
  static const Color lightSage = Color(0xffd7f2c3);
  static const Color washedOutGreen = Color(0xffc3ef9e);
  static const Color coolGray = Color(0xff9ea9b2);
  static const Color coolGray2 = Color(0xFFb2bdc6);
  static const Color primaryAccent = Color(0xff6bae33);
  static const Color primaryAccentLight = Color(0xff7dc144);
  static const Color secondaryAccent = Color(0xff447ac1);
  static const Color orange = Color(0xffff7335);
  static const Color sandyYellow = Color(0xffedcc1f);
  static const Color darkRed = Color(0xffef1a1a);
  static const Color blueishWhite = Color(0xfff5f9fc);
  static const Color white = Color(0xffffffff);
  static const Color paleGray = Color(0xffdfe5f2);

  static const Color loadingIndicator = Color(0xFFffffff);
  static const Color brightIcon = Color(0xFFffffff);
  static const Color darkIcon = Color(0xff2a2828);
  static const Color secondaryText = Color(0xFF242a30);
  static const Color error = Color(0xffe21717);
  static const Color darkError = Color(0xffb50505);
  static const Color tabItemMainIcon = Color(0xffff0001);
  static const Color bottomNavBarMainButton = Color(0xFF1d61a5);
  static const Color sos = Color(0xffff0000);
  static const Color pttIdle = Color(0xFFff6c00);
  static const Color pttTransmitting = Color(0xFFff0d0d);
  static const Color pttReceiving = Color(0xFF7dc144);
  static const Color overlayBarrier = Color.fromRGBO(0, 0, 0, .6);
  static const Color alertnessFailed = Color(0xFFff5a04);
  static const Color shiftSummaryIconColor = Color(0x800D64F5);
  static const Color selectedItemIconColor = Color(0x80032A6C);
  static const Color mapMarkerPath = Colors.blue;
  static const Color qrScannerRect = Color(0xFFffc000);
  static const Color graphBorder = Color(0xffbfbfbf);
  static const Color textFieldFill = Color(0xfff1f1f1);
}

class AppTypography {
  final TextStyle authCaptionStyle;
  final TextStyle bgText1Style;
  final TextStyle bgText2Style;
  final TextStyle bgText3Style;
  final TextStyle bgText4Style;
  final TextStyle bgTitle1Style;
  final TextStyle bgTitle2Style;
  final TextStyle tabTitleStyle;
  final TextStyle tabTitle2Style =
      title2BaseStyle.copyWith(color: AppColors.lightText);
  final TextStyle listItemTitleStyle;
  final TextStyle chatMsgAuthorStyle;
  final TextStyle chatQuoteTitleStyle;
  final TextStyle bottomNavBarTitleStyle;
  final TextStyle groupSectionTitleStyle = title3BaseStyle;
  final TextStyle userIsTypingTextStyle = title3BaseStyle;
  final TextStyle drawerUserNameStyle;
  final TextStyle drawerListItemStyle;
  final TextStyle alertCheckTitleStyle =
      title1BaseStyle.copyWith(color: AppColors.brightText);
  final TextStyle memberNameStyle;
  final TextStyle reportEntryNameStyle;
  final TextStyle reportEntryValueStyle;
  final inputTextStyle =
      text3BaseStyle.copyWith(color: AppTheme().colors.inputText);
  final appVersionStyle = text3BaseStyle.copyWith(color: AppColors.lightText);

  final eventTitleStyle = title3BaseStyle.copyWith(color: AppColors.lightText);
  final appbarTextStyle =
      headline2BaseStyle.copyWith(color: AppColors.brightText);
  final buttonTextStyle = text3BaseStyle.copyWith(color: AppColors.brightText);
  final emptyGroupSectionPlaceholderStyle =
      text3BaseStyle.copyWith(color: AppColors.lightText);
  final errorTextStyle = text4BaseStyle.copyWith(color: AppColors.danger);
  final activityStatusTextStyle =
      text3BaseStyle.copyWith(color: AppColors.brightText);
  final dialogTitleStyle =
      title2BaseStyle.copyWith(color: AppColors.brightText);
  final subtitle2Style =
      subtitle2BaseStyle.copyWith(color: AppColors.lightText);
  final verticalCaptionStyle =
      subtitle2BaseStyle.copyWith(color: AppColors.lightText);
  final subtitle1Style =
      subtitle1BaseStyle.copyWith(color: AppColors.lightText);
  final TextStyle memberInfoWindowTextStyle;
  final memberInfoWindowText2Style =
      text5BaseStyle.copyWith(color: AppColors.lightText);

  AppTypography({required bool isDarkTheme})
      : authCaptionStyle = text1BaseStyle.copyWith(
            color: isDarkTheme ? AppColors.brightText : AppColors.darkText),
        bgText1Style = text1BaseStyle.copyWith(
            color: isDarkTheme ? AppColors.brightText : AppColors.darkText),
        bgText2Style = text2BaseStyle.copyWith(
            color: isDarkTheme ? AppColors.brightText : AppColors.darkText),
        bgText3Style = text3BaseStyle.copyWith(
            color: isDarkTheme ? AppColors.brightText : AppColors.darkText),
        bgText4Style = text4BaseStyle.copyWith(
            color: isDarkTheme ? AppColors.brightText : AppColors.darkText),
        bgTitle1Style = title1BaseStyle.copyWith(
            color: isDarkTheme ? AppColors.brightText : AppColors.darkText),
        bgTitle2Style = title2BaseStyle.copyWith(
            color: isDarkTheme ? AppColors.brightText : AppColors.darkText),
        tabTitleStyle = headline3BaseStyle.copyWith(
            color: isDarkTheme ? AppColors.brightText : AppColors.darkText),
        memberNameStyle = subtitle2BaseStyle.copyWith(
            color: isDarkTheme ? AppColors.brightText : AppColors.darkText,
            height: 1),
        listItemTitleStyle = title3BaseStyle.copyWith(
            color: isDarkTheme ? AppColors.brightText : AppColors.darkText),
        reportEntryNameStyle = text2BaseStyle.copyWith(
            color: isDarkTheme ? AppColors.brightText : AppColors.darkText),
        reportEntryValueStyle = title2BaseStyle.copyWith(
            color: isDarkTheme ? AppColors.brightText : AppColors.darkText),
        chatMsgAuthorStyle = title3BaseStyle.copyWith(
          color: isDarkTheme ? AppColors.brightText : AppColors.darkText,
          height: 1.2,
        ),
        chatQuoteTitleStyle = title4BaseStyle.copyWith(
            color: isDarkTheme ? AppColors.brightText : AppColors.darkText),
        bottomNavBarTitleStyle = text4BaseStyle.copyWith(
            color: isDarkTheme ? AppColors.coolGray : AppColors.brightText),
        memberInfoWindowTextStyle = title5BaseStyle.copyWith(
            color: isDarkTheme ? AppColors.brightText : AppColors.darkText),
        drawerUserNameStyle = headline1BaseStyle.copyWith(
            color: isDarkTheme ? AppColors.brightText : AppColors.darkText),
        drawerListItemStyle = title1BaseStyle.copyWith(
            color: isDarkTheme ? AppColors.brightText : AppColors.darkText);

  static const headline1BaseStyle = TextStyle(
    fontSize: 26.0,
    fontWeight: FontWeight.w700,
  );

  static const headline2BaseStyle = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w700,
  );

  static const headline3BaseStyle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w700,
  );

  static const title1BaseStyle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
  );

  static const title2BaseStyle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
  );

  static const title3BaseStyle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
  );

  static const title4BaseStyle = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
  );

  static const title5BaseStyle = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.w600,
  );

  static const subtitle1BaseStyle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
  );

  static const subtitle2BaseStyle = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
  );

  static const text1BaseStyle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w400,
  );

  static const text2BaseStyle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
  );

  static const text3BaseStyle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
  );

  static const text4BaseStyle = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
  );

  static const text5BaseStyle = TextStyle(
    fontSize: 10.0,
    fontWeight: FontWeight.w400,
  );

  static const badgeCounterTextStyle = TextStyle(
    fontSize: 9.0,
    color: AppColors.brightText,
    fontWeight: FontWeight.w500,
  );

  //the following styles need to be removed if aren't used

  static const bodyText7TextStyle = TextStyle(
    fontSize: 16.0,
    color: Colors.black,
    fontWeight: FontWeight.w600,
  );
  static const headline6TextStyle = TextStyle(
    fontSize: 25.0,
    color: AppColors.darkText,
    fontWeight: FontWeight.w700,
  );
  static const subtitleChatViewersTextStyle = TextStyle(
    fontSize: 18.0,
    color: AppColors.brightText,
    fontWeight: FontWeight.w600,
  );
  static const subtitle1TextStyle = TextStyle(
    fontSize: 22.0,
    color: AppColors.brightText,
    fontWeight: FontWeight.w800,
  );
  static const appBarTextStyle = TextStyle(
    fontSize: 20.0,
    color: AppColors.brightText,
    fontWeight: FontWeight.w600,
  );
  static const appBarTextStyle1 = TextStyle(
    fontSize: 11.0,
    color: AppColors.brightText,
    fontWeight: FontWeight.w500,
    backgroundColor: Colors.orange,
  );
  static const subtitle2TextStyle = TextStyle(
    fontSize: 15.0,
    color: AppColors.secondaryText,
    fontWeight: FontWeight.w600,
  );
  static const subtitleChatTextStyle = TextStyle(
    fontSize: 10.0,
    color: AppColors.selectedItemIconColor,
    fontWeight: FontWeight.w800,
  );
  static const subtitle2ChatTextStyle = TextStyle(
    fontSize: 10.0,
    color: AppColors.secondaryText,
    fontWeight: FontWeight.w600,
  );
  static const subtitle3TextStyle = TextStyle(
    fontSize: 15.0,
    color: AppColors.darkText,
    fontWeight: FontWeight.w400,
  );
  static const subtitle4TextStyle = TextStyle(
    fontSize: 15.0,
    color: AppColors.brightText,
    fontWeight: FontWeight.w600,
  );
  static const subtitleSelectedPositionTextStyle = TextStyle(
    fontSize: 16.0,
    color: AppColors.darkText,
    fontWeight: FontWeight.w600,
  );
  static const subtitle5TextStyle = TextStyle(
    fontSize: 14.0,
    color: AppColors.darkText,
    fontWeight: FontWeight.w600,
  );
  static const subtitleSelectedItemTextStyle = TextStyle(
    fontSize: 14.0,
    color: AppColors.selectedItemIconColor,
    fontWeight: FontWeight.w600,
  );
  static const subtitlePositionDistanceTextStyle = TextStyle(
    fontSize: 14.0,
    color: AppColors.error,
    fontWeight: FontWeight.w600,
  );
  static const subtitle6TextStyle = TextStyle(
    fontSize: 20.0,
    color: AppColors.brightText,
    fontWeight: FontWeight.w600,
  );
  static const subtitle7TextStyle = TextStyle(
    fontSize: 16.0,
    color: AppColors.brightText,
    fontWeight: FontWeight.w600,
  );
  static const captionTextStyle = TextStyle(
    fontSize: 16.0,
    color: AppColors.brightText,
    fontWeight: FontWeight.w700,
  );
  static const caption2TextStyle = TextStyle(
    fontSize: 15.0,
    color: AppColors.darkText,
    fontWeight: FontWeight.w700,
  );
  static const timerTextStyle = TextStyle(
    fontSize: 15.0,
    color: AppColors.darkText,
    fontWeight: FontWeight.w700,
  );
  static const appBarTimerTextStyle = TextStyle(
    fontSize: 14.0,
    color: AppColors.brightText,
    fontWeight: FontWeight.w600,
    fontFamily: 'Poppins',
  );
  static const bodyText2TextStyle = TextStyle(
    fontSize: 12.0,
    color: AppColors.lightText,
    fontWeight: FontWeight.w400,
  );
  static const linkTextStyle = TextStyle(
    fontSize: 14.0,
    color: AppColors.darkText,
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.underline,
  );
  static const bodyUserTypingStyleStyle = TextStyle(
    fontSize: 14.0,
    color: AppColors.lightText,
    fontWeight: FontWeight.w600,
  );
  static const bodyText5TextStyle = TextStyle(
    fontSize: 12.0,
    color: AppColors.lightText,
    fontWeight: FontWeight.w600,
  );
  static const bottomToolbarTextStyle = TextStyle(
    fontSize: 9.0,
    color: AppColors.brightText,
    fontWeight: FontWeight.w400,
  );
  static const markerCaptionTextStyle = TextStyle(
    fontSize: 28.0,
    color: AppColors.darkText,
    fontWeight: FontWeight.w500,
  );
  static const distanceCaptionTextStyle = TextStyle(
    fontSize: 28.0,
    color: AppColors.error,
    fontWeight: FontWeight.w600,
  );
  static const bodyText3TextStyle = TextStyle(
    fontSize: 12.0,
    color: AppColors.brightText,
    fontWeight: FontWeight.w400,
  );
  static const bodyText4TextStyle = TextStyle(
    fontSize: 10.0,
    color: AppColors.darkText,
    fontWeight: FontWeight.w400,
  );
  static const bodyText8TextStyle = TextStyle(
    fontSize: 12.0,
    color: AppColors.darkText,
    fontWeight: FontWeight.w400,
  );

  static const bodyText6TextStyle = TextStyle(
    fontSize: 9.0,
    color: AppColors.darkText,
    fontWeight: FontWeight.w600,
  );
  static const groupUnitTitleStyle = TextStyle(
    fontSize: 12.0,
    color: AppColors.darkText,
    fontWeight: FontWeight.w700,
  );
  static const chatIncomingMessageTitle = TextStyle(
    fontSize: 14.0,
    color: AppColors.darkText,
    fontWeight: FontWeight.w600,
  );
}
