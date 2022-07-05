//TODO: refactor to Prefs, and manipulate local storage directly, with separate keys
import 'dart:async';
import 'dart:convert';

import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/coordinates_model.dart';
import 'package:bazz_flutter/models/events_settings.dart';
import 'package:bazz_flutter/models/logger_config.dart';
import 'package:bazz_flutter/models/rating_color_config.dart';
import 'package:bazz_flutter/models/services_address.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/general/general_repo.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
// import 'package:package_info/package_info.dart';
import 'package:package_info/package_info.dart';

//TODO: check and refactor all durations to seconds, there are a lot of them in minutes
class AppSettings {
  static final AppSettings _instance = AppSettings._();

  factory AppSettings() => _instance;

  AppSettings._();

  Completer isUpdated = Completer();

  bool get updateCompleted => isUpdated.isCompleted;

  bool get updateNotCompleted => !updateCompleted;

  void resetIsUpdatedCompleter() => isUpdated = Completer();

  late EventsSettings eventSettings;

  bool get hasEventSettings => eventSettings != null;

  bool get hasNoEventSettings => !hasEventSettings;

  Future<void> updateEventSettings(EventsSettings settings) async {
    if (hasNoEventSettings) {
      eventSettings = settings;
    } else {
      eventSettings.update(settings);
    }
    await eventSettings.processIcons();
  }

  late String baseUrl;
  late String simSerial;
  late String _version;
  late String _clientVersion = "---";
  late String _clientBuildNumber = "---";
  late String _apkUrl = '';
  late String _mediaWsUrl;
  late String _eventWsUrl;
  late String _videoWsUrl = 'https://services.dev.bazzptt.com:8086';
  late String _chatWsUrl = 'https://services.dev.bazzptt.com:8087';
  late String _externalTileServerUrl = 'https://{s}.tile.openstreetmap.org/';
  late String _loginPageImage;
  late String _siteLogo;

  late DeviceStatus _deviceStatusConfig;

  bool _isProduction = false;
  bool _useKalmanFilterForGPS = true;
  bool _useStillActivitiesForGPS = false;
  late bool _isDarkTheme;
  late bool _videoModeEnabled;
  late bool _showNetworkJitter;
  bool _verifyUserLocationForPositionShift = true;
  bool _ignoreActiveSession = true;
  bool _enableRemoteDebuggingLogger = false;
  bool _enableHistoryTracking = true;
  bool _faceDetectionForLogin = false;
  bool _enableMobileKioskMode = false;
  bool _enableMobileScreenLock = false;
  bool _forceAndroidLocationManager = true;
  bool _cacheMapTiles = true;
  bool _enableActivityTracking = true;
  bool _isNfcLoginEnabled = true;
  bool _detectSinglePositionAssignment = true;
  bool _enableVideoChatService = false;
  int _stillActivityDuration = 180;
  int _locationMovementPauseDuration = 180;
  int _userNameMinLen = 5;
  int _passwordMinLen = 5;
  int _positionSearchMaxRadius = 1000;
  int _positionSearchMinRadius = 5;

  double _screenBrightness = 0.5;
  late double _maxMapZoomLevel;
  late double _minMapZoom;

  late double _maxNativeMapZoomLevel;
  late double _minNativeMapZoom;
  double _minLabelShowingZoom = 16.0;
  int _getCurrentPositionTimeout = 10;

