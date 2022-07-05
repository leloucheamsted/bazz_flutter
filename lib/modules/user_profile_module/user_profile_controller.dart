import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/routes/app_pages.dart';
import 'package:get/get.dart';

class UserProfileController extends GetxController {
  static UserProfileController get to => Get.find();

  final _loadingState = ViewState.idle.obs;

  ViewState get loadingState => _loadingState.value;

  void onConfirmPressed() {
    Get.until((route) => route.isFirst);
  }
}
