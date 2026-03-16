// ignore_for_file: unused_local_variable

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emartconsumer/cab_service/cab_intercity_service_screen.dart';
import 'package:emartconsumer/cab_service/cab_service_screen.dart';
import 'package:emartconsumer/constants.dart';
import 'package:emartconsumer/model/BannerModel.dart';
import 'package:emartconsumer/model/User.dart';
import 'package:emartconsumer/services/FirebaseHelper.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/theme/app_them_data.dart';
import 'package:emartconsumer/utils/network_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:location/location.dart';

class CabHomeScreen extends StatefulWidget {
  final User? user;

  const CabHomeScreen({Key? key, this.user}) : super(key: key);

  @override
  State<CabHomeScreen> createState() => _CabHomeScreenState();
}

class _CabHomeScreenState extends State<CabHomeScreen> {

  @override
  void initState() {
    getBanner();
    super.initState();
  }

  List<BannerModel> bannerTopHome = [];
  bool isHomeBannerLoading = true;

  getBanner() async {
    try {
      LocationData location = await Location().getLocation();
    } catch (e) {
      throw Exception(e);
    }

    await FireStoreUtils().getHomeTopBanner().then((value) {
      setState(() {
        bannerTopHome = value;
        isHomeBannerLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: isDarkMode(context) ? AppThemeData.surfaceDark : AppThemeData.surface,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CabBannerView(bannerList: bannerTopHome),
              SizedBox(height: 20,),
              Text(
                "Where are you going for?".tr(),
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontFamily: AppThemeData.bold,
                  fontSize: 16,
                  color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900,
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                decoration: ShapeDecoration(
                  color: isDarkMode(context) ? AppThemeData.grey900 : AppThemeData.grey50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    children: [
                      InkWell(
                        splashColor: AppThemeData.primary300.withOpacity(0.5),
                        onTap: () {
                          push(context, const CabServiceScreen());
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SvgPicture.asset("assets/icons/ic_ride.svg"),
                            SizedBox(
                              width: 20,
                            ),
                            Expanded(
                              child: Text(
                                "Ride".tr(),
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontFamily: AppThemeData.medium,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: isDarkMode(context) ? AppThemeData.grey500 : AppThemeData.grey400,
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 50, top: 10, bottom: 10),
                        child: Divider(
                          thickness: 1,
                        ),
                      ),
                      InkWell(
                        splashColor: AppThemeData.primary300.withOpacity(0.5),
                        onTap: () {
                          push(context, const CabInterCityServiceScreen());
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SvgPicture.asset("assets/icons/ic_intercity.svg"),
                            SizedBox(
                              width: 20,
                            ),
                            Expanded(
                              child: Text(
                                "Intercity/outstation".tr(),
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontFamily: AppThemeData.medium,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: isDarkMode(context) ? AppThemeData.grey500 : AppThemeData.grey400,
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Widget buildBestDealPage(BannerModel categoriesModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        child: CachedNetworkImage(
          imageUrl: getImageVAlidUrl(categoriesModel.photo.toString()),
          imageBuilder: (context, imageProvider) => Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
            ),
          ),
          color: Colors.black.withOpacity(0.5),
          placeholder: (context, url) => Center(
              child: CircularProgressIndicator.adaptive(
            valueColor: AlwaysStoppedAnimation(AppThemeData.primary300),
          )),
          errorWidget: (context, url, error) => ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                placeholderImage,
                fit: BoxFit.cover,
              )),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class CabBannerView extends StatefulWidget {
  final List<BannerModel> bannerList;

  const CabBannerView({super.key, required this.bannerList});

  @override
  State<CabBannerView> createState() => _BannerViewState();
}

class _BannerViewState extends State<CabBannerView> {
  PageController pageController = PageController(viewportFraction: 0.877);
  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return widget.bannerList.isEmpty
        ? SizedBox()
        : SizedBox(
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
                  onTap: () async {},
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
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
          );
  }
}
