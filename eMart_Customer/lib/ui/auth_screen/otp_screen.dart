import 'package:easy_localization/easy_localization.dart';
import 'package:emartconsumer/constants.dart';
import 'package:emartconsumer/main.dart';
import 'package:emartconsumer/model/User.dart';
import 'package:emartconsumer/services/FirebaseHelper.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/services/notification_service.dart';
import 'package:emartconsumer/services/show_toast_dialog.dart';
import 'package:emartconsumer/theme/app_them_data.dart';
import 'package:emartconsumer/theme/round_button_fill.dart';
import 'package:emartconsumer/ui/auth_screen/login_screen.dart';
import 'package:emartconsumer/ui/auth_screen/signup_screen.dart';
import 'package:emartconsumer/ui/container/ContainerScreen.dart';
import 'package:emartconsumer/ui/location_permission_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';


class OtpScreen extends StatefulWidget {
  final String? countryCode;
  final String? phoneNumber;
  final String? verificationId;

  const OtpScreen({super.key, this.countryCode, this.phoneNumber, this.verificationId});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  @override
  void initState() {
    getArgument();
    super.initState();
  }

  TextEditingController otpController = TextEditingController();

  String countryCode = "";
  String phoneNumber = "";
  String verificationId = "";
  int resendToken = 0;
  bool isLoading = true;

  getArgument() async {
    countryCode = widget.countryCode ?? '';
    phoneNumber = widget.phoneNumber ?? '';
    verificationId = widget.verificationId ?? '';
    isLoading = false;
    setState(() {});
  }

