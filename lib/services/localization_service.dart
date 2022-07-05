import 'package:flutter/cupertino.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:bazz_flutter/constants.dart';

import 'logger.dart';

class LocalizationService {
  static final LocalizationService _singleton = LocalizationService._();

  factory LocalizationService() => _singleton;

  LocalizationService._();

  BuildContext? _context;

  // ignore: use_setters_to_change_properties
  void init() {}

  String getLanguageCode() {
    return Localizations.localeOf(Get.context!).languageCode;
  }

  List<Locale> supportedLocales() {
    final List<Locale> list = [
      const Locale('en', ''), // English, no country code
      const Locale('fr', ''), // French, no country code
    ];
    return list;
  }

  void saveLocale(Locale value) {
    GetStorage().write(StorageKeys.cultureId, value.languageCode);
    Get.updateLocale(value);
  }

  void restoreDefaultLocale() {
    GetStorage()
        .write(StorageKeys.cultureId, supportedLocales()[0].countryCode);
    Get.updateLocale(supportedLocales()[0]);
  }

  void loadCurrentLocale() {
    final countryCode = GetStorage().read(StorageKeys.cultureId) as String;
    TelloLogger().i("countryCode $countryCode");
    if (countryCode.isNotEmpty) {
      Get.updateLocale(Locale(countryCode as String, ''));
    } else {
      Get.updateLocale(supportedLocales()[0]);
    }
  }

  Locale getCurrentLocale() {
    return Get.locale!;
  }

  of() {}

  // AppLocalizations of() {
  //   return AppLocalizations.of(Get.context);
  // }
}
