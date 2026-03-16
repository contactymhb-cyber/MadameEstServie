import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:emartstore/constants.dart';
import 'package:emartstore/main.dart';
import 'package:emartstore/model/SectionModel.dart';
import 'package:emartstore/model/User.dart';
import 'package:emartstore/model/VendorModel.dart';
import 'package:emartstore/model/subscription_history.dart';
import 'package:emartstore/model/subscription_plan_model.dart';
import 'package:emartstore/services/FirebaseHelper.dart';
import 'package:emartstore/services/helper.dart';
import 'package:emartstore/services/show_toast_dailog.dart';
import 'package:emartstore/theme/app_them_data.dart';
import 'package:emartstore/theme/responsive.dart';
import 'package:emartstore/theme/round_button_fill.dart';
import 'package:emartstore/ui/container/ContainerScreen.dart';
import 'package:emartstore/ui/ordersScreen/OrdersScreen.dart';
import 'package:emartstore/ui/subscription_screen/app_not_access_screen.dart';
import 'package:emartstore/ui/subscription_screen/select_payment_screen.dart';
import 'package:emartstore/utils/network_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionScreens extends StatefulWidget {
  final bool isShowAppBar;
  final bool? isDropDownDisble;

  const SubscriptionScreens(
      {super.key, this.isDropDownDisble, required this.isShowAppBar});

  @override
  State<SubscriptionScreens> createState() => _SubscriptionScreensState();
}

class _SubscriptionScreensState extends State<SubscriptionScreens> {
  bool isLoading = true;
  List<SubscriptionPlanModel> subscriptionPlanList = <SubscriptionPlanModel>[];
  SubscriptionPlanModel selectedSubscriptionPlan = SubscriptionPlanModel();
  User userModel = User();

  String selectedPaymentMethod = '';

  List<SectionModel> sectionsVal = [];
  SectionModel? selectedSectionModelData;
  VendorModel vendorModel = VendorModel();

  @override
  void initState() {
    // TODO: implement initState
    getInitPlanSettings();
    super.initState();
  }

  getInitPlanSettings() async {
    userModel =
        await FireStoreUtils.getCurrentUser(MyAppState.currentUser!.userID) ??
            User();
    if (userModel.userID.isNotEmpty) {
      MyAppState.currentUser = userModel;
    }
    await FireStoreUtils.getSections().then(
      (value) async {
        value.forEach((element) {
          if (element.serviceTypeFlag == "ecommerce-service" ||
              element.serviceTypeFlag == "delivery-service") {
            sectionsVal.add(element);
          }
        });

        if (MyAppState.currentUser?.section_id.isNotEmpty == true) {
          selectedSectionModelData = sectionsVal.firstWhere(
              (element) => element.id == MyAppState.currentUser?.section_id);
        } else {
          selectedSectionModelData = sectionsVal.first;
        }
        selectedSectionModel = selectedSectionModelData;
        if (MyAppState.currentUser?.vendorID != null &&
            MyAppState.currentUser?.vendorID != '') {
          vendorModel =
              await FireStoreUtils.getVendor(MyAppState.currentUser!.vendorID);
        }
        if (selectedSectionModelData?.id != null)
          await getSubscriptionPlanList();
        isLoading = false;
        setState(() {});
      },
    );
    // await getSubscriptionPlanList();
  }

