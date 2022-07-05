import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:ansicolor/ansicolor.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/settings_module/settings_controller.dart';
import 'package:bazz_flutter/modules/synchronization/sync_repo.dart';
import 'package:bazz_flutter/services/data_connection_checker.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:logger/logger.dart';
import 'package:logger/logger.dart' as log;
import 'package:uuid/uuid.dart';

class RemoteLog {
  String message;
  String? stackTrace;
  String? dateTimeLocal;
  int? dateTimeUtc;
  TelloLogLevel logLevel;
  Map<String, dynamic>? data;

  RemoteLog(
      {required this.message,
      required this.logLevel,
      this.data,
      this.stackTrace}) {
    final DateTime now = DateTime.now();
    dateTimeUtc = dateTimeToSeconds(now);
    final formattedDateTime = DateFormat('yyyy-MM-ddTHH:mm:ss').format(now);
    dateTimeLocal = formattedDateTime + getFormattedTimeZoneOffset(now);
  }

  Map<String, dynamic> toMap() {
    return {
      'dateTimeUtc': dateTimeUtc,
      'dateTimeLocal': dateTimeLocal,
      'logLevel': logLevel.index,
      'message': {
        'message': message,
        'data': data,
        'stackTrace': stackTrace,
      },
    };
  }
}

enum LogColor { white, green, red, cyan, blue }

log.Logger flutterLogger = log.Logger(
  printer:
      log.PrettyPrinter(printTime: true, methodCount: 4, errorMethodCount: 16),
);
log.Logger flutterLongMsgLogger = log.Logger(
  printer: log.PrettyPrinter(
      printTime: true, lineLength: 8024, methodCount: 4, errorMethodCount: 16),
);

log.Logger flutterLoggerNoStack = log.Logger(
  printer: log.PrettyPrinter(methodCount: 0),
);

typedef LoggerListener = void Function(OutputEvent event);

class TelloLogger {
  static final TelloLogger _singleton = TelloLogger._internal();

  factory TelloLogger() => _singleton;

  ListQueue<OutputEvent> outputEventBuffer = ListQueue();

  static String sessionId = Uuid().v1();
  final List<RemoteLog> _logQueue = [];
  Completer _dumpingLogs = Completer()..complete();
  AnsiPen greenPen = AnsiPen()..green();
  AnsiPen whitePen = AnsiPen()..white();
  AnsiPen redPen = AnsiPen()..white();
  AnsiPen cyanPen = AnsiPen()..cyan();
  AnsiPen bluePen = AnsiPen()..blue();
  final List<LoggerListener> listeners = [];
  final _printer =
      PrettyPrinter(printTime: true, methodCount: 4, errorMethodCount: 16);
  final _printerLong = PrettyPrinter(
      printTime: true, lineLength: 2024, methodCount: 4, errorMethodCount: 16);

  int get dumpLogsTimeout => AppSettings().loggerConfig.sendBulkTimeout;

  TelloLogger._internal() {
    _printer.init();
    _printerLong.init();
    Future.delayed(Duration(seconds: dumpLogsTimeout), _dumpLogs);
  }

  Future<void> _dumpLogs() async {
    final remoteUrl = AppSettings().loggerConfig.remoteUrl;
    final canSendLogs = (remoteUrl.isNotEmpty) && Session.hasAuthToken;

    if (canSendLogs) {
      final isOnline = await DataConnectionChecker().isConnectedToInternet;

      if (_logQueue.isNotEmpty && isOnline) {
        i('dumping logs... Length: ${_logQueue.length}');
        _dumpingLogs = Completer();
        try {
          await SyncRepo().dumpLogs(
            remoteUrl,
            'Mobile',
            AppSettings().appVersion,
            _logQueue,
            userId: Session.user!.id,
            shiftId: Session.shift!.id,
            positionId: Session.shift!.positionId,
            deviceId: Session.device!.id,
          );
          _logQueue.clear();
        } catch (e, s) {
          this.e('Error dumping logs: $e', stackTrace: s);
        } finally {
          if (!_dumpingLogs.isCompleted) {
            _dumpingLogs.complete();
          }
        }
      }
    }
    Future.delayed(Duration(seconds: dumpLogsTimeout), _dumpLogs);
  }

