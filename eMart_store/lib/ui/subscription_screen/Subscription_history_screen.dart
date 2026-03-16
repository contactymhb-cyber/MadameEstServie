import 'package:easy_localization/easy_localization.dart';
import 'package:emartstore/constants.dart';
import 'package:emartstore/model/subscription_history.dart';
import 'package:emartstore/services/FirebaseHelper.dart';
import 'package:emartstore/services/helper.dart';
import 'package:emartstore/theme/app_them_data.dart';
import 'package:emartstore/utils/network_image_widget.dart';
import 'package:flutter/material.dart';

class SubscriptionHistoryScreen extends StatefulWidget {
  const SubscriptionHistoryScreen({super.key});

  @override
  State<SubscriptionHistoryScreen> createState() => _SubscriptionHistoryScreenState();
}

class _SubscriptionHistoryScreenState extends State<SubscriptionHistoryScreen> {

  bool isLoading = true;
  List<SubscriptionHistoryModel> subscriptionHistoryList = <SubscriptionHistoryModel>[];

  @override
  void initState() {
    getAllSubscriptionList();
    super.initState();
  }

  getAllSubscriptionList() async {
    subscriptionHistoryList = await FireStoreUtils.getSubscriptionHistory();
    isLoading = false;
    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? loader()
          : subscriptionHistoryList.isEmpty
              ? showEmptyView(message: "Purchase History Not found")
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: subscriptionHistoryList.length,
                  itemBuilder: (context, index) {
                    final subscriptionHistoryModel = subscriptionHistoryList[index];
                    return Container(
                      margin: const EdgeInsets.only(left: 16, right: 16, top: 20),
                      decoration: ShapeDecoration(
                        color: isDarkMode(context) ? AppThemeData.grey900 : AppThemeData.grey50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        shadows: const [
                          BoxShadow(
                            color: Color(0x07000000),
                            blurRadius: 20,
                            offset: Offset(0, 0),
                            spreadRadius: 0,
                          )
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      NetworkImageWidget(
                                        imageUrl: subscriptionHistoryModel.subscriptionPlan?.image ?? '',
                                        fit: BoxFit.cover,
                                        width: 45,
                                        height: 45,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        subscriptionHistoryModel.subscriptionPlan?.name ?? '',
                                        textAlign: TextAlign.start,
                                        style: TextStyle(
                                          fontFamily: AppThemeData.medium,
                                          fontSize: 16,
                                          color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (index == 0)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.check_circle_outlined,
                                          color: AppThemeData.success400,
                                        ),
                                        SizedBox(width: 5),
                                        Text(
                                          'Active'.tr(),
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                            fontFamily: AppThemeData.medium,
                                            fontSize: 16,
                                            color: AppThemeData.success400,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Divider(color: isDarkMode(context) ? AppThemeData.grey800 : AppThemeData.grey100),
                            const SizedBox(height: 5),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Validity'.tr(),
                                          textAlign: TextAlign.end,
                                          maxLines: 2,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: AppThemeData.regular,
                                            color: isDarkMode(context) ? AppThemeData.grey200 : AppThemeData.grey900,
                                          )),
                                      Text(
                                          subscriptionHistoryModel.subscriptionPlan?.expiryDay == '-1'
                                              ? "Unlimited".tr()
                                              : '${subscriptionHistoryModel.subscriptionPlan?.expiryDay ?? '0'}  Days',
                                          textAlign: TextAlign.end,
                                          maxLines: 2,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: AppThemeData.medium,
                                            color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey800,
                                          )),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Price'.tr(),
                                          textAlign: TextAlign.end,
                                          maxLines: 2,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: AppThemeData.regular,
                                            color: isDarkMode(context) ? AppThemeData.grey200 : AppThemeData.grey900,
                                          )),
                                      Text(amountShow(amount: subscriptionHistoryModel.subscriptionPlan?.price ?? '0'),
                                          textAlign: TextAlign.end,
                                          maxLines: 2,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: AppThemeData.medium,
                                            color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey800,
                                          )),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Payment Type'.tr(),
                                          textAlign: TextAlign.end,
                                          maxLines: 2,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: AppThemeData.regular,
                                            color: isDarkMode(context) ? AppThemeData.grey200 : AppThemeData.grey900,
                                          )),
                                      Text((subscriptionHistoryModel.paymentType ?? '').capitalizeString(),
                                          textAlign: TextAlign.end,
                                          maxLines: 2,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: AppThemeData.medium,
                                            color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey800,
                                          )),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Purchase Date'.tr(),
                                          textAlign: TextAlign.end,
                                          maxLines: 2,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: AppThemeData.regular,
                                            color: isDarkMode(context) ? AppThemeData.grey200 : AppThemeData.grey900,
                                          )),
                                      Text(timestampToDateTime(subscriptionHistoryModel.subscriptionPlan!.createdAt!),
                                          textAlign: TextAlign.end,
                                          maxLines: 2,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: AppThemeData.medium,
                                            color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey800,
                                          )),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Expiry Date'.tr(),
                                          textAlign: TextAlign.end,
                                          maxLines: 2,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: AppThemeData.regular,
                                            color: isDarkMode(context) ? AppThemeData.grey200 : AppThemeData.grey900,
                                          )),
                                      Text(subscriptionHistoryModel.expiryDate == null ? "Unlimited" : timestampToDateTime(subscriptionHistoryModel.expiryDate!),
                                          textAlign: TextAlign.end,
                                          maxLines: 2,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: AppThemeData.medium,
                                            color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey800,
                                          )),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  }),
    );
  }
}