  getSubscriptionPlanList() async {
    setState(() {
      isLoading = true;
    });
    await FireStoreUtils.getSubscriptionCommissionPlanById(
            selectedSectionModelData?.id ?? '')
        .then(
      (value) {
        value.forEach(
          (element) {
            if (selectedSectionModelData?.adminCommision?.enable == true &&
                element.name == 'Commission Base Plan') {
              subscriptionPlanList.add(element);
            }
          },
        );
      },
    );
    if (isSubscriptionModelApplied && selectedSectionModelData?.id != null) {
      await FireStoreUtils.getAllSubscriptionPlans(
              selectedSectionModelData?.id ?? '')
          .then(
        (value) {
          value.forEach(
            (element) {
              subscriptionPlanList.add(element);
            },
          );
        },
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isShowAppBar == false
          ? PreferredSize(
              preferredSize: Size.fromHeight(8.0),
              child: AppBar(
                backgroundColor: AppThemeData.secondary300,
              ))
          : null,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: isLoading
            ? loader()
            : Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  widget.isShowAppBar == true
                      ? SizedBox()
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Choose Your Business Plan".tr(),
                                style: TextStyle(
                                  color: isDarkMode(context)
                                      ? AppThemeData.grey50
                                      : AppThemeData.grey900,
                                  fontSize: 24,
                                  fontFamily: AppThemeData.semiBold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Select the most suitable business plan for your business to maximize your potential and access exclusive features."
                                    .tr(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDarkMode(context)
                                      ? AppThemeData.grey400
                                      : AppThemeData.grey500,
                                  fontSize: 16,
                                  fontFamily: AppThemeData.regular,
                                ),
                              ),
                            ],
                          ),
                        ),
                  const SizedBox(
                    height: 10,
                  ),
                  widget.isShowAppBar || widget.isDropDownDisble == true
                      ? Container(
                          padding: const EdgeInsetsDirectional.only(bottom: 10),
                          child: InkWell(
                            onTap: () {
                              ShowToastDialog.showToast(
                                  "You are not able to change section. because of your plan is purchased on ${selectedSectionModelData!.name} section");
                            },
                            child: TextFormField(
                                initialValue: selectedSectionModelData!.name
                                        .toString() +
                                    " (${selectedSectionModelData!.serviceType})",
                                textAlignVertical: TextAlignVertical.center,
                                textInputAction: TextInputAction.next,
                                validator: validateEmptyField,
                                // onSaved: (text) => line1 = text,
                                keyboardType: TextInputType.streetAddress,
                                enabled: false,
                                cursorColor: Color(COLOR_PRIMARY),
                                // initialValue: MyAppState.currentUser!.shippingAddress.line1,
                                decoration: InputDecoration(
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    hintText: 'Section'.tr(),
                                    hintStyle: TextStyle(
                                      color: isDarkMode(context)
                                          ? Colors.white
                                          : Color(0Xff333333),
                                      fontSize: 14,
                                      fontFamily: AppThemeData.medium,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(7.0),
                                        borderSide: BorderSide(
                                            color: Color(COLOR_PRIMARY),
                                            width: 2.0)),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error),
                                      borderRadius: BorderRadius.circular(7.0),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error),
                                      borderRadius: BorderRadius.circular(7.0),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade400),
                                      borderRadius: BorderRadius.circular(7.0),
                                    ),
                                    disabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade400),
                                      borderRadius: BorderRadius.circular(7.0),
                                    ))),
                          ),
                        )
                      : Container(
                          height: 60,
                          child: DropdownButtonFormField<SectionModel>(
                              isExpanded: true,
                              decoration: InputDecoration(
                                contentPadding:
                                    EdgeInsets.fromLTRB(10, 2, 10, 2),
                                enabledBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.grey, width: 1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                border: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.grey, width: 1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              validator: (value) =>
                                  value == null ? 'field required' : null,
                              value: selectedSectionModelData,
                              onChanged: (value) {
                                selectedSectionModelData = value;
                                selectedSectionModel = selectedSectionModelData;
                                subscriptionPlanList.clear();
                                setState(() {});
                                getSubscriptionPlanList();
                              },
                              hint: Text('Select Section'.tr()),
                              items: sectionsVal.map((SectionModel item) {
                                return DropdownMenuItem<SectionModel>(
                                  child: Text(item.name.toString() +
                                      " (${item.serviceType})"),
                                  value: item,
                                );
                              }).toList()),
                        ),
                  const SizedBox(
                    height: 10,
                  ),
                  subscriptionPlanList.isEmpty
                      ? SizedBox(
                          width: Responsive.width(100, context),
                          height: Responsive.height(50, context),
                          child: showEmptyView(
                              message:
                                  "Oops! The selected section doesn't have a subscription plan. Please contact the admin."
                                          .tr() +
                                      "\n${adminEmail}"))
                      : Expanded(
                          child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: subscriptionPlanList.length,
                              itemBuilder: (context, index) {
                                SubscriptionPlanModel subscriptionPlanModel =
                                    subscriptionPlanList[index];
                                return subscriptionPlanWidget(
                                    subscriptionPlanModel);
                              }),
                        ),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              ),
      ),
    );
  }

  subscriptionPlanWidget(SubscriptionPlanModel subscriptionPlanModel) {
    return InkWell(
      splashColor: Colors.transparent,
      onTap: () {
        setState(() {
          selectedSubscriptionPlan = subscriptionPlanModel;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(
              color: isDarkMode(context)
                  ? AppThemeData.grey800
                  : AppThemeData.grey200),
          color: selectedSubscriptionPlan.id == subscriptionPlanModel.id
              ? isDarkMode(context)
                  ? AppThemeData.grey50
                  : AppThemeData.grey800
              : isDarkMode(context)
                  ? AppThemeData.grey900
                  : AppThemeData.grey50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  NetworkImageWidget(
                    imageUrl: subscriptionPlanModel.image ?? '',
                    fit: BoxFit.cover,
                    width: 50,
                    height: 50,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subscriptionPlanModel.name ?? '',
                          style: TextStyle(
                            color: selectedSubscriptionPlan.id ==
                                    subscriptionPlanModel.id
                                ? isDarkMode(context)
                                    ? AppThemeData.grey900
                                    : AppThemeData.grey50
                                : isDarkMode(context)
                                    ? AppThemeData.grey50
                                    : AppThemeData.grey900,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppThemeData.semiBold,
                          ),
                        ),
                        Text(
                          "${subscriptionPlanModel.description}",
                          maxLines: 2,
                          softWrap: true,
                          style: const TextStyle(
                            fontFamily: AppThemeData.regular,
                            fontSize: 14,
                            color: AppThemeData.grey400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  userModel.subscriptionPlanId == subscriptionPlanModel.id
                      ? RoundedButtonFill(
                          title: "Active".tr(),
                          width: 18,
                          height: 4,
                          color: AppThemeData.success500,
                          textColor: AppThemeData.grey50,
                          onPress: () async {},
                        )
                      : SizedBox(),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subscriptionPlanModel.type == "free"
                        ? "Free"
                        : amountShow(
                            amount: double.parse(
                                    subscriptionPlanModel.price ?? '0.0')
                                .toString()),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: selectedSubscriptionPlan.id ==
                              subscriptionPlanModel.id
                          ? isDarkMode(context)
                              ? AppThemeData.grey800
                              : AppThemeData.grey200
                          : isDarkMode(context)
                              ? AppThemeData.grey200
                              : AppThemeData.grey800,
                      fontFamily: AppThemeData.semiBold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subscriptionPlanModel.expiryDay == "-1"
                        ? "Lifetime"
                        : "${subscriptionPlanModel.expiryDay} Days",
                    style: TextStyle(
                      fontFamily: AppThemeData.medium,
                      fontSize: 14,
                      color: selectedSubscriptionPlan.id ==
                              subscriptionPlanModel.id
                          ? isDarkMode(context)
                              ? AppThemeData.grey500
                              : AppThemeData.grey500
                          : isDarkMode(context)
                              ? AppThemeData.grey500
                              : AppThemeData.grey500,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
              Divider(
                  color: selectedSubscriptionPlan.id == subscriptionPlanModel.id
                      ? isDarkMode(context)
                          ? AppThemeData.grey200
                          : AppThemeData.grey700
                      : isDarkMode(context)
                          ? AppThemeData.grey700
                          : AppThemeData.grey200),
              const SizedBox(height: 10),
              Wrap(
                spacing: 0,
                runSpacing: 10,
                children: subscriptionPlanModel.features!
                    .toJson()
                    .entries
                    .map((entry) {
                  return SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        entry.value == true
                            ? SvgPicture.asset(
                                'assets/icons/ic_check.svg',
                              )
                            : SvgPicture.asset(
                                'assets/icons/ic_close.svg',
                                colorFilter: const ColorFilter.mode(
                                  AppThemeData.danger200,
                                  BlendMode.srcIn,
                                ),
                              ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            entry.key == 'chat'
                                ? 'Chat'.tr()
                                : entry.key == 'qrCodeGenerate'
                                    ? 'QR Code Generate'.tr()
                                    : entry.key == 'ownerMobileApp'
                                        ? 'Store Mobile App'.tr()
                                        : '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: AppThemeData.medium,
                              color: isDarkMode(context)
                                  ? selectedSubscriptionPlan.id ==
                                          subscriptionPlanModel.id
                                      ? AppThemeData.grey900
                                      : AppThemeData.grey50
                                  : selectedSubscriptionPlan.id ==
                                          subscriptionPlanModel.id
                                      ? AppThemeData.grey50
                                      : AppThemeData.grey900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              SizedBox(
                height: 10,
              ),
              Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text('•  ',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: AppThemeData.medium,
                            color: isDarkMode(context)
                                ? selectedSubscriptionPlan.id ==
                                        subscriptionPlanModel.id
                                    ? AppThemeData.grey800
                                    : AppThemeData.grey200
                                : selectedSubscriptionPlan.id ==
                                        subscriptionPlanModel.id
                                    ? AppThemeData.grey200
                                    : AppThemeData.grey800,
                          )),
                      Expanded(
                        child: Text(
                            vendorModel.adminCommission?.commission != null
                                ? "Pay a commission of ${vendorModel.adminCommission?.type == 'percentage' ? "${vendorModel.adminCommission!.commission}%" : "${amountShow(amount: vendorModel.adminCommission!.commission.toString())} Flat"} on each order".tr()
                                    .tr()
                                : "Pay a commission of ${selectedSectionModelData!.adminCommision!.type == 'percentage' ? "${selectedSectionModelData!.adminCommision!.commission}%" : "${amountShow(amount: selectedSectionModelData!.adminCommision!.commission.toString())} Flat"} on each order"
                                    .tr(),
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: AppThemeData.regular,
                              color: isDarkMode(context)
                                  ? selectedSubscriptionPlan.id ==
                                          subscriptionPlanModel.id
                                      ? AppThemeData.grey800
                                      : AppThemeData.grey200
                                  : selectedSubscriptionPlan.id ==
                                          subscriptionPlanModel.id
                                      ? AppThemeData.grey200
                                      : AppThemeData.grey800,
                            )),
                      ),
                    ],
                  )),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: subscriptionPlanModel.planPoints == null
                    ? 0
                    : subscriptionPlanModel.planPoints!.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text('•  ',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: AppThemeData.medium,
                              color: isDarkMode(context)
                                  ? selectedSubscriptionPlan.id ==
                                          subscriptionPlanModel.id
                                      ? AppThemeData.grey800
                                      : AppThemeData.grey200
                                  : selectedSubscriptionPlan.id ==
                                          subscriptionPlanModel.id
                                      ? AppThemeData.grey200
                                      : AppThemeData.grey800,
                            )),
                        Expanded(
                          child: Text(
                              subscriptionPlanModel.planPoints?[index] ?? '',
                              maxLines: 2,
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: AppThemeData.regular,
                                color: isDarkMode(context)
                                    ? selectedSubscriptionPlan.id ==
                                            subscriptionPlanModel.id
                                        ? AppThemeData.grey800
                                        : AppThemeData.grey200
                                    : selectedSubscriptionPlan.id ==
                                            subscriptionPlanModel.id
                                        ? AppThemeData.grey200
                                        : AppThemeData.grey800,
                              )),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              Divider(
                  color: selectedSubscriptionPlan.id == subscriptionPlanModel.id
                      ? isDarkMode(context)
                          ? AppThemeData.grey200
                          : AppThemeData.grey700
                      : isDarkMode(context)
                          ? AppThemeData.grey700
                          : AppThemeData.grey200),
              const SizedBox(height: 10),
              Text(
                  'Add item limits : ${subscriptionPlanModel.itemLimit == '-1' ? 'Unlimited' : subscriptionPlanModel.itemLimit ?? '0'}'.tr(),
                  maxLines: 2,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                      fontSize: 14,
                      fontFamily: AppThemeData.regular,
                      color: isDarkMode(context)
                          ? selectedSubscriptionPlan.id ==
                                  subscriptionPlanModel.id
                              ? AppThemeData.grey900
                              : AppThemeData.grey50
                          : selectedSubscriptionPlan.id ==
                                  subscriptionPlanModel.id
                              ? AppThemeData.grey50
                              : AppThemeData.grey900)),
              const SizedBox(height: 10),
              Text(
                  'Accept order limits : ${subscriptionPlanModel.orderLimit == '-1' ? 'Unlimited' : subscriptionPlanModel.orderLimit ?? '0'}'.tr(),
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  style: TextStyle(
                      fontSize: 14,
                      fontFamily: AppThemeData.regular,
                      color: isDarkMode(context)
                          ? selectedSubscriptionPlan.id ==
                                  subscriptionPlanModel.id
                              ? AppThemeData.grey900
                              : AppThemeData.grey50
                          : selectedSubscriptionPlan.id ==
                                  subscriptionPlanModel.id
                              ? AppThemeData.grey50
                              : AppThemeData.grey900)),
              const SizedBox(height: 20),
              RoundedButtonFill(
                radius: 14,
                textColor:
                    selectedSubscriptionPlan.id == subscriptionPlanModel.id
                        ? AppThemeData.grey200
                        : isDarkMode(context)
                            ? AppThemeData.grey500
                            : AppThemeData.grey500,
                title: userModel.subscriptionPlanId == subscriptionPlanModel.id
                    ? "Renew"
                    : selectedSubscriptionPlan.id == subscriptionPlanModel.id
                        ? "Active".tr()
                        : "Select Plan".tr(),
                color: selectedSubscriptionPlan.id == subscriptionPlanModel.id
                    ? AppThemeData.secondary300
                    : isDarkMode(context)
                        ? AppThemeData.grey800
                        : AppThemeData.grey200,
                width: 80,
                height: 5,
                onPress: () async {
                  if (selectedSubscriptionPlan.id == subscriptionPlanModel.id) {
                    if (selectedSubscriptionPlan.type == 'free' ||
                        subscriptionPlanModel.isCommissionPlan == true) {
                      selectedPaymentMethod = 'free';
                      log(":::::::::FREE::::::::::");
                      await setOrder();
                      // push(
                      //     context,
                      //     SelectPaymentScreen(
                      //       subscriptionPlanModel: selectedSubscriptionPlan,
                      //       isShowAppBar: widget.isShowAppBar,
                      //     ));
                    } else {
                      push(
                          context,
                          SelectPaymentScreen(
                            subscriptionPlanModel: selectedSubscriptionPlan,
                            isShowAppBar: widget.isShowAppBar,
                          ));
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  setOrder() async {
    ShowToastDialog.showLoader("Please wait".tr());
    userModel.subscriptionPlanId = selectedSubscriptionPlan.id;
    userModel.subscriptionPlan = selectedSubscriptionPlan;
    userModel.subscriptionPlan?.createdAt = Timestamp.now();
    userModel.subscriptionExpiryDate =
        selectedSubscriptionPlan.expiryDay == '-1'
            ? null
            : addDayInTimestamp(
                days: selectedSubscriptionPlan.expiryDay,
                date: Timestamp.now());
    userModel.section_id = selectedSectionModelData?.id ?? '';

    if (userModel.vendorID.isNotEmpty) {
      VendorModel? vendorModel =
          await FireStoreUtils.getVendor(userModel.vendorID.toString());
      if (vendorModel.id.isNotEmpty) {
        vendorModel.subscriptionPlanId = selectedSubscriptionPlan.id;
        vendorModel.subscriptionPlan = selectedSubscriptionPlan;
        vendorModel.subscriptionPlan?.createdAt = Timestamp.now();
        vendorModel.subscriptionExpiryDate =
            selectedSubscriptionPlan.expiryDay == '-1'
                ? null
                : addDayInTimestamp(
                    days: selectedSubscriptionPlan.expiryDay,
                    date: Timestamp.now());
        vendorModel.subscriptionTotalOrders =
            selectedSubscriptionPlan.orderLimit;
        if (vendorModel.adminCommission?.commission == null ||
            vendorModel.adminCommission?.commission == '') {
          vendorModel.adminCommission =
              selectedSectionModelData!.adminCommision;
        }
      }

      await FireStoreUtils.updateVendor(vendorModel);
    }

    SubscriptionHistoryModel subscriptionHistoryData = SubscriptionHistoryModel(
        id: getUuid(),
        createdAt: Timestamp.now(),
        expiryDate: userModel.subscriptionExpiryDate,
        subscriptionPlan: userModel.subscriptionPlan,
        paymentType: selectedPaymentMethod,
        userId: userModel.userID);

    await FireStoreUtils.setSubscriptionTransaction(subscriptionHistoryData);

    await FireStoreUtils.updateCurrentUser(userModel).then(
      (value) async {
        MyAppState.currentUser = userModel;
        log("userModel.section_id :: ${userModel.toJson()}");
        ShowToastDialog.closeLoader();
        if (userModel.subscriptionPlan?.features?.ownerMobileApp == true) {
          pushAndRemoveUntil(
              context,
              ContainerScreen(
                user: MyAppState.currentUser!,
                currentWidget: OrdersScreen(),
                appBarTitle: 'Orders'.tr(),
                drawerSelection: DrawerSelection.Orders,
              ),
              false);
          ShowToastDialog.showToast(
              "Success! You’ve unlocked your subscription benefits starting today."
                  .tr());
        } else {
          pushAndRemoveUntil(context, AppNotAccessScreen(), false);
        }
      },
    );
  }
}
