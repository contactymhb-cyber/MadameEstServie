import 'package:emartconsumer/constants.dart';
import 'package:emartconsumer/main.dart';
import 'package:emartconsumer/model/User.dart';
import 'package:emartconsumer/services/FirebaseHelper.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/services/notification_service.dart';
import 'package:emartconsumer/services/show_toast_dialog.dart';
import 'package:emartconsumer/ui/auth_screen/login_screen.dart';
import 'package:emartconsumer/ui/location_permission_screen.dart';
import 'package:emartconsumer/ui/service_list_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  Rx<TextEditingController> emailEditingController =
      TextEditingController().obs;
  Rx<TextEditingController> passwordEditingController =
      TextEditingController().obs;

  RxBool passwordVisible = true.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
  }

  loginWithEmailAndPassword(BuildContext context) async {
    ShowToastDialog.showLoader("Please wait".tr);
    try {
      final credential =
          await auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailEditingController.value.text.trim(),
        password: passwordEditingController.value.text.trim(),
      );
      User? userModel =
          await FireStoreUtils.getUserProfile(credential.user!.uid);
      if (userModel!.role == USER_ROLE_CUSTOMER) {
        if (userModel.active == true) {
          userModel.fcmToken = await NotificationService.getToken();
          await FireStoreUtils.updateCurrentUser(userModel);
          if (userModel.shippingAddress != null &&
              userModel.shippingAddress!.isNotEmpty) {
            if (userModel.shippingAddress!
                .where((element) => element.isDefault == true)
                .isNotEmpty) {
              MyAppState.selectedPosotion = userModel.shippingAddress!
                  .where((element) => element.isDefault == true)
                  .single;
            } else {
              MyAppState.selectedPosotion = userModel.shippingAddress!.first;
            }
            pushAndRemoveUntil(context, ServiceListScreen());
          } else {
            pushAndRemoveUntil(context, LocationPermissionScreen());
          }
        } else {
          await auth.FirebaseAuth.instance.signOut();
          pushAndRemoveUntil(context, LoginScreen());
          ShowToastDialog.showToast(
              "This user is disable please contact to administrator".tr);
        }
      } else {
        await auth.FirebaseAuth.instance.signOut();
        pushAndRemoveUntil(context, LoginScreen());
      }
    } on auth.FirebaseAuthException catch (e) {
      print(e.code);
      if (e.code == 'user-not-found') {
        ShowToastDialog.showToast("No user found for that email.".tr);
      } else if (e.code == 'wrong-password') {
        ShowToastDialog.showToast("Wrong password provided for that user.".tr);
      } else if (e.code == 'invalid-email') {
        ShowToastDialog.showToast("Invalid Email.".tr);
      } else {
        ShowToastDialog.showToast("${e.message}");
      }
    }
    ShowToastDialog.closeLoader();
  }
}
