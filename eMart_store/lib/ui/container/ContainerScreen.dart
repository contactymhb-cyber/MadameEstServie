import 'dart:developer';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emartstore/constants.dart';
import 'package:emartstore/main.dart';
import 'package:emartstore/model/CurrencyModel.dart';
import 'package:emartstore/model/SectionModel.dart';
import 'package:emartstore/model/User.dart';
import 'package:emartstore/model/VendorModel.dart';
import 'package:emartstore/services/FirebaseHelper.dart';
import 'package:emartstore/services/helper.dart';
import 'package:emartstore/services/show_toast_dailog.dart';
import 'package:emartstore/theme/app_them_data.dart';
import 'package:emartstore/theme/responsive.dart';
import 'package:emartstore/theme/round_button_fill.dart';
import 'package:emartstore/ui/DineIn/DineInRequest.dart';
import 'package:emartstore/ui/Language/language_choose_screen.dart';
import 'package:emartstore/ui/addDineIn/AddDineIn.dart';
import 'package:emartstore/ui/add_store/add_store.dart';
import 'package:emartstore/ui/add_story_screen.dart';
import 'package:emartstore/ui/auth/AuthScreen.dart';
import 'package:emartstore/ui/bank_details/bank_details_Screen.dart';
import 'package:emartstore/ui/chat_screen/inbox_screen.dart';
import 'package:emartstore/ui/manageProductsScreen/ManageProductsScreen.dart';
import 'package:emartstore/ui/offer/offers.dart';
import 'package:emartstore/ui/ordersScreen/OrdersScreen.dart';
import 'package:emartstore/ui/privacy_policy/privacy_policy.dart';
import 'package:emartstore/ui/profile/ProfileScreen.dart';
import 'package:emartstore/ui/special_offer_screen/SpecialOfferScreen.dart';
import 'package:emartstore/ui/subscription_screen/Subscription_history_screen.dart';
import 'package:emartstore/ui/subscription_screen/subscription_screens.dart';
import 'package:emartstore/ui/termsAndCondition/terms_and_codition.dart';
import 'package:emartstore/ui/wallet/walletScreen.dart';
import 'package:emartstore/utils/network_image_widget.dart';
import 'package:emartstore/working_hour/working_hours_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum DrawerSelection {
  Orders,
  DineIn,
  DineInReq,
  SpecialOffer,
  WorkingHours,
  ManageProducts,
  addStory,
  AddRestauarnt,
  Offers,
  Profile,
  Wallet,
  subscription,
  subscription_history,
  BankInfo,
  chooseLanguage,
  termsCondition,
  privacyPolicy,
  inbox,
  Logout,
  documentVerification,
}

class ContainerScreen extends StatefulWidget {
  final User? user;

  final Widget currentWidget;
  final String appBarTitle;
  final DrawerSelection drawerSelection;
  String? userId = "";
  bool? isDineInReq = false;

  ContainerScreen(
      {Key? key,
      this.user,
      this.userId,
      this.isDineInReq,
      appBarTitle,
      currentWidget,
      this.drawerSelection = DrawerSelection.Orders})
      : this.appBarTitle = appBarTitle ?? 'Orders'.tr(),
        this.currentWidget = currentWidget ?? OrdersScreen(),
        super(key: key);

  @override
  _ContainerScreen createState() {
    return _ContainerScreen();
  }
}

class _ContainerScreen extends State<ContainerScreen> {
  late String _appBarTitle;
  final fireStoreUtils = FireStoreUtils();

  late Widget _currentWidget;
  late DrawerSelection _drawerSelection;
  VendorModel? vendorModel;
  final audioPlayer = AudioPlayer(playerId: "playerId");
  SectionModel? selectedModel;

  @override
  void initState() {
    super.initState();
    getInit();
  }

