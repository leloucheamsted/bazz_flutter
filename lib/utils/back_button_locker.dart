import 'package:back_button_interceptor/back_button_interceptor.dart';

class BackButtonLocker {
  static void lockBackButton() {
    BackButtonInterceptor.add((stopDefaultButtonEvent, routeInfo) => true);
  }

  static void unlockBackButton() {
    BackButtonInterceptor.removeAll();
  }
}
