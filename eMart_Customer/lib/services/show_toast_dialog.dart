import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart' hide tr;

class ShowToastDialog {
  static showToast(String? message, {EasyLoadingToastPosition position = EasyLoadingToastPosition.top}) {
    EasyLoading.showToast(message!, toastPosition: position);
  }

  static showLoader(String message) {
    EasyLoading.show(
      status: message,
      dismissOnTap: false,
      maskType: EasyLoadingMaskType.clear,
    );
  }

  static closeLoader() {
    EasyLoading.dismiss();
  }
}