  getInit() async {
    _currentWidget = widget.currentWidget;
    _appBarTitle = widget.appBarTitle;
    _drawerSelection = widget.drawerSelection;

    await FireStoreUtils.getCurrentUser(MyAppState.currentUser == null
            ? widget.userId!
            : MyAppState.currentUser!.userID)
        .then((value) {
      setState(() {
        MyAppState.currentUser = value;
      });
    });

    await getSpecialDiscount();
    if (MyAppState.currentUser!.vendorID.isNotEmpty) {
      await FireStoreUtils.getVendor(MyAppState.currentUser!.vendorID)
          .then((value) async {
        if (value.id.isNotEmpty) {
          vendorModel = value;
          vendorAdminCommission = value.adminCommission;
          await getCategory();
          await FireStoreUtils.getDineStatus(vendorModel!.section_id)
              .then((value) async {
            if (vendorModel!.dine_in_active != value) {
              vendorModel!.dine_in_active = value;
              await FirebaseFirestore.instance
                  .collection(VENDORS)
                  .doc(vendorModel!.id)
                  .update({"dine_in_active": value});
            }
            setState(() {});
          });
        }
      });
    }

    await fireStoreUtils.getplaceholderimage();
    setState(() {});
  }

  getCategory() async {
    await FireStoreUtils.getSectionsById(vendorModel!.section_id).then((value) {
      setState(() {
        selectedModel = value;
      });
    });
  }

  bool specialDiscountEnable = false;
  bool storyEnable = false;

  getSpecialDiscount() async {
    await FirebaseFirestore.instance
        .collection(Setting)
        .doc('specialDiscountOffer')
        .get()
        .then((value) {
      specialDiscountEnable = value.data()!['isEnable'];
    });
    await FirebaseFirestore.instance
        .collection(Setting)
        .doc('story')
        .get()
        .then((value) {
      storyEnable = value.data()!['isEnabled'];
    });
    await FirebaseFirestore.instance
        .collection(Setting)
        .doc('digitalProduct')
        .get()
        .then((value) {
      fileSize = value.data()!['fileSize'];
    });
    setState(() {});
  }

