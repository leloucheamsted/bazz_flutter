import 'package:logger/src/logger.dart';

class LayoutConstants {
  static const pagePadding = 8.0;
  static const compactPadding = 5.0;
  static const trackSeekerThumbRadius = 8.0;
  static const shadowRadius = 5.0;
  static const appBarHeight = 60.0;
  static const rPointInfoWindowWidth = 200.0;
  static const flutterMapInfoWindowWidth = 250.0;
  static const rPointVisitDateTimeWidth = 125.0;
  static const pttSosBottomPanelHeight = 80.0;
}

class Int32 {
  static const int maxSize = 2147483647;
  static const int minSize = -2147483647;
}

class StorageKeys {
  static const messageUploadQueueBox = 'messageUploadQueueBox';
  static const rPointVisitsUploadQueueBox = 'rPointVisitsUploadQueueBox';
  static const offlineEventsBox = 'offlineEventsBox';
  static const readOfflineChatMessagesBox = 'readOfflineChatMessagesBox';

  static const lastKnownLocation = 'lastKnownLocation';
  static const appVersion = 'appVersion';
  static const appSettings = 'appSettings';
  static const currentActiveGroup = 'currentActiveGroup';
  static const currentSession = 'currentSession';
  static const offlineLocations = 'offlineLocations';
  static const offlineDeviceStates = 'offlineDeviceStates';
  static const offlineAlertCheckResults = 'offlineAlertCheckResults';
  static const offlineReportingPoints = 'offlineReportingPoints';
  static const secondsSinceLastAlertCheck = 'secondsSinceLastAlertCheck';
  static const alertCheckSnoozes = 'alertCheckSnoozes';
  static const prevBrokenPackageId = 'prevBrokenPackageId';
  static const cultureId = 'cultureId';
  static const systemSettingsId = 'systemSettingsId';
  static const pttKeyCodeId = 'pttKeyCodeId';
  static const sosKeyCodeId = 'sosKeyCodeId';
  static const deviceOutputId = 'deviceOutputId';
  static const totalPTTStreamIncomingId = 'totalPTTStreamIncomingId';
  static const totalPTTStreamOutgoingId = 'totalPTTStreamIncomingId';
  static const totalDataUsageId = 'totalDataUsageId';
  static const dataUsageId = 'dataUsageId';
  static const switchUpKeyCodeId = 'switchUpKeyCodeId';
  static const switchDownKeyCodeId = 'switchDownKeyCodeId';
  static const notifications = 'notifications';
  static const currentAlertCheckRPoints = 'currentAlertCheckRPoints';
  static const periodicShiftTimestamp = 'periodicShiftTimestamp';
  static const sosEvent = 'sosEvent';
  static const groups = 'groups';
  static const activeGroup = 'activeGroup';
  static const adminUsers = 'adminUsers';
  static const eventSettings = 'eventSettings';
  static const incomingEvents = 'incomingEvents';
}

enum MobilityType {
  // ignore: constant_identifier_names
  Pedestrian,
  // ignore: constant_identifier_names
  Motorized,
}

enum LocationType {
  // ignore: constant_identifier_names
  Static,
  // ignore: constant_identifier_names
  Dynamic,
}

enum MobileNetworkType {
  // ignore: constant_identifier_names
  WiFi,
  // ignore: constant_identifier_names
  GSM,
  none,
}

enum AuthenticationType {
  Password,
  FaceId,
}

enum SuggestionType {
  Assigned,
  Location,
  LastShift,
  DevicePosition,
}

enum SosMode {
  // ignore: constant_identifier_names
  Silence,
  // ignore: constant_identifier_names
  Sound,
}

enum ViewState {
  idle,
  loading,
  success,
  initialize,
  exit,
  lock,
  error,
}

enum PositionStatus {
  active,
  inactive,
  outOfRange,
}

enum PttStatus {
  idle,
  transmitting,
  listening,
}

enum StreamingState {
  connecting,
  idle,
  preparing,
  sending,
  receiving,
  cleaning,
}

enum EventResolveStatus {
  justified,
  treated,
}

enum EventStatus {
  open,
  ongoing,
  closed,
}

enum EventSeverity {
  low,
  minor,
  major,
  critical,
}

enum EventPriority {
  low,
  medium,
  high,
  immediate,
}

enum PerimeterType {
  circle,
  polygon,
}

enum AlertCheckState {
  ok,
  failed,
}

enum DeviceStatus {
  recognized,
  notRecognized,
}

enum NotificationGroupType {
  systemEvents,
  chat,
  broadcast,
  messagesHistory,
  noActivityDetected,
  alertCheck,
  others,
}

enum RPValidationType {
  geoQr,
  geo,
  qr,
}

enum OfflineReason {
  dataUsage,
  batteryStatus,
  networkAvailability,
  deviceUnexpectedShutdown,
}

enum LoggerType {
  remote,
  console,
}

enum TelloLogLevel {
  trace,
  debug,
  info,
  log,
  warning,
  error,
  fatal,
}

const telloLogLevelToLevel = {
  TelloLogLevel.trace: Level.verbose,
  TelloLogLevel.debug: Level.debug,
  TelloLogLevel.info: Level.info,
  TelloLogLevel.warning: Level.warning,
  TelloLogLevel.error: Level.error,
  TelloLogLevel.fatal: Level.wtf,
};

const levelToTelloLogLevel = {
  Level.verbose: TelloLogLevel.trace,
  Level.debug: TelloLogLevel.debug,
  Level.info: TelloLogLevel.info,
  Level.warning: TelloLogLevel.warning,
  Level.error: TelloLogLevel.error,
  Level.wtf: TelloLogLevel.fatal,
};
