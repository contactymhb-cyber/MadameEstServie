import 'dart:async';
import 'dart:developer';
import 'package:emartstore/model/CurrencyModel.dart';
import 'package:emartstore/theme/app_them_data.dart';
import 'package:emartstore/ui/onBoarding/on_boarding_screen.dart';
import 'package:emartstore/ui/subscription_screen/app_not_access_screen.dart';
import 'package:emartstore/ui/subscription_screen/subscription_screens.dart';
import 'package:emartstore/utils/Preferences.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emartstore/constants.dart';
import 'package:emartstore/firebase_options.dart';
import 'package:emartstore/model/User.dart';
import 'package:emartstore/model/mail_setting.dart';
import 'package:emartstore/services/FirebaseHelper.dart';
import 'package:emartstore/services/helper.dart';
import 'package:emartstore/services/notification_service.dart';
import 'package:emartstore/ui/auth/AuthScreen.dart';
import 'package:emartstore/ui/container/ContainerScreen.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  await Preferences.initPref();
  runApp(
    EasyLocalization(
        supportedLocales: [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        fallbackLocale: Preferences.getString('languageCode').isNotEmpty
            ? Locale(Preferences.getString('languageCode'))
            : Locale('en'),
        useFallbackTranslations: true,
        saveLocale: true,
        useOnlyLangCode: true,
        child: MyApp()),
  );
}

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static User? currentUser;

  static AudioPlayer audioPlayer = AudioPlayer(playerId: "playerId");

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    audioPlayer.stop();
    print("0000000000--------->${MyAppState.audioPlayer.state}");
  }

  // Define an async function to initialize FlutterFire
  void initializeFlutterFire() async {
    try {
      await FirebaseFirestore.instance
          .collection(Setting)
          .doc('vendor')
          .get()
          .then((value) {
        isSubscriptionModelApplied = value.data()!['subscription_model'];
      });

      await FirebaseFirestore.instance
          .collection(Setting)
          .doc("ContactUs")
          .get()
          .then((value) {
        adminEmail = value.data()!['Email'].toString();
      });

      await FirebaseFirestore.instance
          .collection(Setting)
          .doc("globalSettings")
          .get()
          .then((value) {
        AppThemeData.secondary300 = Color(int.parse(
            value.data()!['app_store_color'].replaceFirst("#", "0xff")));
        COLOR_PRIMARY = int.parse(
            value.data()!['app_store_color'].replaceFirst("#", "0xff"));
      });

      await FirebaseFirestore.instance
          .collection(Setting)
          .doc("emailSetting")
          .get()
          .then((value) {
        if (value.exists) {
          mailSettings = MailSettings.fromJson(value.data()!);
        }
      });

      await FirebaseFirestore.instance
          .collection(Setting)
          .doc("Version")
          .get()
          .then((value) {
        print(value.data());
        appVersion = value.data()!['app_version'].toString();
        storeUrl = value.data()!['storeUrl'].toString();
      });

      await FirebaseFirestore.instance
          .collection(Setting)
          .doc("googleMapKey")
          .get()
          .then((value) {
        print(value.data());
        GOOGLE_API_KEY = value.data()!['key'].toString();
      });

      await FirebaseFirestore.instance
          .collection(Setting)
          .doc("DriverNearBy")
          .get()
          .then((value) {
        selectedMapType = value.data()!['selectedMapType'].toString();
      });

      await FirebaseFirestore.instance
          .collection(Setting)
          .doc("notification_setting")
          .get()
          .then((value) {
        senderId = value.data()!['senderId'].toString();
        jsonNotificationFileURL = value.data()!['serviceJson'].toString();
      });

      await FireStoreUtils().getCurrency().then((value) {
        if (value != null) {
          currencyData = value;
        } else {
          currencyData = CurrencyModel(
              id: "",
              code: "USD",
              decimal: 2,
              isactive: true,
              name: "US Dollar",
              symbol: "\$",
              symbolatright: false);
        }
      });
    } catch (e) {
      setState(() {
        print(e.toString() + "==========ERROR");
      });
    }

    FireStoreUtils.getWalletSettingData();
    FireStoreUtils.getRazorPayDemo();
    FireStoreUtils.getPaypalSettingData();
    FireStoreUtils.getStripeSettingData();
    FireStoreUtils.getPayStackSettingData();
    FireStoreUtils.getFlutterWaveSettingData();
    FireStoreUtils.getPaytmSettingData();
    FireStoreUtils.getPayFastSettingData();
    FireStoreUtils.getMercadoPagoSettingData();
    FireStoreUtils.getOrangeMoneySettingData();
    FireStoreUtils.getXenditSettingData();
    FireStoreUtils.getMidTransSettingData();
  }

  NotificationService notificationService = NotificationService();

  notificationInit() {
    notificationService.initInfo().then((value) async {
      String token = await NotificationService.getToken();
      log(":::::::TOKEN:::::: $token");
      if (currentUser != null) {
        await FireStoreUtils.getCurrentUser(currentUser!.userID).then((value) {
          if (value != null) {
            currentUser = value;
            currentUser!.fcmToken = token;
            FireStoreUtils.updateCurrentUser(currentUser!);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        navigatorKey: notificationService.navigatorKey,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        title: 'Store Dashboard'.tr(),
        builder: EasyLoading.init(),
        theme: ThemeData(
            bottomSheetTheme:
                BottomSheetThemeData(backgroundColor: Colors.white),
            primaryColor: Color(COLOR_PRIMARY),
            brightness: Brightness.light,
            textSelectionTheme:
                TextSelectionThemeData(selectionColor: Colors.black),
            appBarTheme: AppBarTheme(
                centerTitle: true,
                titleTextStyle: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.normal),
                color: Colors.transparent,
                elevation: 0,
                actionsIconTheme: IconThemeData(color: Color(COLOR_PRIMARY)),
                iconTheme: IconThemeData(color: Color(COLOR_PRIMARY)))),
        darkTheme: ThemeData(
            bottomSheetTheme:
                BottomSheetThemeData(backgroundColor: Colors.grey.shade900),
            primaryColor: Color(COLOR_PRIMARY),
            brightness: Brightness.light,
            textSelectionTheme:
                TextSelectionThemeData(selectionColor: Colors.white),
            appBarTheme: AppBarTheme(
                centerTitle: true,
                titleTextStyle: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.normal),
                color: Colors.transparent,
                elevation: 0,
                actionsIconTheme: IconThemeData(color: Color(COLOR_PRIMARY)),
                iconTheme: IconThemeData(color: Color(COLOR_PRIMARY)))),
        debugShowCheckedModeBanner: false,
        color: Color(COLOR_PRIMARY),
        home: const FlutterSplashScreen(),
);
  }

  @override
  void initState() {
    notificationInit();
    initializeFlutterFire();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class FlutterSplashScreen extends StatefulWidget {
  const FlutterSplashScreen({Key? key}) : super(key: key);

  @override
  State<FlutterSplashScreen> createState() => _FlutterSplashScreenState();
}

class _FlutterSplashScreenState extends State<FlutterSplashScreen> {
  @override
  void initState() {
    super.initState();
    _goNext();
  }

  Future<void> _goNext() async {
    // SHOW SPLASH FOR 2 SECONDS
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => OnBoarding()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// SPLASH IMAGE (FULL SCREEN)
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash.png',
              fit: BoxFit.cover,
            ),
          ),

          /// LOADING INDICATOR
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class OnBoarding extends StatefulWidget {
  @override
  State createState() {
    return OnBoardingState();
  }
}

class OnBoardingState extends State<OnBoarding> {
  Future hasFinishedOnBoarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool finishedOnBoarding = (prefs.getBool(FINISHED_ON_BOARDING) ?? false);

    if (finishedOnBoarding) {
      auth.User? firebaseUser = auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        User? user = await FireStoreUtils.getCurrentUser(firebaseUser.uid);
        if (user != null && user.role == USER_ROLE_VENDOR) {
          if (user.active == true) {
            user.active = true;
            user.role = USER_ROLE_VENDOR;
            FireStoreUtils.firebaseMessaging.getToken().then((value) async {
              user.fcmToken = value!;
              await FireStoreUtils.firestore
                  .collection(USERS)
                  .doc(user.userID)
                  .update({"fcmToken": user.fcmToken});
              if (user.vendorID.isNotEmpty) {
                await FireStoreUtils.firestore
                    .collection(VENDORS)
                    .doc(user.vendorID)
                    .update({"fcmToken": value});
              }
            });
            MyAppState.currentUser = user;

            if (MyAppState.currentUser!.section_id.isNotEmpty) {
              await FireStoreUtils.getSectionsById(
                      MyAppState.currentUser!.section_id)
                  .then(
                (value) {
                  if (value != null) {
                    selectedSectionModel = value;
                  }
                },
              );
            }
            if (MyAppState.currentUser!.section_id.isEmpty &&
                isSubscriptionModelApplied == false) {
              pushAndRemoveUntil(context, ContainerScreen(user: user), false);
            } else if (user.subscriptionPlanId == null ||
                isExpire(user) == true) {
              if ((selectedSectionModel != null &&
                      selectedSectionModel!.adminCommision!.enable == false) &&
                  isSubscriptionModelApplied == false) {
                pushAndRemoveUntil(context, ContainerScreen(user: user), false);
              } else {
                pushAndRemoveUntil(
                    context,
                    SubscriptionScreens(
                      isShowAppBar: false,
                      isDropDownDisble:
                          user.section_id.isEmpty == true ? false : true,
                    ),
                    false);
              }
            } else if (user.subscriptionPlan?.features?.ownerMobileApp ==
                true) {
              pushAndRemoveUntil(context, ContainerScreen(user: user), false);
            } else {
              pushAndRemoveUntil(context, AppNotAccessScreen(), false);
            }
          } else {
            user.lastOnlineTimestamp = Timestamp.now();
            await FireStoreUtils.firestore
                .collection(USERS)
                .doc(user.userID)
                .update({"fcmToken": ""});
            if (user.vendorID.isNotEmpty) {
              await FireStoreUtils.firestore
                  .collection(VENDORS)
                  .doc(user.vendorID)
                  .update({"fcmToken": ""});
            }
            // await FireStoreUtils.updateCurrentUser(user);
            await auth.FirebaseAuth.instance.signOut();
            MyAppState.currentUser = null;
            pushReplacement(context, new AuthScreen());
          }
        } else {
          pushReplacement(context, new AuthScreen());
        }
      } else {
        pushReplacement(context, new AuthScreen());
      }
    } else {
      pushReplacement(context, new OnBoardingScreen());
    }
  }

  @override
  void initState() {
    super.initState();
    hasFinishedOnBoarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
