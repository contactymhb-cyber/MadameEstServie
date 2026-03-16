import 'dart:io';

import 'package:emartconsumer/controller/login_controller.dart';
import 'package:emartconsumer/main.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/services/show_toast_dialog.dart';
import 'package:emartconsumer/theme/app_them_data.dart';
import 'package:emartconsumer/theme/round_button_fill.dart';
import 'package:emartconsumer/theme/text_field_widget.dart';
import 'package:emartconsumer/ui/auth_screen/phone_number_screen.dart';
import 'package:emartconsumer/ui/auth_screen/signup_screen.dart';
import 'package:emartconsumer/ui/forgot_password_screen/forgot_password_screen.dart';
import 'package:emartconsumer/ui/location_permission_screen.dart';
import 'package:emartconsumer/ui/service_list_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX(
        init: LoginController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: isDarkMode(context) ? AppThemeData.surfaceDark : AppThemeData.surface,
            appBar: AppBar(
              backgroundColor: isDarkMode(context) ? AppThemeData.surfaceDark : AppThemeData.surface,
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  child: RoundedButtonFill(
                    title: "Skip".tr,
                    width: 16,
                    textColor: AppThemeData.grey50,
                    color: isDarkMode(context) ? AppThemeData.primary300 : AppThemeData.primary300.withOpacity(0.40),
                    isRight: false,
                    onPress: () async {
                      LocationPermission permission = await Geolocator.checkPermission();
                      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
                        if (MyAppState.selectedPosotion.location == null) {
                          pushAndRemoveUntil(context, LocationPermissionScreen());
                        } else {
                          pushAndRemoveUntil(context, ServiceListScreen());
                        }
                      } else {
                        pushAndRemoveUntil(context, LocationPermissionScreen());
                      }
                    },
                  ),
                ),
              ],
            ),
            body:  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Bon retour!".tr,
                            style: TextStyle(color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900, fontSize: 22, fontFamily: AppThemeData.semiBold),
                          ),
                          Text(
                            "Connectez-vous pour explorer vos favoris et faire vos achats en toute simplicité.".tr,
                            style: TextStyle(color: isDarkMode(context) ? AppThemeData.grey400 : AppThemeData.grey500, fontSize: 16, fontFamily: AppThemeData.regular),
                          ),
                          const SizedBox(
                            height: 32,
                          ),
                          TextFieldWidget(
                            title: 'Email Address'.tr,
                            controller: controller.emailEditingController.value,
                            hintText: 'Enter email address'.tr,
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
                            title: 'Password'.tr,
                            controller: controller.passwordEditingController.value,
                            hintText: 'Enter password'.tr,
                            obscureText: controller.passwordVisible.value,
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
                                    controller.passwordVisible.value = !controller.passwordVisible.value;
                                  },
                                  child: controller.passwordVisible.value
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
                          Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              onTap: () {
                                push(context, ForgotPasswordScreen());
                              },
                              child: Text(
                                "Mot de passe oublié".tr,
                                style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppThemeData.secondary300,
                                    color: isDarkMode(context) ? AppThemeData.secondary300 : AppThemeData.secondary300,
                                    fontSize: 14,
                                    fontFamily: AppThemeData.regular),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          RoundedButtonFill(
                            title: "Login".tr,
                            color: AppThemeData.primary300,
                            textColor: AppThemeData.grey50,
                            onPress: () async {
                              if (controller.emailEditingController.value.text.isEmpty) {
                                ShowToastDialog.showToast("Please enter valid email".tr);
                              } else if (controller.passwordEditingController.value.text.isEmpty) {
                                ShowToastDialog.showToast("Please enter valid password".tr);
                              } else {
                                controller.loginWithEmailAndPassword(context);
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
                            isRight: false,
                            onPress: () async {
                              push(context, PhoneNumberScreen());
                            },
                          ),
                        ],
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
                            text: 'Vous ne possédez pas de compte?'.tr,
                            style: TextStyle(
                              color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900,
                              fontFamily: AppThemeData.medium,
                              fontWeight: FontWeight.w500,
                            )),
                        const WidgetSpan(
                          child: SizedBox(
                            width: 10,
                          ),
                        ),
                        TextSpan(
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                push(context, SignupScreen());
                              },
                            text: 'Créer un compte'.tr,
                            style: TextStyle(
                                color: AppThemeData.primary300,
                                fontFamily: AppThemeData.bold,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                                decorationColor: AppThemeData.primary300)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
