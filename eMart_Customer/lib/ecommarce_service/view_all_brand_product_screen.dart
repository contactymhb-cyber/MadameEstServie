import 'package:easy_localization/easy_localization.dart';
import 'package:emartconsumer/AppGlobal.dart';
import 'package:emartconsumer/constants.dart';
import 'package:emartconsumer/model/BrandsModel.dart';
import 'package:emartconsumer/model/ProductModel.dart';
import 'package:emartconsumer/model/VendorModel.dart';
import 'package:emartconsumer/services/FirebaseHelper.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/theme/app_them_data.dart';
import 'package:emartconsumer/ui/productDetailsScreen/ProductDetailsScreen.dart';
import 'package:emartconsumer/utils/network_image_widget.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class ViewAllBrandProductScreen extends StatefulWidget {
  BrandsModel? brandModel;

  ViewAllBrandProductScreen({Key? key, this.brandModel}) : super(key: key);

  @override
  State<ViewAllBrandProductScreen> createState() => _ViewAllBrandProductScreenState();
}

class _ViewAllBrandProductScreenState extends State<ViewAllBrandProductScreen> {
  final fireStoreUtils = FireStoreUtils();
  List<ProductModel> productList = [];
  bool showLoader = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getProductByCategoryId();
  }

  getProductByCategoryId() async {
    List<ProductModel> productDataList = await FireStoreUtils.getProductListByBrandId(widget.brandModel!.id.toString());

    List<VendorModel> vendorList = await FireStoreUtils().getAllStoresFuture();
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
    productDataList.forEach((element) {
      final bool _productIsInList = allProduct.any((product) => product.id == element.id);
      if (_productIsInList) {
        productList.add(element);
      }
    });
    showLoader = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode(context) ? AppThemeData.surfaceDark : AppThemeData.surface,
      appBar: AppGlobal.buildAppBar(context, widget.brandModel!.title.toString()),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        margin: const EdgeInsets.fromLTRB(10, 0, 0, 10),
        child: showLoader
            ? Center(
                child: CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation(AppThemeData.primary300),
                ),
              )
            : productList.isEmpty
                ? showEmptyState("No Item found".tr(), context)
                : ListView.builder(
                    shrinkWrap: true,
                    scrollDirection: Axis.vertical,
                    physics: const BouncingScrollPhysics(),
                    itemCount: productList.length,
                    itemBuilder: (context, index) {
                      return buildVendorItemData(context, productList[index]);
                    }),
      ),
    );
  }

  Widget buildVendorItemData(BuildContext context, ProductModel productModel) {
    return FutureBuilder(
        future: FireStoreUtils.getVendor(productModel.vendorID),
        builder: (context, vendorSnapshot) {
          if (!vendorSnapshot.hasData || vendorSnapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(); // Show placeholder or loader
          }
          VendorModel? vendordata = vendorSnapshot.data;
          String price = "0.0";
          String disPrice = "0.0";
          List<String> selectedVariants = [];
          List<String> selectedIndexVariants = [];
          List<String> selectedIndexArray = [];
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
              price = productCommissionPrice(vendordata?.adminCommission,
                  productModel.itemAttributes!.variants!.where((element) => element.variant_sku == selectedVariants.join('-')).first.variant_price ?? '0');
              disPrice = "0";
            }
          } else {
            price = productCommissionPrice(vendordata?.adminCommission, productModel.price.toString());
            disPrice = double.parse(productModel.disPrice.toString()) <= 0 ? "0" : productCommissionPrice(vendordata?.adminCommission, productModel.disPrice.toString());
          }
          return GestureDetector(
            onTap: () {
              VendorModel? vendorModel = vendordata;
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
              padding: const EdgeInsets.all(8.0),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  color: isDarkMode(context) ? AppThemeData.grey900 : AppThemeData.grey50,
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
                width: MediaQuery.of(context).size.width * 0.8,
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: NetworkImageWidget(
                        imageUrl: productModel.photo,
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productModel.name,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xff000000),
                            ),
                            maxLines: 1,
                          ),
                          disPrice == "" || disPrice == "0"
                              ? Text(
                                  amountShow(amount: price.toString()),
                                  style: TextStyle(fontSize: 16, letterSpacing: 0.5, color: AppThemeData.primary300),
                                )
                              : Row(
                                  children: [
                                    Text(
                                      amountShow(amount: disPrice.toString()),
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
                                      amountShow(amount: price.toString()),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, decoration: TextDecoration.lineThrough),
                                    ),
                                  ],
                                ),
                          const SizedBox(
                            height: 5,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(productModel.reviewsCount != 0 ? (productModel.reviewsSum / productModel.reviewsCount).toStringAsFixed(1) : 0.toString(),
                                      style: const TextStyle(
                                        letterSpacing: 0.5,
                                        fontSize: 12,
                                        color: Colors.white,
                                      )),
                                  const SizedBox(width: 3),
                                  const Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }
}
