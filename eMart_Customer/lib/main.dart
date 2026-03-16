import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emartconsumer/constants.dart';
import 'package:emartconsumer/firebase_options.dart';
import 'package:emartconsumer/model/AddressModel.dart';
import 'package:emartconsumer/model/CurrencyModel.dart';
import 'package:emartconsumer/model/mail_setting.dart';
import 'package:emartconsumer/services/FirebaseHelper.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/services/localDatabase.dart';
import 'package:emartconsumer/services/notification_service.dart';
import 'package:emartconsumer/ui/service_list_screen.dart';
import 'package:emartconsumer/ui/auth_screen/login_screen.dart';
import 'package:emartconsumer/ui/location_permission_screen.dart';
import 'package:emartconsumer/ui/onBoarding/on_boarding_screen.dart';
import 'package:emartconsumer/userPrefrence.dart';
import 'package:emartconsumer/utils/Styles.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model/User.dart';
import 'theme/app_them_data.dart';
import 'utils/DarkThemeProvider.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest,
  );

  await EasyLocalization.ensureInitialized();

  FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance
      .setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  await UserPreference.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<CartDatabase>(create: (_) => CartDatabase()),
      ],
      child: EasyLocalization(
        supportedLocales: const [
          Locale('en'),
          Locale('ar'),
          Locale('fr'),
          Locale('nl')
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        saveLocale: false,
        useOnlyLangCode: true,
        useFallbackTranslations: true,
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static User? currentUser;
  static AddressModel selectedPosotion = AddressModel();

  NotificationService notificationService = NotificationService();
  DarkThemeProvider themeChangeProvider = DarkThemeProvider();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    notificationInit();
    initializeFlutterFire();
    getCurrentAppTheme();
  }

  void notificationInit() {
    notificationService.initInfo().then((value) async {
      String token = await NotificationService.getToken();
      log("FCM TOKEN: $token");

      if (currentUser != null) {
        await FireStoreUtils.getCurrentUser(currentUser!.userID)
            .then((value) {
          if (value != null) {
            currentUser = value;
            currentUser!.fcmToken = token;
            FireStoreUtils.updateCurrentUser(currentUser!);
          }
        });
      }
    });
  }

  void initializeFlutterFire() async {
    try {
      await FireStoreUtils.firestore
          .collection(Setting)
          .doc("globalSettings")
          .get()
          .then((value) {
        if (value.exists) {
          AppThemeData.primary300 = Color(
              int.parse(value.data()!['app_customer_color']
                  .replaceFirst("#", "0xff")));
        }
      });

      SharedPreferences sp = await SharedPreferences.getInstance();
      if (sp.getString("languageCode")?.isNotEmpty == true) {
        context.setLocale(
            Locale(sp.getString("languageCode") ?? "fr"));
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void getCurrentAppTheme() async {
    themeChangeProvider.darkTheme =
        await themeChangeProvider.darkThemePreference.getTheme();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => themeChangeProvider,
      child: Consumer<DarkThemeProvider>(
        builder: (context, value, child) {
          return MaterialApp(
            navigatorKey: notificationService.navigatorKey,
            localizationsDelegates: context.localizationDelegates,
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            debugShowCheckedModeBanner: false,
            theme: Styles.themeData(
                themeChangeProvider.darkTheme, context),
            builder: EasyLoading.init(),
            home: const FlutterSplashScreen(), // 👈 SPLASH FIRST
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

/* -------------------------------------------------------------------------- */
/*                              FLUTTER SPLASH                                */
/* -------------------------------------------------------------------------- */

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
      MaterialPageRoute(builder: (_) => const OnBoarding()),
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

          /// LOADING INDICATOR (BOTTOM CENTER)
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(
                  Colors.white, // change if needed
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


/* -------------------------------------------------------------------------- */
/*                                ONBOARDING                                  */
/* -------------------------------------------------------------------------- */

class OnBoarding extends StatefulWidget {
  const OnBoarding({Key? key}) : super(key: key);

  @override
  State<OnBoarding> createState() => OnBoardingState();
}

class OnBoardingState extends State<OnBoarding> {
  @override
  void initState() {
    super.initState();
    hasFinishedOnBoarding();
  }

  Future hasFinishedOnBoarding() async {
    SharedPreferences prefs =
        await SharedPreferences.getInstance();
    bool finished =
        (prefs.getBool(FINISHED_ON_BOARDING) ?? false);

    if (!mounted) return;

    if (!finished) {
      pushReplacement(context, const OnBoardingScreen());
      return;
    }

    auth.User? firebaseUser =
        auth.FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      pushReplacement(context, const LoginScreen());
      return;
    }

    User? user =
        await FireStoreUtils.getCurrentUser(firebaseUser.uid);

    if (user == null || !user.active) {
      await auth.FirebaseAuth.instance.signOut();
      pushReplacement(context, const LoginScreen());
      return;
    }

    MyAppState.currentUser = user;

   if (user.shippingAddress != null &&
    user.shippingAddress!.isNotEmpty) {

  MyAppState.selectedPosotion =
      user.shippingAddress!.firstWhere(
    (e) => e.isDefault == true,
    orElse: () => user.shippingAddress!.first,
  );

  pushReplacement(context, const ServiceListScreen());
} else {
  pushAndRemoveUntil(context, LocationPermissionScreen());
}

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode(context)
          ? AppThemeData.surfaceDark
          : AppThemeData.surface,
      body: Center(
        child: CircularProgressIndicator.adaptive(
          valueColor:
              AlwaysStoppedAnimation(AppThemeData.primary300),
        ),
      ),
    );
  }
}
