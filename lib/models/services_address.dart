import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/services/logger.dart';

class ServiceAddress {
  static final ServiceAddress _instance = ServiceAddress._();

  late factory ServiceAddress() => _instance;

  ServiceAddress._();

  late String _baseUrl;
  static String ? _webSocketAddress, _webSocketSchema;
  int _wwsPort = 3030;
  static String ? _webSystemEventsSocketAddress = "services.dev.bazzptt.com",  _webSystemEventsSocketSchema;
   int _wwsSystemEventsPort = 4040;
 late  String _webSocketVideoAddress, _webSocketVideoSchema;
  late int _wwsVideoPort;
  late String _webSocketChatAddress, _webSocketChatSchema;
  late int _wwsChatPort;

  String get baseUrl => _baseUrl;

   String? get webSocketAddress => _webSocketAddress;

  String get webSocketVideoAddress => _webSocketVideoAddress;

  String get webSocketChatAddress => _webSocketChatAddress;

  String? get webSystemEventsSocketAddress => _webSystemEventsSocketAddress;

  String? get webSocketSchema => _webSocketSchema;

  String get webSocketVideoSchema => _webSocketVideoSchema;

  String get webSocketChatSchema => _webSocketChatSchema;

  String ?get webSystemEventsSocketSchema => _webSystemEventsSocketSchema;

  int get wwsPort => _wwsPort;

  int get wwsSystemEventsPort => _wwsSystemEventsPort;

  int get wwsVideoPort => _wwsVideoPort;

  int get wwsChatPort => _wwsChatPort;

  bool get initialized => _baseUrl != null;

  bool get notInitialized => !initialized;

  bool tryInit(AppSettings appSettings) {
    if (appSettings.notInitialized) return false;

    TelloLogger().i("Initializing ServiceAddress from AppSettings...");
    _baseUrl = appSettings.baseUrl;

    try {
      final mediaWsUri = Uri.parse(appSettings.mediaWsUrl);
      _wwsPort = mediaWsUri.port;
      _webSocketAddress = mediaWsUri.host;
      _webSocketSchema = mediaWsUri.scheme;
      // _wwsPort = 3030;//mediaWsUri.port;
      // _webSocketAddress = "192.168.10.165";//mediaWsUri.host;
      // _webSocketSchema = "wss";

      final eventWsUri = Uri.parse(appSettings.eventWsUrl);
      _wwsSystemEventsPort = eventWsUri.port;
      _webSystemEventsSocketAddress = eventWsUri.host;
      _webSystemEventsSocketSchema = eventWsUri.scheme;

      final videoWsUri = Uri.parse(appSettings.videoWsUrl);
      _wwsVideoPort = videoWsUri.port;
      _webSocketVideoAddress = videoWsUri.host;
      _webSocketVideoSchema = videoWsUri.scheme;
      /*_wwsVideoPort = 8086;//videoWsUri.port;
      _webSocketVideoAddress = "192.168.10.153";//videoWsUri.host;
      _webSocketVideoSchema = "http";*/

      final chatWsUri = Uri.parse(appSettings.chatWsUrl);
      _wwsChatPort = chatWsUri.port;
      _webSocketChatAddress = chatWsUri.host;
      _webSocketChatSchema = chatWsUri.scheme;
      // _wwsChatPort = 8087;//chatWsUri.port;
      // _webSocketChatAddress = "192.168.10.165";//chatWsUri.host;
      // _webSocketChatSchema = "http";
    } catch (e, s) {
      TelloLogger().e('tryInit() error: $e', stackTrace: s, caller: 'ServiceAddress');
    }
    return true;
  }
}
