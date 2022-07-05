import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/models/coordinates_model.dart';
import 'package:bazz_flutter/modules/home_module/flutter_map/flutter_map.dart'
    as flutter_map;
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong/latlong.dart' as flutter_cor;

class LayoutUtils {
  static void buildDescription(String description,
      {Widget? icon, String? title}) {
    final defaultIcon = SvgPicture.asset(
      'assets/images/rp_info_icon.svg',
      color: AppColors.primaryAccent,
      height: 20,
    );
    final defaultTitle = " LocalizationService().of().description.capitalize";

    Get.bottomSheet(
      Container(
        height: Get.height * 0.4,
        color: AppTheme().colors.infoWindowBg,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 7, 10, 10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  icon ?? defaultIcon,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text(
                      title ?? defaultTitle,
                      style: AppTheme()
                          .typography
                          .bgTitle2Style
                          .copyWith(color: AppColors.primaryAccent),
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
              Divider(color: AppTheme().colors.dividerLight),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    description,
                    style: AppTheme().typography.bgText3Style,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GeoUtils {
  static List<LatLng> createMapCirclePoints(
      LatLng point, double radius, int dir) {
    final double d2r = math.pi / 180; // degrees to radians
    final double r2d = 180 / math.pi; // radians to degrees
    const double earthsradius =
        6377.81442 * 1000; // 3963 is the radius of the earth in miles

    const int points = 32;

    // find the raidus in lat/lon
    final double rlat = (radius / earthsradius) * r2d;
    final double rlng = rlat / math.cos(point.latitude * d2r);

    final List<LatLng> extp = <LatLng>[];
    final int start = dir == 1 ? 0 : points + 1;
    final int end = dir == 1 ? points + 1 : 0;

    // ignore: unnecessary_parenthesis
    for (var i = start; (dir == 1 ? i < end : i > end); i = i + dir) {
      final theta = math.pi * (i / (points / 2));
      final double ey = point.longitude +
          (rlng * math.cos(theta)); // center a + radius x * cos(theta)
      final double ex = point.latitude +
          (rlat * math.sin(theta)); // center b + radius y * sin(theta)
      extp.add(LatLng(ex, ey));
    }

    return extp;
  }

  static List<LatLng> createCirclePoints(LatLng point, double radius, int dir) {
    final double d2r = math.pi / 180; // degrees to radians
    final double r2d = 180 / math.pi; // radians to degrees
    const double earthsradius =
        6377.81442 * 1000; // 3963 is the radius of the earth in miles

    const int points = 32;

    // find the raidus in lat/lon
    final double rlat = (radius / earthsradius) * r2d;
    final double rlng = rlat / math.cos(point.latitude * d2r);

    final List<LatLng> extp = <LatLng>[];
    final int start = dir == 1 ? 0 : points + 1;
    final int end = dir == 1 ? points + 1 : 0;

    // ignore: unnecessary_parenthesis
    for (var i = start; (dir == 1 ? i < end : i > end); i = i + dir) {
      final theta = math.pi * (i / (points / 2));
      final double ey = point.longitude +
          (rlng * math.cos(theta)); // center a + radius x * cos(theta)
      final double ex = point.latitude +
          (rlat * math.sin(theta)); // center b + radius y * sin(theta)
      extp.add(LatLng(ex, ey));
    }

    return extp;
  }

  static LatLngBounds boundsFromCoordinatesList(List<Coordinates> list) {
    late double x0, x1, y0, y1;
    for (final latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1) y1 = latLng.longitude;
        if (latLng.longitude < y0) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(northeast: LatLng(x1, y1), southwest: LatLng(x0, y0));
  }

  static flutter_map.LatLngBounds mapBoundsFromCoordinatesList(
      List<Coordinates> list) {
    late double x0, x1, y0, y1;
    for (final latLng in list) {
      TelloLogger().i("mapBoundsFromCoordinatesList ==> ${latLng.toJson()}");
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1) y1 = latLng.longitude;
        if (latLng.longitude < y0) y0 = latLng.longitude;
      }
    }
    return flutter_map.LatLngBounds(
        flutter_cor.LatLng(x1, y1), flutter_cor.LatLng(x0, y0));
  }

  static double degreeToRadian(double degree) {
    return degree * math.pi / 180;
  }
}

class ImageUtils {
  static Future<Uint8List> getBytesFromAsset(String path, int width) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    final fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  static Future<ui.Image> getImageFromAsset(String path, {int? width}) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    final fi = await codec.getNextFrame();
    return fi.image;
  }

  static Future<ByteData> load(Uri uri) async {
    final HttpClient httpClient = HttpClient();
    final HttpClientRequest request = await httpClient.getUrl(uri);
    final HttpClientResponse response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('Unable to load asset: $uri'),
        IntProperty('HTTP status code', response.statusCode),
      ]);
    }
    final Uint8List bytes = await consolidateHttpClientResponseBytes(response);
    return bytes.buffer.asByteData();
  }

  static Future<ui.Image> getImageFromUrl(String url, {int? width}) async {
    final avatarImage = Image.network(url);
    final data = await load(Uri.parse(url));

    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    final fi = await codec.getNextFrame();
    return fi.image;
  }
}