  Future<bool> sendOTP() async {
    await auth.FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: countryCode + phoneNumber,
      verificationCompleted: (auth.PhoneAuthCredential credential) {},
      verificationFailed: (auth.FirebaseAuthException e) {},
      codeSent: (String verificationId0, int? resendToken0) async {
        verificationId = verificationId0;
        resendToken = resendToken0!;
        ShowToastDialog.showToast("OTP sent");
      },
      timeout: const Duration(seconds: 25),
      forceResendingToken: resendToken,
      codeAutoRetrievalTimeout: (String verificationId0) {
        verificationId0 = verificationId;
      },
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode(context) ? AppThemeData.surfaceDark : AppThemeData.surface,
      ),
      body: isLoading
          ? loader()
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Verify Your Number".tr(),
                      style: TextStyle(
                          color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900, fontSize: 22, fontFamily: AppThemeData.semiBold),
                    ),
                    Text(
                      "Enter the OTP sent to your mobile to confirm your number and continue shopping.".tr(),
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: isDarkMode(context) ? AppThemeData.grey200 : AppThemeData.grey700,
                        fontSize: 16,
                        fontFamily: AppThemeData.regular,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(
                      height: 60,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: PinCodeTextField(
                        length: 6,
                        appContext: context,
                        keyboardType: TextInputType.phone,
                        enablePinAutofill: true,
                        hintCharacter: "-",
                        textStyle:
                            TextStyle(color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900, fontFamily: AppThemeData.regular),
                        pinTheme: PinTheme(
                            fieldHeight: 50,
                            fieldWidth: 50,
                            inactiveFillColor: isDarkMode(context) ? AppThemeData.grey900 : AppThemeData.grey50,
                            selectedFillColor: isDarkMode(context) ? AppThemeData.grey900 : AppThemeData.grey50,
                            activeFillColor: isDarkMode(context) ? AppThemeData.grey900 : AppThemeData.grey50,
                            selectedColor: isDarkMode(context) ? AppThemeData.grey900 : AppThemeData.grey50,
                            activeColor: isDarkMode(context) ? AppThemeData.primary300 : AppThemeData.primary300,
                            inactiveColor: isDarkMode(context) ? AppThemeData.grey900 : AppThemeData.grey50,
                            disabledColor: isDarkMode(context) ? AppThemeData.grey900 : AppThemeData.grey50,
                            shape: PinCodeFieldShape.box,
                            errorBorderColor: isDarkMode(context) ? AppThemeData.grey600 : AppThemeData.grey300,
                            borderRadius: const BorderRadius.all(Radius.circular(10))),
                        cursorColor: AppThemeData.primary300,
                        enableActiveFill: true,
                        controller: otpController,
                        onCompleted: (v) async {},
                        onChanged: (value) {},
                      ),
                    ),
                    const SizedBox(
                      height: 50,
                    ),
                    RoundedButtonFill(
                      title: "Verify & Next".tr(),
                      color: AppThemeData.primary300,
                      textColor: AppThemeData.grey50,
                      onPress: () async {
                        if (otpController.text.length == 6) {
                          ShowToastDialog.showLoader("Verify otp".tr());

                          auth.PhoneAuthCredential credential =
                              auth.PhoneAuthProvider.credential(verificationId: verificationId, smsCode: otpController.text);
                          String fcmToken = await NotificationService.getToken();
                          await auth.FirebaseAuth.instance.signInWithCredential(credential).then((value) async {
                            if (value.additionalUserInfo!.isNewUser) {
                              User userModel = User();
                              userModel.userID = value.user!.uid;
                              userModel.countryCode = countryCode;
                              userModel.phoneNumber = phoneNumber;
                              userModel.fcmToken = fcmToken;

                              ShowToastDialog.closeLoader();
                              push(
                                  context,
                                  SignupScreen(
                                    type: "mobileNumber",
                                    userModel: userModel,
                                  ));
                            } else {
                              await FireStoreUtils.userExistOrNot(value.user!.uid).then((userExit) async {
                                ShowToastDialog.closeLoader();
                                if (userExit == true) {
                                  User? userModel = await FireStoreUtils.getUserProfile(value.user!.uid);
                                  if (userModel!.role == USER_ROLE_CUSTOMER) {
                                    if (userModel.active == true) {
                                      userModel.fcmToken = await NotificationService.getToken();
                                      await FireStoreUtils.updateCurrentUser(userModel);
                                      if (userModel.shippingAddress != null && userModel.shippingAddress!.isNotEmpty) {
                                        if (userModel.shippingAddress!.where((element) => element.isDefault == true).isNotEmpty) {
                                          MyAppState.selectedPosotion =
                                              userModel.shippingAddress!.where((element) => element.isDefault == true).single;
                                        } else {
                                          MyAppState.selectedPosotion = userModel.shippingAddress!.first;
                                        }
                                        pushAndRemoveUntil(context, ContainerScreen(user: userModel));
                                      } else {
                                        pushAndRemoveUntil(context, LocationPermissionScreen());
                                      }
                                    } else {
                                      ShowToastDialog.showToast("This user is disable please contact to administrator".tr());
                                      await auth.FirebaseAuth.instance.signOut();
                                      pushAndRemoveUntil(context, LoginScreen());
                                    }
                                  } else {
                                    await auth.FirebaseAuth.instance.signOut();
                                    pushAndRemoveUntil(context, LoginScreen());
                                  }
                                } else {
                                  User userModel = User();
                                  userModel.userID = value.user!.uid;
                                  userModel.countryCode = countryCode;
                                  userModel.phoneNumber = phoneNumber;
                                  userModel.fcmToken = fcmToken;

                                  pushReplacement(
                                      context,
                                      SignupScreen(
                                        userModel: userModel,
                                        type: "mobileNumber",
                                      ));
                                }
                              });
                            }
                          }).catchError((error) {
                            print(error);
                            ShowToastDialog.closeLoader();
                            ShowToastDialog.showToast("Invalid Code".tr());
                          });
                        } else {
                          ShowToastDialog.showToast("Enter Valid otp".tr());
                        }
                      },
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                    Text.rich(
                      textAlign: TextAlign.start,
                      TextSpan(
                        text: "Did’t receive any code?".tr(),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          fontFamily: AppThemeData.medium,
                          color: isDarkMode(context) ? AppThemeData.grey100 : AppThemeData.grey800,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                otpController.clear();
                                sendOTP();
                              },
                            text: 'Send Again'.tr(),
                            style: TextStyle(
                                color: isDarkMode(context) ? AppThemeData.primary300 : AppThemeData.primary300,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                fontFamily: AppThemeData.medium,
                                decoration: TextDecoration.underline,
                                decorationColor: AppThemeData.primary300),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
