import 'package:flutter/services.dart';
import 'package:bazz_flutter/services/logger.dart';

class IconConfig {
  final String id, url;

  /// Whether we have this icon in assets folder
  bool iconAssetExists = false;

  bool get iconAssetNotExists => !iconAssetExists;

  IconConfig.fromMap(Map<String, dynamic> map)
      : id = map['id'] != null ? map['id'] as String : null!,
        url = map['url'] != null ? map['url'] as String : null!;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
    };
  }

  /// If don't, we will load the icon from the url
  Future<bool> setIconAssetExists({bool forEvents = false}) async {
    final path = 'assets/images/${forEvents ? "events/" : ""}$id.svg';
    try {
      await rootBundle.loadString(path);
      TelloLogger().v('setIconAssetExists() have loaded path: $path',
          caller: 'IconConfig');
      return iconAssetExists = true;
    } catch (_) {
      TelloLogger().v('setIconAssetExists() failed loading path: $path',
          caller: 'IconConfig');
      return false;
    }
  }
}
