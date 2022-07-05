import 'package:get/get.dart';

extension Inst on GetInterface {
  Future<SnackbarController> showSnackbarEx<T>(GetBar snackbar) async {
    /* if (Get.isRegistered<HomeController>() && HomeController.to.txState.value.state != StreamingState.idle) {
      return null;
    }*/
    if (Get.isSnackbarOpen) {
      Get.back();
    }
    return Get.showSnackbar(snackbar);
  }
}