  SosMode _sosMode = SosMode.Silence;
  final int _outOfRangeDisplayElapsedPeriod = 120;
  int _sendEventTimeout = 5;
  final _socketTimeout = 5;
  int _sendRestRequestTimeout = 300;
  int _sendTransportTimeoutInMilliseconds = 10000;
  int _switchToPrimaryGroupTimeoutSec = 60;
  int _heartbeatPeriod = 10;
  int _videoSocketRecoveryPeriod = 3;
  int _chatSocketRecoveryPeriod = 3;
  int _signalingSocketRecoveryPeriod = 2;
  int _lastMessageAtRefreshPeriod = 10;
  final int _batteryLevelPeriod = 2;
  int _locationUpdatePeriod = 2;
  int _createTransportsPeriod = 2;
  int _audioMessageLifePeriod = 60;
  int _audioMessageDebugLifePeriod = 10;
  int _positionRangeAlertDuration = 5;
  int _positionRangeMessagePeriod = 30;
  int _sosAutoBroadcastPeriod = 10;
  int _pttBroadcastTimeoutDuration = 30;
  int _clearLastKnownLocationPeriod = 300;
  double _maxVolumeOnMobileDevice = 0.7;
  String _dateTimeFormat = 'MM-dd-yyyy HH:mm';
  late String _dateFormat;
  String _dateTimeFormatShort = 'MMM d, HH:mm';
  String _timeFormat = "HH:mm";
  String _languageCode = "en";
  String _fullTimeFormat = "HH:mm:ss";
  final RxString _appVersion = "".obs;
  Coordinates _initialMapCoordinates =
      Coordinates(latitude: 4.274711, longitude: 11.429955);
  int _highResolutionDeviceDensity = 710;
  int _audioMessageRetainThresholdMs = 500;
  late int _maxMediaToAdd;
  late int _maxVideoDurationSec;
  String _technicianCode = "tech123";
  RxInt updatesCounter$ = 0.obs;
  late int _reportingPointLocationTolerance;
  late int _shiftInterruptedThresholdSec;
  late double _pingIntervalSec;
  late List<RatingColorConfig> _ratingColorSettings;
  late LoggerConfig _loggerConfig;

  List<RatingColorConfig> get ratingColorSettings => _ratingColorSettings;

  LoggerConfig get loggerConfig => _loggerConfig;

  bool get initialized => baseUrl != null;

  bool get notInitialized => !initialized;

  int get updatesCounter => updatesCounter$.value;

  double get minMapZoom => _minMapZoom;

  double get maxMapZoomLevel => _maxMapZoomLevel;

  double get minNativeMapZoom => _minNativeMapZoom;

  double get maxNativeMapZoomLevel => _maxNativeMapZoomLevel;

  double get pingIntervalSec => _pingIntervalSec;

  int get reportingPointLocationTolerance => _reportingPointLocationTolerance;

  int get shiftInterruptedThresholdSec => _shiftInterruptedThresholdSec;

  int get maxMediaToAdd => _maxMediaToAdd;

  int get outOfRangeDisplayElapsedPeriod => _outOfRangeDisplayElapsedPeriod;

  int get maxVideoDurationSec => _maxVideoDurationSec;

  int get pttBroadcastTimeoutDuration => _pttBroadcastTimeoutDuration;

  DeviceStatus get deviceStatusConfig => _deviceStatusConfig;

  bool get isCustomer => deviceStatusConfig == DeviceStatus.notRecognized;

  bool get isNotCustomer => deviceStatusConfig == DeviceStatus.recognized;

  bool get forceAndroidLocationManager => _forceAndroidLocationManager;

  bool get isNfcLoginEnabled => _isNfcLoginEnabled;

  bool get enableVideoChatService => _enableVideoChatService;

  bool get detectSinglePositionAssignment => _detectSinglePositionAssignment;

  bool get enableActivityTracking => _enableActivityTracking;

  bool get videoModeEnabled => _videoModeEnabled;

  int get stillActivityDuration => _stillActivityDuration;

  int get locationMovementPauseDuration => _locationMovementPauseDuration;

  Coordinates get initialMapCoordinates => _initialMapCoordinates;

  int get userNameMinLen => _userNameMinLen;

  int get passwordMinLen => _passwordMinLen;

  int get positionSearchMaxRadius => _positionSearchMaxRadius;

  int get positionSearchMinRadius => _positionSearchMinRadius;

  double get screenBrightness => _screenBrightness;

  double get minLabelShowingZoom => _minLabelShowingZoom;

  int get sendEventTimeout => _sendEventTimeout;

