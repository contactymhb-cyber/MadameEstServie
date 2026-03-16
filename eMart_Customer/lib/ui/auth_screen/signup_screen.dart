import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:emartconsumer/constants.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:emartconsumer/main.dart';
import 'package:emartconsumer/model/User.dart';
import 'package:emartconsumer/model/referral_model.dart';
import 'package:emartconsumer/services/FirebaseHelper.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/services/notification_service.dart';
import 'package:emartconsumer/services/show_toast_dialog.dart';
import 'package:emartconsumer/theme/app_them_data.dart';
import 'package:emartconsumer/theme/round_button_fill.dart';
import 'package:emartconsumer/theme/text_field_widget.dart';
import 'package:emartconsumer/ui/auth_screen/phone_number_screen.dart';
import 'package:emartconsumer/ui/location_permission_screen.dart';
import 'package:emartconsumer/ui/service_list_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class SignupScreen extends StatefulWidget {
  final User? userModel;
  final String? type;

  const SignupScreen({super.key, this.userModel, this.type});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  TextEditingController firstNameEditingController = TextEditingController();
  TextEditingController lastNameEditingController = TextEditingController();
  TextEditingController emailEditingController = TextEditingController();
  TextEditingController phoneNUmberEditingController = TextEditingController();
  TextEditingController countryCodeEditingController = TextEditingController();
  TextEditingController passwordEditingController = TextEditingController();
  TextEditingController conformPasswordEditingController = TextEditingController();
  TextEditingController referralCodeEditingController = TextEditingController();

  bool passwordVisible = true;
  bool conformPasswordVisible = true;

  String type = "";

  User userModel = User();

  @override
  void initState() {
    getArgument();
    super.initState();
  }

  getArgument() {
    type = widget.type ?? '';
    userModel = widget.userModel ?? User();
    if (type == "mobileNumber") {
      phoneNUmberEditingController.text = userModel.phoneNumber.toString();
      countryCodeEditingController.text = userModel.countryCode.toString();
    }
  }

  signUpWithEmailAndPassword(BuildContext context) async {
    if (referralCodeEditingController.text.toString().isNotEmpty) {
      await FireStoreUtils.checkReferralCodeValidOrNot(referralCodeEditingController.text.toString()).then((value) async {
        if (value == true) {
          signUp(context);
        } else {
          ShowToastDialog.showToast("Referral code is Invalid");
        }
      });
    } else {
      signUp(context);
    }
  }

  signUp(BuildContext context) async {
    ShowToastDialog.showLoader("Please wait".tr);
    if (type == "mobileNumber") {
      userModel.firstName = firstNameEditingController.text.toString();
      userModel.lastName = lastNameEditingController.text.toString();
      userModel.email = emailEditingController.text.toString().toLowerCase();
      userModel.phoneNumber = phoneNUmberEditingController.text.toString();
      userModel.role = USER_ROLE_CUSTOMER;
      userModel.fcmToken = await NotificationService.getToken();
      userModel.active = true;
      userModel.countryCode = countryCodeEditingController.text;
      userModel.createdAt = Timestamp.now();

      await FireStoreUtils.getReferralUserByCode(referralCodeEditingController.text).then((value) async {
        if (value != null) {
          ReferralModel ownReferralModel = ReferralModel(id: FireStoreUtils.getCurrentUid(), referralBy: value.id, referralCode: getReferralCode());
          await FireStoreUtils.referralAdd(ownReferralModel);
        } else {
          ReferralModel referralModel = ReferralModel(id: FireStoreUtils.getCurrentUid(), referralBy: "", referralCode: getReferralCode());
          await FireStoreUtils.referralAdd(referralModel);
        }
      });

      await FireStoreUtils.updateCurrentUser(userModel).then(
            (value) async {
          if (userModel.shippingAddress != null && userModel.shippingAddress!.isNotEmpty) {
            if (userModel.shippingAddress!.where((element) => element.isDefault == true).isNotEmpty) {
              MyAppState.selectedPosotion = userModel.shippingAddress!.where((element) => element.isDefault == true).single;
            } else {
              MyAppState.selectedPosotion = userModel.shippingAddress!.first;
            }
            pushAndRemoveUntil(context, ServiceListScreen());
          } else {
            pushAndRemoveUntil(context, LocationPermissionScreen());
          }
        },
      );
    } else {
      try {
        final credential = await auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailEditingController.text.trim(),
          password: passwordEditingController.text.trim(),
        );
        if (credential.user != null) {
          userModel.userID = credential.user!.uid;
          userModel.firstName = firstNameEditingController.text.toString();
          userModel.lastName = lastNameEditingController.text.toString();
          userModel.email = emailEditingController.text.toString().toLowerCase();
          userModel.phoneNumber = phoneNUmberEditingController.text.toString();
          userModel.role = USER_ROLE_CUSTOMER;
          userModel.fcmToken = await NotificationService.getToken();
          userModel.active = true;
          userModel.countryCode = countryCodeEditingController.text;
          userModel.createdAt = Timestamp.now();

          await FireStoreUtils.getReferralUserByCode(referralCodeEditingController.text).then((value) async {
            if (value != null) {
              ReferralModel ownReferralModel = ReferralModel(id: FireStoreUtils.getCurrentUid(), referralBy: value.id, referralCode: getReferralCode());
              await FireStoreUtils.referralAdd(ownReferralModel);
            } else {
              ReferralModel referralModel = ReferralModel(id: FireStoreUtils.getCurrentUid(), referralBy: "", referralCode: getReferralCode());
              await FireStoreUtils.referralAdd(referralModel);
            }
          });

          await FireStoreUtils.updateCurrentUser(userModel).then(
                (value) async {
              if (userModel.shippingAddress != null && userModel.shippingAddress!.isNotEmpty) {
                if (userModel.shippingAddress!.where((element) => element.isDefault == true).isNotEmpty) {
                  MyAppState.selectedPosotion = userModel.shippingAddress!.where((element) => element.isDefault == true).single;
                } else {
                  MyAppState.selectedPosotion = userModel.shippingAddress!.first;
                }
                pushAndRemoveUntil(context, ServiceListScreen());
              } else {
                pushAndRemoveUntil(context, LocationPermissionScreen());
              }
            },
          );
        }
      } on auth.FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          ShowToastDialog.showToast("The password provided is too weak.");
        } else if (e.code == 'email-already-in-use') {
          ShowToastDialog.showToast("The account already exists for that email.");
        } else if (e.code == 'invalid-email') {
          ShowToastDialog.showToast("Enter email is Invalid");
        }
      } catch (e) {
        print("====>");
        print(e);
        ShowToastDialog.showToast(e.toString());
      }
    }

    ShowToastDialog.closeLoader();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode(context) ? AppThemeData.surfaceDark : AppThemeData.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Rejoignez l'application Madame Est Servie".tr,
                  style: TextStyle(color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900, fontSize: 22, fontFamily: AppThemeData.semiBold),
                ),
                Text(
                  "Rejoignez-nous pour des recommandations sur mesure et des offres exclusives.".tr,
                  style: TextStyle(color: isDarkMode(context) ? AppThemeData.grey400 : AppThemeData.grey500, fontSize: 16, fontFamily: AppThemeData.regular),
                ),
                const SizedBox(
                  height: 32,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFieldWidget(
                        title: 'First Name'.tr,
                        controller: firstNameEditingController,
                        hintText: 'Enter First Name'.tr,
                        prefix: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SvgPicture.asset(
                            "assets/icons/ic_user.svg",
                            colorFilter: ColorFilter.mode(
                              isDarkMode(context) ? AppThemeData.grey300 : AppThemeData.grey600,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: TextFieldWidget(
                        title: 'Last Name'.tr,
                        controller: lastNameEditingController,
                        hintText: 'Enter Last Name'.tr,
                        prefix: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SvgPicture.asset(
                            "assets/icons/ic_user.svg",
                            colorFilter: ColorFilter.mode(
                              isDarkMode(context) ? AppThemeData.grey300 : AppThemeData.grey600,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                TextFieldWidget(
                  title: 'Email Address'.tr,
                  textInputType: TextInputType.emailAddress,
                  controller: emailEditingController,
                  hintText: 'Enter Email Address'.tr,
                  prefix: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SvgPicture.asset(
                      "assets/icons/ic_mail.svg",
                      colorFilter: ColorFilter.mode(
                        isDarkMode(context) ? AppThemeData.grey300 : AppThemeData.grey600,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                TextFieldWidget(
                  title: 'Phone Number'.tr,
                  controller: phoneNUmberEditingController,
                  hintText: 'Enter Phone Number'.tr,
                  enable: type == "mobileNumber" ? false : true,
                  textInputType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9]')),
                  ],
                  prefix: CountryCodePicker(
                    enabled: type == "mobileNumber" ? false : true,
                    onChanged: (value) {
                      countryCodeEditingController.text = value.dialCode.toString();
                    },
                    dialogTextStyle:
                    TextStyle(color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900, fontWeight: FontWeight.w500, fontFamily: AppThemeData.medium),
                    dialogBackgroundColor: isDarkMode(context) ? AppThemeData.grey800 : AppThemeData.grey100,
                    initialSelection: countryCodeEditingController.text,
                    comparator: (a, b) => b.name!.compareTo(a.name.toString()),
                    textStyle: TextStyle(fontSize: 14, color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900, fontFamily: AppThemeData.medium),
                    searchDecoration: InputDecoration(iconColor: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900),
                    searchStyle: TextStyle(color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900, fontWeight: FontWeight.w500, fontFamily: AppThemeData.medium),
                  ),
                ),
                type == "mobileNumber"
                    ? const SizedBox()
                    : Column(
                  children: [
                    TextFieldWidget(
                      title: 'Password'.tr,
                      controller: passwordEditingController,
                      hintText: 'Enter Password'.tr,
                      obscureText: passwordVisible,
                      prefix: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SvgPicture.asset(
                          "assets/icons/ic_lock.svg",
                          colorFilter: ColorFilter.mode(
                            isDarkMode(context) ? AppThemeData.grey300 : AppThemeData.grey600,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      suffix: Padding(
                        padding: const EdgeInsets.all(12),
                        child: InkWell(
                            onTap: () {
                              passwordVisible = !passwordVisible;
                            },
                            child: passwordVisible
                                ? SvgPicture.asset(
                              "assets/icons/ic_password_show.svg",
                              colorFilter: ColorFilter.mode(
                                isDarkMode(context) ? AppThemeData.grey300 : AppThemeData.grey600,
                                BlendMode.srcIn,
                              ),
                            )
                                : SvgPicture.asset(
                              "assets/icons/ic_password_close.svg",
                              colorFilter: ColorFilter.mode(
                                isDarkMode(context) ? AppThemeData.grey300 : AppThemeData.grey600,
                                BlendMode.srcIn,
                              ),
                            )),
                      ),
                    ),
                    TextFieldWidget(
                      title: 'Confirm Password'.tr,
                      controller: conformPasswordEditingController,
                      hintText: 'Enter Confirm Password'.tr,
                      obscureText: conformPasswordVisible,
                      prefix: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SvgPicture.asset(
                          "assets/icons/ic_lock.svg",
                          colorFilter: ColorFilter.mode(
                            isDarkMode(context) ? AppThemeData.grey300 : AppThemeData.grey600,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      suffix: Padding(
                        padding: const EdgeInsets.all(12),
                        child: InkWell(
                            onTap: () {
                              conformPasswordVisible = !conformPasswordVisible;
                            },
                            child: conformPasswordVisible
                                ? SvgPicture.asset(
                              "assets/icons/ic_password_show.svg",
                              colorFilter: ColorFilter.mode(
                                isDarkMode(context) ? AppThemeData.grey300 : AppThemeData.grey600,
                                BlendMode.srcIn,
                              ),
                            )
                                : SvgPicture.asset(
                              "assets/icons/ic_password_close.svg",
                              colorFilter: ColorFilter.mode(
                                isDarkMode(context) ? AppThemeData.grey300 : AppThemeData.grey600,
                                BlendMode.srcIn,
                              ),
                            )),
                      ),
                    ),
                  ],
                ),
                TextFieldWidget(
                  title: 'Referral Code(Optional)'.tr,
                  controller: referralCodeEditingController,
                  hintText: 'Enter Referral Code(Optional)'.tr,
                  prefix: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SvgPicture.asset(
                      "assets/icons/ic_gift.svg",
                      colorFilter: ColorFilter.mode(
                        isDarkMode(context) ? AppThemeData.grey300 : AppThemeData.grey600,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                RoundedButtonFill(
                  title: "Signup".tr,
                  color: AppThemeData.primary300,
                  textColor: AppThemeData.grey50,
                  onPress: () async {
                    if (type == "mobileNumber".tr) {
                      if (firstNameEditingController.text.isEmpty) {
                        ShowToastDialog.showToast("Please enter first name".tr);
                      } else if (lastNameEditingController.text.isEmpty) {
                        ShowToastDialog.showToast("Please enter last name".tr);
                      } else if (emailEditingController.text.isEmpty) {
                        ShowToastDialog.showToast("Please enter valid email".tr);
                      } else if (phoneNUmberEditingController.text.isEmpty) {
                        ShowToastDialog.showToast("Please enter valid phone number".tr);
                      } else {
                        signUpWithEmailAndPassword(context);
                      }
                    } else {
                      if (firstNameEditingController.text.isEmpty) {
                        ShowToastDialog.showToast("Please enter first name".tr);
                      } else if (lastNameEditingController.text.isEmpty) {
                        ShowToastDialog.showToast("Please enter last name".tr);
                      } else if (emailEditingController.text.isEmpty) {
                        ShowToastDialog.showToast("Please enter valid email".tr);
                      }else if (phoneNUmberEditingController.text.isEmpty) {
                        ShowToastDialog.showToast("Please enter valid phone number".tr);
                      }  else if (passwordEditingController.text.length < 6) {
                        ShowToastDialog.showToast("Please enter minimum 6 digit password".tr);
                      } else if (passwordEditingController.text.isEmpty) {
                        ShowToastDialog.showToast("Please enter password".tr);
                      } else if (conformPasswordEditingController.text.isEmpty) {
                        ShowToastDialog.showToast("Please enter Confirm password".tr);
                      } else if (passwordEditingController.text != conformPasswordEditingController.text) {
                        ShowToastDialog.showToast("Password and Confirm password doesn't match".tr);
                      } else {
                        signUpWithEmailAndPassword(context);
                      }
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    children: [
                      const Expanded(child: Divider(thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                        child: Text(
                          "ou".tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDarkMode(context) ? AppThemeData.grey500 : AppThemeData.grey400,
                            fontSize: 16,
                            fontFamily: AppThemeData.medium,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                ),
                RoundedButtonFill(
                  title: "Continue with Mobile Number".tr,
                  textColor: AppThemeData.primary300,
                  color: isDarkMode(context) ? AppThemeData.grey900 : AppThemeData.grey50,
                  icon: SvgPicture.asset("assets/icons/ic_phone.svg"),
                  isRight: false,
                  onPress: () async {
                    push(context, PhoneNumberScreen());
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(vertical: Platform.isAndroid ? 10 : 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                      text: 'Vous avez déjà un compte?'.tr,
                      style: TextStyle(
                        color: isDarkMode(context) ? AppThemeData.secondary300 : AppThemeData.secondary300,
                        fontFamily: AppThemeData.medium,
                        fontWeight: FontWeight.w500,
                      )),
                  const WidgetSpan(
                    child: SizedBox(
                      width: 5,
                    ),
                  ),
                  TextSpan(
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.pop(context);
                        },
                      text: 'se connecter'.tr,
                      style: TextStyle(
                          color: AppThemeData.secondary400,
                          fontFamily: AppThemeData.bold,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                          decorationColor: AppThemeData.secondary400)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
