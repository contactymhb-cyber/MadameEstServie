import 'package:easy_localization/easy_localization.dart';
import 'package:emartconsumer/constants.dart';
import 'package:emartconsumer/main.dart';
import 'package:emartconsumer/model/BannerModel.dart';
import 'package:emartconsumer/model/ParcelCategory.dart';
import 'package:emartconsumer/model/User.dart';
import 'package:emartconsumer/parcel_delivery/parcel_ui/book_parcel_screen.dart';
import 'package:emartconsumer/services/FirebaseHelper.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/theme/app_them_data.dart';
import 'package:emartconsumer/ui/auth_screen/login_screen.dart';
import 'package:emartconsumer/utils/network_image_widget.dart';

import 'package:flutter/material.dart';

class ParcelHomeScreen extends StatefulWidget {
  final User? user;

  const ParcelHomeScreen({Key? key, this.user}) : super(key: key);

  @override
  State<ParcelHomeScreen> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<ParcelHomeScreen> {
  List<ParcelCategory> parcelCategory = [];
  bool isLoading = true;
  List<BannerModel> bannerTopHome = [];

  @override
  void initState() {
    getParcelCategory();
    // TODO: implement initState
    super.initState();
  }

  getParcelCategory() async {
    await FireStoreUtils().getHomeTopBanner().then((value) {
      setState(() {
        bannerTopHome = value;
      });
    });

    await FireStoreUtils().getParcelServiceCategory().then((value) {
      if (value != null) {
        setState(() {
          parcelCategory = value;
          isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode(context) ? AppThemeData.surfaceDark : AppThemeData.surface,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ParcelBannerView(bannerList: bannerTopHome),
              SizedBox(
                height: 20,
              ),
              Text(
                "What are you sending?".tr(),
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontFamily: AppThemeData.medium,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900,
                ),
              ),
              SizedBox(
                height: 10,
              ),
              isLoading
                  ? loader()
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Container(
                        decoration: ShapeDecoration(
                          color: isDarkMode(context) ? AppThemeData.grey900 : AppThemeData.grey50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                          child: ListView.separated(
                            itemCount: parcelCategory.length,
                            shrinkWrap: true,
                            physics: const ScrollPhysics(),
                            itemBuilder: (context, index) {
                              return buildItems(item: parcelCategory[index]);
                            },
                            separatorBuilder: (BuildContext context, int index) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 60, bottom: 10),
                                child: Divider(),
                              );
                            },
                          ),
                        ),
                      ),
                    )
            ],
          ),
        ),
      ),
    );
  }

  buildItems({required ParcelCategory item}) {
    return InkWell(
      splashColor: AppThemeData.primary300.withOpacity(0.5),
      onTap: () {
        if (MyAppState.currentUser != null) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => BookParcelScreen(
                        parcelCategory: item,
                      )));
        } else {
          push(context, const LoginScreen());
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          NetworkImageWidget(
            imageUrl: item.image.toString(),
            height: 38,
            width: 38,
          ),
          SizedBox(
            width: 20,
          ),
          Expanded(
            child: Text(
              "${item.title.toString()}".tr(),
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
    );
  }
}

class ParcelBannerView extends StatefulWidget {
  final List<BannerModel> bannerList;

  const ParcelBannerView({super.key, required this.bannerList});

  @override
  State<ParcelBannerView> createState() => _BannerViewState();
}

class _BannerViewState extends State<ParcelBannerView> {
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