  int get socketTimeout => _socketTimeout;

  int get getCurrentPositionTimeout => _getCurrentPositionTimeout;

  int get sendRestRequestTimeout => _sendRestRequestTimeout;

  int get sendTransportTimeoutInMilliseconds =>
      _sendTransportTimeoutInMilliseconds;

  int get positionRangeAlertDuration => _positionRangeAlertDuration;

  int get sosAutoBroadcastPeriod => _sosAutoBroadcastPeriod;

  double get maxVolumeOnMobileDevice => _maxVolumeOnMobileDevice;

  int get positionRangeMessagePeriod => _positionRangeMessagePeriod;

  int get heartbeatPeriod => _heartbeatPeriod;

  int get batteryLevelPeriod => _batteryLevelPeriod;

  int get videoSocketRecoveryPeriod => _videoSocketRecoveryPeriod;

  int get chatSocketRecoveryPeriod => _chatSocketRecoveryPeriod;

  int get signalingSocketRecoveryPeriod => _signalingSocketRecoveryPeriod;

  int get lastMessageAtRefreshPeriod => _lastMessageAtRefreshPeriod;

  int get locationUpdatePeriod => _locationUpdatePeriod;

  int get clearLastKnownLocationPeriod => _clearLastKnownLocationPeriod;

  int get createTransportsPeriod => _createTransportsPeriod;

  int get audioMessageLifePeriodSec => _audioMessageLifePeriod * 60;

  int get audioMessageDebugLifePeriod => _audioMessageDebugLifePeriod;

  SosMode get sosMode => _sosMode;

  String get languageCode => _languageCode;

  String get loginPageImage => _loginPageImage;

  String get siteLogo => _siteLogo;

  String get dateTimeFormat => _dateTimeFormat;

  String get apkUrl => _apkUrl;

  String get mediaWsUrl => _mediaWsUrl;

  String get eventWsUrl => _eventWsUrl;

  String get videoWsUrl => _videoWsUrl;

  String get chatWsUrl => _chatWsUrl;

  String get externalTileServerUrl => _externalTileServerUrl;

  int get audioMessageRetainThresholdMs => _audioMessageRetainThresholdMs;

  String get dateTimeFormatShort => _dateTimeFormatShort;

  String get timeFormat => _timeFormat;

  String get dateFormat => _dateFormat;

  String get fullTimeFormat => _fullTimeFormat;

  int get highResolutionDeviceDensity => _highResolutionDeviceDensity;

  int get switchToPrimaryGroupTimeoutSec => _switchToPrimaryGroupTimeoutSec;

  String get clientVersion => _clientVersion;

  String get clientBuildNumber => _clientBuildNumber;

  String get version => _version;

  String get technicianCode => _technicianCode;

  // ignore: unnecessary_getters_setters
  bool get enableRemoteDebuggingLogger => _enableRemoteDebuggingLogger;

  bool get faceDetectionForLogin => _faceDetectionForLogin;

  bool get enableHistoryTracking =>
      _enableHistoryTracking &&
      (Session.user == null ||
          (Session.user != null && Session.user!.isSupervisor!));

  bool get cacheMapTiles => _cacheMapTiles;

  bool get isProduction => _isProduction;

  bool get ignoreActiveSession => _ignoreActiveSession;

  bool get verifyUserLocationForPositionShift =>
      _verifyUserLocationForPositionShift;

  bool get enableMobileKioskMode => _enableMobileKioskMode;

  bool get enableMobileScreenLock => _enableMobileScreenLock;

  bool get useKalmanFilterForGPS => _useKalmanFilterForGPS;

  bool get useStillActivitiesForGPS => _useStillActivitiesForGPS;

  bool get showNetworkJitter => _showNetworkJitter;

  bool get isDarkTheme => _isDarkTheme;

  // ignore: unnecessary_getters_setters
  set enableRemoteDebuggingLogger(bool val) =>
      _enableRemoteDebuggingLogger = val;

