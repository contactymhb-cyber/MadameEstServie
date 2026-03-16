import 'dart:io';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:emartconsumer/controller/phone_number_controller.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/services/show_toast_dialog.dart';
import 'package:emartconsumer/theme/app_them_data.dart';
import 'package:emartconsumer/theme/round_button_fill.dart';
import 'package:emartconsumer/theme/text_field_widget.dart';
import 'package:emartconsumer/ui/auth_screen/signup_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class PhoneNumberScreen extends StatelessWidget {
  const PhoneNumberScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX(
        init: PhoneNumberController(),
        builder: (controller) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: isDarkMode(context) ? AppThemeData.surfaceDark : AppThemeData.surface,
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Accès rapide depuis mobile".tr,
                      style: TextStyle(color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900, fontSize: 22, fontFamily: AppThemeData.semiBold),
                    ),
                    Text(
                      "Utilisez votre numéro de téléphone pour vous connecter facilement et en toute sécurité.".tr,
                      style: TextStyle(color: isDarkMode(context) ? AppThemeData.grey400 : AppThemeData.grey500, fontSize: 16, fontFamily: AppThemeData.regular),
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    TextFieldWidget(
                      title: 'Phone Number'.tr,
                      controller: controller.phoneNUmberEditingController.value,
                      hintText: 'Enter Phone Number'.tr,
                      textInputType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[0-9]')),
                      ],
                      prefix: CountryCodePicker(
                        onChanged: (value) {
                          controller.countryCodeEditingController.value.text = value.dialCode.toString();
                        },
                        dialogTextStyle:
                            TextStyle(color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900, fontWeight: FontWeight.w500, fontFamily: AppThemeData.medium),
                        dialogBackgroundColor: isDarkMode(context) ? AppThemeData.grey800 : AppThemeData.grey100,
                        initialSelection: controller.countryCodeEditingController.value.text,
                        comparator: (a, b) => b.name!.compareTo(a.name.toString()),
                        textStyle: TextStyle(fontSize: 14, color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900, fontFamily: AppThemeData.medium),
                        searchDecoration: InputDecoration(iconColor: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900),
                        searchStyle:
                            TextStyle(color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900, fontWeight: FontWeight.w500, fontFamily: AppThemeData.medium),
                      ),
                    ),
                    const SizedBox(
                      height: 36,
                    ),
                    RoundedButtonFill(
                      title: "Send OTP".tr,
                      color: AppThemeData.primary300,
                      textColor: AppThemeData.grey50,
                      onPress: () async {
                        if (controller.phoneNUmberEditingController.value.text.isEmpty) {
                          ShowToastDialog.showToast("Please enter mobile number".tr);
                        } else {
                          controller.sendCode(context);
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
                      title: "Continue with Email".tr,
                      textColor: AppThemeData.primary300,
                      color: isDarkMode(context) ? AppThemeData.grey900 : AppThemeData.grey50,
                      icon: SvgPicture.asset(
                        "assets/icons/ic_mail.svg",
                        colorFilter: ColorFilter.mode(AppThemeData.primary300, BlendMode.srcIn),
                      ),
                      isRight: false,
                      onPress: () async {
                        Navigator.pop(context);
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
                        )),
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