  void clearOutputEventBuffer() => outputEventBuffer.clear();

  void addOutputListener(LoggerListener callback) {
    listeners.add(callback);
  }

  void removeOutputListener(LoggerListener callback) {
    listeners.remove(callback);
  }

  void v(dynamic logObject,
      {bool isWrapped = false,
      StackTrace? stackTrace,
      Map<String, dynamic>? data,
      String? caller}) {
    _log(Level.verbose, logObject,
        isWrapped: isWrapped,
        stackTrace: stackTrace!,
        data: data!,
        caller: caller!);
  }

  void i(dynamic logObject,
      {bool isWrapped = false,
      StackTrace? stackTrace,
      Map<String, dynamic>? data,
      String? caller}) {
    _log(Level.info, logObject,
        isWrapped: isWrapped,
        stackTrace: stackTrace!,
        data: data!,
        caller: caller!);
  }

  void w(dynamic logObject,
      {bool isWrapped = false,
      StackTrace? stackTrace,
      Map<String, dynamic>? data,
      String? caller}) {
    _log(Level.warning, logObject,
        isWrapped: isWrapped,
        stackTrace: stackTrace!,
        data: data!,
        caller: caller!);
  }

  void e(dynamic logObject,
      {bool isWrapped = false,
      StackTrace? stackTrace,
      Map<String, dynamic>? data,
      String? caller}) {
    _log(Level.error, logObject,
        isWrapped: isWrapped,
        stackTrace: stackTrace!,
        data: data!,
        caller: caller!);
  }

  void wtf(dynamic logObject,
      {bool isWrapped = false,
      StackTrace? stackTrace,
      Map<String, dynamic>? data,
      String? caller}) {
    _log(Level.wtf, logObject,
        isWrapped: isWrapped,
        stackTrace: stackTrace!,
        data: data!,
        caller: caller!);
  }

  void _log(
    Level level,
    dynamic logObject, {
    bool isWrapped = false,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    String? caller,
  }) {
    const debugLevel = Level.error;
    if (Logger.level != debugLevel)
      Logger.level = debugLevel; //Sets threshold log level in debug mode

    final telloLogLevel = levelToTelloLogLevel[level];

    String message = caller != null ? '<$caller> ' : '';

    if (logObject.runtimeType == String) {
      message += logObject as String;
    } else if (logObject is JsonSerializable) {
      message += jsonEncode(logObject.toJson());
    } else {
      message += logObject.toString();
    }

    final dataMessage = '$message${data != null ? '\nData: $data' : ''}';

    if (isWrapped) {
      flutterLongMsgLogger.log(level, dataMessage, null, stackTrace);
    } else {
      flutterLogger.log(level, dataMessage, null, stackTrace);
    }

    final canLog = AppSettings().loggerConfig.logLevels.contains(telloLogLevel);

    if (AppSettings().loggerConfig == null || !canLog) return;

    if (AppSettings().loggerConfig.isRemote) {
      _dumpingLogs.future.whenComplete(() {
        final remoteLog = RemoteLog(
          message: message,
          logLevel: levelToTelloLogLevel[level]!,
          data: data,
          stackTrace: stackTrace.toString(),
        );
        _logQueue.add(remoteLog);
        if (_logQueue.length > AppSettings().loggerConfig.maxLogMessages)
          _logQueue.removeAt(0);
      });
    }

    if (SettingsController.to?.loggerEnabled ?? false) {
      final logEvent = LogEvent(level, dataMessage, null, stackTrace);
      final outputEvent = OutputEvent(
        level,
        isWrapped ? _printerLong.log(logEvent) : _printer.log(logEvent),
      );

      outputEventBuffer.add(outputEvent);
      if (outputEventBuffer.length >
          AppSettings().loggerConfig.maxLogMessages) {
        outputEventBuffer.removeFirst();
      }

      for (final listener in listeners) {
        listener(outputEvent);
      }
    }
  }
}
