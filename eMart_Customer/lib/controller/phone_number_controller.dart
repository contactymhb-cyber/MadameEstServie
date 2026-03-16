import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/services/show_toast_dialog.dart';
import 'package:emartconsumer/ui/auth_screen/otp_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PhoneNumberController extends GetxController {
  Rx<TextEditingController> phoneNUmberEditingController = TextEditingController().obs;
  Rx<TextEditingController> countryCodeEditingController = TextEditingController().obs;

  sendCode(BuildContext context) async {
    ShowToastDialog.showLoader("Please wait".tr);
    await FirebaseAuth.instance
        .verifyPhoneNumber(
            phoneNumber: countryCodeEditingController.value.text + phoneNUmberEditingController.value.text,
            verificationCompleted: (PhoneAuthCredential credential) {},
            verificationFailed: (FirebaseAuthException e) {
              debugPrint("FirebaseAuthException--->${e.message}");
              ShowToastDialog.closeLoader();
              if (e.code == 'invalid-phone-number') {
                ShowToastDialog.showToast("invalid_phone_number".tr);
              } else {
                ShowToastDialog.showToast(e.message);
              }
            },
            codeSent: (String verificationId, int? resendToken) {
              ShowToastDialog.closeLoader();
              push(context, OtpScreen(countryCode: countryCodeEditingController.value.text,phoneNumber: phoneNUmberEditingController.value.text,verificationId: verificationId,));
            },
            codeAutoRetrievalTimeout: (String verificationId) {})
        .catchError((error) {
      debugPrint("catchError--->$error");
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("multiple_time_request".tr);
    });
  }
}
