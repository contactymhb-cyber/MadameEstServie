import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emartconsumer/constants.dart';
import 'package:emartconsumer/main.dart';
import 'package:emartconsumer/model/User.dart';
import 'package:emartconsumer/rental_service/rental_booking_screen.dart';
import 'package:emartconsumer/rental_service/rental_service_home_screen.dart';
import 'package:emartconsumer/services/FirebaseHelper.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/services/localDatabase.dart';
import 'package:emartconsumer/services/show_toast_dialog.dart';
import 'package:emartconsumer/theme/app_them_data.dart';
import 'package:emartconsumer/ui/Language/language_choose_screen.dart';
import 'package:emartconsumer/ui/service_list_screen.dart';
import 'package:emartconsumer/ui/auth_screen/login_screen.dart';

import 'package:emartconsumer/ui/chat_screen/inbox_driver_screen.dart';
import 'package:emartconsumer/ui/gift_card/gift_card_screen.dart';
import 'package:emartconsumer/ui/privacy_policy/privacy_policy.dart';
import 'package:emartconsumer/ui/profile/ProfileScreen.dart';
import 'package:emartconsumer/ui/referral_screen/referral_screen.dart';
import 'package:emartconsumer/ui/termsAndCondition/terms_and_codition.dart';
import 'package:emartconsumer/ui/wallet/walletScreen.dart';
import 'package:emartconsumer/userPrefrence.dart';
import 'package:emartconsumer/utils/DarkThemeProvider.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum DrawerSelection { Dashboard, Home, Wallet, referral, Profile, Orders, termsCondition, privacyPolicy, chooseLanguage, driver, Logout, giftCard }

class RentalServiceDashBoard extends StatefulWidget {
  final User? user;
  final Widget currentWidget;
  final String appBarTitle;
  final DrawerSelection drawerSelection;

  RentalServiceDashBoard({Key? key, required this.user, currentWidget, appBarTitle, this.drawerSelection = DrawerSelection.Home})
      : appBarTitle = appBarTitle ?? 'Home'.tr(),
        currentWidget = currentWidget ??
            RentalServiceHomeScreen(
              user: MyAppState.currentUser,
            ),
        super(key: key);

  @override
  State<RentalServiceDashBoard> createState() => _RentalServiceDashBoardState();
}

class _RentalServiceDashBoardState extends State<RentalServiceDashBoard> {
  var key = GlobalKey<ScaffoldState>();

  late CartDatabase cartDatabase;
  late User user;
  late String _appBarTitle;
  final fireStoreUtils = FireStoreUtils();

  late Widget _currentWidget;
  late DrawerSelection _drawerSelection;

  int cartCount = 0;
  bool? isWalletEnable;

  @override
  void initState() {
    FireStoreUtils.getWalletSettingData();

    super.initState();
    //FireStoreUtils.walletSettingData().then((value) => isWalletEnable = value);
    if (widget.user != null) {
      user = widget.user!;
    } else {
      user = User();
    }
    _currentWidget = widget.currentWidget;
    _appBarTitle = widget.appBarTitle;
    _drawerSelection = widget.drawerSelection;
    //getKeyHash();
    /// On iOS, we request notification permissions, Does nothing and returns null on Android
    FireStoreUtils.firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    getTaxList();
  }

