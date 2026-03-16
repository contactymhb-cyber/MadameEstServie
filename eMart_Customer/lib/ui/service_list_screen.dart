import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emartconsumer/cab_service/dashboard_cab_service.dart';
import 'package:emartconsumer/ecommarce_service/ecommarce_dashboard.dart';
import 'package:emartconsumer/main.dart';
import 'package:emartconsumer/model/CurrencyModel.dart';
import 'package:emartconsumer/model/User.dart';
import 'package:emartconsumer/onDemand_service/onDemand_ui/onDemand_dashboard.dart';
import 'package:emartconsumer/parcel_delivery/parcel_dashboard.dart';
import 'package:emartconsumer/rental_service/rental_service_dash_board.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/services/localDatabase.dart';
import 'package:emartconsumer/services/show_toast_dialog.dart';
import 'package:emartconsumer/ui/auth_screen/login_screen.dart';
import 'package:emartconsumer/ui/container/ContainerScreen.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:easy_localization/easy_localization.dart';
import 'package:emartconsumer/constants.dart';
import 'package:emartconsumer/model/SectionModel.dart';
import 'package:emartconsumer/services/FirebaseHelper.dart';
import 'package:emartconsumer/theme/app_them_data.dart';
import 'package:emartconsumer/utils/DarkThemeProvider.dart';
import 'package:emartconsumer/utils/network_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';


