import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emartstore/constants.dart';
import 'package:emartstore/main.dart';
import 'package:emartstore/model/ProductModel.dart';
import 'package:emartstore/services/FirebaseHelper.dart';
import 'package:emartstore/services/helper.dart';
import 'package:emartstore/services/show_toast_dailog.dart';
import 'package:emartstore/theme/app_them_data.dart';
import 'package:emartstore/ui/addOrUpdateProduct/AddOrUpdateProductScreen.dart';
import 'package:emartstore/utils/network_image_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ManageProductsScreen extends StatefulWidget {
  @override
  _ManageProductsScreenState createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  FireStoreUtils fireStoreUtils = FireStoreUtils();
  // Stream<List<ProductModel>>? productsStream;
  List<ProductModel> productsList = <ProductModel>[];
  late ProductModel futureproduct;
  late bool publish;
  var product;
  var isItemLoading = true;

  @override
  void initState() {
    super.initState();
    getInit();
  }

  getInit() async {
    isItemLoading = true;
    await fireStoreUtils.getProductsFuture(MyAppState.currentUser!.vendorID).then((value) {
      isItemLoading = false;
      productsList = value;
      setState(() {});
    });
  }

  @override
  void dispose() {
    fireStoreUtils.closeProductsStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: isDarkMode(context) ? Color(COLOR_DARK) : null,
        floatingActionButton: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppThemeData.secondary300, width: 5, style: BorderStyle.solid)),
          child: FloatingActionButton(
            elevation: 0,
            backgroundColor: AppThemeData.secondary300,
            onPressed: () async {
              if (MyAppState.currentUser!.vendorID.isEmpty) {
                final snackBar = SnackBar(
                  content: Text('Please add a Store first'.tr()),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                return;
              } else if ((isSubscriptionModelApplied == true || vendorAdminCommission?.enable == true) && MyAppState.currentUser?.subscriptionPlan?.itemLimit != '-1') {
                if ((productsList.length >= int.parse(MyAppState.currentUser?.subscriptionPlan?.itemLimit ?? '0'))) {
                  ShowToastDialog.showToast("Your current subscription plan has reached its maximum product limit. Upgrade now to add more products.".tr());
                  return;
                } else {
                  Navigator.of(context).push(new MaterialPageRoute(builder: (context) => AddOrUpdateProductScreen(product: null))).then((value) {
                    if (value == true) {
                      getInit();
                    }
                  });
                }
              } else {
                Navigator.of(context).push(new MaterialPageRoute(builder: (context) => AddOrUpdateProductScreen(product: null))).then((value) {
                  if (value == true) {
                    getInit();
                  }
                });
              }
            },
            child: Icon(
              Icons.add,
              color: AppThemeData.grey50,
            ),
          ),
        ),
        body: SingleChildScrollView(
            child: Container(
                width: MediaQuery.of(context).size.width * 1,
                height: MediaQuery.of(context).size.height * 0.9,
                child: isItemLoading == true
                    ? loader()
                    : productsList.length == 0
                        ? Container(
                            height: MediaQuery.of(context).size.height * 0.9,
                            alignment: Alignment.center,
                            child: showEmptyState('No Products'.tr(), 'All your products will show up here'.tr()),
                          )
                        : ListView.builder(
                            primary: false,
                            shrinkWrap: true,
                            itemCount: productsList.length,
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 55),
                            itemBuilder: (context, index) => buildRow(productsList[index], index)))));
  }

  Widget buildRow(ProductModel productModel, int index) {
    bool isDisplayItemAlert = false;
    if ((isSubscriptionModelApplied == true || vendorAdminCommission?.enable == true)) {
      if (MyAppState.currentUser?.subscriptionPlan?.itemLimit == '-1') {
        isDisplayItemAlert = false;
      } else {
        isDisplayItemAlert = (index < int.parse(MyAppState.currentUser?.subscriptionPlan?.itemLimit ?? '0') == true) ? false : true;
      }
    }
    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .push(new MaterialPageRoute(
                builder: (context) => AddOrUpdateProductScreen(
                      product: productModel,
                    )))
            .then((value) {
          if (value == true) {
            getInit();
          }
        });
      },
      // onLongPress: () => showProductOptionsSheet(productModel),
      child: Container(
        margin: EdgeInsets.fromLTRB(7, 7, 7, 7),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // if you need this
            side: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 8.0,
              ),
              child: SingleChildScrollView(
                child: Column(children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: NetworkImageWidget(
                          imageUrl: productModel.photo,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(
                        width: 20,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                productModel.name,
                                style: TextStyle(fontSize: 17, fontFamily: "Poppins", color: isDarkMode(context) ? Colors.white : Color.fromRGBO(0, 0, 0, 100)),
                              ),
                              SizedBox(height: 5),
                              Text(
                                productModel.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 15, fontFamily: "Poppins", color: isDarkMode(context) ? Colors.white : Color(0xff5E5C5C)),
                              ),
                              SizedBox(height: 5),
                              Row(
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          Visibility(
                                            visible: productModel.disPrice.toString() != "0",
                                            child: Row(
                                              children: [
                                                Text(
                                                  amountShow(amount: productModel.disPrice.toString()),
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontFamily: "Poppins",
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(COLOR_PRIMARY),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 7,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            amountShow(amount: productModel.price.toString()),
                                            style: TextStyle(
                                                fontSize: 18,
                                                decoration: productModel.disPrice.toString() != "0" ? TextDecoration.lineThrough : null,
                                                fontFamily: "Poppins",
                                                color: productModel.disPrice.toString() == "0" ? Color(COLOR_PRIMARY) : Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
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
                                                fontFamily: "Poppinsm",
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
                              )

                              /* Visibility(
                                visible: productModel.addOnsTitle.length!=0,
                                child: Column(
                                  children: [
                                    SizedBox(height: 8),
                                    Text("("+productModel.addOnsTitle.join(",")+")")

                                  ],
                                ),
                              ),*/
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Padding(padding: EdgeInsets.fromLTRB(0, 5, 0,0)),
                  SizedBox(
                    height: 10,
                  ),
                  Divider(color: Color(0xFFC8D2DF), height: 0.1),
                  Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          showProductOptionsSheet(productModel);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image(
                              image: AssetImage('assets/images/delete.png'),
                              width: 20,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              "Delete".tr(),
                              style: TextStyle(fontSize: 15, color: isDarkMode(context) ? Colors.white : Color(0XFF768296), fontFamily: "Poppins"),
                            )
                          ],
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(right: 0),
                      child: Image(
                        image: AssetImage("assets/images/verti_divider.png"),
                        height: 30,
                      ),
                    ),
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            activeColor: Color(COLOR_ACCENT),
                            title: Text('Publish'.tr(),
                                textAlign: TextAlign.end, style: TextStyle(fontSize: 15, color: isDarkMode(context) ? Colors.white : Color(0XFF768296), fontFamily: "Poppins")),
                            value: productModel.publish,
                            onChanged: (bool newValue) async {
                              productModel.publish = newValue;
                              await fireStoreUtils.addOrUpdateProduct(productModel);

                              setState(() {});
                            })
                      ],
                    ))
                  ]),
                  Visibility(
                    visible: isDisplayItemAlert,
                    child: Text(
                      "This product will not be displayed to customers due to your current subscription limitations.".tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppThemeData.danger300, fontSize: 12, fontFamily: AppThemeData.regular),
                    ),
                  ),
                ]),
              )),
        ),
      ),
    );
  }

  Widget bottomsheet_view_all(BuildContext context, ProductModel productModel) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 7,
            margin: EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: new BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: SingleChildScrollView(
              child: Stack(children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 15,
                      ),
                      Text(
                        productModel.name,
                        style: TextStyle(fontFamily: AppThemeData.medium, fontSize: 17, color: Color(0xff000000)),
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      Row(
                        children: [
                          Visibility(
                            visible: productModel.disPrice.toString() != "0",
                            child: Row(
                              children: [
                                Text(
                                  // symbol != '' ? symbol + double.parse(productModel.disPrice.toString()).toStringAsFixed(decimal) : '\$${double.parse(productModel.disPrice.toString()).toDouble().toStringAsFixed(2)}',
                                  amountShow(amount: productModel.disPrice.toString()),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontFamily: "Poppins",
                                    fontWeight: FontWeight.bold,
                                    color: Color(COLOR_PRIMARY),
                                  ),
                                ),
                                SizedBox(
                                  width: 7,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            amountShow(amount: productModel.price.toString()),
                            style: TextStyle(
                                fontSize: 18,
                                decoration: productModel.disPrice.toString() != "0" ? TextDecoration.lineThrough : null,
                                fontFamily: "Poppins",
                                color: productModel.disPrice.toString() == "0" ? Color(COLOR_PRIMARY) : Colors.grey),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      Text(
                        productModel.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15, fontFamily: "Poppinsm", color: isDarkMode(context) ? Colors.white : Color(0xff5E5C5C)),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      Visibility(
                        visible: productModel.addOnsTitle.isNotEmpty,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Addons".tr(),
                              style: TextStyle(fontFamily: "Poppinsb", fontSize: 15, color: Color(0xff000000)),
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: productModel.addOnsTitle
                                      .map((data) => Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            child: Text(data, style: TextStyle(fontSize: 18, fontFamily: "Poppins", fontWeight: FontWeight.normal, color: Colors.grey)),
                                          ))
                                      .toList(),
                                ),
                                Expanded(child: SizedBox()),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: productModel.addOnsPrice
                                      .map((data) => Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            child: Text(amountShow(amount: data.toString()),
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontFamily: "Poppins",
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(COLOR_PRIMARY),
                                                )),
                                          ))
                                      .toList(),
                                )
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ]),
            ),
          ),
          Align(
            alignment: Alignment(0, -1.35),
            child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.3,
                margin: EdgeInsets.only(right: 10, left: 10),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), image: DecorationImage(image: NetworkImage(productModel.photo), fit: BoxFit.cover))),
          ),
        ],
      ),
    );
  }

  showProductOptionsSheet(ProductModel productModel) {
    final action = CupertinoActionSheet(
      message: Text(
        'Are you sure you want to delete this product?'.tr(),
        style: TextStyle(fontSize: 15.0),
      ).tr(),
      title: Text(
        '${productModel.name}',
        style: TextStyle(fontSize: 17.0),
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text("Yes, i'm sure, Delete").tr(),
          isDestructiveAction: true,
          onPressed: () async {
            Navigator.pop(context);
            fireStoreUtils.deleteProduct(productModel.id);
            productsList.remove(productModel);
            setState(() {});
          },
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text('Cancel').tr(),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }
}