  DateTime pre_backpress = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar:
          _drawerSelection == DrawerSelection.Wallet ? true : false,
      backgroundColor: isDarkMode(context) ? Color(COLOR_DARK) : null,
      drawer: Drawer(
          child: Container(
        color: isDarkMode(context) ? Color(COLOR_DARK) : null,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  SizedBox(
                    height: 160,
                    child: DrawerHeader(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: [
                              displayCircleImage(
                                  MyAppState.currentUser!.profilePictureURL,
                                  60,
                                  false),
                              SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        MyAppState.currentUser!.fullName(),
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    Text(
                                      MyAppState.currentUser!.email,
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                      decoration: BoxDecoration(
                        color: Color(COLOR_PRIMARY),
                      ),
                    ),
                  ),
                  if (isSubscriptionModelApplied == true ||
                      selectedSectionModel?.adminCommision?.enable == true)
                    Visibility(
                      visible: MyAppState
                              .currentUser!.subscriptionPlanId?.isNotEmpty ==
                          true,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 0),
                        child: SubscriptionPlanWidget(
                          onClick: () {
                            _drawerSelection = DrawerSelection.subscription;
                            _appBarTitle = 'Subscription'.tr();
                            _currentWidget =
                                SubscriptionScreens(isShowAppBar: true);
                            Navigator.pop(context);
                            setState(() {});
                          },
                          userModel: MyAppState.currentUser!,
                        ),
                      ),
                    ),
                  ListTileTheme(
                    style: ListTileStyle.drawer,
                    selectedColor: Color(COLOR_PRIMARY),
                    child: ListTile(
                      selected: _drawerSelection == DrawerSelection.Orders,
                      title: Text('Orders').tr(),
                      onTap: () {
                        Navigator.pop(context);
                        setState(
                          () {
                            _drawerSelection = DrawerSelection.Orders;
                            _appBarTitle = 'Orders'.tr();
                            _currentWidget = OrdersScreen();
                          },
                        );
                      },
                      leading: Image.asset(
                        'assets/images/order.png',
                        color: _drawerSelection == DrawerSelection.Orders
                            ? Color(COLOR_PRIMARY)
                            : isDarkMode(context)
                                ? Colors.grey.shade200
                                : Colors.grey.shade600,
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: vendorModel != null && vendorModel!.dine_in_active,
                    child: ListTileTheme(
                      style: ListTileStyle.drawer,
                      selectedColor: Color(COLOR_PRIMARY),
                      child: ListTile(
                        selected: _drawerSelection == DrawerSelection.DineInReq,
                        title: Text('Dine-in Requests').tr(),
                        onTap: () {
                          Navigator.pop(context);
                          setState(
                            () {
                              _drawerSelection = DrawerSelection.DineInReq;
                              _appBarTitle = 'Dine-in Requests'.tr();
                              _currentWidget = DineInRequest();
                            },
                          );
                        },
                        leading: Icon(Icons.restaurant_menu),
                      ),
                    ),
                  ),
                  ListTileTheme(
                    style: ListTileStyle.drawer,
                    selectedColor: Color(COLOR_PRIMARY),
                    child: ListTile(
                      selected:
                          _drawerSelection == DrawerSelection.AddRestauarnt,
                      leading: Icon(Icons.restaurant_outlined),
                      title: Text('Add Store').tr(),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _drawerSelection = DrawerSelection.AddRestauarnt;
                          _appBarTitle = 'Add Store'.tr();
                          _currentWidget = AddStoreScreen();
                        });
                      },
                    ),
                  ),
                  Visibility(
                    visible: vendorModel != null && vendorModel!.dine_in_active,
                    child: ListTileTheme(
                      style: ListTileStyle.drawer,
                      selectedColor: Color(COLOR_PRIMARY),
                      child: ListTile(
                        selected: _drawerSelection == DrawerSelection.DineIn,
                        leading: Icon(Icons.restaurant_outlined),
                        title: Text('Dine-in').tr(),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _drawerSelection = DrawerSelection.DineIn;
                            _appBarTitle = 'Dine-in'.tr();
                            _currentWidget = AddDineIn();
                          });
                        },
                      ),
                    ),
                  ),
                  ListTileTheme(
                    style: ListTileStyle.drawer,
                    selectedColor: Color(COLOR_PRIMARY),
                    child: ListTile(
                      selected:
                          _drawerSelection == DrawerSelection.ManageProducts,
                      leading: FaIcon(FontAwesomeIcons.pizzaSlice),
                      title: Text('Manage Products').tr(),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _drawerSelection = DrawerSelection.ManageProducts;
                          _appBarTitle = 'Your Products'.tr();
                          _currentWidget = ManageProductsScreen();
                        });
                      },
                    ),
                  ),
                  Visibility(
                    visible: storyEnable == true &&
                            (selectedModel != null &&
                                selectedModel!.serviceTypeFlag !=
                                    "ecommerce-service")
                        ? true
                        : false,
                    child: ListTileTheme(
                      style: ListTileStyle.drawer,
                      selectedColor: Color(COLOR_PRIMARY),
                      child: ListTile(
                        selected: _drawerSelection == DrawerSelection.addStory,
                        leading: Icon(Icons.ad_units),
                        title: Text('Add Story').tr(),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            if (MyAppState.currentUser!.vendorID.isNotEmpty) {
                              _drawerSelection = DrawerSelection.addStory;
                              _appBarTitle = 'Add Story'.tr();
                              _currentWidget = AddStoryScreen();
                            } else {
                              final snackBar = SnackBar(
                                content: const Text('Please add store first.'),
                              );
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(snackBar);
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  Visibility(
                    visible: specialDiscountEnable,
                    child: ListTileTheme(
                      style: ListTileStyle.drawer,
                      selectedColor: Color(COLOR_PRIMARY),
                      child: ListTile(
                        selected:
                            _drawerSelection == DrawerSelection.SpecialOffer,
                        leading: Icon(Icons.local_offer_outlined),
                        title: Text('Special Discount').tr(),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _drawerSelection = DrawerSelection.SpecialOffer;
                            _appBarTitle = 'Special Discount'.tr();
                            _currentWidget = SpecialOfferScreen();
                          });
                        },
                      ),
                    ),
                  ),
                  ListTileTheme(
                    style: ListTileStyle.drawer,
                    selectedColor: Color(COLOR_PRIMARY),
                    child: ListTile(
                      selected: _drawerSelection == DrawerSelection.Offers,
                      leading: Icon(Icons.local_offer_outlined),
                      title: Text('Offers').tr(),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _drawerSelection = DrawerSelection.Offers;
                          _appBarTitle = 'Offers'.tr();
                          _currentWidget = OffersScreen();
                        });
                      },
                    ),
                  ),
                  Visibility(
                    visible: (selectedModel != null &&
                            selectedModel!.serviceTypeFlag !=
                                "ecommerce-service")
                        ? true
                        : false,
                    child: ListTileTheme(
                      style: ListTileStyle.drawer,
                      selectedColor: Color(COLOR_PRIMARY),
                      child: ListTile(
                        selected:
                            _drawerSelection == DrawerSelection.WorkingHours,
                        leading: Icon(Icons.access_time_sharp),
                        title: Text('Working Hours').tr(),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _drawerSelection = DrawerSelection.WorkingHours;
                            _appBarTitle = 'Working Hours'.tr();
                            _currentWidget = WorkingHoursScreen();
                          });
                        },
                      ),
                    ),
                  ),
                  ListTileTheme(
                    style: ListTileStyle.drawer,
                    selectedColor: Color(COLOR_PRIMARY),
                    child: ListTile(
                      selected: _drawerSelection == DrawerSelection.Profile,
                      leading: Icon(CupertinoIcons.person),
                      title: Text('Profile').tr(),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _drawerSelection = DrawerSelection.Profile;
                          _appBarTitle = 'Profile'.tr();
                          _currentWidget = ProfileScreen(
                            user: MyAppState.currentUser!,
                          );
                        });
                      },
                    ),
                  ),
                  ListTileTheme(
                    style: ListTileStyle.drawer,
                    selectedColor: Color(COLOR_PRIMARY),
                    child: ListTile(
                      selected: _drawerSelection == DrawerSelection.Wallet,
                      leading: Icon(Icons.account_balance_wallet_sharp),
                      title: Text('Wallet').tr(),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _drawerSelection = DrawerSelection.Wallet;
                          _appBarTitle = 'Wallet'.tr();
                          _currentWidget = WalletScreen();
                        });
                      },
                    ),
                  ),
                  if (isSubscriptionModelApplied == true ||
                      selectedSectionModel?.adminCommision?.enable == true)
                    ListTileTheme(
                      style: ListTileStyle.drawer,
                      selectedColor: Color(COLOR_PRIMARY),
                      child: ListTile(
                        selected:
                            _drawerSelection == DrawerSelection.subscription,
                        leading: Icon(Icons.currency_exchange),
                        title: Text('Subscription').tr(),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _drawerSelection = DrawerSelection.subscription;
                            _appBarTitle = 'Subscription'.tr();
                            _currentWidget =
                                SubscriptionScreens(isShowAppBar: true);
                          });
                        },
                      ),
                    ),
                  ListTileTheme(
                    style: ListTileStyle.drawer,
                    selectedColor: Color(COLOR_PRIMARY),
                    child: ListTile(
                      selected: _drawerSelection ==
                          DrawerSelection.subscription_history,
                      leading: Icon(Icons.history),
                      title: Text('Subscription History').tr(),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _drawerSelection =
                              DrawerSelection.subscription_history;
                          _appBarTitle = 'Subscription History'.tr();
                          _currentWidget = SubscriptionHistoryScreen();
                        });
                      },
                    ),
                  ),
                  ListTileTheme(
                    style: ListTileStyle.drawer,
                    selectedColor: Color(COLOR_PRIMARY),
                    child: ListTile(
                      selected: _drawerSelection == DrawerSelection.BankInfo,
                      leading: Icon(Icons.account_balance),
                      title: Text('Withdraw method').tr(),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _drawerSelection = DrawerSelection.BankInfo;
                          _appBarTitle = 'Withdraw method'.tr();
                          _currentWidget = BankDetailsScreen();
                        });
                      },
                    ),
                  ),
                  ListTileTheme(
                    style: ListTileStyle.drawer,
                    selectedColor: Color(COLOR_PRIMARY),
                    child: ListTile(
                      selected:
                          _drawerSelection == DrawerSelection.chooseLanguage,
                      leading: Icon(
                        Icons.language,
                        color:
                            _drawerSelection == DrawerSelection.chooseLanguage
                                ? Color(COLOR_PRIMARY)
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
                    selectedColor: Color(COLOR_PRIMARY),
                    child: ListTile(
                      selected:
                          _drawerSelection == DrawerSelection.termsCondition,
                      leading: const Icon(Icons.policy),
                      title: const Text('Terms and Condition').tr(),
                      onTap: () async {
                        push(context, const TermsAndCondition());
                      },
                    ),
                  ),
                  ListTileTheme(
                    style: ListTileStyle.drawer,
                    selectedColor: Color(COLOR_PRIMARY),
                    child: ListTile(
                      selected:
                          _drawerSelection == DrawerSelection.privacyPolicy,
                      leading: const Icon(Icons.privacy_tip),
                      title: const Text('Privacy policy').tr(),
                      onTap: () async {
                        push(context, const PrivacyPolicyScreen());
                      },
                    ),
                  ),
                  ListTileTheme(
                    style: ListTileStyle.drawer,
                    selectedColor: Color(COLOR_PRIMARY),
                    child: ListTile(
                      selected: _drawerSelection == DrawerSelection.inbox,
                      leading: Icon(CupertinoIcons.chat_bubble_2_fill),
                      title: Text('Inbox').tr(),
                      onTap: () {
                        if (MyAppState.currentUser == null) {
                          Navigator.pop(context);
                          push(context, AuthScreen());
                        } else {
                          Navigator.pop(context);
                          setState(() {
                            _drawerSelection = DrawerSelection.inbox;
                            _appBarTitle = 'My Inbox'.tr();
                            _currentWidget = InboxScreen();
                          });
                        }
                      },
                    ),
                  ),
                  ListTileTheme(
                    style: ListTileStyle.drawer,
                    selectedColor: Color(COLOR_PRIMARY),
                    child: ListTile(
                      selected: _drawerSelection == DrawerSelection.Logout,
                      leading: Icon(Icons.logout),
                      title: Text('Log out').tr(),
                      onTap: () async {
                        ShowToastDialog.showLoader("Please wait");
                        audioPlayer.stop();
                        Navigator.pop(context);
                        //user.active = false;
                        MyAppState.currentUser!.lastOnlineTimestamp =
                            Timestamp.now();
                        await FireStoreUtils.firestore
                            .collection(USERS)
                            .doc(MyAppState.currentUser!.userID)
                            .update({"fcmToken": ""});
                        if (MyAppState.currentUser!.vendorID.isNotEmpty) {
                          await FireStoreUtils.firestore
                              .collection(VENDORS)
                              .doc(MyAppState.currentUser!.vendorID)
                              .update({"fcmToken": ""});
                        }
                        // await FireStoreUtils.updateCurrentUser(user);
                        await auth.FirebaseAuth.instance.signOut();
                        MyAppState.currentUser = null;
                        ShowToastDialog.closeLoader();
                        pushAndRemoveUntil(context, AuthScreen(), false);
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Version".tr() + " : $appVersion"),
            )
          ],
        ),
      )),
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: _drawerSelection == DrawerSelection.Wallet
              ? Colors.white
              : isDarkMode(context)
                  ? Colors.white
                  : Color(DARK_COLOR),
        ),
        centerTitle: _drawerSelection == DrawerSelection.Wallet ? true : false,
        backgroundColor: _drawerSelection == DrawerSelection.Wallet
            ? Colors.transparent
            : isDarkMode(context)
                ? Color(DARK_COLOR)
                : Colors.white,
        actions: [
          // if (_currentWidget is ManageProductsScreen)
          // IconButton(
          //   icon: Icon(
          //     CupertinoIcons.add_circled,
          //     color: Color(COLOR_PRIMARY),
          //   ),
          //   onPressed: () => push(
          //     context,
          //     AddOrUpdateProductScreen(product: null),
          //   ),
          // ),
        ],
        title: Text(
          _appBarTitle,
          style: TextStyle(
            fontSize: 20,
            color: _drawerSelection == DrawerSelection.Wallet
                ? Colors.white
                : isDarkMode(context)
                    ? Colors.white
                    : Color(DARK_COLOR),
          ),
        ),
      ),
      body: PopScope(
          canPop: canPopNow,
          onPopInvoked: (didPop) {
            final now = DateTime.now();
            if (currentBackPressTime == null ||
                now.difference(currentBackPressTime!) >
                    const Duration(seconds: 2)) {
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
          child: _currentWidget),
    );
  }

  DateTime? currentBackPressTime;
  bool canPopNow = false;
}