  String get appVersion => _appVersion.value;

  bool _fetching = false;

  Future<void> setAppVersion() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    _appVersion.value = '${info.version}-${info.buildNumber}';
    final version = '$clientVersion-$clientBuildNumber';

    if (_appVersion.compareTo(version) != 0) {
      updatesCounter$.value = 1;
    } else {
      updatesCounter$.value = 0;
    }
    TelloLogger().i(
        'AppSettings ==> $_appVersion == > clientVersion $version ,,, updatesCounter == $updatesCounter ${_appVersion.compareTo(version)}');
  }

  void store(Map<String, dynamic> m) {
    setPermanentSettings(m);
    setExternalSettings(m);
    GetStorage().write(StorageKeys.appSettings, toMap());
  }

  void tryRestore() {
    final data =
        GetStorage().read<Map<String, dynamic>>(StorageKeys.appSettings);
    if (data != null) {
      setPermanentSettings(data);
      setExternalSettings(data, listFromJson: true);
    }
  }

  Future<bool> tryUpdate() async {
    assert(ServiceAddress().initialized);
    bool isSuccess = false;

    if (_fetching) return false;
    TelloLogger().i('tryUpdate() fetching started', caller: 'AppSettings');
    _fetching = true;

    try {
      final settingsData =
          await GeneralRepository().fetchSettings(AppSettings().simSerial);
      if (settingsData['status']['code'] as int > 0)
        throw settingsData['status']['message'];

      AppSettings().store(settingsData);
      ServiceAddress().tryInit(AppSettings());
      if (updateNotCompleted) isUpdated.complete();
      isSuccess = true;
      TelloLogger().i('tryUpdate() fetching success', caller: 'AppSettings');
    } catch (e, s) {
      TelloLogger()
          .e("tryUpdate() error: $e", stackTrace: s, caller: 'AppSettings');
      isSuccess = false;
    }

    _fetching = false;
    return isSuccess;
  }

  void setPermanentSettings(Map<String, dynamic> m) {
    TelloLogger().i("Settings Data ===> $m");
    if (m['baseUrl'] != null) baseUrl = m['baseUrl'] as String;
    if (m['simSerial'] != null) simSerial = m['simSerial'] as String;
    _mediaWsUrl = m['serviceUrl']['mediaWsUrl'] as String;
    _eventWsUrl = m['serviceUrl']['eventWsUrl'] as String;
    _videoWsUrl = m['serviceUrl']['videoWsUrl'] as String;
    _chatWsUrl = m['serviceUrl']['chatWsUrl'] as String;
    _loginPageImage = m['settings']['loginPageImage'] as String;
    _siteLogo = m['settings']['siteLogo'] as String;
  }

  Future<void> setExternalSettings(Map<String, dynamic> data,
      {bool listFromJson = false}) async {
    _externalTileServerUrl = data['settings']['externalServerUrl'] != null
        ? "${data['settings']['externalServerUrl'] as String}tile/"
        : "https://{s}.tile.openstreetmap.org/";
    TelloLogger().i("setExternalSettings ===> ${data['settings']['apkUrl']}");
    _apkUrl = data['settings']['apkUrl'] as String;
    _deviceStatusConfig =
        DeviceStatus.values[data['settings']['deviceStatusConfig'] as int];
    _enableRemoteDebuggingLogger =
        data['settings']['enableRemoteDebuggingLogger'] as bool;
    _cacheMapTiles = data['settings']['cacheMapTiles'] as bool;
    _faceDetectionForLogin = data['settings']['faceDetectionForLogin'] as bool;
    _enableMobileKioskMode = data['settings']['enableMobileKioskMode'] as bool;
    _enableMobileScreenLock =
        data['settings']['enableMobileScreenLock'] as bool;
    _verifyUserLocationForPositionShift =
        data['settings']['verifyUserLocationForPositionShift'] as bool;
    _detectSinglePositionAssignment =
        data['settings']['detectSinglePositionAssignment'] as bool;
    _isProduction = data['settings']['isProduction'] as bool;
    _ignoreActiveSession = data['settings']['ignoreActiveSession'] as bool;
    _userNameMinLen = data['settings']['userNameMinLen'] as int;
    _useKalmanFilterForGPS = data['settings']['useKalmanFilterForGPS'] as bool;
    _useStillActivitiesForGPS =
        data['settings']['useStillActivitiesForGPS'] as bool;
    _enableActivityTracking =
        data['settings']['enableActivityTracking'] as bool;
    _videoModeEnabled = data['settings']['videoModeEnabled'] as bool;
    _isNfcLoginEnabled = data['settings']['isNfcLoginEnabled'] as bool;
    _forceAndroidLocationManager =
        data['settings']['forceAndroidLocationManager'] as bool;
    _enableVideoChatService =
        data['settings']['enableVideoChatService'] as bool;
    _showNetworkJitter = data['settings']['showNetworkJitter'] as bool;
    _isDarkTheme = data['settings']['isDarkTheme'] as bool;
    _stillActivityDuration = data['settings']['stillActivityDuration'] as int;
    _locationMovementPauseDuration =
        data['settings']['locationMovementPauseDuration'] as int;
    _passwordMinLen = data['settings']['passwordMinLen'] as int;
    _positionSearchMaxRadius =
        data['settings']['positionSearchMaxRadius'] as int;
    _positionSearchMinRadius =
        data['settings']['positionSearchMinRadius'] as int;
    _maxMapZoomLevel = data['settings']['maxMapZoomLevel'] != null
        ? data['settings']['maxMapZoomLevel'] as double
        : 18.0;
    _minMapZoom = 10.0; //data['settings']['minMapZoom'] as double ?? 10.0;
    _maxNativeMapZoomLevel =
        data['settings']['maxNativeMapZoomLevel'] as double;
    _minNativeMapZoom = data['settings']['minNativeMapZoom'] as double;
    _screenBrightness = data['settings']['screenBrightness'] != null
        ? data['settings']['screenBrightness'] as double
        : 0.5;
    _minLabelShowingZoom = data['settings']['minLabelShowingZoom'] as double;
    _initialMapCoordinates = Coordinates.fromMap(
        data['settings']['initialMapCoordinates'] as Map<String, dynamic>);
    _sendEventTimeout = data['settings']['sendEventTimeout'] as int;
    _sendRestRequestTimeout = data['settings']['sendRestRequestTimeout'] as int;
    _sendTransportTimeoutInMilliseconds =
        data['settings']['sendTransportTimeoutInMilliseconds'] as int;
    _sosAutoBroadcastPeriod = data['settings']['sosAutoBroadcastPeriod'] as int;
    _maxVolumeOnMobileDevice =
        data['settings']['maxVolumeOnMobileDevice'] as double;
    _getCurrentPositionTimeout =
        data['settings']['getCurrentPositionTimeout'] as int;
    _heartbeatPeriod = data['settings']['heartbeatPeriod'] as int;
    _videoSocketRecoveryPeriod =
        data['settings']['videoSocketRecoveryPeriod'] as int;
    _chatSocketRecoveryPeriod =
        data['settings']['chatSocketRecoveryPeriod'] as int;
    _signalingSocketRecoveryPeriod =
        data['settings']['signalingSocketRecoveryPeriod'] as int;
    _lastMessageAtRefreshPeriod =
        data['settings']['lastMessageAtRefreshPeriod'] as int;
    _locationUpdatePeriod = data['settings']['locationUpdatePeriod'] as int;
    _sosMode = data['settings']['sosMode'] != null
        ? SosMode.values[data['settings']['sosMode'] as int]
        : SosMode.values[0];
    _createTransportsPeriod = data['settings']['createTransportsPeriod'] as int;
    _audioMessageLifePeriod = data['settings']['audioMessageLifePeriod'] as int;
    _audioMessageDebugLifePeriod =
        data['settings']['audioMessageDebugLifePeriod'] as int;
    _switchToPrimaryGroupTimeoutSec =
        data['settings']['switchToPrimaryGroupTimeoutSec'] as int;
    _positionRangeAlertDuration =
        data['settings']['positionRangeAlertDuration'] as int;
    _positionRangeMessagePeriod =
        data['settings']['positionRangeMessagePeriod'] as int;
    _version = data['settings']['version'] as String;
    _clientVersion = "${data['settings']['clientVersion']}";
    _clientBuildNumber = "${data['settings']['clientBuildNumber'] ?? '00'}";
    _dateTimeFormat = data['settings']['dateTimeFormat'] as String;
    _audioMessageRetainThresholdMs =
        data['settings']['audioMessageRetainThresholdMs'] as int;
    _dateFormat = data['settings']['dateFormat'] as String;
    _timeFormat = data['settings']['timeFormat'] as String;
    _fullTimeFormat = data['settings']['fullTimeFormat'] as String;
    _technicianCode = data['settings']['technicianCode'] != null
        ? data['settings']['technicianCode'] as String
        : "tech123";
    _languageCode = data['settings']['languageCode'] != null
        ? data['settings']['languageCode'] as String
        : "en";
    _highResolutionDeviceDensity =
        data['settings']['highResolutionDeviceDensity'] as int;
    _maxMediaToAdd = data['settings']['maxMediaToAdd'] as int;
    _maxVideoDurationSec = data['settings']['maxVideoDurationSec'] as int;
    _pttBroadcastTimeoutDuration =
        data['settings']['pttBroadcastTimeoutDuration'] as int;
    _reportingPointLocationTolerance =
        data['settings']['reportingPointLocationTolerance'] as int;
    _shiftInterruptedThresholdSec =
        data['settings']['shiftInterruptedThresholdSec'] as int;
    _clearLastKnownLocationPeriod =
        data['settings']['clearLastKnownLocationPeriod'] as int;
    _pingIntervalSec = data['settings']['pingIntervalSec'] as double;
    _ratingColorSettings = (listFromJson
            ? json.decode(data['settings']['styleSettings']
                ['ratingColorSettings'] as String) as List<dynamic>
            : data['settings']['styleSettings']['ratingColorSettings']
                as List<dynamic>)
        .map((c) => RatingColorConfig.fromMap(c as Map<String, dynamic>))
        .toList();
    _loggerConfig = LoggerConfig.fromMap(
      data['settings']['loggerConfig'] as Map<String, dynamic>,
      listFromJson: listFromJson,
    );

    await setAppVersion();
  }

  Map<String, Object> toMap() {
    return {
      'baseUrl': baseUrl,
      'simSerial': simSerial,
      'serviceUrl': {
        'mediaWsUrl': mediaWsUrl,
        'eventWsUrl': eventWsUrl,
        'videoWsUrl': videoWsUrl,
        'chatWsUrl': chatWsUrl,
      },
      'settings': {
        'loginPageImage': _loginPageImage,
        'siteLogo': _siteLogo,
        'externalTileServerUrl': _externalTileServerUrl,
        'apkUrl': _apkUrl,
        'deviceStatusConfig': _deviceStatusConfig.index,
        'enableRemoteDebuggingLogger': _enableRemoteDebuggingLogger,
        'cacheMapTiles': _cacheMapTiles,
        'faceDetectionForLogin': _faceDetectionForLogin,
        'enableMobileKioskMode': _enableMobileKioskMode,
        'enableMobileScreenLock': _enableMobileScreenLock,
        'verifyUserLocationForPositionShift':
            _verifyUserLocationForPositionShift,
        'detectSinglePositionAssignment': _detectSinglePositionAssignment,
        'isProduction': _isProduction,
        'ignoreActiveSession': _ignoreActiveSession,
        'userNameMinLen': _userNameMinLen,
        'useKalmanFilterForGPS': _useKalmanFilterForGPS,
        'useStillActivitiesForGPS': _useStillActivitiesForGPS,
        'enableActivityTracking': _enableActivityTracking,
        'videoModeEnabled': _videoModeEnabled,
        'isNfcLoginEnabled': _isNfcLoginEnabled,
        'forceAndroidLocationManager': _forceAndroidLocationManager,
        'enableVideoChatService': _enableVideoChatService,
        'showNetworkJitter': _showNetworkJitter,
        'isDarkTheme': _isDarkTheme,
        'stillActivityDuration': _stillActivityDuration,
        'locationMovementPauseDuration': _locationMovementPauseDuration,
        'passwordMinLen': _passwordMinLen,
        'positionSearchMaxRadius': _positionSearchMaxRadius,
        'positionSearchMinRadius': _positionSearchMinRadius,
        'maxMapZoomLevel': _maxMapZoomLevel,
        'minMapZoom': _minMapZoom,
        'maxNativeMapZoomLevel': _maxNativeMapZoomLevel,
        'minNativeMapZoom': _minNativeMapZoom,
        'screenBrightness': _screenBrightness,
        'minLabelShowingZoom': _minLabelShowingZoom,
        'initialMapCoordinates': _initialMapCoordinates.toMap(),
        'sendEventTimeout': _sendEventTimeout,
        'sendRestRequestTimeout': _sendRestRequestTimeout,
        'sendTransportTimeoutInMilliseconds':
            _sendTransportTimeoutInMilliseconds,
        'sosAutoBroadcastPeriod': _sosAutoBroadcastPeriod,
        'maxVolumeOnMobileDevice': _maxVolumeOnMobileDevice,
        'getCurrentPositionTimeout': _getCurrentPositionTimeout,
        'heartbeatPeriod': _heartbeatPeriod,
        'videoSocketRecoveryPeriod': _videoSocketRecoveryPeriod,
        'chatSocketRecoveryPeriod': _chatSocketRecoveryPeriod,
        'signalingSocketRecoveryPeriod': _signalingSocketRecoveryPeriod,
        'lastMessageAtRefreshPeriod': _lastMessageAtRefreshPeriod,
        'locationUpdatePeriod': _locationUpdatePeriod,
        'sosMode': _sosMode.index,
        'createTransportsPeriod': _createTransportsPeriod,
        'audioMessageLifePeriod': _audioMessageLifePeriod,
        'audioMessageDebugLifePeriod': _audioMessageDebugLifePeriod,
        'switchToPrimaryGroupTimeoutSec': _switchToPrimaryGroupTimeoutSec,
        'positionRangeAlertDuration': _positionRangeAlertDuration,
        'positionRangeMessagePeriod': _positionRangeMessagePeriod,
        'version': _version,
        'clientVersion': _clientVersion,
        'clientBuildNumber': _clientBuildNumber,
        'dateTimeFormat': _dateTimeFormat,
        'audioMessageRetainThresholdMs': _audioMessageRetainThresholdMs,
        'dateFormat': _dateFormat,
        'timeFormat': _timeFormat,
        'fullTimeFormat': _fullTimeFormat,
        'technicianCode': _technicianCode,
        'languageCode': _languageCode,
        'highResolutionDeviceDensity': _highResolutionDeviceDensity,
        'maxMediaToAdd': _maxMediaToAdd,
        'maxVideoDurationSec': _maxVideoDurationSec,
        'pttBroadcastTimeoutDuration': _pttBroadcastTimeoutDuration,
        'reportingPointLocationTolerance': _reportingPointLocationTolerance,
        'shiftInterruptedThresholdSec': _shiftInterruptedThresholdSec,
        'clearLastKnownLocationPeriod': _clearLastKnownLocationPeriod,
        'pingIntervalSec': _pingIntervalSec,
        'styleSettings': {
          'ratingColorSettings':
              json.encode(ratingColorSettings.map((c) => c.toMap()).toList()),
        },
        'loggerConfig': _loggerConfig.toMap(),
      },
    };
  }
}
