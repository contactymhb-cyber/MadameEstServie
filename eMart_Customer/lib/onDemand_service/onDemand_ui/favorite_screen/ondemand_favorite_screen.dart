import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/src/public_ext.dart';
import 'package:emartconsumer/constants.dart';
import 'package:emartconsumer/main.dart';
import 'package:emartconsumer/model/favorite_ondemand_service_model.dart';
import 'package:emartconsumer/onDemand_service/onDemand_model/provider_serivce_model.dart';
import 'package:emartconsumer/onDemand_service/onDemand_ui/ondemand_details_screen/ondemand_details_screen.dart';
import 'package:emartconsumer/services/FirebaseHelper.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/theme/app_them_data.dart';
import 'package:emartconsumer/ui/auth_screen/login_screen.dart';
import 'package:flutter/material.dart';

class OndemandFavouriteServiceScreen extends StatefulWidget {
  const OndemandFavouriteServiceScreen({Key? key}) : super(key: key);

  @override
  _OndemandFavouriteServiceScreenState createState() =>
      _OndemandFavouriteServiceScreenState();
}

class _OndemandFavouriteServiceScreenState
    extends State<OndemandFavouriteServiceScreen> {
  final fireStoreUtils = FireStoreUtils();
  List<FavouriteOndemandServiceModel> lstFavourite = [];
  bool showLoader = true;

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: showLoader
            ? Center(
                child: CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation(AppThemeData.primary300),
                ),
              )
            : lstFavourite.isEmpty
                ? showEmptyState('No Favourite Service'.tr(), context)
                : ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.all(15),
                    scrollDirection: Axis.vertical,
                    physics: const BouncingScrollPhysics(),
                    itemCount: lstFavourite.length,
                    itemBuilder: (context, index) {
                      return FutureBuilder<List<ProviderServiceModel>>(
                          future: fireStoreUtils
                              .getCurrentProviderService(lstFavourite[index]),
                          builder: (context, snapshot) {
                            return snapshot.data != null
                                ? GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTap: () async {
                                      push(
                                          context,
                                          OnDemandDetailsScreen(
                                              providerModel:
                                                  snapshot.data![0]));
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5),
                                      child: Container(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.16,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: isDarkMode(context)
                                                  ? const Color(
                                                      DarkContainerBorderColor)
                                                  : Colors.grey.shade100,
                                              width: 1),
                                          color: isDarkMode(context)
                                              ? Color(DarkContainerColor)
                                              : Colors.white,
                                        ),
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.only(
                                                  bottomLeft:
                                                      Radius.circular(10),
                                                  topLeft: Radius.circular(10)),
                                              child: CachedNetworkImage(
                                                imageUrl: getImageVAlidUrl(
                                                    snapshot.data![0].photos
                                                            .isNotEmpty
                                                        ? snapshot
                                                            .data![0].photos[0]
                                                            .toString()
                                                        : ''),
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.16,
                                                // height: 100,
                                                width: 110,
                                                // memCacheHeight: 110,
                                                // memCacheWidth: 120,
                                                placeholder: (context, url) =>
                                                    Center(
                                                  child:
                                                      CircularProgressIndicator
                                                          .adaptive(
                                                    valueColor:
                                                        AlwaysStoppedAnimation(
                                                            AppThemeData
                                                                .primary300),
                                                  ),
                                                ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.only(
                                                          bottomLeft:
                                                              Radius.circular(
                                                                  10),
                                                          topLeft:
                                                              Radius.circular(
                                                                  10)),
                                                  child: Image.network(
                                                    placeholderImage,
                                                    fit: BoxFit.cover,
                                                    // cacheHeight: 100,
                                                    // cacheWidth: 100,
                                                  ),
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 10),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            snapshot
                                                                .data![0].title
                                                                .toString(),
                                                            maxLines: 1,
                                                            style: TextStyle(
                                                              fontSize: 18,
                                                              fontFamily:
                                                                  AppThemeData
                                                                      .regular,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              color: isDarkMode(
                                                                      context)
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black,
                                                            ),
                                                          ),
                                                        ),
                                                        GestureDetector(
                                                          onTap: () {
                                                            if (MyAppState
                                                                    .currentUser ==
                                                                null) {
                                                              push(context,
                                                                  const LoginScreen());
                                                            } else {
                                                              var contain = lstFavourite
                                                                  .where((element) =>
                                                                      element
                                                                          .service_id ==
                                                                      snapshot
                                                                          .data![
                                                                              0]
                                                                          .id);

                                                              if (contain
                                                                  .isNotEmpty) {
                                                                FavouriteOndemandServiceModel favouriteModel = FavouriteOndemandServiceModel(
                                                                    section_id: snapshot
                                                                        .data![
                                                                            0]
                                                                        .sectionId,
                                                                    service_id:
                                                                        snapshot
                                                                            .data![
                                                                                0]
                                                                            .id,
                                                                    user_id: MyAppState
                                                                        .currentUser!
                                                                        .userID,
                                                                    serviceAuthorId:
                                                                        snapshot
                                                                            .data![0]
                                                                            .author);
                                                                FireStoreUtils()
                                                                    .removeFavouriteOndemandService(
                                                                        favouriteModel);
                                                                lstFavourite.removeWhere((item) =>
                                                                    item.service_id ==
                                                                    snapshot
                                                                        .data![
                                                                            0]
                                                                        .id);
                                                              } else {
                                                                FavouriteOndemandServiceModel favouriteModel = FavouriteOndemandServiceModel(
                                                                    section_id: snapshot
                                                                        .data![
                                                                            0]
                                                                        .sectionId,
                                                                    service_id:
                                                                        snapshot
                                                                            .data![
                                                                                0]
                                                                            .id,
                                                                    user_id: MyAppState
                                                                        .currentUser!
                                                                        .userID,
                                                                    serviceAuthorId:
                                                                        snapshot
                                                                            .data![0]
                                                                            .author);
                                                                FireStoreUtils()
                                                                    .setFavouriteOndemandSection(
                                                                        favouriteModel);
                                                                lstFavourite.add(
                                                                    favouriteModel);
                                                              }
                                                            }
                                                            setState(() {});
                                                          },
                                                          child: lstFavourite
                                                                  .where((element) =>
                                                                      element
                                                                          .service_id ==
                                                                      snapshot
                                                                          .data![
                                                                              0]
                                                                          .id)
                                                                  .isNotEmpty
                                                              ? Icon(
                                                                  Icons
                                                                      .favorite,
                                                                  size: 24,
                                                                  color: AppThemeData
                                                                      .primary300,
                                                                )
                                                              : Icon(
                                                                  Icons
                                                                      .favorite_border,
                                                                  size: 24,
                                                                  color: isDarkMode(
                                                                          context)
                                                                      ? Colors
                                                                          .white38
                                                                      : Colors
                                                                          .black38,
                                                                ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(
                                                      height: 4,
                                                    ),
                                                    if (snapshot.data![0]
                                                            .categoryId !=
                                                        null)
                                                      FutureBuilder(
                                                          future: FireStoreUtils()
                                                              .getCategoryById(
                                                                  snapshot
                                                                      .data![0]
                                                                      .categoryId
                                                                      .toString()),
                                                          builder: (context,
                                                              AsyncSnapshot) {
                                                            if (AsyncSnapshot
                                                                        .connectionState ==
                                                                    ConnectionState
                                                                        .waiting ||
                                                                AsyncSnapshot
                                                                    .hasError ||
                                                                snapshot.data ==
                                                                    null) {
                                                              return SizedBox();
                                                            } else {
                                                              return AsyncSnapshot
                                                                          .data !=
                                                                      null
                                                                  ? Text(
                                                                      AsyncSnapshot
                                                                          .data!
                                                                          .title!
                                                                          .toString(),
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            14,
                                                                        fontFamily:
                                                                            AppThemeData.regular,
                                                                        fontWeight:
                                                                            FontWeight.w400,
                                                                        color: isDarkMode(context)
                                                                            ? Colors.white
                                                                            : Colors.black,
                                                                      ),
                                                                    )
                                                                  : Container();
                                                            }
                                                          }),

                                                    SizedBox(
                                                      height: 5,
                                                    ),
                                                    snapshot.data![0]
                                                                    .disPrice ==
                                                                "" ||
                                                            snapshot.data![0]
                                                                    .disPrice ==
                                                                "0"
                                                        ? Text(
                                                            snapshot.data![0]
                                                                        .priceUnit ==
                                                                    'Fixed'
                                                                ? amountShow(
                                                                    amount: snapshot
                                                                        .data![
                                                                            0]
                                                                        .price)
                                                                : '${amountShow(amount: snapshot.data![0].price ?? '0')}/hr',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontFamily:
                                                                  AppThemeData
                                                                      .regular,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: isDarkMode(
                                                                      context)
                                                                  ? Colors.white
                                                                  : AppThemeData
                                                                      .primary300,
                                                            ),
                                                          )
                                                        : Row(
                                                            children: [
                                                              Text(
                                                                snapshot.data![0].priceUnit ==
                                                                        'Fixed'
                                                                    ? amountShow(
                                                                        amount: snapshot.data![0].disPrice ??
                                                                            '0')
                                                                    : '${amountShow(amount: snapshot.data![0].disPrice)}/hr',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 14,
                                                                  fontFamily:
                                                                      AppThemeData
                                                                          .regular,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: isDarkMode(
                                                                          context)
                                                                      ? Colors
                                                                          .white
                                                                      : AppThemeData
                                                                          .primary300,
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        left:
                                                                            8.0),
                                                                child: Text(
                                                                  snapshot.data![0].priceUnit ==
                                                                          'Fixed'
                                                                      ? amountShow(
                                                                          amount: snapshot
                                                                              .data![0]
                                                                              .price)
                                                                      : '${amountShow(amount: snapshot.data![0].price)}/hr',
                                                                  style: const TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          14,
                                                                      color: Colors
                                                                          .grey,
                                                                      decoration:
                                                                          TextDecoration
                                                                              .lineThrough),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                    SizedBox(
                                                      height: 5,
                                                    ),
                                                    Container(
                                                      decoration: BoxDecoration(
                                                          color: AppThemeData
                                                              .warning400,
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          16))),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 10,
                                                                vertical: 5),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            const Icon(
                                                              Icons.star,
                                                              size: 16,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                            const SizedBox(
                                                                width: 3),
                                                            Text(
                                                              snapshot.data![0]
                                                                          .reviewsCount !=
                                                                      0
                                                                  ? ((snapshot.data![0].reviewsSum ??
                                                                              0.0) /
                                                                          (snapshot.data![0].reviewsCount ??
                                                                              0.0))
                                                                      .toStringAsFixed(
                                                                          1)
                                                                  : 0.toString(),
                                                              style:
                                                                  const TextStyle(
                                                                letterSpacing:
                                                                    0.5,
                                                                fontSize: 12,
                                                                fontFamily:
                                                                    AppThemeData
                                                                        .regular,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    // Container(
                                                    //   decoration: BoxDecoration(
                                                    //       borderRadius: BorderRadius.circular(36), color: timeCheck(providerList) == true ? Colors.green.withOpacity(0.40) : Colors.red.withOpacity(0.20)),
                                                    //   child: Padding(
                                                    //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                                    //     child: Text(
                                                    //       timeCheck(providerList) == true ? "Open" : "Close",
                                                    //       textAlign: TextAlign.center,
                                                    //       style: TextStyle(
                                                    //          fontFamily: AppThemeData.regular,
                                                    //         fontWeight: FontWeight.bold,
                                                    //         color: timeCheck(providerList) == true ? Colors.white : Colors.white,
                                                    //         fontSize: 14,
                                                    //       ),
                                                    //     ),
                                                    //   ),
                                                    // ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                : Container();
                          });
                    }));
  }

  Future<void> getData() async {
    lstFavourite.clear();
    List<FavouriteOndemandServiceModel> lstFavouriteService =
        await fireStoreUtils
            .getFavouritesServiceList(MyAppState.currentUser!.userID);

    List<String?> uniqueAuthId =
        lstFavouriteService.map((service) => service.serviceAuthorId).toList();
    List<String?> uniqueServiceId =
        lstFavouriteService.map((service) => service.service_id).toList();
    for (var service in uniqueServiceId) {
      log("lstFavourite :::: service :: ${service}");
    }
    List<ProviderServiceModel> filterByItemLimit = <ProviderServiceModel>[];
    List<String?> uniqueId = <String>[];

    if (isSubscriptionModelApplied == true ||
        sectionConstantModel?.adminCommision?.enable == true) {
      for (var authUser in uniqueAuthId) {
        List<ProviderServiceModel> listofAllServiceByAuth =
            await fireStoreUtils.getAllProviderServicebyAuthorId(authUser!);

        for (int i = 0; i < listofAllServiceByAuth.length; i++) {
          log('lstFavourite :::: ${listofAllServiceByAuth[i].id} :: ${listofAllServiceByAuth[i].subscriptionPlan?.itemLimit}}');
          if (i <
                  int.parse(
                      listofAllServiceByAuth[i].subscriptionPlan?.itemLimit ??
                          '0') ||
              listofAllServiceByAuth[i].subscriptionPlan?.itemLimit == '-1' ||
              listofAllServiceByAuth[i].subscriptionPlan?.itemLimit == null) {
            if (uniqueServiceId.contains(listofAllServiceByAuth[i].id)) {
              filterByItemLimit.add(listofAllServiceByAuth[i]);
            }
          }
        }
        // log('lstFavourite ::::  ::${filterByItemLimit.length} :: ${lstFavouriteService.length}');
      }

      for (var service in filterByItemLimit) {
        for (var fav in lstFavouriteService) {
          if (service.id == fav.service_id &&
              !uniqueId.contains(service.id) &&
              service.subscriptionTotalOrders != '0') {
            uniqueId.add(service.id);
            lstFavourite.add(fav);
          }
        }
      }
    } else {
      lstFavourite.addAll(lstFavouriteService);
    }

    setState(() {});
    showLoader = false;
  }
}