class GeneralUtils {
  static bool isSmallScreen() {
    TelloLogger()
        .i("Get.height == ${Get.height}  Get.pixelRatio ${Get.pixelRatio}");
    return Get.height < 640;
  }
}

String getStreamSize(double bytes, int decimals) {
  if (bytes <= 0) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
  final i = (math.log(bytes) / math.log(1024)).floor();
  return '${(bytes / math.pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
}

Future<int> getFileSize(String filepath) async {
  final file = File(filepath);
  final int bytes = await file.length();
  return bytes;
}

Future<String> getFileSizeFormat(String filepath, int decimals) async {
  final file = File(filepath);
  final int bytes = await file.length();
  if (bytes <= 0) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
  final i = (math.log(bytes) / math.log(1024)).floor();
  return '${(bytes / math.pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
}

String? humanizeDuration({int? seconds}) {
  if (seconds == null) return null;
  int remainder = seconds;
  final String hours = (remainder ~/ 3600).toString().padLeft(2, '0');
  remainder = seconds % 3600;
  final String minutes = (remainder ~/ 60).toString().padLeft(2, '0');
  remainder = remainder % 60;
  final String secs = remainder.toString().padLeft(2, '0');
  return '$hours:$minutes:$secs';
}

TimeAndUnit timeAndUnitFromSeconds(int value) {
  if (value == null) return null as TimeAndUnit;

  final timeAndUnit = TimeAndUnit();
  final elapsedTime = DateTime.now()
      .toUtc()
      .difference(dateTimeFromSeconds(value, isUtc: true)!);
  if (elapsedTime.inSeconds < 60.seconds.inSeconds) {
    timeAndUnit.time = elapsedTime.inSeconds;
    timeAndUnit.unit = 'sec';
  } else if (elapsedTime.inMinutes < 59.minutes.inMinutes) {
    timeAndUnit.time = elapsedTime.inMinutes;
    timeAndUnit.unit = 'min';
  } else {
    timeAndUnit.time = elapsedTime.inHours;
    timeAndUnit.unit = elapsedTime.inHours > 1 ? 'hours' : 'hour';
  }
  return timeAndUnit;
}

int dateTimeToSeconds(DateTime dateTime) =>
    dateTime.millisecondsSinceEpoch ~/ 1000;

int millisecondsToSeconds(int ms) => ms ~/ 1000;

DateTime? dateTimeFromSeconds(int seconds, {bool isUtc = false}) {
  return seconds != null
      ? DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: isUtc)
      : null;
}

String getFormattedTimeZoneOffset(DateTime time) {
  String twoDigits(int n) {
    if (n >= 10) return '$n';
    return '0$n';
  }

  final duration = time.timeZoneOffset,
      hours = duration.inHours,
      minutes = duration.inMinutes.remainder(60).abs().toInt();

  return '${hours > 0 ? '+' : '-'}${twoDigits(hours.abs())}:${twoDigits(minutes)}';
}

String getFilenameFromUrl(String url) {
  final regexp = RegExp(r'[^/\\&\?]+\.\w{3,4}(?=([\?&].*$|$))');
  return regexp.firstMatch(url)!.group(0) as String;
}

class TimeAndUnit {
  int? time;
  String? unit;

  TimeAndUnit({
    this.time,
    this.unit,
  });
}

extension BoolParsing on String {
  bool parseBool() {
    return toLowerCase() == 'true';
  }
}

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}
