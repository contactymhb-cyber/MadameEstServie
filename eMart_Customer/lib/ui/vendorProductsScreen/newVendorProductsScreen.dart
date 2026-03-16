import 'dart:async';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:emartconsumer/constants.dart';
import 'package:emartconsumer/main.dart';
import 'package:emartconsumer/model/FavouriteItemModel.dart';
import 'package:emartconsumer/model/FavouriteModel.dart';
import 'package:emartconsumer/model/ProductModel.dart';
import 'package:emartconsumer/model/VendorCategoryModel.dart';
import 'package:emartconsumer/model/VendorModel.dart';
import 'package:emartconsumer/model/WorkingHoursModel.dart';
import 'package:emartconsumer/model/offer_model.dart';
import 'package:emartconsumer/services/FirebaseHelper.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/services/show_toast_dialog.dart';
import 'package:emartconsumer/theme/app_them_data.dart';
import 'package:emartconsumer/theme/responsive.dart';
import 'package:emartconsumer/theme/round_button_fill.dart';
import 'package:emartconsumer/theme/text_field_widget.dart';
import 'package:emartconsumer/ui/productDetailsScreen/ProductDetailsScreen.dart';
import 'package:emartconsumer/ui/review_list_screen/review_list_screen.dart';
import 'package:emartconsumer/utils/network_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewVendorProductsScreen extends StatefulWidget {
  final VendorModel vendorModel;

  const NewVendorProductsScreen({Key? key, required this.vendorModel})
      : super(key: key);

  @override
  State<NewVendorProductsScreen> createState() =>
      _NewVendorProductsScreenState();
}

