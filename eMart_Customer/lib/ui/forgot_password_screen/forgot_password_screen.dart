
import 'package:emartconsumer/controller/forgot_password_controller.dart';
import 'package:emartconsumer/services/show_toast_dialog.dart';
import 'package:emartconsumer/theme/app_them_data.dart';
import 'package:emartconsumer/theme/round_button_fill.dart';
import 'package:emartconsumer/theme/text_field_widget.dart';
import 'package:emartconsumer/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
      init: ForgotPasswordController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: themeChange.getThem() ? AppThemeData.surfaceDark : AppThemeData.surface,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mot de passe oublié?".tr,
                  style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900, fontSize: 22, fontFamily: AppThemeData.semiBold),
                ),
                Text(
                  "Pas de souci ! Réinitialisez votre mot de passe et retrouvez votre expérience culinaire en quelques secondes.".tr,
                  style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey500, fontSize: 16, fontFamily: AppThemeData.regular),
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
                        themeChange.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 32,
                ),

                RoundedButtonFill(
                  title: "Forgot Password".tr,
                  color: AppThemeData.primary300,
                  textColor: AppThemeData.grey50,
                  onPress: () async {
                    if (controller.emailEditingController.value.text.isEmpty) {
                      ShowToastDialog.showToast("Please enter valid email");
                    }  else {
                      controller.forgotPassword();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}