class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({super.key});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  List<SectionModel> sectionList = [];
  bool isLoading = true;

  @override
  void initState() {
    // TODO: implement initState
    getSection();
    super.initState();
  }
  List<dynamic>? serviceListBanner = [];

  getSection() async {
    await FireStoreUtils().getCurrency().then((value) {
      print("---->" + value.toString());
      if (value != null) {
        currencyData = value;
      } else {
        currencyData = CurrencyModel(id: "", code: "USD", decimal: 2, isactive: true, name: "US Dollar", symbol: "\$", symbolatright: false);
      }
    });

    List<Placemark> placeMarks = await placemarkFromCoordinates(MyAppState.selectedPosotion.location!.latitude, MyAppState.selectedPosotion.location!.longitude);
    country = placeMarks.first.country;

    await FireStoreUtils.getSections().then(
      (value) {
        setState(() {
          sectionList = value;
        });
      },
    );

    await FireStoreUtils.firestore.collection(Setting).doc("AppHomeBanners").get().then((value) {
      setState(() {
        serviceListBanner = value.data()!['banners'];
      });
    });

    await FireStoreUtils.getRazorPayDemo();
    await FireStoreUtils.getPaypalSettingData();
    await FireStoreUtils.getStripeSettingData();
    await FireStoreUtils.getPayStackSettingData();
    await FireStoreUtils.getFlutterWaveSettingData();
    await FireStoreUtils.getPaytmSettingData();
    await FireStoreUtils.getPayFastSettingData();
    await FireStoreUtils.getWalletSettingData();
    await FireStoreUtils.getMercadoPagoSettingData();
    await FireStoreUtils.getOrangeMoneySettingData();
    await FireStoreUtils.getXenditSettingData();
    await FireStoreUtils.getMidTransSettingData();

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Scaffold(
      backgroundColor: themeChange.getThem() ? AppThemeData.surfaceDark : AppThemeData.surface,
      appBar: AppBar(
        backgroundColor: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
        centerTitle: false,
        titleSpacing: 20,
        toolbarHeight: 60,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "eMart".tr(),
              textAlign: TextAlign.start,
              style: TextStyle(
                fontFamily: AppThemeData.semiBold,
                fontSize: 22,
                color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
              ),
            ),
            Text(
              "All-in-One Multi-Service App".tr(),
              textAlign: TextAlign.start,
              style: TextStyle(
                fontFamily: AppThemeData.regular,
                fontSize: 14,
                color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
              ),
            ),
          ],
        ),
      ),
      body: isLoading == true
          ? loader()
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    serviceListBanner!.isEmpty
                        ? const SizedBox()
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: BannerView(bannerList: serviceListBanner!),
                          ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      "Explore our Services".tr(),
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontFamily: AppThemeData.semiBold,
                        fontSize: 20,
                        color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sectionList.length,
                      itemBuilder: (context, index) {
                        SectionModel sectionModel = sectionList[index];
                        return InkWell(
                          onTap: () async {
                            ShowToastDialog.showLoader("Please wait");
                            AppThemeData.primary300 = Color(int.parse(sectionModel.color!.replaceFirst("#", "0xff")));


                            if (auth.FirebaseAuth.instance.currentUser != null && MyAppState.currentUser != null) {
                              User? user = await FireStoreUtils.getCurrentUser(MyAppState.currentUser!.userID);

                              if (user!.role == USER_ROLE_CUSTOMER) {
                                user.active = true;
                                user.role = USER_ROLE_CUSTOMER;
                                sectionConstantModel = sectionModel;

                                user.fcmToken = await FireStoreUtils.firebaseMessaging.getToken() ?? '';
                                await FireStoreUtils.updateCurrentUser(user);
                                ShowToastDialog.closeLoader();
                                if (sectionConstantModel!.serviceTypeFlag == "ecommerce-service") {
                                  await Provider.of<CartDatabase>(context, listen: false).allCartProducts.then((value) {
                                    if (value.isNotEmpty) {
                                      showAlertDialog(context, user, sectionModel);
                                    } else {
                                      push(context, EcommeceDashBoardScreen(user: user));
                                    }
                                  });
                                } else if (sectionConstantModel!.serviceTypeFlag == "cab-service") {
                                  push(context, DashBoardCabService(user: user));
                                } else if (sectionConstantModel!.serviceTypeFlag == "rental-service") {
                                  push(context, RentalServiceDashBoard(user: user));
                                } else if (sectionConstantModel!.serviceTypeFlag == "parcel_delivery") {
                                  push(context, ParcelDahBoard(user: user));
                                } else if (sectionConstantModel!.serviceTypeFlag == "ondemand-service") {
                                  push(context, OnDemandDahBoard(user: user));
                                } else {
                                  await Provider.of<CartDatabase>(context, listen: false).allCartProducts.then((value) {
                                    if (value.isNotEmpty) {
                                      showAlertDialog(context, user, sectionConstantModel!);
                                    } else {
                                      push(context, ContainerScreen(user: user));
                                    }
                                  });
                                }
                              } else {
                                pushReplacement(context, const LoginScreen());
                              }
                            } else {
                              sectionConstantModel = sectionModel;

                              ShowToastDialog.closeLoader();
                              if (sectionConstantModel!.serviceTypeFlag == "ecommerce-service") {
                                push(context, EcommeceDashBoardScreen(user: null));
                              } else if (sectionConstantModel!.serviceTypeFlag == "cab-service") {
                                push(context, DashBoardCabService(user: null));
                              } else if (sectionConstantModel!.serviceTypeFlag == "rental-service") {
                                push(context, RentalServiceDashBoard(user: null));
                              } else if (sectionConstantModel!.serviceTypeFlag == "parcel_delivery") {
                                push(context, ParcelDahBoard(user: null));
                              } else if (sectionConstantModel!.serviceTypeFlag == "ondemand-service") {
                                push(context, OnDemandDahBoard(user: null));
                              } else {
                                push(context, ContainerScreen(user: null));
                              }
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Container(
                              clipBehavior: Clip.antiAlias,
                              decoration: ShapeDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment(0.00, -1.00),
                                  end: Alignment(0, 1),
                                  colors: sectionColor[index % sectionColor.length],
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10, left: 5, right: 5),
                                    child: Text(
                                      "${sectionModel.name}".tr(),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      style: TextStyle(
                                        fontFamily: AppThemeData.semiBold,
                                        color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                      ),
                                    ),
                                  ),
                                  Transform(
                                    transform: Matrix4.translationValues(0, 30, 0),
                                    child: NetworkImageWidget(
                                      imageUrl: sectionModel.sectionImage.toString(),
                                      width: 90,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 0, crossAxisSpacing: 8, mainAxisExtent: 130),
                    )
                  ],
                ),
              ),
            ),
    );
  }

  showAlertDialog(BuildContext context, User? user, SectionModel sectionModel) {
    // set up the button
    Widget okButton = TextButton(
      child: const Text("OK"),
      onPressed: () async {
        if (sectionModel.serviceTypeFlag == "ecommerce-service") {
          Provider.of<CartDatabase>(context, listen: false).deleteAllProducts();
          push(context, EcommeceDashBoardScreen(user: user));
        } else {
          Provider.of<CartDatabase>(context, listen: false).deleteAllProducts();
          push(context, ContainerScreen(user: user));
        }
      },
    );

    Widget cancelButton = TextButton(
      child: const Text("Cancel"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Alert!"),
      content: const Text("If you select this Section/Service, your previously added items will be removed from the cart."),
      actions: [
        cancelButton,
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}

class BannerView extends StatefulWidget {
  final List<dynamic> bannerList;

  const BannerView({super.key, required this.bannerList});

  @override
  State<BannerView> createState() => _BannerViewState();
}

class _BannerViewState extends State<BannerView> {
  PageController pageController = PageController(viewportFraction: 0.877);
  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: PageView.builder(
        physics: const BouncingScrollPhysics(),
        controller: pageController,
        scrollDirection: Axis.horizontal,
        itemCount: widget.bannerList.length,
        padEnds: false,
        pageSnapping: true,
        onPageChanged: (value) {
          setState(() {
            currentPage = value;
          });
        },
        itemBuilder: (BuildContext context, int index) {
          String bannerModel = widget.bannerList[index];
          return InkWell(
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                child: NetworkImageWidget(
                  imageUrl: bannerModel.toString(),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
