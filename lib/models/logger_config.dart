import 'dart:convert';

import 'package:bazz_flutter/constants.dart';
import 'package:flutter/material.dart';

class LoggerConfig {
  final String remoteUrl;
  final LoggerType loggerType;
  final List<TelloLogLevel> logLevels;
  final int maxLogMessages;
  final int sendBulkTimeout;

  bool get isRemote => loggerType == LoggerType.remote;

  LoggerConfig({
    required this.remoteUrl,
    required this.loggerType,
    required this.logLevels,
    required this.maxLogMessages,
    required this.sendBulkTimeout,
  });

  LoggerConfig.fromMap(Map<String, dynamic> map, {bool listFromJson = false})
      : remoteUrl = map['remoteUrl'] as String,
        loggerType = LoggerType.values[map['loggerType'] as int],
        logLevels = (listFromJson
                ? json.decode(map['logLevels'] as String) as List<dynamic>
                : map['logLevels'] as List<dynamic>)
            .map((lvl) => TelloLogLevel.values[lvl as int])
            .toList(),
        maxLogMessages = map['maxLogMessage'] as int,
        sendBulkTimeout = map['sendingBulkTimeout'] as int;

  Map<String, dynamic> toMap() {
    return {
      'remoteUrl': remoteUrl,
      'loggerType': loggerType.index,
      'logLevels': json.encode(logLevels.map((lvl) => lvl.index).toList()),
      'maxLogMessage': maxLogMessages,
      'sendingBulkTimeout': sendBulkTimeout,
    };
  }
}