  getTaxList() async {
    await FireStoreUtils().getTaxList(sectionConstantModel!.id).then((value) {
      if (value != null) {
        taxList = value;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    cartDatabase = Provider.of<CartDatabase>(context);
  }


  DateTime? currentBackPressTime;
  bool canPopNow = false;

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return PopScope(
      canPop: canPopNow,
      onPopInvoked: (didPop) {
        final now = DateTime.now();
        if (currentBackPressTime == null || now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
          currentBackPressTime = now;
          setState(() {
            canPopNow = false;
          });
          ShowToastDialog.showToast("Double press to exit");
          return;
        } else {

          setState(() {
            canPopNow = true;
          });
        }
      },
      child: ChangeNotifierProvider.value(
        value: user,
        child: Consumer<User>(
          builder: (context, user, _) {
            return Scaffold(
              backgroundColor: isDarkMode(context) ? AppThemeData.surfaceDark : AppThemeData.surface,
              key: key,
              drawer: Drawer(
                child: Container(
                    color: isDarkMode(context) ? Colors.black : null,
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              Consumer<User>(builder: (context, user, _) {
                                return DrawerHeader(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      displayCircleImage(user.profilePictureURL, 75, false),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 8.0),
                                                  child: Text(
                                                    user.fullName(),
                                                    style: const TextStyle(color: Colors.white),
                                                  ),
                                                ),
                                                Padding(
                                                    padding: const EdgeInsets.only(top: 8.0),
                                                    child: Text(
                                                      user.email,
                                                      style: const TextStyle(color: Colors.white),
                                                    )),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              !themeChange.darkTheme ? const Icon(Icons.light_mode_sharp) : const Icon(Icons.nightlight),
                                              Switch(
                                                // thumb color (round icon)
                                                splashRadius: 50.0,
                                                // activeThumbImage: const AssetImage('https://lists.gnu.org/archive/html/emacs-devel/2015-10/pngR9b4lzUy39.png'),
                                                // inactiveThumbImage: const AssetImage('http://wolfrosch.com/_img/works/goodies/icon/vim@2x'),

                                                value: themeChange.darkTheme,
                                                onChanged: (value) => setState(() => themeChange.darkTheme = value),
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppThemeData.primary300,
                                  ),
                                );
                              }),
                              ListTileTheme(
                                style: ListTileStyle.drawer,
                                selectedColor: AppThemeData.primary300,
                                child: ListTile(
                                  selected: _drawerSelection == DrawerSelection.Dashboard,
                                  title: const Text('Dashboard').tr(),
                                  onTap: () {
                                    Navigator.pop(context);
                                    pushAndRemoveUntil(context, const ServiceListScreen());
                                  },
                                  leading: Image.asset(
                                    'assets/images/dashboard.png',
                                    color: _drawerSelection == DrawerSelection.Dashboard
                                        ? AppThemeData.primary300
                                        : isDarkMode(context)
                                            ? Colors.grey.shade200
                                            : Colors.grey.shade600,
                                    width: 24,
                                    height: 24,
                                  ),
                                ),
                              ),
                              ListTileTheme(
                                style: ListTileStyle.drawer,
                                selectedColor: AppThemeData.primary300,
                                child: ListTile(
                                  selected: _drawerSelection == DrawerSelection.Home,
                                  title: const Text('Home').tr(),
                                  onTap: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      _drawerSelection = DrawerSelection.Home;
                                      _appBarTitle = 'Home'.tr();
                                      _currentWidget = RentalServiceHomeScreen(
                                        user: MyAppState.currentUser,
                                      );
                                    });
                                  },
                                  leading: const Icon(CupertinoIcons.home),
                                ),
                              ),
                              Visibility(
                                visible: UserPreference.getWalletData() ?? false,
                                child: ListTileTheme(
                                  style: ListTileStyle.drawer,
                                  selectedColor: AppThemeData.primary300,
                                  child: ListTile(
                                    selected: _drawerSelection == DrawerSelection.Wallet,
                                    leading: const Icon(Icons.account_balance_wallet_outlined),
                                    title: const Text('Wallet').tr(),
                                    onTap: () {
                                      Navigator.pop(context);
                                      if (MyAppState.currentUser == null) {
                                        push(context, const LoginScreen());
                                      } else {
                                        setState(() {
                                          _drawerSelection = DrawerSelection.Wallet;
                                          _appBarTitle = 'Wallet'.tr();
                                          _currentWidget = const WalletScreen();
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                              ListTileTheme(
                                style: ListTileStyle.drawer,
                                selectedColor: AppThemeData.primary300,
                                child: ListTile(
                                  selected: _drawerSelection == DrawerSelection.referral,
                                  leading: Image.asset(
                                    'assets/images/refer.png',
                                    width: 28,
                                    color: Colors.grey,
                                  ),
                                  title: const Text('Refer a friend').tr(),
                                  onTap: () async {
                                    if (MyAppState.currentUser == null) {
                                      Navigator.pop(context);
                                      push(context, const LoginScreen());
                                    } else {
                                      Navigator.pop(context);
                                      push(context, const ReferralScreen());
                                    }
                                  },
                                ),
                              ),
                              ListTileTheme(
                                style: ListTileStyle.drawer,
                                selectedColor: AppThemeData.primary300,
                                child: ListTile(
                                  selected: _drawerSelection == DrawerSelection.Profile,
                                  leading: const Icon(CupertinoIcons.person),
                                  title: const Text("Profile").tr(),
                                  onTap: () {
                                    Navigator.pop(context);
                                    if (MyAppState.currentUser == null) {
                                      push(context, const LoginScreen());
                                    } else {
                                      setState(() {
                                        _drawerSelection = DrawerSelection.Profile;
                                        _appBarTitle = 'My Profile'.tr();
                                        _currentWidget = const ProfileScreen();
                                      });
                                    }
                                  },
                                ),
                              ),
                              ListTileTheme(
                                style: ListTileStyle.drawer,
                                selectedColor: AppThemeData.primary300,
                                child: ListTile(
                                    selected: _drawerSelection == DrawerSelection.giftCard,
                                    title: Text('Gift Card').tr(),
                                    leading: Icon(Icons.card_giftcard),
                                    onTap: () async {
                                      key.currentState!.openEndDrawer();
                                      push(context, const GiftCardScreen());
                                    }),
                              ),
                              ListTileTheme(
                                style: ListTileStyle.drawer,
                                selectedColor: AppThemeData.primary300,
                                child: ListTile(
                                  selected: _drawerSelection == DrawerSelection.Orders,
                                  leading: Image.asset(
                                    'assets/images/truck.png',
                                    color: _drawerSelection == DrawerSelection.Orders
                                        ? AppThemeData.primary300
                                        : isDarkMode(context)
                                            ? Colors.grey.shade200
                                            : Colors.grey.shade600,
                                    width: 24,
                                    height: 24,
                                  ),
                                  title: const Text('Booking').tr(),
                                  onTap: () {
                                    Navigator.pop(context);
                                    if (MyAppState.currentUser == null) {
                                      push(context, const LoginScreen());
                                    } else {
                                      setState(() {
                                        _drawerSelection = DrawerSelection.Orders;
                                        _appBarTitle = 'Booking'.tr();
                                        _currentWidget = const RentalBookingScreen();
                                      });
                                    }
                                  },
                                ),
                              ),
                              ListTileTheme(
                                style: ListTileStyle.drawer,
                                selectedColor: AppThemeData.primary300,
                                child: ListTile(
                                  selected: _drawerSelection == DrawerSelection.termsCondition,
                                  leading: const Icon(Icons.policy),
                                  title: const Text('Terms and Condition').tr(),
                                  onTap: () async {
                                    push(context, const TermsAndCondition());
                                  },
                                ),
                              ),
                              ListTileTheme(
                                style: ListTileStyle.drawer,
                                selectedColor: AppThemeData.primary300,
                                child: ListTile(
                                  selected: _drawerSelection == DrawerSelection.privacyPolicy,
                                  leading: const Icon(Icons.privacy_tip),
                                  title: const Text('Privacy policy').tr(),
                                  onTap: () async {
                                    push(context, const PrivacyPolicyScreen());
                                  },
                                ),
                              ),
                              ListTileTheme(
                                style: ListTileStyle.drawer,
                                selectedColor: AppThemeData.primary300,
                                child: ListTile(
                                  selected: _drawerSelection == DrawerSelection.chooseLanguage,
                                  leading: Icon(
                                    Icons.language,
                                    color: _drawerSelection == DrawerSelection.chooseLanguage
                                        ? AppThemeData.primary300
                                        : isDarkMode(context)
                                            ? Colors.grey.shade200
                                            : Colors.grey.shade600,
                                  ),
                                  title: const Text('Language').tr(),
                                  onTap: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      _drawerSelection = DrawerSelection.chooseLanguage;
                                      _appBarTitle = 'Language'.tr();
                                      _currentWidget = LanguageChooseScreen(
                                        isContainer: true,
                                      );
                                    });
                                  },
                                ),
                              ),
                              ListTileTheme(
                                style: ListTileStyle.drawer,
                                selectedColor: AppThemeData.primary300,
                                child: ListTile(
                                  selected: _drawerSelection == DrawerSelection.driver,
                                  leading: const Icon(CupertinoIcons.chat_bubble_2_fill),
                                  title: const Text('Driver Inbox').tr(),
                                  onTap: () {
                                    if (MyAppState.currentUser == null) {
                                      Navigator.pop(context);
                                      push(context, const LoginScreen());
                                    } else {
                                      Navigator.pop(context);
                                      setState(() {
                                        _drawerSelection = DrawerSelection.driver;
                                        _appBarTitle = 'Driver Inbox'.tr();
                                        _currentWidget = const InboxDriverScreen();
                                      });
                                    }
                                  },
                                ),
                              ),
                              ListTileTheme(
                                style: ListTileStyle.drawer,
                                selectedColor: AppThemeData.primary300,
                                child: ListTile(
                                  selected: _drawerSelection == DrawerSelection.Logout,
                                  leading: const Icon(Icons.logout),
                                  title: Text((MyAppState.currentUser == null) ? 'Log In'.tr() : 'Log Out'.tr()),
                                  onTap: () async {
                                    if (MyAppState.currentUser == null) {
                                      pushAndRemoveUntil(context, const LoginScreen());
                                    } else {
                                      Navigator.pop(context);
                                      //user.active = false;
                                      user.lastOnlineTimestamp = Timestamp.now();
                                      user.fcmToken = "";
                                      await FireStoreUtils.updateCurrentUser(user);
                                      await auth.FirebaseAuth.instance.signOut();
                                      MyAppState.currentUser = null;
                                      Provider.of<CartDatabase>(context, listen: false).deleteAllProducts();
                                      pushAndRemoveUntil(context, const LoginScreen());
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("V : $appVersion"),
                        )
                      ],
                    )),
              ),
              appBar: AppBar(
                centerTitle: false,
                backgroundColor: isDarkMode(context) ? AppThemeData.surfaceDark : AppThemeData.surface,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onTap: () {
                      key.currentState!.openDrawer();
                    },
                    child: ClipOval(
                      child: Container(
                        color: isDarkMode(context) ? AppThemeData.grey700 : AppThemeData.grey200,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(Icons.menu),
                        ),
                      ),
                    ),
                  ),
                ),
                title: Text(
                  _appBarTitle,
                  style: TextStyle(
                    fontSize: 18,
                    color: isDarkMode(context) ? Colors.white : Colors.black,
                    fontFamily: AppThemeData.medium,
                  ),
                ),
              ),
              body: _currentWidget,
            );
          },
        ),
      ),
    );
  }
}
