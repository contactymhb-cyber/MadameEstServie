import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emartconsumer/constants.dart';
import 'package:emartconsumer/ecommarce_service/view_all_category_product_screen.dart';
import 'package:emartconsumer/main.dart';
import 'package:emartconsumer/model/AddressModel.dart';
import 'package:emartconsumer/model/BannerModel.dart';
import 'package:emartconsumer/model/BrandsModel.dart';
import 'package:emartconsumer/model/FavouriteModel.dart';
import 'package:emartconsumer/model/ProductModel.dart';
import 'package:emartconsumer/model/User.dart';
import 'package:emartconsumer/model/VendorCategoryModel.dart';
import 'package:emartconsumer/model/VendorModel.dart';
import 'package:emartconsumer/model/offer_model.dart';
import 'package:emartconsumer/services/FirebaseHelper.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/services/show_toast_dialog.dart';
import 'package:emartconsumer/theme/app_them_data.dart';
import 'package:emartconsumer/theme/responsive.dart';
import 'package:emartconsumer/theme/text_field_widget.dart';
import 'package:emartconsumer/ui/categoryDetailsScreen/CategoryDetailsScreen.dart';
import 'package:emartconsumer/ui/cuisinesScreen/CuisinesScreen.dart';
import 'package:emartconsumer/ui/home/view_all_new_arrival_store_screen.dart';
import 'package:emartconsumer/ui/home/view_all_restaurant.dart';
import 'package:emartconsumer/ui/productDetailsScreen/ProductDetailsScreen.dart';
import 'package:emartconsumer/ui/searchScreen/SearchScreen.dart';
import 'package:emartconsumer/utils/network_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ui/vendorProductsScreen/newVendorProductsScreen.dart';
import 'view_all_brand_product_screen.dart';

class EcommerceHomeScreen extends StatefulWidget {
  final User? user;
  final String vendorId;

  EcommerceHomeScreen({
    Key? key,
    required this.user,
    vendorId,
  })  : vendorId = vendorId ?? "",
        super(key: key);

  @override
  _EcommerceHomeScreenState createState() => _EcommerceHomeScreenState();
}

class _EcommerceHomeScreenState extends State<EcommerceHomeScreen> {
  final fireStoreUtils = FireStoreUtils();
  List<VendorCategoryModel> vendorCategoryModel = [];

  List<ProductModel> productsFuture = <ProductModel>[];
  List<VendorModel> vendors = [];
  List<VendorModel> popularRestaurantLst = [];
  List<VendorModel> newArrivalLst = [];
  VendorModel? popularNearFoodVendorModel;
  List<VendorModel> lstAllRestaurant = <VendorModel>[];
  bool showLoader = true;

  late Future<List<FavouriteModel>> lstFavourites;
  List<String> lstFav = [];

  String? name = "";

  String? currentLocation = "";

  String? selctedOrderTypeValue = "Delivery".tr();

  loc.Location location = loc.Location();

  bool isLoading = true;