class _NewVendorProductsScreenState extends State<NewVendorProductsScreen>
    with SingleTickerProviderStateMixin {
  final FireStoreUtils fireStoreUtils = FireStoreUtils();

  bool isLoading = true;

  @override
  void initState() {
    getFoodType();
    statusCheck();
    animateSlider();
    super.initState();
  }

  String? foodType;

  List a = [];
  List<ProductModel> allProductList = [];
  List<ProductModel> productList = [];

  void getFoodType() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    foodType = sp.getString("foodType") ?? "Delivery".tr();

    print("------->${foodType}");
    if (foodType == "Takeaway") {
      log("isSubscriptionModelApplied :: 11 :: ${isSubscriptionModelApplied} || ${widget.vendorModel.adminCommission?.enable} && ${widget.vendorModel.subscriptionPlan?.toJson()} ");
      await fireStoreUtils
          .getVendorProductsTakeAWay(widget.vendorModel.id)
          .then((value) {
        if (isSubscriptionModelApplied == true ||
            widget.vendorModel.adminCommission?.enable == true) {
          if (widget.vendorModel.subscriptionPlan != null) {
            if (widget.vendorModel.subscriptionPlan?.itemLimit == '-1') {
              allProductList = value;
              productList = value;
            } else {
              int selectedProduct = value.length <
                      int.parse(
                          widget.vendorModel.subscriptionPlan?.itemLimit ?? '0')
                  ? (value.isEmpty ? 0 : (value.length))
                  : int.parse(
                      widget.vendorModel.subscriptionPlan?.itemLimit ?? '0');
              allProductList = value.sublist(0, selectedProduct);
              productList = value.sublist(0, selectedProduct);
            }
          }
        } else {
          allProductList = value;
          productList = value;
        }
        getVendorCategoryById();
        setState(() {});
      });
    } else {
      await fireStoreUtils
          .getVendorProductsDelivery(widget.vendorModel.id)
          .then((value) {
        if (isSubscriptionModelApplied == true ||
            widget.vendorModel.adminCommission?.enable == true) {
          if (widget.vendorModel.subscriptionPlan != null) {
            if (widget.vendorModel.subscriptionPlan?.itemLimit == '-1') {
              allProductList = value;
              productList = value;
            } else {
              int selectedProduct = value.length <
                      int.parse(
                          widget.vendorModel.subscriptionPlan?.itemLimit ?? '0')
                  ? (value.isEmpty ? 0 : (value.length))
                  : int.parse(
                      widget.vendorModel.subscriptionPlan?.itemLimit ?? '0');
              allProductList = value.sublist(0, selectedProduct);
              productList = value.sublist(0, selectedProduct);
            }
          }
        } else {
          allProductList = value;
          productList = value;
        }
        getVendorCategoryById();
        setState(() {});
      });
    }
  }

  List<VendorCategoryModel> vendorCategoryList = [];
  List<OfferModel> offerList = [];
  List<FavouriteItemModel> favouriteItemList = <FavouriteItemModel>[];

  getVendorCategoryById() async {
    vendorCategoryList.clear();

    for (var element in productList) {
      FireStoreUtils.getVendorCategoryById(element.categoryID.toString()).then(
        (value) {
          if (value != null) {
            if (vendorCategoryList
                .where((element) => element.id == value.id)
                .isEmpty) {
              vendorCategoryList.add(value);
            }
          }
        },
      );
    }

    var seen = <String>{};
    vendorCategoryList = vendorCategoryList
        .where((element) => seen.add(element.id.toString()))
        .toList();

    await FireStoreUtils()
        .getOfferByVendorID(widget.vendorModel.id)
        .then((value) {
      setState(() {
        offerList = value;
      });
    });

    if (MyAppState.currentUser != null) {
      await FireStoreUtils.getFavouriteStore(FireStoreUtils.getCurrentUid())
          .then(
        (value) {
          setState(() {
            favouriteList = value;
          });
        },
      );

      await FireStoreUtils.getFavouriteItem().then(
        (value) {
          setState(() {
            favouriteItemList = value;
          });
        },
      );
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<FavouriteModel> favouriteList = [];
  PageController pageController = PageController();
  int currentPage = 0;

  void animateSlider() {
    if (widget.vendorModel.photos.isNotEmpty) {
      Timer.periodic(const Duration(seconds: 2), (Timer timer) {
        if (currentPage < widget.vendorModel.photos.length - 1) {
          currentPage++;
        } else {
          currentPage = 0;
        }

        if (pageController.hasClients) {
          pageController.animateToPage(
            currentPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeIn,
          );
        }
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          isDarkMode(context) ? AppThemeData.surfaceDark : AppThemeData.surface,
      body: isLoading == true
          ? loader()
          : NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverAppBar(
                    expandedHeight: Responsive.height(30, context),
                    floating: true,
                    pinned: true,
                    automaticallyImplyLeading: false,
                    backgroundColor: AppThemeData.primary300,
                    title: Row(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Icon(
                            Icons.arrow_back,
                            color: isDarkMode(context)
                                ? AppThemeData.grey50
                                : AppThemeData.grey50,
                          ),
                        ),
                        const Expanded(child: SizedBox()),
                        InkWell(
                          onTap: () async {
                            if (favouriteList
                                .where((p0) =>
                                    p0.store_id == widget.vendorModel.id)
                                .isNotEmpty) {
                              FavouriteModel favouriteModel = FavouriteModel(
                                  section_id: sectionConstantModel!.id,
                                  store_id: widget.vendorModel.id,
                                  user_id: MyAppState.currentUser!.userID);
                              favouriteList.removeWhere((item) =>
                                  item.store_id == widget.vendorModel.id);
                              await FireStoreUtils.removeFavouriteStore(
                                  favouriteModel);
                            } else {
                              FavouriteModel favouriteModel = FavouriteModel(
                                  section_id: sectionConstantModel!.id,
                                  store_id: widget.vendorModel.id,
                                  user_id: MyAppState.currentUser!.userID);
                              await FireStoreUtils.setFavouriteStore(
                                  favouriteModel);
                              favouriteList.add(favouriteModel);
                            }
                            setState(() {});
                          },
                          child: favouriteList
                                  .where((p0) =>
                                      p0.store_id == widget.vendorModel.id)
                                  .isNotEmpty
                              ? SvgPicture.asset(
                                  "assets/icons/ic_like_fill.svg",
                                  colorFilter: const ColorFilter.mode(
                                      AppThemeData.grey50, BlendMode.srcIn),
                                )
                              : SvgPicture.asset(
                                  "assets/icons/ic_like.svg",
                                ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                      ],
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        children: [
                          widget.vendorModel.photos.isEmpty
                              ? Stack(
                                  children: [
                                    NetworkImageWidget(
                                      imageUrl:
                                          widget.vendorModel.photo.toString(),
                                      fit: BoxFit.cover,
                                      width: Responsive.width(100, context),
                                      height: Responsive.height(40, context),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: const Alignment(0.00, -1.00),
                                          end: const Alignment(0, 1),
                                          colors: [
                                            Colors.black.withOpacity(0),
                                            Colors.black
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : PageView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  controller: pageController,
                                  scrollDirection: Axis.horizontal,
                                  itemCount: widget.vendorModel.photos.length,
                                  padEnds: false,
                                  pageSnapping: true,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    String image =
                                        widget.vendorModel.photos[index];
                                    return Stack(
                                      children: [
                                        NetworkImageWidget(
                                          imageUrl: image.toString(),
                                          fit: BoxFit.cover,
                                          width: Responsive.width(100, context),
                                          height:
                                              Responsive.height(40, context),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin:
                                                  const Alignment(0.00, -1.00),
                                              end: const Alignment(0, 1),
                                              colors: [
                                                Colors.black.withOpacity(0),
                                                Colors.black
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                          Positioned(
                            bottom: 10,
                            right: 0,
                            left: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: List.generate(
                                widget.vendorModel.photos.length,
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
                                          : AppThemeData.grey300,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.vendorModel.title.toString(),
                                        textAlign: TextAlign.start,
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: 22,
                                          overflow: TextOverflow.ellipsis,
                                          fontFamily: AppThemeData.semiBold,
                                          color: isDarkMode(context)
                                              ? AppThemeData.grey50
                                              : AppThemeData.grey900,
                                        ),
                                      ),
                                      SizedBox(
                                        width: Responsive.width(78, context),
                                        child: Text(
                                          widget.vendorModel.location
                                              .toString(),
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                            fontFamily: AppThemeData.medium,
                                            fontWeight: FontWeight.w500,
                                            color: isDarkMode(context)
                                                ? AppThemeData.grey400
                                                : AppThemeData.grey400,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Container(
                                      decoration: ShapeDecoration(
                                        color: isDarkMode(context)
                                            ? AppThemeData.primary600
                                            : AppThemeData.primary50,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(120)),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 4),
                                        child: Row(
                                          children: [
                                            SvgPicture.asset(
                                              "assets/icons/ic_star.svg",
                                              colorFilter: ColorFilter.mode(
                                                  AppThemeData.primary300,
                                                  BlendMode.srcIn),
                                            ),
                                            const SizedBox(
                                              width: 5,
                                            ),
                                            Text(
                                              calculateReview(
                                                  reviewCount: widget
                                                      .vendorModel.reviewsCount
                                                      .toStringAsFixed(0),
                                                  reviewSum: widget
                                                      .vendorModel.reviewsSum
                                                      .toString()),
                                              style: TextStyle(
                                                color: isDarkMode(context)
                                                    ? AppThemeData.primary300
                                                    : AppThemeData.primary300,
                                                fontFamily:
                                                    AppThemeData.semiBold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    InkWell(
                                      onTap: () {
                                        push(
                                            context,
                                            ReviewListScreen(
                                              vendorId: widget.vendorModel.id,
                                            ));
                                      },
                                      child: Text(
                                        'ratingsCount'.tr(args: [widget.vendorModel.reviewsCount.toString()]),
                                        style: TextStyle(
                                          decoration: TextDecoration.underline,
                                          color: isDarkMode(context)
                                              ? AppThemeData.grey200
                                              : AppThemeData.grey700,
                                          fontFamily: AppThemeData.regular,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            sectionConstantModel!.serviceTypeFlag ==
                                    "ecommerce-service"
                                ? SizedBox()
                                : Row(
                                    children: [
                                      Text(
                                        isOpen ? "Open".tr() : "Close".tr(),
                                        textAlign: TextAlign.start,
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: 14,
                                          overflow: TextOverflow.ellipsis,
                                          fontFamily: AppThemeData.semiBold,
                                          color: isOpen
                                              ? AppThemeData.success400
                                              : AppThemeData.danger300,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        child: Icon(
                                          Icons.circle,
                                          size: 5,
                                          color: isDarkMode(context)
                                              ? AppThemeData.grey400
                                              : AppThemeData.grey500,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          if (widget.vendorModel.workingHours
                                              .isEmpty) {
                                            ShowToastDialog.showToast(
                                                "Timing is not added by restaurant");
                                          } else {
                                            timeShowBottomSheet(context);
                                          }
                                        },
                                        child: Text(
                                          "View Timings".tr(),
                                          textAlign: TextAlign.start,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontSize: 14,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor:
                                                AppThemeData.secondary300,
                                            overflow: TextOverflow.ellipsis,
                                            fontFamily: AppThemeData.semiBold,
                                            color: isDarkMode(context)
                                                ? AppThemeData.secondary300
                                                : AppThemeData.secondary300,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                            offerList.isEmpty
                                ? const SizedBox()
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(
                                        height: 20,
                                      ),
                                      Text(
                                        "Additional Offers".tr(),
                                        textAlign: TextAlign.start,
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: 16,
                                          overflow: TextOverflow.ellipsis,
                                          fontFamily: AppThemeData.semiBold,
                                          color: isDarkMode(context)
                                              ? AppThemeData.grey50
                                              : AppThemeData.grey900,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      CouponListView(offerList: offerList),
                                    ],
                                  ),
                            const SizedBox(
                              height: 20,
                            ),
                            Text(
                              "Menu".tr(),
                              textAlign: TextAlign.start,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 16,
                                overflow: TextOverflow.ellipsis,
                                fontFamily: AppThemeData.semiBold,
                                color: isDarkMode(context)
                                    ? AppThemeData.grey50
                                    : AppThemeData.grey900,
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            TextFieldWidget(
                              controller: null,
                              hintText:
                                  'Search the dish, food, meals and more...'.tr(),
                              onchange: (value) {
                                searchProduct(value);
                              },
                              prefix: Padding(
                                padding: const EdgeInsets.all(12),
                                child: SvgPicture.asset(
                                    "assets/icons/ic_search.svg"),
                              ),
                            ),
                            sectionConstantModel!.isProductDetails == false
                                ? SizedBox()
                                : Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          if (isVag == true) {
                                            isVag = false;
                                          } else {
                                            isVag = true;
                                          }
                                          filterRecord();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          decoration: isVag
                                              ? ShapeDecoration(
                                                  color: isDarkMode(context)
                                                      ? AppThemeData.primary600
                                                      : AppThemeData.primary300
                                                          .withOpacity(0.20),
                                                  shape: RoundedRectangleBorder(
                                                    side: BorderSide(
                                                        width: 1,
                                                        color: AppThemeData
                                                            .primary300),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            120),
                                                  ),
                                                )
                                              : ShapeDecoration(
                                                  color: isDarkMode(context)
                                                      ? AppThemeData.grey800
                                                      : AppThemeData.grey100,
                                                  shape: RoundedRectangleBorder(
                                                    side: BorderSide(
                                                        width: 1,
                                                        color:
                                                            isDarkMode(context)
                                                                ? AppThemeData
                                                                    .grey700
                                                                : AppThemeData
                                                                    .grey200),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            120),
                                                  ),
                                                ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              SvgPicture.asset(
                                                "assets/icons/ic_veg.svg",
                                                height: 20,
                                                width: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Veg'.tr(),
                                                style: TextStyle(
                                                  color: isDarkMode(context)
                                                      ? AppThemeData.grey100
                                                      : AppThemeData.grey800,
                                                  fontFamily:
                                                      AppThemeData.semiBold,
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
                                          if (isNonVag == true) {
                                            isNonVag = false;
                                          } else {
                                            isNonVag = true;
                                          }
                                          filterRecord();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          decoration: isNonVag
                                              ? ShapeDecoration(
                                                  color: isDarkMode(context)
                                                      ? AppThemeData.primary600
                                                      : AppThemeData.primary300
                                                          .withOpacity(0.20),
                                                  shape: RoundedRectangleBorder(
                                                    side: BorderSide(
                                                        width: 1,
                                                        color: AppThemeData
                                                            .primary300),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            120),
                                                  ),
                                                )
                                              : ShapeDecoration(
                                                  color: isDarkMode(context)
                                                      ? AppThemeData.grey800
                                                      : AppThemeData.grey100,
                                                  shape: RoundedRectangleBorder(
                                                    side: BorderSide(
                                                        width: 1,
                                                        color:
                                                            isDarkMode(context)
                                                                ? AppThemeData
                                                                    .grey700
                                                                : AppThemeData
                                                                    .grey200),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            120),
                                                  ),
                                                ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              SvgPicture.asset(
                                                "assets/icons/ic_nonveg.svg",
                                                height: 20,
                                                width: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Non Veg'.tr(),
                                                style: TextStyle(
                                                  color: isDarkMode(context)
                                                      ? AppThemeData.grey100
                                                      : AppThemeData.grey800,
                                                  fontFamily:
                                                      AppThemeData.semiBold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      productListView(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  bool isVag = false;
  bool isNonVag = false;

  filterRecord() {
    if (isVag == true && isNonVag == true) {
      productList = allProductList
          .where((p0) => p0.nonveg == true || p0.nonveg == false)
          .toList();
    } else if (isVag == true && isNonVag == false) {
      productList = allProductList.where((p0) => p0.nonveg == false).toList();
    } else if (isVag == false && isNonVag == true) {
      productList = allProductList.where((p0) => p0.nonveg == true).toList();
    } else if (isVag == false && isNonVag == false) {
      productList = allProductList
          .where((p0) => p0.nonveg == true || p0.nonveg == false)
          .toList();
    }
    setState(() {});
  }

  searchProduct(String name) {
    if (name.isEmpty) {
      productList.clear();
      productList.addAll(allProductList);
    } else {
      isVag = false;
      isNonVag = false;
      productList = allProductList
          .where((p0) => p0.name.toLowerCase().contains(name.toLowerCase()))
          .toList();
    }
    setState(() {});
  }

  bool isOpen = false;

  statusCheck() {
    final now = DateTime.now();
    var day = DateFormat('EEEE', 'en_US').format(now);
    var date = DateFormat('dd-MM-yyyy').format(now);
    for (var element in widget.vendorModel.workingHours ?? []) {
      if (day == element.day.toString()) {
        if (element.timeslot!.isNotEmpty) {
          for (var element in element.timeslot!) {
            var start =
                DateFormat("dd-MM-yyyy HH:mm").parse("$date ${element.from}");
            var end =
                DateFormat("dd-MM-yyyy HH:mm").parse("$date ${element.to}");
            if (isCurrentDateInRange(start, end)) {
              setState(() {
                isOpen = true;
              });
            }
          }
        }
      }
    }
  }

  timeShowBottomSheet(BuildContext context) {
    return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(30),
          ),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        builder: (context) => FractionallySizedBox(
              heightFactor: 0.70,
              child: StatefulBuilder(builder: (context1, setState) {
                return Scaffold(
                  backgroundColor: isDarkMode(context)
                      ? AppThemeData.surfaceDark
                      : AppThemeData.surface,
                  body: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Center(
                            child: Container(
                              width: 134,
                              height: 5,
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: ShapeDecoration(
                                color: isDarkMode(context)
                                    ? AppThemeData.grey50
                                    : AppThemeData.grey800,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            itemCount: widget.vendorModel.workingHours.length,
                            itemBuilder: (context, dayIndex) {
                              WorkingHoursModel workingHours =
                                  widget.vendorModel.workingHours[dayIndex];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      workingHours.day.toString().tr(),
                                      textAlign: TextAlign.start,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: 16,
                                        overflow: TextOverflow.ellipsis,
                                        fontFamily: AppThemeData.semiBold,
                                        color: isDarkMode(context)
                                            ? AppThemeData.grey50
                                            : AppThemeData.grey900,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    workingHours.timeslot == null ||
                                            workingHours.timeslot!.isEmpty
                                        ? const SizedBox()
                                        : ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount:
                                                workingHours.timeslot!.length,
                                            itemBuilder: (context, timeIndex) {
                                              Timeslot timeSlotModel =
                                                  workingHours
                                                      .timeslot![timeIndex];
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 10),
                                                        decoration: BoxDecoration(
                                                            borderRadius:
                                                                const BorderRadius
                                                                    .all(Radius
                                                                        .circular(
                                                                            12)),
                                                            border: Border.all(
                                                                color: isDarkMode(
                                                                        context)
                                                                    ? AppThemeData
                                                                        .grey400
                                                                    : AppThemeData
                                                                        .grey200)),
                                                        child: Center(
                                                          child: Text(
                                                            timeSlotModel.from
                                                                .toString(),
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  AppThemeData
                                                                      .medium,
                                                              fontSize: 14,
                                                              color: isDarkMode(
                                                                      context)
                                                                  ? AppThemeData
                                                                      .grey400
                                                                  : AppThemeData
                                                                      .grey500,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width: 10,
                                                    ),
                                                    Expanded(
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 10),
                                                        decoration: BoxDecoration(
                                                            borderRadius:
                                                                const BorderRadius
                                                                    .all(Radius
                                                                        .circular(
                                                                            12)),
                                                            border: Border.all(
                                                                color: isDarkMode(
                                                                        context)
                                                                    ? AppThemeData
                                                                        .grey400
                                                                    : AppThemeData
                                                                        .grey200)),
                                                        child: Center(
                                                          child: Text(
                                                            timeSlotModel.to
                                                                .toString(),
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  AppThemeData
                                                                      .medium,
                                                              fontSize: 14,
                                                              color: isDarkMode(
                                                                      context)
                                                                  ? AppThemeData
                                                                      .grey400
                                                                  : AppThemeData
                                                                      .grey500,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ));
  }

  bool isCurrentDateInRange(DateTime startDate, DateTime endDate) {
    print(startDate);
    print(endDate);
    final currentDate = DateTime.now();
    print(currentDate);
    return currentDate.isAfter(startDate) && currentDate.isBefore(endDate);
  }

  productListView() {
    return Container(
      color: isDarkMode(context) ? AppThemeData.grey900 : AppThemeData.grey50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: vendorCategoryList.length,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          VendorCategoryModel vendorCategoryModel = vendorCategoryList[index];
          return ExpansionTile(
            childrenPadding: EdgeInsets.zero,
            tilePadding: EdgeInsets.zero,
            shape: const Border(),
            initiallyExpanded: true,
            title: Text(
              "${vendorCategoryModel.title.toString()} (${productList.where((p0) => p0.categoryID == vendorCategoryModel.id).toList().length})",
              style: TextStyle(
                fontSize: 18,
                fontFamily: AppThemeData.semiBold,
                color: isDarkMode(context)
                    ? AppThemeData.grey50
                    : AppThemeData.grey900,
              ),
            ),
            children: [
              ListView.builder(
                itemCount: productList
                    .where((p0) => p0.categoryID == vendorCategoryModel.id)
                    .toList()
                    .length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  ProductModel productModel = productList
                      .where((p0) => p0.categoryID == vendorCategoryModel.id)
                      .toList()[index];

                  String price = "0.0";
                  String disPrice = "0.0";
                  List<String> selectedVariants = [];
                  List<String> selectedIndexVariants = [];
                  List<String> selectedIndexArray = [];
                  if (productModel.itemAttributes != null) {
                    if (productModel.itemAttributes!.attributes!.isNotEmpty) {
                      for (var element
                          in productModel.itemAttributes!.attributes!) {
                        if (element.attributeOptions!.isNotEmpty) {
                          selectedVariants.add(productModel
                              .itemAttributes!
                              .attributes![productModel
                                  .itemAttributes!.attributes!
                                  .indexOf(element)]
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
                        .where((element) =>
                            element.variant_sku == selectedVariants.join('-'))
                        .isNotEmpty) {
                      price = productCommissionPrice(
                          widget.vendorModel.adminCommission,
                          productModel.itemAttributes!.variants!
                                  .where((element) =>
                                      element.variant_sku ==
                                      selectedVariants.join('-'))
                                  .first
                                  .variant_price ??
                              '0');
                      disPrice = "0";
                    }
                  } else {
                    price = productCommissionPrice(
                        widget.vendorModel.adminCommission,
                        productModel.price.toString());
                    disPrice =
                        double.parse(productModel.disPrice.toString()) <= 0
                            ? "0"
                            : productCommissionPrice(
                                widget.vendorModel.adminCommission,
                                productModel.disPrice.toString());
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              sectionConstantModel!.isProductDetails == false
                                  ? SizedBox()
                                  : Row(
                                      children: [
                                        productModel.nonveg == true
                                            ? SvgPicture.asset(
                                                "assets/icons/ic_nonveg.svg")
                                            : SvgPicture.asset(
                                                "assets/icons/ic_veg.svg"),
                                        const SizedBox(
                                          width: 5,
                                        ),
                                        Text(
                                          productModel.nonveg == true
                                              ? "Non Veg.".tr()
                                              : "Pure veg.".tr(),
                                          style: TextStyle(
                                            color: productModel.nonveg == true
                                                ? AppThemeData.danger300
                                                : AppThemeData.success400,
                                            fontFamily: AppThemeData.semiBold,
                                          ),
                                        ),
                                      ],
                                    ),
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                productModel.name.toString(),
                                style: TextStyle(
                                  fontSize: 18,
                                  color: isDarkMode(context)
                                      ? AppThemeData.grey50
                                      : AppThemeData.grey900,
                                  fontFamily: AppThemeData.semiBold,
                                ),
                              ),
                              disPrice == "" || disPrice == "0"
                                  ? Text(
                                      amountShow(amount: price),
                                      style: TextStyle(
                                          fontSize: 16,
                                          letterSpacing: 0.5,
                                          color: AppThemeData.primary300),
                                    )
                                  : Row(
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
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                              decoration:
                                                  TextDecoration.lineThrough),
                                        ),
                                      ],
                                    ),
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    "assets/icons/ic_star.svg",
                                    colorFilter: const ColorFilter.mode(
                                        AppThemeData.warning300,
                                        BlendMode.srcIn),
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  Text(
                                    "${calculateReview(reviewCount: productModel.reviewsCount.toStringAsFixed(0), reviewSum: productModel.reviewsSum.toString())} (${productModel.reviewsCount.toStringAsFixed(0)})",
                                    style: TextStyle(
                                      color: isDarkMode(context)
                                          ? AppThemeData.grey50
                                          : AppThemeData.grey900,
                                      fontFamily: AppThemeData.regular,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                "${productModel.description}",
                                maxLines: 2,
                                style: TextStyle(
                                  overflow: TextOverflow.ellipsis,
                                  color: isDarkMode(context)
                                      ? AppThemeData.grey50
                                      : AppThemeData.grey900,
                                  fontFamily: AppThemeData.regular,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(16)),
                          child: Stack(
                            children: [
                              NetworkImageWidget(
                                imageUrl: productModel.photo.toString(),
                                fit: BoxFit.cover,
                                height: Responsive.height(16, context),
                                width: Responsive.width(34, context),
                              ),
                              Container(
                                height: Responsive.height(16, context),
                                width: Responsive.width(34, context),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: const Alignment(-0.00, -1.00),
                                    end: const Alignment(0, 1),
                                    colors: [
                                      Colors.black.withOpacity(0),
                                      const Color(0xFF111827)
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 10,
                                top: 10,
                                child: InkWell(
                                  onTap: () async {
                                    if (favouriteItemList
                                        .where((p0) =>
                                            p0.product_id == productModel.id)
                                        .isNotEmpty) {
                                      FavouriteItemModel favouriteModel =
                                          FavouriteItemModel(
                                              product_id: productModel.id,
                                              store_id: widget.vendorModel.id,
                                              user_id: FireStoreUtils
                                                  .getCurrentUid(),
                                              section_id:
                                                  sectionConstantModel!.id);
                                      favouriteItemList.removeWhere((item) =>
                                          item.product_id == productModel.id);
                                      await FireStoreUtils.removeFavouriteItem(
                                          favouriteModel);
                                    } else {
                                      FavouriteItemModel favouriteModel =
                                          FavouriteItemModel(
                                              product_id: productModel.id,
                                              store_id: widget.vendorModel.id,
                                              user_id: FireStoreUtils
                                                  .getCurrentUid(),
                                              section_id:
                                                  sectionConstantModel!.id);
                                      favouriteItemList.add(favouriteModel);

                                      await FireStoreUtils.setFavouriteItem(
                                          favouriteModel);
                                    }
                                    setState(() {});
                                  },
                                  child: favouriteItemList
                                          .where((p0) =>
                                              p0.product_id == productModel.id)
                                          .isNotEmpty
                                      ? SvgPicture.asset(
                                          "assets/icons/ic_like_fill.svg",
                                        )
                                      : SvgPicture.asset(
                                          "assets/icons/ic_like.svg",
                                        ),
                                ),
                              ),
                              sectionConstantModel!.serviceTypeFlag ==
                                      "ecommerce-service"
                                  ? Positioned(
                                      bottom: 10,
                                      left: 20,
                                      right: 20,
                                      child: RoundedButtonFill(
                                        title: "Add".tr(),
                                        width: 10,
                                        height: 4,
                                        color: isDarkMode(context)
                                            ? AppThemeData.grey900
                                            : AppThemeData.grey50,
                                        textColor: AppThemeData.primary300,
                                        onPress: () async {
                                          await Navigator.of(context)
                                              .push(MaterialPageRoute(
                                                  builder: (context) =>
                                                      ProductDetailsScreen(
                                                          productModel:
                                                              productModel,
                                                          vendorModel: widget
                                                              .vendorModel)))
                                              .whenComplete(() {
                                            setState(() {});
                                          });
                                        },
                                      ),
                                    )
                                  : isOpen == false ||
                                          MyAppState.currentUser == null
                                      ? const SizedBox()
                                      : Positioned(
                                          bottom: 10,
                                          left: 20,
                                          right: 20,
                                          child: RoundedButtonFill(
                                            title: "Add".tr(),
                                            width: 10,
                                            height: 4,
                                            color: isDarkMode(context)
                                                ? AppThemeData.grey900
                                                : AppThemeData.grey50,
                                            textColor: AppThemeData.primary300,
                                            onPress: () async {
                                              await Navigator.of(context)
                                                  .push(MaterialPageRoute(
                                                      builder: (context) =>
                                                          ProductDetailsScreen(
                                                              productModel:
                                                                  productModel,
                                                              vendorModel: widget
                                                                  .vendorModel)))
                                                  .whenComplete(() {
                                                setState(() {});
                                              });
                                            },
                                          ),
                                        )
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              )
            ],
          );
        },
      ),
    );
  }
}

class CouponListView extends StatelessWidget {
  final List<OfferModel> offerList;

  const CouponListView({super.key, required this.offerList});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Responsive.height(9, context),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: offerList.length,
        itemBuilder: (BuildContext context, int index) {
          OfferModel offerModel = offerList[index];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: ShapeDecoration(
                color: isDarkMode(context)
                    ? AppThemeData.grey900
                    : AppThemeData.grey50,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                      width: 1,
                      color: isDarkMode(context)
                          ? AppThemeData.grey800
                          : AppThemeData.grey100),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: SizedBox(
                  width: Responsive.width(80, context),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        decoration: const BoxDecoration(
                            image: DecorationImage(
                                image:
                                    AssetImage("assets/images/offer_gif.gif"),
                                fit: BoxFit.fill)),
                        child: Center(
                            child: Text(
                          offerModel.discountTypeOffer == "Fix Price"
                              ? amountShow(amount: offerModel.discountOffer)
                              : "${offerModel.discountOffer}%",
                          style: TextStyle(
                              color: isDarkMode(context)
                                  ? AppThemeData.grey50
                                  : AppThemeData.grey50,
                              fontFamily: AppThemeData.semiBold,
                              fontSize: 12),
                        )),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offerModel.descriptionOffer.toString(),
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode(context)
                                  ? AppThemeData.grey50
                                  : AppThemeData.grey900,
                              fontFamily: AppThemeData.semiBold,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(
                                      text: offerModel.offerCode.toString()))
                                  .then(
                                (value) {
                                  ShowToastDialog.showToast("Copied".tr());
                                },
                              );
                            },
                            child: Row(
                              children: [
                                Text(
                                  offerModel.offerCode.toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode(context)
                                        ? AppThemeData.grey400
                                        : AppThemeData.grey500,
                                    fontFamily: AppThemeData.semiBold,
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                SvgPicture.asset("assets/icons/ic_copy.svg"),
                                const SizedBox(
                                    height: 10, child: VerticalDivider()),
                                const SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  timestampToDateTime(
                                      offerModel.expireOfferDate!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode(context)
                                        ? AppThemeData.grey400
                                        : AppThemeData.grey500,
                                    fontFamily: AppThemeData.semiBold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
