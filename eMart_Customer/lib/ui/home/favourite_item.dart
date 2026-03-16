import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/src/public_ext.dart';
import 'package:emartconsumer/main.dart';
import 'package:emartconsumer/model/FavouriteItemModel.dart';
import 'package:emartconsumer/model/ProductModel.dart';
import 'package:emartconsumer/model/VendorModel.dart';
import 'package:emartconsumer/services/FirebaseHelper.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/theme/app_them_data.dart';
import 'package:emartconsumer/ui/productDetailsScreen/ProductDetailsScreen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../constants.dart';

class FavouriteItemScreen extends StatefulWidget {
  const FavouriteItemScreen({Key? key}) : super(key: key);

  @override
  _FavouriteItemScreenState createState() => _FavouriteItemScreenState();
}

class _FavouriteItemScreenState extends State<FavouriteItemScreen> {
  final fireStoreUtils = FireStoreUtils();
  List<FavouriteItemModel> lstFavourite = [];
  List<ProductModel> favProductList = [];
  var position = const LatLng(23.12, 70.22);
  bool showLoader = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: isDarkMode(context) ? AppThemeData.surfaceDark : AppThemeData.surface,
        body: showLoader
            ? Center(
                child: CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation(AppThemeData.primary300),
                ),
              )
            : favProductList.isEmpty
                ? showEmptyState('No Favourite Item'.tr(), context)
                : ListView.builder(
                    shrinkWrap: true,
                    scrollDirection: Axis.vertical,
                    physics: const BouncingScrollPhysics(),
                    itemCount: favProductList.length,
                    itemBuilder: (context, index) {
                      ProductModel? productModel = favProductList[index];

                      return productModel.id.isEmpty
                          ? Container()
                          : Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: buildAllStoreData(productModel, index),
                            );
                    }));
  }

  Widget buildAllStoreData(ProductModel productModel, int index) {
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
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () async {
                  VendorModel? vendorModel = await FireStoreUtils.getVendor(productModel.vendorID);
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                  ),
                  child: Row(
                    // crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      CachedNetworkImage(
                          height: MediaQuery.of(context).size.height * 0.075,
                          width: MediaQuery.of(context).size.width * 0.16,
                          imageUrl: getImageVAlidUrl(productModel.photo),
                          imageBuilder: (context, imageProvider) => Container(
                                // width: 100,
                                // height: 100,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    image: DecorationImage(
                                      image: imageProvider,
                                      fit: BoxFit.cover,
                                    )),
                              ),
                          errorWidget: (context, url, error) => ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: Image.network(
                                placeholderImage,
                                fit: BoxFit.cover,
                              ))),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(productModel.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff272727),
                                      // Color(0xff272727)
                                    )),
                                const SizedBox(height: 3),
                                disPrice == "" || disPrice == "0" || disPrice == "0.0"
                                    ? Text(
                                        amountShow(amount: price),
                                        style: TextStyle(fontSize: 16, letterSpacing: 0.5, color: AppThemeData.primary300),
                                      )
                                    : Row(
                                        children: [
                                          Text(
                                            "${amountShow(amount: disPrice.toString())}",
                                            // "$symbol${double.parse(productModel.disPrice.toString()).toStringAsFixed(decimal)}",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppThemeData.primary300,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          Text(
                                            amountShow(amount: price),
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, decoration: TextDecoration.lineThrough),
                                          ),
                                        ],
                                      ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            }
          }
        });
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

    VendorModel? vendorModel = await FireStoreUtils.getVendor(productModel.vendorID.toString());
    if (productModel.itemAttributes != null) {
      if (productModel.itemAttributes!.attributes!.isNotEmpty) {
        for (var element in productModel.itemAttributes!.attributes!) {
          if (element.attributeOptions!.isNotEmpty) {
            selectedVariants.add(productModel.itemAttributes!.attributes![productModel.itemAttributes!.attributes!.indexOf(element)].attributeOptions![0].toString());
            selectedIndexVariants
                .add('${productModel.itemAttributes!.attributes!.indexOf(element)} _${productModel.itemAttributes!.attributes![0].attributeOptions![0].toString()}');
            selectedIndexArray.add('${productModel.itemAttributes!.attributes!.indexOf(element)}_0');
          }
        }
      }
      if (productModel.itemAttributes!.variants!.where((element) => element.variant_sku == selectedVariants.join('-')).isNotEmpty) {
        price = productCommissionPrice(
            vendorModel!.adminCommission, productModel.itemAttributes!.variants!.where((element) => element.variant_sku == selectedVariants.join('-')).first.variant_price ?? '0');
        disPrice = productCommissionPrice(vendorModel.adminCommission, '0');
      }
    } else {
      price = productCommissionPrice(vendorModel!.adminCommission!, productModel.price.toString());
      disPrice = productCommissionPrice(vendorModel.adminCommission, productModel.disPrice.toString());
    }

    return {'price': price, 'disPrice': disPrice};
  }

  Future<void> getData() async {
    print(MyAppState.currentUser!.userID);
    await fireStoreUtils.getFavouritesProductList(MyAppState.currentUser!.userID).then((value) {
      setState(() {
        lstFavourite.clear();
        lstFavourite.addAll(value);
      });
    });

    List<VendorModel> vendorList = await fireStoreUtils.getAllStoresFuture();
    List<ProductModel> allProduct = <ProductModel>[];
    for (var vendor in vendorList) {
      await fireStoreUtils.getAllProducts(vendor.id).then((value) {
        if (isSubscriptionModelApplied == true || vendor.adminCommission?.enable == true) {
          if (vendor.subscriptionPlan != null && isExpire(vendor) == false) {
            if (vendor.subscriptionPlan?.itemLimit == '-1') {
              allProduct.addAll(value);
            } else {
              int selectedProduct =
                  value.length < int.parse(vendor.subscriptionPlan?.itemLimit ?? '0') ? (value.isEmpty ? 0 : (value.length)) : int.parse(vendor.subscriptionPlan?.itemLimit ?? '0');
              allProduct.addAll(value.sublist(0, selectedProduct));
            }
          }
        } else {
          allProduct.addAll(value);
        }
      });
    }

    lstFavourite.forEach((element) {
      final bool _productIsInList = allProduct.any((product) => product.id == element.product_id);
      if (_productIsInList) {
        ProductModel productModel = allProduct.firstWhere((product) => product.id == element.product_id);
        favProductList.add(productModel);
      }
    });
    showLoader = false;
    setState(() {});
  }
}
