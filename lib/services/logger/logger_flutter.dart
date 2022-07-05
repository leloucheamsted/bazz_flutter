/// Flutter extension for logger
library logger_flutter;

import 'dart:collection';
import 'dart:io';
import 'dart:ui';

import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';
import 'package:open_file/open_file.dart';

import 'ansi_parser.dart';
import 'shake_detector.dart';

part 'log_console.dart';

part 'log_console_on_shake.dart';
