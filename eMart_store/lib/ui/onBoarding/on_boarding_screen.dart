import 'package:emartstore/constants.dart';
import 'package:emartstore/model/on_boarding_model.dart';
import 'package:emartstore/services/FirebaseHelper.dart';
import 'package:emartstore/services/helper.dart';
import 'package:emartstore/theme/app_them_data.dart';
import 'package:emartstore/theme/responsive.dart';
import 'package:emartstore/theme/round_button_fill.dart';
import 'package:emartstore/ui/auth/AuthScreen.dart';
import 'package:emartstore/ui/login/LoginScreen.dart';
import 'package:emartstore/utils/network_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({Key? key}) : super(key: key);

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  int selectedPageIndex = 0;

  bool get isLastPage => selectedPageIndex == onBoardingList.length - 1;
  var pageController = PageController();

  @override
  void initState() {
    getOnBoardingData();
    super.initState();
  }

  bool isLoading = true;
  List<OnBoardingModel> onBoardingList = <OnBoardingModel>[];

  getOnBoardingData() async {
    await FireStoreUtils.getOnBoardingList().then((value) {
      setState(() {
        onBoardingList = value;
      });
    });
    // onBoardingList.add(OnBoardingModel(
    //     id: "",
    //     title: "All-in-One Multi-Service App",
    //     description: "Discover eMart, the ultimate platform for food delivery, on-demand eCommerce, parcel services, taxi booking, and car rentals—all in one app.",
    //     image: "assets/images/image_1.png"));
    // onBoardingList.add(OnBoardingModel(
    //     id: "",
    //     title: "Convenient & Captivating User Experience",
    //     description:
    //         "Enjoy eMart’s modern UI that makes navigating multiple services a breeze. Whether it’s booking a taxi or ordering groceries, every service is at your fingertips.",
    //     image: "assets/images/image_2.png"));
    // onBoardingList.add(OnBoardingModel(
    //     id: "",
    //     title: "From Shopping to Rides, We’ve Got You Covered",
    //     description: "Manage vendors, orders, bookings, and transactions efficiently with a user-friendly interface.",
    //     image: "assets/images/image_3.png"));

    isLoading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          isDarkMode(context) ? AppThemeData.surfaceDark : AppThemeData.surface,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
              color: isDarkMode(context)
                  ? AppThemeData.surfaceDark
                  : AppThemeData.surface,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: RoundedButtonFill(
                          title: "Skip".tr(),
                          width: 20,
                          height: 5,
                          color: isDarkMode(context)
                              ? AppThemeData.primary600
                              : AppThemeData.primary50,
                          textColor: AppThemeData.primary300,
                          onPress: () {
                            setFinishedOnBoarding();
                            pushReplacement(context, AuthScreen());
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Expanded(
                      child: PageView.builder(
                          controller: pageController,
                          onPageChanged: (value) {
                            setState(() {
                              selectedPageIndex = value;
                            });
                          },
                          itemCount: onBoardingList.length,
                          itemBuilder: (context, index) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  onBoardingList[index].title.toString(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDarkMode(context)
                                        ? AppThemeData.grey50
                                        : AppThemeData.grey900,
                                    fontSize: 24,
                                    fontFamily: AppThemeData.semiBold,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                Text(
                                  onBoardingList[index].description.toString(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDarkMode(context)
                                        ? AppThemeData.grey300
                                        : AppThemeData.grey600,
                                    fontSize: 14,
                                    fontFamily: AppThemeData.regular,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                Expanded(
                                  child: NetworkImageWidget(
                                    imageUrl: onBoardingList[selectedPageIndex].image
                                        .toString(),
                                    width: Responsive.width(90, context),
                                  ),
                                ),
                              ],
                            );
                          }),
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    RoundedButtonFill(
                      title: selectedPageIndex == 2
                          ? "Get Started".tr()
                          : "Next".tr(),
                      width: 60,
                      color: selectedPageIndex == 2
                          ? isDarkMode(context)
                              ? AppThemeData.grey50
                              : AppThemeData.grey900
                          : isDarkMode(context)
                              ? AppThemeData.grey900
                              : AppThemeData.grey200,
                      textColor: selectedPageIndex == 2
                          ? isDarkMode(context)
                              ? AppThemeData.grey900
                              : AppThemeData.grey50
                          : isDarkMode(context)
                              ? AppThemeData.grey50
                              : AppThemeData.grey900,
                      onPress: () {
                        if (selectedPageIndex == 2) {
                          setFinishedOnBoarding();
                          pushReplacement(context, AuthScreen());
                        } else {
                          pageController.jumpToPage(selectedPageIndex + 1);
                        }
                      },
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<bool> setFinishedOnBoarding() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(FINISHED_ON_BOARDING, true);
  }
}
