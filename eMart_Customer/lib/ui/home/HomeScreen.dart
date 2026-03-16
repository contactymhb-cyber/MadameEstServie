import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emartconsumer/constants.dart';
import 'package:emartconsumer/main.dart';
import 'package:emartconsumer/model/AddressModel.dart';
import 'package:emartconsumer/model/BannerModel.dart';
import 'package:emartconsumer/model/FavouriteModel.dart';
import 'package:emartconsumer/model/ProductModel.dart';
import 'package:emartconsumer/model/User.dart';
import 'package:emartconsumer/model/VendorCategoryModel.dart';
import 'package:emartconsumer/model/VendorModel.dart';
import 'package:emartconsumer/model/offer_model.dart';
import 'package:emartconsumer/model/story_model.dart';
import 'package:emartconsumer/services/FirebaseHelper.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/services/localDatabase.dart';
import 'package:emartconsumer/services/show_toast_dialog.dart';
import 'package:emartconsumer/theme/app_them_data.dart';
import 'package:emartconsumer/theme/responsive.dart';
import 'package:emartconsumer/theme/text_field_widget.dart';
import 'package:emartconsumer/ui/QrCodeScanner/QrCodeScanner.dart';
import 'package:emartconsumer/ui/auth_screen/login_screen.dart';
import 'package:emartconsumer/ui/cartScreen/CartScreen.dart';
import 'package:emartconsumer/ui/categoryDetailsScreen/CategoryDetailsScreen.dart';
import 'package:emartconsumer/ui/container/ContainerScreen.dart';
import 'package:emartconsumer/ui/cuisinesScreen/CuisinesScreen.dart';
import 'package:emartconsumer/ui/deliveryAddressScreen/DeliveryAddressScreen.dart';
import 'package:emartconsumer/ui/home/story_view.dart';
import 'package:emartconsumer/ui/home/view_all_new_arrival_store_screen.dart';
import 'package:emartconsumer/ui/home/view_all_popular_food_near_by_screen.dart';
import 'package:emartconsumer/ui/home/view_all_restaurant.dart';
import 'package:emartconsumer/ui/mapView/MapViewScreen.dart';
import 'package:emartconsumer/ui/productDetailsScreen/ProductDetailsScreen.dart';
import 'package:emartconsumer/ui/searchScreen/SearchScreen.dart';
import 'package:emartconsumer/ui/vendorProductsScreen/NewVendorProductsScreen.dart';
import 'package:emartconsumer/utils/network_image_widget.dart';
import 'package:emartconsumer/widget/place_picker_osm.dart';
import 'package:emartconsumer/widget/story_view/controller/story_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  final User? user;
  final String vendorId;

  HomeScreen({
    Key? key,
    required this.user,
    vendorId,
  })  : vendorId = vendorId ?? "",
        super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late CartDatabase cartDatabase;
  int cartCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    cartDatabase = Provider.of<CartDatabase>(context);
  }

  final fireStoreUtils = FireStoreUtils();

  List<ProductModel> productsFuture = <ProductModel>[];
  List<VendorModel> vendors = [];
  List<VendorModel> popularRestaurantLst = [];
  List<VendorModel> offerVendorList = [];
  List<VendorModel> newArrivalRestaurantList = [];
  List<OfferModel> offersList = [];
  List<VendorModel>? lstAllRestaurant = <VendorModel>[];
  List<ProductModel> lstNearByFood = [];
  bool islocationGet = false;

  late Future<List<FavouriteModel>> lstFavourites;
  List<String> lstFav = [];

  String? name = "";

  String? selctedOrderTypeValue = "Delivery".tr();

  bool isLoading = true;

  getLocationData() async {
    try {
      await getData();
    } catch (e) {
      getPermission();
    }
  }

  getPermission() async {
    setState(() {
      isLoading = false;
    });
    loc.PermissionStatus _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        getData();
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  loc.Location location = loc.Location();

  // Database db;
  bool? storyEnable = false;

  @override
  void initState() {
    super.initState();
    getLocationData();
    getBanner();
  }

  List<BannerModel> bannerTopHome = [];
  List<BannerModel> bannerMiddleHome = [];

  bool isListView = true;
  bool isHomeBannerLoading = true;
  bool isHomeBannerMiddleLoading = true;
  List<OfferModel> offerList = [];
  List<VendorCategoryModel> vendorCategoryModel = [];

  getBanner() async {
    await fireStoreUtils.getCuisines().then(
      (value) {
        vendorCategoryModel = value;
      },
    );
    await fireStoreUtils.getHomeTopBanner().then((value) {
      setState(() {
        bannerTopHome = value;
        isHomeBannerLoading = false;
      });
    });

    await fireStoreUtils.getHomeMiddleBanner().then((value) {
      setState(() {
        bannerMiddleHome = value;
        isHomeBannerMiddleLoading = false;
      });
    });
    await FireStoreUtils().getPublicCoupons().then((value) {
      setState(() {
        offerList = value;
      });
    });
    await FireStoreUtils.firestore
        .collection(Setting)
        .doc('story')
        .get()
        .then((value) {
      setState(() {
        storyEnable = value.data()!['isEnabled'];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          isDarkMode(context) ? AppThemeData.surfaceDark : AppThemeData.surface,
      body: isLoading == true
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding:
                  EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top),
              child: isListView == false
                  ? MapViewScreen(isShowAppBar: false)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: [
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          Scaffold.of(context).openDrawer();
                                        },
                                        child: ClipOval(
                                          child: Container(
                                            color: isDarkMode(context)
                                                ? AppThemeData.grey700
                                                : AppThemeData.grey200,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Icon(Icons.menu),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 12,
                                      ),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            MyAppState.currentUser == null
                                                ? InkWell(
                                                    onTap: () {
                                                      pushAndRemoveUntil(
                                                          context,
                                                          LoginScreen());
                                                    },
                                                    child: Text(
                                                      "Login".tr(),
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        fontFamily:
                                                            AppThemeData.medium,
                                                        color:
                                                            isDarkMode(context)
                                                                ? AppThemeData
                                                                    .grey50
                                                                : AppThemeData
                                                                    .grey900,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  )
                                                : Text(
                                                    "${MyAppState.currentUser!.fullName()}",
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontFamily:
                                                          AppThemeData.medium,
                                                      color: isDarkMode(context)
                                                          ? AppThemeData.grey50
                                                          : AppThemeData
                                                              .grey900,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                            InkWell(
                                              onTap: () async {
                                                if (MyAppState.currentUser !=
                                                    null) {
                                                  await Navigator.of(context)
                                                      .push(MaterialPageRoute(
                                                          builder: (context) =>
                                                              DeliveryAddressScreen()))
                                                      .then((value) {
                                                    if (value != null) {
                                                      AddressModel
                                                          addressModel = value;
                                                      MyAppState
                                                              .selectedPosotion =
                                                          addressModel;
                                                      setState(() {});
                                                      getData();
                                                    }
                                                  });
                                                } else {
                                                  checkPermission(() async {
                                                    await showProgress(
                                                        "Please wait...".tr(),
                                                        false);
                                                    AddressModel addressModel =
                                                        AddressModel();
                                                    try {
                                                      await Geolocator
                                                          .requestPermission();
                                                      await Geolocator
                                                          .getCurrentPosition();
                                                      await hideProgress();
                                                      if (selectedMapType ==
                                                          'osm') {
                                                        Navigator.of(context)
                                                            .push(MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        LocationPicker()))
                                                            .then(
                                                          (value) async {
                                                            if (value != null) {
                                                              AddressModel
                                                                  addressModel =
                                                                  AddressModel();
                                                              addressModel
                                                                      .addressAs =
                                                                  "Home";
                                                              addressModel
                                                                      .locality =
                                                                  value
                                                                      .displayName!
                                                                      .toString();
                                                              addressModel
                                                                      .location =
                                                                  UserLocation(
                                                                      latitude:
                                                                          value
                                                                              .lat,
                                                                      longitude:
                                                                          value
                                                                              .lon);
                                                              MyAppState
                                                                      .selectedPosotion =
                                                                  addressModel;
                                                              getData();
                                                            }
                                                          },
                                                        );
                                                      } else {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (context) =>
                                                                    PlacePicker(
                                                              apiKey:
                                                                  GOOGLE_API_KEY,
                                                              onPlacePicked:
                                                                  (result) async {
                                                                AddressModel
                                                                    addressModel =
                                                                    AddressModel();
                                                                addressModel
                                                                        .addressAs =
                                                                    "Home";
                                                                addressModel
                                                                        .locality =
                                                                    result
                                                                        .formattedAddress!
                                                                        .toString();
                                                                addressModel.location = UserLocation(
                                                                    latitude: result
                                                                        .geometry!
                                                                        .location
                                                                        .lat,
                                                                    longitude: result
                                                                        .geometry!
                                                                        .location
                                                                        .lng);
                                                                MyAppState
                                                                        .selectedPosotion =
                                                                    addressModel;
                                                                getData();
                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                              initialPosition:
                                                                  const LatLng(
                                                                      -33.8567844,
                                                                      151.213108),
                                                              useCurrentLocation:
                                                                  true,
                                                              selectInitialPosition:
                                                                  true,
                                                              usePinPointingSearch:
                                                                  true,
                                                              usePlaceDetailSearch:
                                                                  true,
                                                              zoomGesturesEnabled:
                                                                  true,
                                                              zoomControlsEnabled:
                                                                  true,
                                                              resizeToAvoidBottomInset:
                                                                  false, // only works in page mode, less flickery, remove if wrong offsets
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    } catch (e) {
                                                      await placemarkFromCoordinates(
                                                              19.228825,
                                                              72.854118)
                                                          .then(
                                                              (valuePlaceMaker) {
                                                        Placemark placeMark =
                                                            valuePlaceMaker[0];
                                                        setState(() {
                                                          addressModel
                                                                  .location =
                                                              UserLocation(
                                                                  latitude:
                                                                      19.228825,
                                                                  longitude:
                                                                      72.854118);
                                                          String
                                                              currentLocation =
                                                              "${placeMark.name}, ${placeMark.subLocality}, ${placeMark.locality}, ${placeMark.administrativeArea}, ${placeMark.postalCode}, ${placeMark.country}";
                                                          addressModel
                                                                  .locality =
                                                              currentLocation;
                                                        });
                                                      });

                                                      MyAppState
                                                              .selectedPosotion =
                                                          addressModel;
                                                      await hideProgress();
                                                      getData();
                                                    }
                                                  }, context);
                                                }
                                              },
                                              child: Text.rich(
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: MyAppState
                                                          .selectedPosotion
                                                          .getFullAddress(),
                                                      style: TextStyle(
                                                        fontFamily: AppThemeData
                                                            .semiBold,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        color:
                                                            isDarkMode(context)
                                                                ? AppThemeData
                                                                    .grey50
                                                                : AppThemeData
                                                                    .grey900,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    WidgetSpan(
                                                      child: SvgPicture.asset(
                                                          "assets/icons/ic_down.svg"),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      InkWell(
                                        onTap: () {
                                          if (MyAppState.currentUser == null) {
                                            push(context, const LoginScreen());
                                          } else {
                                            pushAndRemoveUntil(
                                                context,
                                                ContainerScreen(
                                                  user: MyAppState.currentUser!,
                                                  currentWidget: CartScreen(),
                                                  appBarTitle: 'Your Cart'.tr(),
                                                  drawerSelection:
                                                      DrawerSelection.Cart,
                                                ));
                                          }
                                        },
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Icon(
                                              Icons.shopping_cart,
                                              color: AppThemeData.primary300,
                                            ),
                                            StreamBuilder<List<CartProduct>>(
                                              stream:
                                                  cartDatabase.watchProducts,
                                              builder: (context, snapshot) {
                                                cartCount = 0;
                                                if (snapshot.hasData) {
                                                  for (var element
                                                      in snapshot.data!) {
                                                    cartCount +=
                                                        element.quantity;
                                                  }
                                                }
                                                return Visibility(
                                                  visible: cartCount >= 1,
                                                  child: Positioned(
                                                    right: -6,
                                                    top: -8,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              4),
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: AppThemeData
                                                            .primary300,
                                                      ),
                                                      constraints:
                                                          const BoxConstraints(
                                                        minWidth: 12,
                                                        minHeight: 12,
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          cartCount <= 99
                                                              ? '$cartCount'
                                                              : '+99',
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            // fontSize: 10,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  InkWell(
                                    onTap: () {
                                      push(context, const SearchScreen());
                                    },
                                    child: TextFieldWidget(
                                      hintText:
                                          'Search the dish, restaurant, store, meals'.tr(),
                                      controller: null,
                                      enable: false,
                                      prefix: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: SvgPicture.asset(
                                            "assets/icons/ic_search.svg"),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                storyList.isEmpty || storyEnable == false
                                    ? const SizedBox()
                                    : Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: StoryView(storyList: storyList),
                                      ),
                                SizedBox(
                                  height: storyList.isEmpty ? 0 : 20,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      titleView("Explore the Categories".tr(), () {
                                        push(
                                            context,
                                            const CuisinesScreen(
                                                isPageCallFromHomeScreen:
                                                    true));
                                      }),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      CategoryView(
                                          vendorCategoryList:
                                              vendorCategoryModel),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: 32,
                                ),
                                bannerTopHome.isEmpty
                                    ? const SizedBox()
                                    : Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: BannerView(
                                            bannerList: bannerTopHome),
                                      ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      titleView("Top Selling", () {
                                        push(context,
                                            const ViewAllPopularFoodNearByScreen());
                                      }),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      TopSellingView(
                                        vendors: vendors,
                                        lstNearByFood: lstNearByFood,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: 32,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      titleView("New Arrivals", () {
                                        push(
                                            context,
                                            ViewAllNewArrivalStoreScreen(
                                              vendorList:
                                                  newArrivalRestaurantList,
                                            ));
                                      }),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      NewArrival(
                                          newArrivalRestaurantList:
                                              newArrivalRestaurantList)
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: 32,
                                ),
                                bannerMiddleHome.isEmpty
                                    ? const SizedBox()
                                    : Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: BannerView(
                                            bannerList: bannerMiddleHome),
                                      ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      titleView("All Stores", () {
                                        push(
                                            context, const ViewAllRestaurant());
                                      }),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      AllStore(allStoreList: vendors)
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        decoration: BoxDecoration(
            color: isDarkMode(context)
                ? AppThemeData.grey800
                : AppThemeData.grey100,
            borderRadius: const BorderRadius.all(Radius.circular(30))),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode(context)
                      ? AppThemeData.grey900
                      : AppThemeData.grey50,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            isListView = true;
                          });
                        },
                        child: ClipOval(
                          child: Container(
                              decoration: BoxDecoration(
                                  color: isListView
                                      ? AppThemeData.primary300
                                      : null),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SvgPicture.asset(
                                  "assets/icons/ic_view_grid_list.svg",
                                  colorFilter: ColorFilter.mode(
                                      isListView
                                          ? AppThemeData.grey50
                                          : AppThemeData.grey500,
                                      BlendMode.srcIn),
                                ),
                              )),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            isListView = false;
                          });
                        },
                        child: ClipOval(
                          child: Container(
                              decoration: BoxDecoration(
                                  color: isListView == false
                                      ? AppThemeData.primary300
                                      : null),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SvgPicture.asset(
                                  "assets/icons/ic_map_draw.svg",
                                  colorFilter: ColorFilter.mode(
                                      isListView == false
                                          ? AppThemeData.grey50
                                          : AppThemeData.grey500,
                                      BlendMode.srcIn),
                                ),
                              )),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              InkWell(
                onTap: () {
                  push(context, const QrCodeScanner(presectionList: []));
                },
                child: ClipOval(
                  child: Container(
                      decoration: BoxDecoration(
                          color: isDarkMode(context)
                              ? AppThemeData.grey900
                              : AppThemeData.grey50),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: SvgPicture.asset(
                          "assets/icons/ic_scan_code.svg",
                          colorFilter: ColorFilter.mode(
                              isDarkMode(context)
                                  ? AppThemeData.grey400
                                  : AppThemeData.grey500,
                              BlendMode.srcIn),
                        ),
                      )),
                ),
              ),
              const SizedBox(
                width: 14,
              ),
              DropdownButton<String>(
                isDense: false,
                underline: const SizedBox(),
                value: selctedOrderTypeValue,
                icon: const Icon(Icons.keyboard_arrow_down),
                items: <String>[
                  'Delivery'.tr(),
                  'Takeaway'.tr(),
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontFamily: AppThemeData.semiBold,
                        fontSize: 16,
                        color: isDarkMode(context)
                            ? AppThemeData.grey50
                            : AppThemeData.grey900,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) async {
                  int cartProd = 0;
                  await Provider.of<CartDatabase>(context, listen: false)
                      .allCartProducts
                      .then((value) {
                    cartProd = value.length;
                  });

                  if (cartProd > 0) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) => ShowDialogToDismiss(
                        title: '',
                        content: "wantChangeDeliveryOption".tr() +
                            "Your cart will be empty".tr(),
                        buttonText: 'CLOSE'.tr(),
                        secondaryButtonText: 'OK'.tr(),
                        action: () {
                          Navigator.of(context).pop();
                          Provider.of<CartDatabase>(context, listen: false)
                              .deleteAllProducts();
                          setState(() {
                            selctedOrderTypeValue = value.toString();
                            saveFoodTypeValue();
                            getData();
                          });
                        },
                      ),
                    );
                  } else {
                    setState(() {
                      selctedOrderTypeValue = value.toString();

                      saveFoodTypeValue();
                      getData();
                    });
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  titleView(String name, Function()? onPress) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name.tr(),
            textAlign: TextAlign.start,
            style: TextStyle(
              fontFamily: AppThemeData.bold,
              color: isDarkMode(context)
                  ? AppThemeData.grey50
                  : AppThemeData.grey900,
            ),
          ),
        ),
        InkWell(
          onTap: () {
            onPress!();
          },
          child: Text(
            "View all".tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppThemeData.regular,
              color: isDarkMode(context)
                  ? AppThemeData.primary300
                  : AppThemeData.primary300,
            ),
          ),
        )
      ],
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose

    // ImageCache _imageCache = PaintingBinding.instance.imageCache;
    // _imageCache.clear();
    // _imageCache.clearLiveImages();

    fireStoreUtils.closeOfferStream();
    fireStoreUtils.closeVendorStream();
    super.dispose();
  }

  Future<void> saveFoodTypeValue() async {
    SharedPreferences sp = await SharedPreferences.getInstance();

    sp.setString('foodType', selctedOrderTypeValue!);
  }

  getFoodType() async {
    productsFuture.clear();
    lstNearByFood.clear();
    popularRestaurantLst.clear();
    newArrivalRestaurantList.clear();

    SharedPreferences sp = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        selctedOrderTypeValue =
            sp.getString("foodType") == "" || sp.getString("foodType") == null
                ? "Delivery".tr()
                : sp.getString("foodType");
      });
    }
    lstAllRestaurant = await fireStoreUtils.getAllStoresFuture();

    if (lstAllRestaurant?.isNotEmpty == true) {
      for (var vender in lstAllRestaurant!) {
        if (selctedOrderTypeValue == "Takeaway") {
          await fireStoreUtils
              .getAllTakeAWayProducts(vender.id)
              .then((productmodel) {
            if ((isSubscriptionModelApplied == true ||
                    vender.adminCommission?.enable == true) &&
                vender.subscriptionPlan != null) {
              if (vender.subscriptionPlan != null &&
                  isExpire(vender) == false) {
                if (vender.subscriptionPlan?.itemLimit == '-1') {
                  productsFuture.addAll(productmodel);
                } else {
                  int selectedProduct = productmodel.length <
                          int.parse(vender.subscriptionPlan?.itemLimit ?? '0')
                      ? (productmodel.isEmpty ? 0 : (productmodel.length))
                      : int.parse(vender.subscriptionPlan?.itemLimit ?? '0');
                  productsFuture
                      .addAll(productmodel.sublist(0, selectedProduct));
                }
              }
            } else {
              productsFuture.addAll(productmodel);
            }
          });
          log("productsFuture :: ${productsFuture.length}");
        } else {
          await fireStoreUtils
              .getAllDelevryProducts(vender.id)
              .then((productmodel) {
            if ((isSubscriptionModelApplied == true ||
                    vender.adminCommission?.enable == true) &&
                vender.subscriptionPlan != null) {
              if (vender.subscriptionPlan != null &&
                  isExpire(vender) == false) {
                if (vender.subscriptionPlan?.itemLimit == '-1') {
                  productsFuture.addAll(productmodel);
                } else {
                  int selectedProduct = productmodel.length <
                          int.parse(vender.subscriptionPlan?.itemLimit ?? '0')
                      ? (productmodel.isEmpty ? 0 : (productmodel.length))
                      : int.parse(vender.subscriptionPlan?.itemLimit ?? '0');
                  productsFuture
                      .addAll(productmodel.sublist(0, selectedProduct));
                }
              }
            } else {
              productsFuture.addAll(productmodel);
            }
          });
        }
      }
    }
  }

  List<StoryModel> storyList = [];

  Future<void> getData() async {
    await getFoodType();

    if (MyAppState.currentUser != null) {
      lstFavourites =
          FireStoreUtils.getFavouriteStore(MyAppState.currentUser!.userID);
      lstFavourites.then((event) {
        lstFav.clear();
        for (int a = 0; a < event.length; a++) {
          lstFav.add(event[a].store_id!);
        }
      });
      name = toBeginningOfSentenceCase(widget.user!.firstName);
    }

    for (var event in lstAllRestaurant!) {
      vendors.add(event);
      allstoreList.clear();
      allstoreList.add(event);
      for (int d = 0;
          d < (productsFuture.length > 20 ? 20 : productsFuture.length);
          d++) {
        if (event.id == productsFuture[d].vendorID &&
            !lstNearByFood.contains(productsFuture[d])) {
          lstNearByFood.add(productsFuture[d]);
        }
      }
      log("lstAllRestaurant :: lstAllRestaurant :: ${lstAllRestaurant?.length}");
      log("lstAllRestaurant :: lstNearByFood :: ${lstNearByFood.length}");
      popularRestaurantLst.add(event);
      newArrivalRestaurantList.add(event);

      newArrivalRestaurantList.sort(
        (a, b) => (b.createdAt ?? Timestamp.now())
            .toDate()
            .compareTo((a.createdAt ?? Timestamp.now()).toDate()),
      );

      List<VendorModel> temp5 = popularRestaurantLst
          .where((element) =>
              num.parse(
                  (element.reviewsSum / element.reviewsCount).toString()) ==
              5)
          .toList();
      List<VendorModel> temp5_ = popularRestaurantLst
          .where((element) =>
              num.parse(
                      (element.reviewsSum / element.reviewsCount).toString()) >
                  4 &&
              num.parse(
                      (element.reviewsSum / element.reviewsCount).toString()) <
                  5)
          .toList();
      List<VendorModel> temp4 = popularRestaurantLst
          .where((element) =>
              num.parse(
                      (element.reviewsSum / element.reviewsCount).toString()) >
                  3 &&
              num.parse(
                      (element.reviewsSum / element.reviewsCount).toString()) <
                  4)
          .toList();
      List<VendorModel> temp3 = popularRestaurantLst
          .where((element) =>
              num.parse(
                      (element.reviewsSum / element.reviewsCount).toString()) >
                  2 &&
              num.parse(
                      (element.reviewsSum / element.reviewsCount).toString()) <
                  3)
          .toList();
      List<VendorModel> temp2 = popularRestaurantLst
          .where((element) =>
              num.parse(
                      (element.reviewsSum / element.reviewsCount).toString()) >
                  1 &&
              num.parse(
                      (element.reviewsSum / element.reviewsCount).toString()) <
                  2)
          .toList();
      List<VendorModel> temp1 = popularRestaurantLst
          .where((element) =>
              num.parse(
                  (element.reviewsSum / element.reviewsCount).toString()) ==
              1)
          .toList();
      List<VendorModel> temp0 = popularRestaurantLst
          .where((element) =>
              num.parse(
                  (element.reviewsSum / element.reviewsCount).toString()) ==
              0)
          .toList();
      List<VendorModel> temp0_ = popularRestaurantLst
          .where(
              (element) => element.reviewsSum == 0 && element.reviewsCount == 0)
          .toList();

      popularRestaurantLst.clear();
      popularRestaurantLst.addAll(temp5);
      popularRestaurantLst.addAll(temp5_);
      popularRestaurantLst.addAll(temp4);
      popularRestaurantLst.addAll(temp3);
      popularRestaurantLst.addAll(temp2);
      popularRestaurantLst.addAll(temp1);
      popularRestaurantLst.addAll(temp0);
      popularRestaurantLst.addAll(temp0_);

      FireStoreUtils().getPublicCoupons().then((value) {
        offersList.clear();
        offerVendorList.clear();
        value.forEach((element1) {
          vendors.forEach((element) {
            if (element1.storeId == element.id &&
                element1.expireOfferDate!.toDate().isAfter(DateTime.now())) {
              offersList.add(element1);
              offerVendorList.add(element);
            }
          });
        });
        setState(() {});
      });
    }

    FireStoreUtils().getStory().then((value) {
      storyList.clear();
      value.forEach((element1) {
        vendors.forEach((element) {
          if (element1.vendorID == element.id) {
            storyList.add(element1);
          }
        });
      });
      setState(() {});
    });

    setState(() {
      isLoading = false;
    });
  }

  final StoryController controller = StoryController();
}

class StoryView extends StatelessWidget {
  final List<StoryModel> storyList;

  const StoryView({super.key, required this.storyList});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: storyList.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          StoryModel storyModel = storyList[index];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => MoreStories(
                          storyList: storyList,
                          index: index,
                        )));
              },
              child: SizedBox(
                width: 134,
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  child: Stack(
                    children: [
                      NetworkImageWidget(
                        imageUrl: storyModel.videoThumbnail.toString(),
                        fit: BoxFit.cover,
                        height: Responsive.height(100, context),
                        width: Responsive.width(100, context),
                      ),
                      Container(
                        color: Colors.black.withOpacity(0.30),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 8),
                        child: FutureBuilder(
                            future: FireStoreUtils.getVendor(
                                storyModel.vendorID.toString()),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return loader();
                              } else {
                                if (snapshot.hasError) {
                                  return Center(
                                      child: Text('Error: ${snapshot.error}'));
                                } else if (snapshot.data == null) {
                                  return const SizedBox();
                                } else {
                                  VendorModel vendorModel = snapshot.data!;
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipOval(
                                        child: NetworkImageWidget(
                                          imageUrl:
                                              vendorModel.photo.toString(),
                                          width: 30,
                                          height: 30,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 4,
                                      ),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              vendorModel.title.toString(),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  fontFamily:
                                                      AppThemeData.semiBold),
                                            ),
                                            Row(
                                              children: [
                                                SvgPicture.asset(
                                                    "assets/icons/ic_star.svg"),
                                                const SizedBox(
                                                  width: 5,
                                                ),
                                                Text(
                                                  "${calculateReview(reviewCount: vendorModel.reviewsCount.toString(), reviewSum: vendorModel.reviewsSum.toStringAsFixed(0))} reviews",
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  style: const TextStyle(
                                                      color: AppThemeData
                                                          .warning300,
                                                      fontSize: 10,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      fontFamily: AppThemeData
                                                          .semiBold),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }
                              }
                            }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AllStore extends StatelessWidget {
  final List<VendorModel> allStoreList;

  const AllStore({super.key, required this.allStoreList});

  @override
  Widget build(BuildContext context) {
    // final themeChange = Provider.of<DarkThemeProvider>(context);
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      scrollDirection: Axis.vertical,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allStoreList.length >= 10 ? 10 : allStoreList.length,
      itemBuilder: (BuildContext context, int index) {
        VendorModel vendorModel = allStoreList[index];
        return Padding(
          padding: EdgeInsets.only(
              bottom:
                  (allStoreList.length >= 10 ? 10 : allStoreList.length) - 1 ==
                          index
                      ? 90
                      : 20),
          child: InkWell(
            onTap: () {
              push(context, NewVendorProductsScreen(vendorModel: vendorModel));
            },
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  color: isDarkMode(context)
                      ? AppThemeData.grey900
                      : AppThemeData.grey50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  shadows: [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 32,
                      offset: Offset(0, 0),
                      spreadRadius: 0,
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        NetworkImageWidget(
                          imageUrl: vendorModel.photo.toString(),
                          fit: BoxFit.cover,
                          height: Responsive.height(15, context),
                          width: Responsive.width(30, context),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vendorModel.title.toString(),
                                textAlign: TextAlign.start,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 18,
                                  overflow: TextOverflow.ellipsis,
                                  fontFamily: AppThemeData.semiBold,
                                  color: isDarkMode(context)
                                      ? AppThemeData.grey50
                                      : AppThemeData.grey900,
                                ),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    "assets/icons/ic_location.svg",
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Expanded(
                                    child: Text(
                                      vendorModel.location.toString(),
                                      textAlign: TextAlign.start,
                                      maxLines: 1,
                                      style: TextStyle(
                                        overflow: TextOverflow.ellipsis,
                                        fontFamily: AppThemeData.medium,
                                        fontWeight: FontWeight.w500,
                                        color: isDarkMode(context)
                                            ? AppThemeData.grey400
                                            : AppThemeData.grey500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Row(
                                children: [
                                  Row(
                                    children: [
                                      RatingBar.builder(
                                        ignoreGestures: true,
                                        initialRating: double.parse(
                                            calculateReview(
                                                reviewCount:
                                                    vendorModel
                                                        .reviewsCount
                                                        .toString(),
                                                reviewSum: vendorModel
                                                    .reviewsSum
                                                    .toString())),
                                        minRating: 1,
                                        itemSize: 20,
                                        direction: Axis.horizontal,
                                        allowHalfRating: true,
                                        itemCount: 5,
                                        itemPadding:
                                            const EdgeInsets.only(top: 5.0),
                                        itemBuilder: (context, _) => Icon(
                                          Icons.star,
                                          color: AppThemeData.primary300,
                                        ),
                                        onRatingUpdate: (double rate) {
                                          // ratings = rate;
                                          // print(ratings);
                                        },
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        "(${calculateReview(reviewCount: vendorModel.reviewsCount.toString(), reviewSum: vendorModel.reviewsSum.toString())})",
                                        textAlign: TextAlign.start,
                                        maxLines: 1,
                                        style: TextStyle(
                                          overflow: TextOverflow.ellipsis,
                                          fontFamily: AppThemeData.medium,
                                          fontWeight: FontWeight.w500,
                                          decoration: TextDecoration.underline,
                                          color: isDarkMode(context)
                                              ? AppThemeData.grey400
                                              : AppThemeData.grey500,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        "${vendorModel.reviewsCount.toString()}",
                                        textAlign: TextAlign.start,
                                        maxLines: 1,
                                        style: TextStyle(
                                          overflow: TextOverflow.ellipsis,
                                          fontFamily: AppThemeData.medium,
                                          fontWeight: FontWeight.w500,
                                          color: isDarkMode(context)
                                              ? AppThemeData.grey50
                                              : AppThemeData.grey900,
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 5,
                              ),
                            ],
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class NewArrival extends StatelessWidget {
  final List<VendorModel> newArrivalRestaurantList;

  const NewArrival({super.key, required this.newArrivalRestaurantList});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Responsive.height(26, context),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: newArrivalRestaurantList.length >= 10
            ? 10
            : newArrivalRestaurantList.length,
        itemBuilder: (BuildContext context, int index) {
          VendorModel vendorModel = newArrivalRestaurantList[index];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () {
                push(
                    context, NewVendorProductsScreen(vendorModel: vendorModel));
              },
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    color: isDarkMode(context)
                        ? AppThemeData.grey900
                        : AppThemeData.grey50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 32,
                        offset: Offset(0, 0),
                        spreadRadius: 0,
                      )
                    ],
                  ),
                  child: SizedBox(
                    width: Responsive.width(70, context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: NetworkImageWidget(
                            imageUrl: vendorModel.photo.toString(),
                            fit: BoxFit.cover,
                            height: Responsive.height(100, context),
                            width: Responsive.width(100, context),
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vendorModel.title.toString(),
                                textAlign: TextAlign.start,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 18,
                                  overflow: TextOverflow.ellipsis,
                                  fontFamily: AppThemeData.semiBold,
                                  color: isDarkMode(context)
                                      ? AppThemeData.grey50
                                      : AppThemeData.grey900,
                                ),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    "assets/icons/ic_location.svg",
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Expanded(
                                    child: Text(
                                      vendorModel.location.toString(),
                                      textAlign: TextAlign.start,
                                      maxLines: 1,
                                      style: TextStyle(
                                        overflow: TextOverflow.ellipsis,
                                        fontFamily: AppThemeData.medium,
                                        fontWeight: FontWeight.w500,
                                        color: isDarkMode(context)
                                            ? AppThemeData.grey400
                                            : AppThemeData.grey500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Row(
                                children: [
                                  RatingBar.builder(
                                    ignoreGestures: true,
                                    initialRating: double.parse(calculateReview(
                                        reviewCount:
                                            vendorModel.reviewsCount.toString(),
                                        reviewSum:
                                            vendorModel.reviewsSum.toString())),
                                    minRating: 1,
                                    itemSize: 20,
                                    direction: Axis.horizontal,
                                    allowHalfRating: true,
                                    itemCount: 5,
                                    itemPadding:
                                        const EdgeInsets.only(top: 5.0),
                                    itemBuilder: (context, _) => Icon(
                                      Icons.star,
                                      color: AppThemeData.primary300,
                                    ),
                                    onRatingUpdate: (double rate) {
                                      // ratings = rate;
                                      // print(ratings);
                                    },
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    "(${calculateReview(reviewCount: vendorModel.reviewsCount.toString(), reviewSum: vendorModel.reviewsSum.toString())})",
                                    textAlign: TextAlign.start,
                                    maxLines: 1,
                                    style: TextStyle(
                                      overflow: TextOverflow.ellipsis,
                                      fontFamily: AppThemeData.medium,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.underline,
                                      color: isDarkMode(context)
                                          ? AppThemeData.grey400
                                          : AppThemeData.grey500,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    "${vendorModel.reviewsCount.toString()}",
                                    textAlign: TextAlign.start,
                                    maxLines: 1,
                                    style: TextStyle(
                                      overflow: TextOverflow.ellipsis,
                                      fontFamily: AppThemeData.medium,
                                      fontWeight: FontWeight.w500,
                                      color: isDarkMode(context)
                                          ? AppThemeData.grey50
                                          : AppThemeData.grey900,
                                    ),
                                  )
                                ],
                              ),
                              SizedBox(
                                height: 5,
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class TopSellingView extends StatelessWidget {
  final List<VendorModel> vendors;
  final List<ProductModel> lstNearByFood;

  const TopSellingView(
      {super.key, required this.lstNearByFood, required this.vendors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: lstNearByFood.length >= 15 ? 15 : lstNearByFood.length,
        itemBuilder: (context, index) {
          VendorModel? popularNearFoodVendorModel;
          if (vendors.isNotEmpty) {
            for (int a = 0; a < vendors.length; a++) {
              if (vendors[a].id == lstNearByFood[index].vendorID) {
                popularNearFoodVendorModel = vendors[a];
              }
            }
          }
          ProductModel productModel = lstNearByFood[index];
          log("productModel :: ${productModel.name}");

          return FutureBuilder(
              future: getPrice(productModel),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return loader();
                } else {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.data == null) {
                    return const SizedBox();
                  } else {
                    Map<String, dynamic> map = snapshot.data!;
                    String price = map['price'];
                    String disPrice = map['disPrice'];
                    return popularNearFoodVendorModel == null
                        ? Container()
                        : InkWell(
                            onTap: () async {
                              VendorModel? vendorModel =
                                  await FireStoreUtils.getVendor(
                                      productModel.vendorID);
                              if (vendorModel != null) {
                                push(
                                  context,
                                  ProductDetailsScreen(
                                    vendorModel: vendorModel,
                                    productModel: productModel,
                                  ),
                                );
                              }
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              child: SizedBox(
                                width: 145,
                                child: Container(
                                  clipBehavior: Clip.antiAlias,
                                  decoration: ShapeDecoration(
                                    color: isDarkMode(context)
                                        ? AppThemeData.grey900
                                        : AppThemeData.grey50,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    shadows: [
                                      BoxShadow(
                                        color: Color(0x0A000000),
                                        blurRadius: 32,
                                        offset: Offset(0, 0),
                                        spreadRadius: 0,
                                      )
                                    ],
                                  ),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 5),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Center(
                                          child: SizedBox(
                                            width: 70,
                                            height: 70,
                                            child: ClipOval(
                                              child: NetworkImageWidget(
                                                imageUrl: productModel.photo
                                                    .toString(),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${productModel.name.capitalizeString()}',
                                                textAlign: TextAlign.start,
                                                maxLines: 1,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  color: isDarkMode(context)
                                                      ? AppThemeData.grey50
                                                      : AppThemeData.grey900,
                                                  fontFamily:
                                                      AppThemeData.medium,
                                                ),
                                              ),
                                              SizedBox(
                                                height: 5,
                                              ),
                                              Text(
                                                '${productModel.description.capitalizeString()}',
                                                textAlign: TextAlign.start,
                                                maxLines: 2,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDarkMode(context)
                                                      ? AppThemeData.grey50
                                                      : AppThemeData.grey900,
                                                  fontFamily:
                                                      AppThemeData.regular,
                                                ),
                                              ),
                                              SizedBox(
                                                height: 5,
                                              ),
                                              price == "" || disPrice == "0"
                                                  ? Text(
                                                      amountShow(amount: price),
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          letterSpacing: 0.5,
                                                          color: AppThemeData
                                                              .primary300),
                                                    )
                                                  : Row(
                                                      children: [
                                                        Text(
                                                          "${amountShow(amount: disPrice)}",
                                                          // "$symbol${double.parse(productModel.disPrice.toString()).toStringAsFixed(decimal)}",
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: AppThemeData
                                                                .primary300,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 10,
                                                        ),
                                                        Text(
                                                          amountShow(
                                                              amount: disPrice),
                                                          style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.grey,
                                                              decoration:
                                                                  TextDecoration
                                                                      .lineThrough),
                                                        ),
                                                      ],
                                                    ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                  }
                }
              });
        },
      ),
    );
  }

  Future<Map<String, dynamic>> getPrice(ProductModel productModel) async {
    String price = "0.0";
    String disPrice = "0.0";
    List<String> selectedVariants = [];
    List<String> selectedIndexVariants = [];
    List<String> selectedIndexArray = [];

    print("=======>");
    print(productModel.price);
    print(productModel.disPrice);

    VendorModel? vendorModel =
        await FireStoreUtils.getVendor(productModel.vendorID.toString());
    if (productModel.itemAttributes != null) {
      if (productModel.itemAttributes!.attributes!.isNotEmpty) {
        for (var element in productModel.itemAttributes!.attributes!) {
          if (element.attributeOptions!.isNotEmpty) {
            selectedVariants.add(productModel
                .itemAttributes!
                .attributes![
                    productModel.itemAttributes!.attributes!.indexOf(element)]
                .attributeOptions![0]
                .toString());
            selectedIndexVariants.add(
                '${productModel.itemAttributes!.attributes!.indexOf(element)} _${productModel.itemAttributes!.attributes![0].attributeOptions![0].toString()}');
            selectedIndexArray.add(
                '${productModel.itemAttributes!.attributes!.indexOf(element)}_0');
          }
        }
      }
      if (productModel.itemAttributes!.variants!
          .where((element) => element.variant_sku == selectedVariants.join('-'))
          .isNotEmpty) {
        price = productCommissionPrice(
            vendorModel!.adminCommission,
            productModel.itemAttributes!.variants!
                    .where((element) =>
                        element.variant_sku == selectedVariants.join('-'))
                    .first
                    .variant_price ??
                '0');
        disPrice = productCommissionPrice(vendorModel.adminCommission, '0');
      }
    } else {
      price = productCommissionPrice(
          vendorModel?.adminCommission, productModel.price.toString());
      disPrice = productCommissionPrice(
          vendorModel?.adminCommission, productModel.disPrice.toString());
    }

    return {'price': price, 'disPrice': disPrice};
  }
}

class CategoryView extends StatelessWidget {
  final List<VendorCategoryModel> vendorCategoryList;

  const CategoryView({super.key, required this.vendorCategoryList});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 124,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: vendorCategoryList.length,
        itemBuilder: (context, index) {
          VendorCategoryModel vendorCategoryModel = vendorCategoryList[index];
          return InkWell(
            onTap: () {
              push(
                  context,
                  CategoryDetailsScreen(
                      category: vendorCategoryModel, isDineIn: false));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              child: SizedBox(
                width: 100,
                child: Container(
                  decoration: ShapeDecoration(
                    color: isDarkMode(context)
                        ? AppThemeData.grey900
                        : AppThemeData.grey50,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        strokeAlign: BorderSide.strokeAlignOutside,
                        color: isDarkMode(context)
                            ? AppThemeData.grey800
                            : AppThemeData.grey100,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        child: Text(
                          '${vendorCategoryModel.title}',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: TextStyle(
                            color: isDarkMode(context)
                                ? AppThemeData.grey50
                                : AppThemeData.grey900,
                            fontFamily: AppThemeData.medium,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: ClipOval(
                          child: NetworkImageWidget(
                            imageUrl: vendorCategoryModel.photo.toString(),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class BannerView extends StatefulWidget {
  final List<BannerModel> bannerList;

  const BannerView({super.key, required this.bannerList});

  @override
  State<BannerView> createState() => _BannerViewState();
}

class _BannerViewState extends State<BannerView> {
  PageController pageController = PageController(viewportFraction: 0.877);
  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
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
              BannerModel bannerModel = widget.bannerList[index];
              return InkWell(
                onTap: () async {
                  if (bannerModel.redirect_type == "store") {
                    ShowToastDialog.showLoader("Please wait");
                    VendorModel? vendorModel = await FireStoreUtils.getVendor(
                        bannerModel.redirect_id.toString());

                    ShowToastDialog.closeLoader();
                    push(
                      context,
                      NewVendorProductsScreen(vendorModel: vendorModel!),
                    );
                  } else if (bannerModel.redirect_type == "product") {
                    ShowToastDialog.showLoader("Please wait");
                    ProductModel? productModel =
                        await FireStoreUtils.getProductById(
                            bannerModel.redirect_id.toString());
                    VendorModel? vendorModel = await FireStoreUtils.getVendor(
                        productModel!.vendorID.toString());

                    ShowToastDialog.closeLoader();
                    push(
                      context,
                      NewVendorProductsScreen(vendorModel: vendorModel!),
                    );
                  } else if (bannerModel.redirect_type == "external_link") {
                    final uri = Uri.parse(bannerModel.redirect_id.toString());
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      ShowToastDialog.showToast("Could not launch");
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    child: NetworkImageWidget(
                      imageUrl: bannerModel.photo.toString(),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(
              widget.bannerList.length,
              (index) {
                return Container(
                  margin: const EdgeInsets.only(right: 5),
                  alignment: Alignment.centerLeft,
                  height: 9,
                  width: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentPage == index
                        ? AppThemeData.primary300
                        : Colors.black12,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