  getLocationData() async {
    AddressModel addressModel = AddressModel();
    await getCurrentLocation().then((value) async {
      await placemarkFromCoordinates(value.latitude, value.longitude)
          .then((valuePlaceMaker) {
        Placemark placeMark = valuePlaceMaker[0];

        setState(() {
          addressModel.location = UserLocation(
              latitude: value.latitude, longitude: value.longitude);
          currentLocation =
              "${placeMark.name}, ${placeMark.subLocality}, ${placeMark.locality}, ${placeMark.administrativeArea}, ${placeMark.postalCode}, ${placeMark.country}";
          addressModel.locality = currentLocation;
        });
      }).catchError((error) {
        debugPrint("------>${error.toString()}");
      });

      getData();
      setState(() {
        isLoading = false;
      });
    }).onError((error, stackTrace) {
      setState(() {
        isLoading = false;
      });
      getPermission();
    });

    MyAppState.selectedPosotion = addressModel;
    setState(() {
      isLoading = false;
    });
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

  // Database db;

  @override
  void initState() {
    super.initState();
    getLocationData();

    getBanner();
    saveFoodTypeValue();
    getHomePageCategoryProduct();
  }

  List<VendorCategoryModel> categoryWiseProductList = [];
  List<BrandsModel> brandModelList = [];
  List<OfferModel> offerList = [];

  getHomePageCategoryProduct() async {
    await fireStoreUtils.getCuisines().then(
      (value) {
        vendorCategoryModel = value;
      },
    );

    await fireStoreUtils.getHomePageShowCategory().then((value) {
      setState(() {
        categoryWiseProductList = value;
      });
    });

    await FireStoreUtils.getBrands().then((value) {
      setState(() {
        brandModelList = value;
      });
    });

    await FireStoreUtils().getPublicCoupons().then((value) {
      setState(() {
        offerList = value;
      });
    });
  }

  List<BannerModel> bannerTopHome = [];
  List<BannerModel> bannerMiddleHome = [];

  bool isHomeBannerLoading = true;
  bool isHomeBannerMiddleLoading = true;

  getBanner() async {
    print("-------->");
    await fireStoreUtils.getHomeTopBanner().then((value) {
      setState(() {
        print(value);
        bannerTopHome = value;
        isHomeBannerLoading = false;
      });
    });

    await fireStoreUtils.getHomeMiddleBanner().then((value) {
      setState(() {
        print(value);
        bannerMiddleHome = value;
        isHomeBannerMiddleLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: isDarkMode(context)
            ? AppThemeData.surfaceDark
            : AppThemeData.surface,
        body: isLoading == true
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: InkWell(
                        onTap: () {
                          push(context, const SearchScreen());
                        },
                        child: TextFieldWidget(
                          hintText:
                              'Search the dish, restaurant, store, meals'.tr(),
                          controller: null,
                          enable: false,
                          prefix: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child:
                                SvgPicture.asset("assets/icons/ic_search.svg"),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    bannerTopHome.isEmpty
                        ? const SizedBox()
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: BannerView(bannerList: bannerTopHome),
                          ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          titleView("Our Top Categories", () {
                            push(
                                context,
                                const CuisinesScreen(
                                    isPageCallFromHomeScreen: true));
                          }),
                          const SizedBox(
                            height: 10,
                          ),
                          CategoryView(vendorCategoryList: vendorCategoryModel),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          titleView("New Arrivals", () {
                            push(
                                context,
                                ViewAllNewArrivalStoreScreen(
                                  vendorList: newArrivalLst,
                                ));
                          }),
                          const SizedBox(
                            height: 10,
                          ),
                          NewArrival(newArrivalRestaurantList: newArrivalLst)
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          titleView("Brand", () {}, viewAllSHow: false),
                          const SizedBox(
                            height: 10,
                          ),
                          BrandView(brandList: brandModelList)
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    bannerMiddleHome.isEmpty
                        ? const SizedBox()
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: BannerView(bannerList: bannerMiddleHome),
                          ),
                    const SizedBox(
                      height: 32,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ListView.builder(
                        itemCount: categoryWiseProductList.length,
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              decoration: ShapeDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment(0.00, -1.00),
                                  end: Alignment(0, 1),
                                  colors: eCommerceProductColor[
                                      index % eCommerceProductColor.length],
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 14),
                                child: FutureBuilder<List<ProductModel>>(
                                  future: FireStoreUtils()
                                      .getProductListByCategoryId(
                                          categoryWiseProductList[index]
                                              .id
                                              .toString()),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Center(
                                        child:
                                            CircularProgressIndicator.adaptive(
                                          valueColor: AlwaysStoppedAnimation(
                                              AppThemeData.primary300),
                                        ),
                                      );
                                    }
                                    if ((snapshot.hasData ||
                                            (snapshot.data?.isNotEmpty ??
                                                false)) &&
                                        mounted) {
                                      return snapshot.data!.isEmpty
                                          ? Container()
                                          : Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        categoryWiseProductList[
                                                                index]
                                                            .title
                                                            .toString(),
                                                        textAlign:
                                                            TextAlign.start,
                                                        style: TextStyle(
                                                          fontFamily:
                                                              AppThemeData.bold,
                                                          fontStyle:
                                                              FontStyle.italic,
                                                          color: AppThemeData
                                                              .grey900,
                                                        ),
                                                      ),
                                                    ),
                                                    InkWell(
                                                      onTap: () {
                                                        push(
                                                          context,
                                                          ViewAllCategoryProductScreen(
                                                            vendorCategoryModel:
                                                                categoryWiseProductList[
                                                                    index],
                                                          ),
                                                        );
                                                      },
                                                      child: Text(
                                                        "View all".tr(),
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          fontFamily:
                                                              AppThemeData
                                                                  .regular,
                                                          color: isDarkMode(
                                                                  context)
                                                              ? AppThemeData
                                                                  .primary300
                                                              : AppThemeData
                                                                  .primary300,
                                                        ),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                                SizedBox(
                                                  height: 20,
                                                ),
                                                SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                            .size
                                                            .width,
                                                    height: 190,
                                                    child: ListView.builder(
                                                      shrinkWrap: true,
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      physics:
                                                          const BouncingScrollPhysics(),
                                                      padding: EdgeInsets.zero,
                                                      itemCount:
                                                          snapshot.data!.length,
                                                      itemBuilder:
                                                          (context, index) {
                                                        ProductModel
                                                            productModel =
                                                            snapshot
                                                                .data![index];

                                                        return FutureBuilder(
                                                            future: FireStoreUtils
                                                                .getVendor(
                                                                    productModel
                                                                        .vendorID),
                                                            builder: (context,
                                                                vendorSnapshot) {
                                                              if (!vendorSnapshot
                                                                      .hasData ||
                                                                  vendorSnapshot
                                                                          .connectionState ==
                                                                      ConnectionState
                                                                          .waiting) {
                                                                return const SizedBox(); // Show placeholder or loader
                                                              }
                                                              VendorModel?
                                                                  vendordata =
                                                                  vendorSnapshot
                                                                      .data;
                                                              String price =
                                                                  "0.0";
                                                              String disPrice =
                                                                  "0.0";
                                                              List<String>
                                                                  selectedVariants =
                                                                  [];
                                                              List<String>
                                                                  selectedIndexVariants =
                                                                  [];
                                                              List<String>
                                                                  selectedIndexArray =
                                                                  [];
                                                              if (productModel
                                                                      .itemAttributes !=
                                                                  null) {
                                                                if (productModel
                                                                    .itemAttributes!
                                                                    .attributes!
                                                                    .isNotEmpty) {
                                                                  for (var element
                                                                      in productModel
                                                                          .itemAttributes!
                                                                          .attributes!) {
                                                                    if (element
                                                                        .attributeOptions!
                                                                        .isNotEmpty) {
                                                                      selectedVariants.add(productModel
                                                                          .itemAttributes!
                                                                          .attributes![productModel
                                                                              .itemAttributes!
                                                                              .attributes!
                                                                              .indexOf(element)]
                                                                          .attributeOptions![0]
                                                                          .toString());
                                                                      selectedIndexVariants
                                                                          .add(
                                                                              '${productModel.itemAttributes!.attributes!.indexOf(element)} _${productModel.itemAttributes!.attributes![0].attributeOptions![0].toString()}');
                                                                      selectedIndexArray
                                                                          .add(
                                                                              '${productModel.itemAttributes!.attributes!.indexOf(element)}_0');
                                                                    }
                                                                  }
                                                                }

                                                                if (productModel
                                                                    .itemAttributes!
                                                                    .variants!
                                                                    .where((element) =>
                                                                        element
                                                                            .variant_sku ==
                                                                        selectedVariants
                                                                            .join('-'))
                                                                    .isNotEmpty) {
                                                                  price = productCommissionPrice(
                                                                      vendordata
                                                                          ?.adminCommission,
                                                                      productModel
                                                                              .itemAttributes!
                                                                              .variants!
                                                                              .where((element) => element.variant_sku == selectedVariants.join('-'))
                                                                              .first
                                                                              .variant_price ??
                                                                          '0');
                                                                  disPrice =
                                                                      "0";
                                                                }
                                                              } else {
                                                                price = productCommissionPrice(
                                                                    vendordata
                                                                        ?.adminCommission,
                                                                    productModel
                                                                        .price
                                                                        .toString());
                                                                disPrice = double.parse(productModel
                                                                            .disPrice
                                                                            .toString()) <=
                                                                        0
                                                                    ? "0"
                                                                    : productCommissionPrice(
                                                                        vendordata
                                                                            ?.adminCommission,
                                                                        productModel
                                                                            .disPrice
                                                                            .toString());
                                                              }
                                                              return Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        right:
                                                                            10),
                                                                child:
                                                                    GestureDetector(
                                                                  onTap:
                                                                      () async {
                                                                    VendorModel?
                                                                        vendorModel =
                                                                        vendordata;
                                                                    if (vendorModel !=
                                                                        null) {
                                                                      push(
                                                                        context,
                                                                        ProductDetailsScreen(
                                                                          vendorModel:
                                                                              vendorModel,
                                                                          productModel:
                                                                              productModel,
                                                                        ),
                                                                      );
                                                                    }
                                                                  },
                                                                  child:
                                                                      SizedBox(
                                                                    width: 150,
                                                                    child:
                                                                        Container(
                                                                      clipBehavior:
                                                                          Clip.antiAlias,
                                                                      decoration:
                                                                          ShapeDecoration(
                                                                        color: isDarkMode(context)
                                                                            ? AppThemeData.grey900
                                                                            : AppThemeData.grey50,
                                                                        shape:
                                                                            RoundedRectangleBorder(
                                                                          borderRadius:
                                                                              BorderRadius.circular(12),
                                                                        ),
                                                                        shadows: [
                                                                          BoxShadow(
                                                                            color:
                                                                                Color(0x0A000000),
                                                                            blurRadius:
                                                                                32,
                                                                            offset:
                                                                                Offset(0, 0),
                                                                            spreadRadius:
                                                                                0,
                                                                          )
                                                                        ],
                                                                      ),
                                                                      child:
                                                                          Padding(
                                                                        padding: const EdgeInsets
                                                                            .symmetric(
                                                                            vertical:
                                                                                5),
                                                                        child:
                                                                            Column(
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
                                                                                    imageUrl: productModel.photo.toString(),
                                                                                    fit: BoxFit.cover,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            Padding(
                                                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                                                              child: Column(
                                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                children: [
                                                                                  Text(
                                                                                    '${productModel.name.capitalizeString()}',
                                                                                    textAlign: TextAlign.start,
                                                                                    maxLines: 1,
                                                                                    style: TextStyle(
                                                                                      fontSize: 18,
                                                                                      color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900,
                                                                                      fontFamily: AppThemeData.medium,
                                                                                    ),
                                                                                  ),
                                                                                  SizedBox(
                                                                                    height: 5,
                                                                                  ),
                                                                                  Row(
                                                                                    children: [
                                                                                      Icon(
                                                                                        Icons.star,
                                                                                        size: 18,
                                                                                        color: AppThemeData.warning300,
                                                                                      ),
                                                                                      const SizedBox(
                                                                                        width: 5,
                                                                                      ),
                                                                                      Text(
                                                                                        "(${calculateReview(reviewCount: productModel.reviewsCount.toString(), reviewSum: productModel.reviewsSum.toString())})",
                                                                                        textAlign: TextAlign.start,
                                                                                        maxLines: 1,
                                                                                        style: TextStyle(
                                                                                          overflow: TextOverflow.ellipsis,
                                                                                          fontFamily: AppThemeData.medium,
                                                                                          fontWeight: FontWeight.w500,
                                                                                          decoration: TextDecoration.underline,
                                                                                          color: isDarkMode(context) ? AppThemeData.grey400 : AppThemeData.grey500,
                                                                                        ),
                                                                                      ),
                                                                                      const SizedBox(
                                                                                        width: 5,
                                                                                      ),
                                                                                      Text(
                                                                                        "${productModel.reviewsCount.toString()}",
                                                                                        textAlign: TextAlign.start,
                                                                                        maxLines: 1,
                                                                                        style: TextStyle(
                                                                                          overflow: TextOverflow.ellipsis,
                                                                                          fontFamily: AppThemeData.medium,
                                                                                          fontWeight: FontWeight.w500,
                                                                                          color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900,
                                                                                        ),
                                                                                      )
                                                                                    ],
                                                                                  ),
                                                                                  SizedBox(
                                                                                    height: 5,
                                                                                  ),
                                                                                  disPrice == "" || disPrice == "0"
                                                                                      ? Text(
                                                                                          amountShow(amount: price),
                                                                                          style: TextStyle(fontSize: 16, letterSpacing: 0.5, color: AppThemeData.primary300),
                                                                                        )
                                                                                      : SingleChildScrollView(
                                                                                          scrollDirection: Axis.horizontal,
                                                                                          child: Row(
                                                                                            children: [
                                                                                              Text(
                                                                                                amountShow(amount: disPrice),
                                                                                                style: TextStyle(
                                                                                                  fontSize: 14,
                                                                                                  fontWeight: FontWeight.bold,
                                                                                                  color: AppThemeData.primary300,
                                                                                                ),
                                                                                              ),
                                                                                              const SizedBox(
                                                                                                width: 5,
                                                                                              ),
                                                                                              Text(
                                                                                                amountShow(amount: price),
                                                                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, decoration: TextDecoration.lineThrough),
                                                                                              ),
                                                                                            ],
                                                                                          ),
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
                                                            });
                                                      },
                                                    )),
                                              ],
                                            );
                                    } else {
                                      return showEmptyState(
                                          'No Categories'.tr(), context);
                                    }
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 28,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          titleView("All Stores", () {
                            push(context, const ViewAllRestaurant());
                          }),
                          const SizedBox(
                            height: 14,
                          ),
                          AllStore(allStoreList: vendors)
                        ],
                      ),
                    ),
                  ],
                ),
              ));
  }

  titleView(String name, Function()? onPress, {bool viewAllSHow = true}) {
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
        viewAllSHow == false
            ? SizedBox()
            : InkWell(
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
    fireStoreUtils.closeOfferStream();
    fireStoreUtils.closeVendorStream();
    super.dispose();
  }

  Future<void> saveFoodTypeValue() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString('foodType', "Delivery");
  }

  getFoodType() async {
    productsFuture.clear();
    popularRestaurantLst.clear();
    vendors.clear();
    allstoreList.clear();
    newArrivalLst.clear();
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
    if (lstAllRestaurant.isNotEmpty == true) {
      for (var vender in lstAllRestaurant) {
        if (selctedOrderTypeValue == "Takeaway") {
          await fireStoreUtils
              .getAllTakeAWayProducts(vender.id)
              .then((productmodel) {
            if (isSubscriptionModelApplied == true ||
                vender.adminCommission?.enable == true) {
              if (vender.subscriptionPlan != null &&
                  isExpire(vender) == false) {
                if (vender.subscriptionPlan?.itemLimit != '-1') {
                  int selectedProduct = productmodel.length <
                          int.parse(vender.subscriptionPlan?.itemLimit ?? '0')
                      ? (productmodel.isEmpty ? 0 : (productmodel.length))
                      : int.parse(vender.subscriptionPlan?.itemLimit ?? '0');
                  productsFuture
                      .addAll(productmodel.sublist(0, selectedProduct));
                } else {
                  productsFuture.addAll(productmodel);
                }
              }
            } else {
              productsFuture.addAll(productmodel);
            }
          });
        } else {
          await fireStoreUtils
              .getAllDelevryProducts(vender.id)
              .then((productmodel) {
            if (isSubscriptionModelApplied == true ||
                vender.adminCommission?.enable == true) {
              if (vender.subscriptionPlan != null &&
                  isExpire(vender) == false) {
                if (vender.subscriptionPlan?.itemLimit != '-1') {
                  int selectedProduct = productmodel.length <
                          int.parse(vender.subscriptionPlan?.itemLimit ?? '0')
                      ? (productmodel.isEmpty ? 0 : (productmodel.length))
                      : int.parse(vender.subscriptionPlan?.itemLimit ?? '0');
                  productsFuture
                      .addAll(productmodel.sublist(0, selectedProduct));
                } else {
                  productsFuture.addAll(productmodel);
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

  Future<void> getData() async {
    print("data calling ");
    if (!mounted) {
      return;
    }
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

    for (var event in lstAllRestaurant) {
      vendors.add(event);
      allstoreList.add(event);
      popularRestaurantLst.add(event);
      newArrivalLst.add(event);
      newArrivalLst.sort((a, b) => (b.createdAt ?? Timestamp.now())
          .toDate()
          .compareTo((a.createdAt ?? Timestamp.now()).toDate()));

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

      setState(() {});
    }
  }
}

class AllStore extends StatelessWidget {
  final List<VendorModel> allStoreList;

  const AllStore({super.key, required this.allStoreList});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
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
                                        "${vendorModel.reviewsSum.toString()}",
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

class CategoryView extends StatelessWidget {
  final List<VendorCategoryModel> vendorCategoryList;

  const CategoryView({super.key, required this.vendorCategoryList});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: vendorCategoryList.length,
        itemBuilder: (context, index) {
          VendorCategoryModel vendorCategoryModel = vendorCategoryList[index];
          return InkWell(
            onTap: () {
              if (sectionConstantModel!.serviceTypeFlag ==
                  "ecommerce-service") {
                push(
                  context,
                  ViewAllCategoryProductScreen(
                    vendorCategoryModel: vendorCategoryModel,
                  ),
                );
              } else {
                push(
                    context,
                    CategoryDetailsScreen(
                        category: vendorCategoryModel, isDineIn: false));
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              child: SizedBox(
                width: 80,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
                    Text(
                      '${vendorCategoryModel.title}',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                          color: isDarkMode(context)
                              ? AppThemeData.grey50
                              : AppThemeData.grey900,
                          fontFamily: AppThemeData.medium,
                          fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
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
                                    "${vendorModel.reviewsSum.toString()}",
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

class BrandView extends StatelessWidget {
  final List<BrandsModel> brandList;

  const BrandView({super.key, required this.brandList});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 11 / 6,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: brandList.length,
      shrinkWrap: true,
      itemBuilder: (BuildContext context, int index) {
        BrandsModel vendorModel = brandList[index];
        return InkWell(
          onTap: () {
            push(context, ViewAllBrandProductScreen(brandModel: vendorModel));
          },
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
            child: NetworkImageWidget(
              imageUrl: vendorModel.photo.toString(),
              fit: BoxFit.cover,
              height: Responsive.height(100, context),
              width: Responsive.width(100, context),
            ),
          ),
        );
      },
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