class SubscriptionPlanWidget extends StatelessWidget {
  final VoidCallback onClick;
  final User userModel;

  const SubscriptionPlanWidget({
    super.key,
    required this.onClick,
    required this.userModel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
            color: isDarkMode(context)
                ? AppThemeData.grey800
                : AppThemeData.grey200),
        color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey800,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
              bottom: 0,
              top: 10,
              child: Opacity(
                  opacity: 0.8,
                  child: Image.asset(
                    width: Responsive.width(100, context),
                    height: Responsive.height(100, context),
                    "assets/images/ic_gradient.png",
                    color: AppThemeData.secondary300,
                    fit: BoxFit.fill,
                  ))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipOval(
                      child: NetworkImageWidget(
                        imageUrl: userModel.subscriptionPlan?.image ?? '',
                        fit: BoxFit.cover,
                        width: 40,
                        height: 40,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userModel.subscriptionPlan?.name ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDarkMode(context)
                                        ? AppThemeData.grey900
                                        : AppThemeData.grey50,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: AppThemeData.semiBold,
                                  ),
                                ),
                                SizedBox(
                                  height: 35,
                                  child: SingleChildScrollView(
                                    child: Text(
                                      userModel.subscriptionPlan?.type == 'free'
                                          ? 'free'
                                          : amountShow(
                                              amount: userModel
                                                  .subscriptionPlan?.price),
                                      style: const TextStyle(
                                        fontFamily: AppThemeData.medium,
                                        fontSize: 12,
                                        color: AppThemeData.grey400,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Expiry Date'.tr(),
                                style: TextStyle(
                                  fontFamily: AppThemeData.medium,
                                  fontSize: 12,
                                  color: isDarkMode(context)
                                      ? AppThemeData.grey900
                                      : AppThemeData.grey50,
                                ),
                              ),
                              Text(
                                userModel.subscriptionPlan!.expiryDay == "-1"
                                    ? "LifeTime"
                                    : timestampToDate(
                                        userModel.subscriptionExpiryDate!),
                                style: const TextStyle(
                                  fontFamily: AppThemeData.regular,
                                  fontSize: 12,
                                  color: AppThemeData.grey400,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                RoundedButtonFill(
                  radius: 14,
                  textColor: AppThemeData.grey200,
                  title: "Change Plan".tr(),
                  color: AppThemeData.secondary300,
                  width: 80,
                  height: 4,
                  onPress: onClick,
                ),
                if (selectedSectionModel?.adminCommision?.enable == true &&
                    MyAppState.currentUser?.vendorID != '' &&
                    MyAppState.currentUser?.vendorID != null)
                  FutureBuilder<VendorModel>(
                      future: FireStoreUtils.getVendor(
                          MyAppState.currentUser!.vendorID),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Container(height: 40));
                        }
                        if (!snapshot.hasData) {
                          return Container();
                        } else {
                          VendorModel model = snapshot.data!;
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              "${model.adminCommission?.type == 'percentage' ? "${model.adminCommission?.commission}%" : "${amountShow(amount: model.adminCommission?.commission.toString())} Flat"} ${"admin commission will be charged from customer billing order and the admin charge will be earned after the order is accepted by the store.".tr()}",
                              style: const TextStyle(
                                fontFamily: AppThemeData.medium,
                                fontSize: 9,
                                color: AppThemeData.grey400,
                              ),
                            ),
                          );
                        }
                      }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
