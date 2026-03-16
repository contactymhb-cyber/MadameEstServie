import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:emartdriver/CabService/cab_order_detail_screen.dart';
import 'package:emartdriver/Parcel_service/parcel_order_detail_screen.dart';
import 'package:emartdriver/Parcel_service/parcel_order_model.dart';
import 'package:emartdriver/model/CabOrderModel.dart';
import 'package:emartdriver/model/FlutterWaveSettingDataModel.dart';
import 'package:emartdriver/model/MercadoPagoSettingsModel.dart';
import 'package:emartdriver/model/OrderModel.dart';
import 'package:emartdriver/model/PayFastSettingData.dart';
import 'package:emartdriver/model/PayStackSettingsModel.dart';
import 'package:emartdriver/model/StripePayFailedModel.dart';
import 'package:emartdriver/model/createRazorPayOrderModel.dart';
import 'package:emartdriver/model/getPaytmTxtToken.dart';
import 'package:emartdriver/model/payStackURLModel.dart';
import 'package:emartdriver/model/payment_model/mid_trans.dart';
import 'package:emartdriver/model/payment_model/orange_money.dart';
import 'package:emartdriver/model/payment_model/xendit.dart';
import 'package:emartdriver/model/paypalSettingData.dart';
import 'package:emartdriver/model/paytmSettingData.dart';
import 'package:emartdriver/model/razorpayKeyModel.dart';
import 'package:emartdriver/model/stripeSettingData.dart';
import 'package:emartdriver/model/withdrawHistoryModel.dart';
import 'package:emartdriver/model/withdraw_method_model.dart';
import 'package:emartdriver/payment/midtrans_screen.dart';
import 'package:emartdriver/payment/orangePayScreen.dart';
import 'package:emartdriver/payment/xenditModel.dart';
import 'package:emartdriver/payment/xenditScreen.dart';
import 'package:emartdriver/rental_service/model/rental_order_model.dart';
import 'package:emartdriver/rental_service/renatal_summary_screen.dart';
import 'package:emartdriver/services/FirebaseHelper.dart';
import 'package:emartdriver/services/helper.dart';
import 'package:emartdriver/services/payStackScreen.dart';
import 'package:emartdriver/services/paystack_url_genrater.dart';
import 'package:emartdriver/services/show_toast_dialog.dart';
import 'package:emartdriver/theme/app_them_data.dart';
import 'package:emartdriver/ui/topup/TopUpScreen.dart';
import 'package:emartdriver/ui/wallet/MercadoPagoScreen.dart';
import 'package:emartdriver/ui/wallet/PayFastScreen.dart';
import 'package:emartdriver/userPrefrence.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_paypal/flutter_paypal.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe1;
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../constants.dart';
import '../../main.dart';
import '../../model/User.dart';
import 'rozorpayConroller.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  WalletScreenState createState() => WalletScreenState();
}

class WalletScreenState extends State<WalletScreen> {
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;
  Stream<QuerySnapshot>? withdrawalHistoryQuery;
  Stream<QuerySnapshot>? dailyEarningQuery;
  Stream<QuerySnapshot>? monthlyEarningQuery;
  Stream<QuerySnapshot>? yearlyEarningQuery;

  Stream<DocumentSnapshot<Map<String, dynamic>>>? userQuery;

  String? selectedRadioTile;

  GlobalKey<FormState> _globalKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  TextEditingController _amountController =
      TextEditingController(text: 50.toString());
  TextEditingController _noteController = TextEditingController(text: '');

  getData() async {
    try {
      userQuery = fireStore.collection(USERS).doc(userId).snapshots();
      print(userQuery!.isEmpty);
    } catch (e) {
      print(e);
    }

    /// withdrawal History
    withdrawalHistoryQuery = fireStore
        .collection(driverPayouts)
        .where('driverID', isEqualTo: userId)
        .orderBy('paidDate', descending: true)
        .snapshots();

    DateTime nowDate = DateTime.now();

    if (MyAppState.currentUser!.serviceType == "cab-service") {
      ///earnings History

      dailyEarningQuery = fireStore
          .collection(RIDESORDER)
          .where('driverID', isEqualTo: driverId)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                  DateTime(nowDate.year, nowDate.month, nowDate.day)))
          .orderBy('createdAt', descending: true)
          .snapshots();

      monthlyEarningQuery = fireStore
          .collection(RIDESORDER)
          .where('driverID', isEqualTo: driverId)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(
                nowDate.year,
                nowDate.month,
              )))
          .orderBy('createdAt', descending: true)
          .snapshots();

      yearlyEarningQuery = fireStore
          .collection(RIDESORDER)
          .where('driverID', isEqualTo: driverId)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(
                nowDate.year,
              )))
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else if (MyAppState.currentUser!.serviceType == "parcel_delivery") {
      ///earnings History
      dailyEarningQuery = fireStore
          .collection(PARCELORDER)
          .where('driverID', isEqualTo: driverId)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                  DateTime(nowDate.year, nowDate.month, nowDate.day)))
          .orderBy('createdAt', descending: true)
          .snapshots();

      monthlyEarningQuery = fireStore
          .collection(PARCELORDER)
          .where('driverID', isEqualTo: driverId)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(
                nowDate.year,
                nowDate.month,
              )))
          .orderBy('createdAt', descending: true)
          .snapshots();

      yearlyEarningQuery = fireStore
          .collection(PARCELORDER)
          .where('driverID', isEqualTo: driverId)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(
                nowDate.year,
              )))
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else if (MyAppState.currentUser!.serviceType == "rental-service") {
      ///earnings History

      dailyEarningQuery = fireStore
          .collection(RENTALORDER)
          .where('driverID', isEqualTo: driverId)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                  DateTime(nowDate.year, nowDate.month, nowDate.day)))
          .orderBy('createdAt', descending: true)
          .snapshots();

      monthlyEarningQuery = fireStore
          .collection(RENTALORDER)
          .where('driverID', isEqualTo: driverId)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(
                nowDate.year,
                nowDate.month,
              )))
          .orderBy('createdAt', descending: true)
          .snapshots();

      yearlyEarningQuery = fireStore
          .collection(RENTALORDER)
          .where('driverID', isEqualTo: driverId)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(
                nowDate.year,
              )))
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      ///earnings History

      dailyEarningQuery = fireStore
          .collection(ORDERS)
          .where('driverID', isEqualTo: driverId)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                  DateTime(nowDate.year, nowDate.month, nowDate.day)))
          .orderBy('createdAt', descending: true)
          .snapshots();

      monthlyEarningQuery = fireStore
          .collection(ORDERS)
          .where('driverID', isEqualTo: driverId)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(
                nowDate.year,
                nowDate.month,
              )))
          .orderBy('createdAt', descending: true)
          .snapshots();

      yearlyEarningQuery = fireStore
          .collection(ORDERS)
          .where('driverID', isEqualTo: driverId)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(
                nowDate.year,
              )))
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
  }

  Map<String, dynamic>? paymentIntentData;

  showAlert(context, {required String response, required Color colors}) {
    return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(response),
      backgroundColor: colors,
      duration: Duration(seconds: 8),
    ));
  }

  final userId = MyAppState.currentUser!.userID;
  final driverId =
      MyAppState.currentUser!.userID; //'8BBDG88lB4dqRaCcLIhdonuwQtU2';
  UserBankDetails? userBankDetail = MyAppState.currentUser!.userBankDetails;
  String walletAmount = "0.0";

  paymentCompleted({required String paymentMethod}) async {
    await FireStoreUtils.createPaymentId().then((value) async {
      final paymentID = value;
      await FireStoreUtils.topUpWalletAmount(
              paymentMethod: paymentMethod,
              amount: double.parse(_amountController.text),
              id: paymentID,
              userID: MyAppState.currentUser!.userID)
          .then((value) {
        FireStoreUtils.updateWalletAmount(
                userId: userId, amount: double.parse(_amountController.text))
            .then((value) {
          FireStoreUtils.sendTopUpMail(
              paymentMethod: paymentMethod,
              amount: _amountController.text,
              tractionId: paymentID);
          ScaffoldMessenger.of(_scaffoldKey.currentContext!)
              .showSnackBar(SnackBar(
            content: Text("Payment Successful!!".tr() + "\n"),
            backgroundColor: Colors.green,
          ));
        });
      });
    });
  }

  WithdrawMethodModel? withdrawMethodModel;
  int selectedValue = 0;

  @override
  void initState() {
    print("here demo");
    print(MyAppState.currentUser!.lastOnlineTimestamp.toDate());

    print(MyAppState.currentUser!.lastOnlineTimestamp
        .toDate()
        .toString()
        .contains(DateTime.now().year.toString()));

    getData();
    getPaymentSettingData();
    selectedRadioTile = "Stripe";

    _razorPay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorPay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWaller);
    _razorPay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    // TODO: implement initState
    super.initState();
  }

  Stream<QuerySnapshot>? topupHistoryQuery;
  Razorpay _razorPay = Razorpay();
  RazorPayModel? razorPayData;
  StripeSettingData? stripeData;
  PaytmSettingData? paytmSettingData;
  PaypalSettingData? paypalSettingData;
  PayStackSettingData? payStackSettingData;
  FlutterWaveSettingData? flutterWaveSettingData;
  PayFastSettingData? payFastSettingData;
  MercadoPagoSettingData? mercadoPagoSettingData;
  MidTrans? midTransModel;
  OrangeMoney? orangeMoneyModel;
  Xendit? xenditModel;

  getPaymentSettingData() async {
    topupHistoryQuery = fireStore
        .collection(Wallet)
        .where('user_id', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots();
    userQuery = fireStore
        .collection(USERS)
        .doc(MyAppState.currentUser!.userID)
        .snapshots();

    await UserPreference.getStripeData().then((value) async {
      stripeData = value;
      stripe1.Stripe.publishableKey = stripeData!.clientpublishableKey;
      stripe1.Stripe.merchantIdentifier = 'Foodie';
      await stripe1.Stripe.instance.applySettings();
    });

    razorPayData = await UserPreference.getRazorPayData();
    paytmSettingData = await UserPreference.getPaytmData();
    paypalSettingData = await UserPreference.getPayPalData();
    payStackSettingData = await UserPreference.getPayStackData();
    flutterWaveSettingData = await UserPreference.getFlutterWaveData();
    payFastSettingData = await UserPreference.getPayFastData();
    mercadoPagoSettingData = await UserPreference.getMercadoPago();
    midTransModel = await UserPreference.getMidTransData();
    orangeMoneyModel = await UserPreference.getOrangeData();
    xenditModel = await UserPreference.getXenditData();

    await FireStoreUtils.getWithdrawMethod().then(
      (value) {
        if (value != null) {
          setState(() {
            withdrawMethodModel = value;
          });
        }
      },
    );

    setRef();
  }

  paypalPaymentSheet(String amount, context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => UsePaypal(
            sandboxMode: paypalSettingData?.isLive == true ? false : true,
            clientId: paypalSettingData?.paypalClient ?? '',
            secretKey: paypalSettingData?.paypalSecret ?? '',
            returnURL: "com.parkme://paypalpay",
            cancelURL: "com.parkme://paypalpay",
            transactions: [
              {
                "amount": {
                  "total": amount,
                  "currency": "USD",
                  "details": {"subtotal": amount}
                },
              }
            ],
            note: "Contact us for any questions on your order.",
            onSuccess: (Map params) async {
              paymentCompleted(paymentMethod: "Paypal");
              ShowToastDialog.showToast("Payment Successful!!");
            },
            onError: (error) {
              Navigator.of(context).pop();
              ShowToastDialog.showToast("Payment UnSuccessful!!");
            },
            onCancel: (params) {
              Navigator.of(context).pop();
              ShowToastDialog.showToast("Payment UnSuccessful!!");
            }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Container(
        color: Colors.black.withOpacity(0.03),
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    image: DecorationImage(
                        fit: BoxFit.fitWidth,
                        image: AssetImage("assets/images/earning_bg_@3x.png"))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        //   crossAxisAlignment: CrossAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 40,
                          ),
                          Text(
                            "Total Balance".tr(),
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 18),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 10.0, bottom: 25.0),
                            child: StreamBuilder<
                                DocumentSnapshot<Map<String, dynamic>>>(
                              stream: userQuery,
                              builder: (context,
                                  AsyncSnapshot<
                                          DocumentSnapshot<
                                              Map<String, dynamic>>>
                                      asyncSnapshot) {
                                if (asyncSnapshot.hasError) {
                                  return Text(
                                    "error".tr(),
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 30),
                                  );
                                }
                                if (asyncSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                      child: SizedBox(
                                          height: 30,
                                          width: 30,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 0.8,
                                            color: Colors.white,
                                            backgroundColor: Colors.transparent,
                                          )));
                                }
                                User userData =
                                    User.fromJson(asyncSnapshot.data!.data()!);
                                walletAmount = userData.walletAmount.toString();
                                return Text(
                                  "${amountShow(amount: userData.walletAmount.toString())}",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 35),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                            bottom: 15.0, right: 15, left: 15),
                        child: buildTopUpButton(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            tabController(),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            buildButton(context, width: 0.32, title: 'WITHDRAW'.tr(),
                onPress: () {
              if (MyAppState
                      .currentUser!.userBankDetails.accountNumber.isNotEmpty ||
                  withdrawMethodModel != null) {
                withdrawAmountBottomSheet(context);
              } else {
                ShowToastDialog.showToast("Please add payment method");
              }
            }),
            buildTransButton(context,
                width: 0.55, title: 'WITHDRAWAL HISTORY'.tr(), onPress: () {
              withdrawalHistoryBottomSheet(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget buildTopUpButton() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            topUpBalance();
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10),
              child: Text(
                "TOPUP WALLET".tr(),
                style: TextStyle(
                    color: Color(DARK_CARD_BG_COLOR),
                    fontWeight: FontWeight.w700,
                    fontSize: 16),
              ),
            ),
          ),
        ),
        SizedBox(height: 5),
        InkWell(
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => TopUpScreen()));
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10),
              child: Text(
                "TOPUP HISTORY".tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(DARK_CARD_BG_COLOR),
                    fontWeight: FontWeight.w700,
                    fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool stripe = true;

  bool razorPay = false;
  bool payTm = false;
  bool paypal = false;
  bool payStack = false;
  bool flutterWave = false;
  bool payFast = false;
  bool mercadoPago = false;
  bool xendit = false;
  bool orange = false;
  bool midtrans = false;

  topUpBalance() {
    final size = MediaQuery.of(context).size;
    return showModalBottomSheet(
        elevation: 5,
        enableDrag: true,
        useRootNavigator: true,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15), topRight: Radius.circular(15))),
        context: context,
        backgroundColor: AppThemeData.grey50,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) => Container(
              width: size.width,
              height: size.height * 0.90,
              child: Form(
                key: _globalKey,
                autovalidateMode: AutovalidateMode.always,
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15.0,
                              ),
                              child: RichText(
                                text: TextSpan(
                                  text: "Topup Wallet".tr(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: isDarkMode(context)
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 5),
                            child: RichText(
                              text: TextSpan(
                                text: "Add Topup Amount".tr(),
                                style: TextStyle(
                                    fontSize: 16,
                                    color: isDarkMode(context)
                                        ? Colors.white54
                                        : Colors.black54),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 2),
                        child: Card(
                          elevation: 2.0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 0.0, horizontal: 8),
                            child: TextFormField(
                              controller: _amountController,
                              style: TextStyle(
                                color: Color(COLOR_PRIMARY),
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                              //initialValue:"50",
                              maxLines: 1,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return "*required Field".tr();
                                } else {
                                  return null;
                                }
                              },
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      signed: true, decimal: true),
                              textInputAction: TextInputAction.done,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp('[0-9]')),
                              ],
                              decoration: InputDecoration(
                                prefix: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0, vertical: 2),
                                  child: Text(
                                    currencyData!.symbol.toString(),
                                    style: TextStyle(
                                      color: Colors.blueGrey.shade900,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 5),
                            child: RichText(
                              text: TextSpan(
                                text: "Select Payment Option".tr(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode(context)
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Visibility(
                        visible: stripeData!.isEnabled,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 3.0, horizontal: 20),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: stripe ? 0 : 2,
                            child: RadioListTile(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                      color: stripe
                                          ? Color(COLOR_PRIMARY)
                                          : Colors.transparent)),
                              controlAffinity: ListTileControlAffinity.trailing,
                              value: "Stripe",
                              groupValue: selectedRadioTile,
                              onChanged: (String? value) {
                                setState(() {
                                  flutterWave = false;
                                  stripe = true;
                                  mercadoPago = false;
                                  payFast = false;
                                  payStack = false;
                                  razorPay = false;
                                  payTm = false;
                                  paypal = false;
                                  orange = false;
                                  midtrans = false;
                                  xendit = false;
                                  selectedRadioTile = value!;
                                });
                              },
                              selected: stripe,
                              //selectedRadioTile == "strip" ? true : false,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4.0, horizontal: 10),
                                        child: SizedBox(
                                          width: 80,
                                          height: 35,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 6.0),
                                            child: Image.asset(
                                              "assets/images/stripe.png",
                                            ),
                                          ),
                                        ),
                                      )),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  Text("Stripe"),
                                ],
                              ),
                              //toggleable: true,
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: payStackSettingData!.isEnabled,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 3.0, horizontal: 20),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: payStack ? 0 : 2,
                            child: RadioListTile(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                      color: payStack
                                          ? Color(COLOR_PRIMARY)
                                          : Colors.transparent)),
                              controlAffinity: ListTileControlAffinity.trailing,
                              value: "PayStack",
                              groupValue: selectedRadioTile,
                              onChanged: (String? value) {
                                setState(() {
                                  flutterWave = false;
                                  payStack = true;
                                  mercadoPago = false;
                                  stripe = false;
                                  payFast = false;
                                  razorPay = false;
                                  payTm = false;
                                  paypal = false;
                                  orange = false;
                                  midtrans = false;
                                  xendit = false;
                                  selectedRadioTile = value!;
                                });
                              },
                              selected: payStack,
                              //selectedRadioTile == "strip" ? true : false,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4.0, horizontal: 10),
                                        child: SizedBox(
                                          width: 80,
                                          height: 35,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 6.0),
                                            child: Image.asset(
                                              "assets/images/paystack.png",
                                            ),
                                          ),
                                        ),
                                      )),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  Text("PayStack".tr()),
                                ],
                              ),
                              //toggleable: true,
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: flutterWaveSettingData != null &&
                            flutterWaveSettingData!.isEnable,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 3.0, horizontal: 20),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: flutterWave ? 0 : 2,
                            child: RadioListTile(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                      color: flutterWave
                                          ? Color(COLOR_PRIMARY)
                                          : Colors.transparent)),
                              controlAffinity: ListTileControlAffinity.trailing,
                              value: "FlutterWave",
                              groupValue: selectedRadioTile,
                              onChanged: (String? value) {
                                setState(() {
                                  flutterWave = true;
                                  payStack = false;
                                  mercadoPago = false;
                                  payFast = false;
                                  stripe = false;
                                  razorPay = false;
                                  payTm = false;
                                  paypal = false;
                                  orange = false;
                                  midtrans = false;
                                  xendit = false;
                                  selectedRadioTile = value!;
                                });
                              },
                              selected: flutterWave,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4.0, horizontal: 10),
                                        child: SizedBox(
                                          width: 80,
                                          height: 35,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 6.0),
                                            child: Image.asset(
                                              "assets/images/flutterwave.png",
                                            ),
                                          ),
                                        ),
                                      )),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  Text("FlutterWave".tr()),
                                ],
                              ),
                              //toggleable: true,
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: razorPayData!.isEnabled,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 3.0, horizontal: 20),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: razorPay ? 0 : 2,
                            child: RadioListTile(
                              //toggleable: true,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                      color: razorPay
                                          ? Color(COLOR_PRIMARY)
                                          : Colors.transparent)),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              controlAffinity: ListTileControlAffinity.trailing,
                              value: "RazorPay",
                              groupValue: selectedRadioTile,
                              onChanged: (String? value) {
                                setState(() {
                                  mercadoPago = false;
                                  flutterWave = false;
                                  stripe = false;
                                  razorPay = true;
                                  payTm = false;
                                  payFast = false;
                                  paypal = false;
                                  payStack = false;
                                  orange = false;
                                  midtrans = false;
                                  xendit = false;
                                  selectedRadioTile = value!;
                                });
                              },
                              selected: razorPay,
                              //selectedRadioTile == "strip" ? true : false,
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 3.0, horizontal: 10),
                                        child: SizedBox(
                                            width: 80,
                                            height: 35,
                                            child: Image.asset(
                                                "assets/images/razorpay_@3x.png")),
                                      )),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  Text("RazorPay").tr(),
                                ],
                              ),
                              //toggleable: true,
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: payFastSettingData != null &&
                            payFastSettingData!.isEnable,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 20),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: payFast ? 0 : 2,
                            child: RadioListTile(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                      color: payFast
                                          ? Color(COLOR_PRIMARY)
                                          : Colors.transparent)),
                              controlAffinity: ListTileControlAffinity.trailing,
                              value: "payFast",
                              groupValue: selectedRadioTile,
                              onChanged: (String? value) {
                                setState(() {
                                  payFast = true;
                                  stripe = false;
                                  mercadoPago = false;
                                  razorPay = false;
                                  payStack = false;
                                  flutterWave = false;
                                  payTm = false;
                                  paypal = false;
                                  orange = false;
                                  midtrans = false;
                                  xendit = false;
                                  selectedRadioTile = value!;
                                });
                              },
                              selected: payFast,
                              //selectedRadioTile == "strip" ? true : false,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4.0, horizontal: 10),
                                        child: SizedBox(
                                          width: 80,
                                          height: 35,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 6.0),
                                            child: Image.asset(
                                              "assets/images/payfast.png",
                                            ),
                                          ),
                                        ),
                                      )),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  Text("Pay Fast"),
                                ],
                              ),
                              //toggleable: true,
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: paytmSettingData!.isEnabled,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 3.0, horizontal: 20),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: payTm ? 0 : 2,
                            child: RadioListTile(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                      color: payTm
                                          ? Color(COLOR_PRIMARY)
                                          : Colors.transparent)),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              controlAffinity: ListTileControlAffinity.trailing,
                              value: "PayTm",
                              groupValue: selectedRadioTile,
                              onChanged: (String? value) {
                                setState(() {
                                  stripe = false;
                                  flutterWave = false;
                                  payTm = true;
                                  mercadoPago = false;
                                  razorPay = false;
                                  paypal = false;
                                  payFast = false;
                                  payStack = false;
                                  orange = false;
                                  midtrans = false;
                                  xendit = false;
                                  selectedRadioTile = value!;
                                });
                              },
                              selected: payTm,
                              //selectedRadioTile == "strip" ? true : false,
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 3.0, horizontal: 10),
                                        child: SizedBox(
                                            width: 80,
                                            height: 35,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 3.0),
                                              child: Image.asset(
                                                "assets/images/paytm_@3x.png",
                                              ),
                                            )),
                                      )),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  Text("Paytm"),
                                ],
                              ),
                              //toggleable: true,
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: mercadoPagoSettingData != null &&
                            mercadoPagoSettingData!.isEnabled,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 20),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: mercadoPago ? 0 : 2,
                            child: RadioListTile(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                      color: mercadoPago
                                          ? Color(COLOR_PRIMARY)
                                          : Colors.transparent)),
                              controlAffinity: ListTileControlAffinity.trailing,
                              value: "MercadoPago",
                              groupValue: selectedRadioTile,
                              onChanged: (String? value) {
                                setState(() {
                                  mercadoPago = true;
                                  payFast = false;
                                  stripe = false;
                                  razorPay = false;
                                  payStack = false;
                                  flutterWave = false;
                                  payTm = false;
                                  paypal = false;
                                  orange = false;
                                  midtrans = false;
                                  xendit = false;
                                  selectedRadioTile = value!;
                                });
                              },
                              selected: mercadoPago,
                              //selectedRadioTile == "strip" ? true : false,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4.0, horizontal: 10),
                                        child: SizedBox(
                                          width: 80,
                                          height: 35,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 6.0),
                                            child: Image.asset(
                                              "assets/images/mercadopago.png",
                                            ),
                                          ),
                                        ),
                                      )),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  Text("Mercado Pago"),
                                ],
                              ),
                              //toggleable: true,
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: paypalSettingData != null &&
                            paypalSettingData!.isEnabled,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 3.0, horizontal: 20),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: paypal ? 0 : 2,
                            child: RadioListTile(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                      color: paypal
                                          ? Color(COLOR_PRIMARY)
                                          : Colors.transparent)),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              controlAffinity: ListTileControlAffinity.trailing,
                              value: "PayPal",
                              groupValue: selectedRadioTile,
                              onChanged: (String? value) {
                                setState(() {
                                  stripe = false;
                                  payTm = false;
                                  mercadoPago = false;
                                  flutterWave = false;
                                  razorPay = false;
                                  paypal = true;
                                  payFast = false;
                                  payStack = false;
                                  orange = false;
                                  midtrans = false;
                                  xendit = false;
                                  selectedRadioTile = value!;
                                });
                              },
                              selected: paypal,
                              //selectedRadioTile == "strip" ? true : false,
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 3.0, horizontal: 10),
                                        child: SizedBox(
                                            width: 80,
                                            height: 35,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 3.0),
                                              child: Image.asset(
                                                  "assets/images/paypal_@3x.png"),
                                            )),
                                      )),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  Text("PayPal"),
                                ],
                              ),
                              //toggleable: true,
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: xenditModel!.enable ?? false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 3.0, horizontal: 20),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: xendit ? 0 : 2,
                            child: RadioListTile(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                      color: xendit
                                          ? AppThemeData.primary300
                                          : Colors.transparent)),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              controlAffinity: ListTileControlAffinity.trailing,
                              value: "Xendit",
                              groupValue: selectedRadioTile,
                              onChanged: (String? value) {
                                print(value);
                                setState(() {
                                  stripe = false;
                                  payTm = false;
                                  mercadoPago = false;
                                  flutterWave = false;
                                  razorPay = false;
                                  paypal = false;
                                  payFast = false;
                                  payStack = false;
                                  orange = false;
                                  midtrans = false;
                                  xendit = true;
                                  selectedRadioTile = value!;
                                });
                              },
                              selected: xendit,
                              //selectedRadioTile == "strip" ? true : false,
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 3.0, horizontal: 10),
                                        child: SizedBox(
                                            width: 80,
                                            height: 35,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 3.0),
                                              child: Image.asset(
                                                  "assets/images/xendit.png"),
                                            )),
                                      )),
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  const Text("Xendit").tr(),
                                ],
                              ),
                              //toggleable: true,
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: orangeMoneyModel!.enable ?? false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 3.0, horizontal: 20),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: orange ? 0 : 2,
                            child: RadioListTile(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                      color: orange
                                          ? AppThemeData.primary300
                                          : Colors.transparent)),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              controlAffinity: ListTileControlAffinity.trailing,
                              value: "OrangeMoney",
                              groupValue: selectedRadioTile,
                              onChanged: (String? value) {
                                print(value);
                                setState(() {
                                  stripe = false;
                                  payTm = false;
                                  mercadoPago = false;
                                  flutterWave = false;
                                  razorPay = false;
                                  paypal = false;
                                  payFast = false;
                                  payStack = false;
                                  orange = true;
                                  midtrans = false;
                                  xendit = false;
                                  selectedRadioTile = value!;
                                });
                              },
                              selected: orange,
                              //selectedRadioTile == "strip" ? true : false,
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 3.0, horizontal: 10),
                                        child: SizedBox(
                                            width: 80,
                                            height: 35,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 3.0),
                                              child: Image.asset(
                                                  "assets/images/orange_money.png"),
                                            )),
                                      )),
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  const Text("OrangeMoney").tr(),
                                ],
                              ),
                              //toggleable: true,
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: midTransModel!.enable ?? false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 3.0, horizontal: 20),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: midtrans ? 0 : 2,
                            child: RadioListTile(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                      color: midtrans
                                          ? AppThemeData.primary300
                                          : Colors.transparent)),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              controlAffinity: ListTileControlAffinity.trailing,
                              value: "Midtrans",
                              groupValue: selectedRadioTile,
                              onChanged: (String? value) {
                                print(value);
                                setState(() {
                                  stripe = false;
                                  payTm = false;
                                  mercadoPago = false;
                                  flutterWave = false;
                                  razorPay = false;
                                  paypal = false;
                                  payFast = false;
                                  payStack = false;
                                  orange = false;
                                  midtrans = true;
                                  xendit = false;
                                  selectedRadioTile = value!;
                                });
                              },
                              selected: midtrans,
                              //selectedRadioTile == "strip" ? true : false,
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 3.0, horizontal: 10),
                                        child: SizedBox(
                                            width: 80,
                                            height: 35,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 3.0),
                                              child: Image.asset(
                                                  "assets/images/midtrans.png"),
                                            )),
                                      )),
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  const Text("Midtrans").tr(),
                                ],
                              ),
                              //toggleable: true,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 22),
                        child: GestureDetector(
                          onTap: () async {
                            await FireStoreUtils.createPaymentId();

                            if (selectedRadioTile == "Stripe" &&
                                stripeData?.isEnabled == true) {
                              Navigator.pop(context);
                              showLoadingAlert();
                              stripeMakePayment(amount: _amountController.text);
                              //push(context, CardDetailsScreen(paymentMode: selectedRadioTile,),);
                            } else if (selectedRadioTile == "MercadoPago") {
                              Navigator.pop(context);
                              mercadoPagoMakePayment();
                            } else if (selectedRadioTile == "payFast") {
                              showLoadingAlert();
                              PayStackURLGen.getPayHTML(
                                      payFastSettingData: payFastSettingData!,
                                      amount: _amountController.text)
                                  .then((value) async {
                                bool isDone = await Navigator.of(context)
                                    .push(MaterialPageRoute(
                                        builder: (context) => PayFastScreen(
                                              htmlData: value,
                                              payFastSettingData:
                                                  payFastSettingData!,
                                            )));
                                if (isDone) {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                  paymentCompleted(paymentMethod: "payFast");
                                } else {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                      "Payment Unsuccessful!!".tr() + "\n",
                                    ),
                                    backgroundColor: Colors.red.shade400,
                                    duration: Duration(seconds: 6),
                                  ));
                                }
                              });
                            } else if (selectedRadioTile == "RazorPay") {
                              Navigator.pop(context);
                              showLoadingAlert();
                              RazorPayController()
                                  .createOrderRazorPay(
                                      amount: int.parse(_amountController.text))
                                  .then((value) {
                                if (value != null) {
                                  CreateRazorPayOrderModel result = value;
                                  print("RAZORPAY");
                                  print(value);

                                  openCheckout(
                                    amount: _amountController.text,
                                    orderId: result.id,
                                  );
                                } else {
                                  Navigator.pop(context);
                                  showAlert(_globalKey.currentContext!,
                                      response:
                                          "Something went wrong, please contact admin."
                                              .tr(),
                                      colors: Colors.red);
                                }
                              });
                            } else if (selectedRadioTile == "PayPal") {
                              Navigator.pop(context);
                              showLoadingAlert();
                              //_paypalPayment();
                              paypalPaymentSheet(
                                  _amountController.text, context);
                            } else if (selectedRadioTile == "PayStack") {
                              Navigator.pop(context);
                              showLoadingAlert();
                              payStackPayment();
                            } else if (selectedRadioTile == "FlutterWave") {
                              _flutterWaveInitiatePayment(context);
                            } else if (selectedRadioTile == "Midtrans") {
                              midtransMakePayment(
                                  context: context,
                                  amount: _amountController.text);
                            } else if (selectedRadioTile == "OrangeMoney") {
                              orangeMakePayment(
                                  context: context,
                                  amount: _amountController.text);
                            } else if (selectedRadioTile == "Xendit") {
                              xenditPayment(context, _amountController.text);
                            }
                          },
                          child: Container(
                            height: 45,
                            decoration: BoxDecoration(
                              color: Color(COLOR_PRIMARY),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                                child: Text(
                              "CONTINUE".tr(),
                              style: TextStyle(color: Colors.white),
                            )),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }

  ///FlutterWave Payment Method
  String? _ref;

  setRef() {
    Random numRef = Random();
    int year = DateTime.now().year;
    int refNumber = numRef.nextInt(20000);
    if (Platform.isAndroid) {
      setState(() {
        _ref = "AndroidRef$year$refNumber";
      });
    } else if (Platform.isIOS) {
      setState(() {
        _ref = "IOSRef$year$refNumber";
      });
    }
  }

  _flutterWaveInitiatePayment(BuildContext context) async {
    final url = Uri.parse('https://api.flutterwave.com/v3/payments');
    final headers = {
      'Authorization': 'Bearer ${flutterWaveSettingData!.secretKey}',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "tx_ref": _ref,
      "amount": _amountController.value.text,
      "currency": "NGN",
      "redirect_url": "${GlobalURL}payment/success",
      "payment_options": "ussd, card, barter, payattitude",
      "customer": {
        "email": MyAppState.currentUser!.email.toString(),
        "phonenumber":
            MyAppState.currentUser!.phoneNumber, // Add a real phone number
        "name": MyAppState.currentUser!.fullName(), // Add a real customer name
      },
      "customizations": {
        "title": "Payment for Services",
        "description": "Payment for XYZ services",
      }
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final bool isDone = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  MercadoPagoScreen(initialURl: data['data']['link'])));

      if (isDone) {
        ShowToastDialog.showToast("Payment Successful!!");
        paymentCompleted(paymentMethod: "FlutterWave");
      } else {
        ShowToastDialog.showToast("Payment UnSuccessful!!");
      }
    } else {
      print('Payment initialization failed: ${response.body}');
      return null;
    }
  }

  Future<void> showLoading(
      {required String message, Color txtColor = Colors.black}) {
    return showDialog(
      context: this.context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Container(
            margin: EdgeInsets.fromLTRB(30, 20, 30, 20),
            width: double.infinity,
            height: 30,
            child: Text(
              message,
              style: TextStyle(color: txtColor),
            ),
          ),
        );
      },
    );
  }

  ///PayStack Payment Method
  payStackPayment() async {
    await PayStackURLGen.payStackURLGen(
      amount: (double.parse(_amountController.text) * 100).toString(),
      currency: currencyData!.code,
      secretKey: payStackSettingData!.secretKey,
    ).then((value) async {
      if (value != null) {
        PayStackUrlModel _payStackModel = value;

        bool isDone = await Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => PayStackScreen(
                  secretKey: payStackSettingData!.secretKey,
                  callBackUrl: payStackSettingData!.callbackURL,
                  initialURl: _payStackModel.data.authorizationUrl,
                  amount: _amountController.text,
                  reference: _payStackModel.data.reference,
                )));
        Navigator.pop(_scaffoldKey.currentContext!);

        if (isDone) {
          paymentCompleted(paymentMethod: "PayStack");
        } else {
          hideProgress();
          ScaffoldMessenger.of(_scaffoldKey.currentContext!)
              .showSnackBar(SnackBar(
            content: Text("Payment UnSuccessful!!".tr() + "\n"),
            backgroundColor: Colors.red,
          ));
        }
      } else {
        hideProgress();

        ScaffoldMessenger.of(_scaffoldKey.currentContext!)
            .showSnackBar(SnackBar(
          content: Text("Error while transaction!".tr() + "\n"),
          backgroundColor: Colors.red,
        ));
      }
    });
  }

  /// PayPal Payment Gateway

  // _paypalPayment() async {
  //   PayPalClientTokenGen.paypalClientToken(
  //           paypalSettingData: paypalSettingData!)
  //       .then((value) async {
  //     final String tokenizationKey = paypalSettingData!
  //         .braintreeTokenizationKey; //"sandbox_w3dpbsks_5whrtf2sbrp4vx74";
  //
  //     var request = BraintreePayPalRequest(
  //         amount: _amountController.text,
  //         currencyCode: currencyData!.code,
  //         billingAgreementDescription: "djsghxghf",
  //         displayName: 'Foodies company');
  //
  //     BraintreePaymentMethodNonce? resultData;
  //
  //     try {
  //       resultData =
  //           await Braintree.requestPaypalNonce(tokenizationKey, request);
  //     } on Exception catch (ex) {
  //       print("Stripe error");
  //       showAlert(context,
  //           response:
  //               "Something went wrong, please contact admin.".tr() + " $ex",
  //           colors: Colors.red);
  //     }
  //     print(resultData?.nonce);
  //     print(resultData?.paypalPayerId);
  //     if (resultData?.nonce != null) {
  //       PayPalClientTokenGen.paypalSettleAmount(
  //         paypalSettingData: paypalSettingData!,
  //         nonceFromTheClient: resultData?.nonce,
  //         amount: _amountController.text,
  //         deviceDataFromTheClient: resultData?.typeLabel,
  //       ).then((value) {
  //         if (value['success'] == "true" || value['success'] == true) {
  //           if (value['data']['success'] == "true" ||
  //               value['data']['success'] == true) {
  //             payPalSettel.PayPalClientSettleModel settleResult =
  //                 payPalSettel.PayPalClientSettleModel.fromJson(value);
  //             if (settleResult.data.success) {
  //               Navigator.pop(context);
  //               ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //                 content: Text(
  //                   "Status : ${settleResult.data.transaction.status}\n"
  //                   "Transaction id : ${settleResult.data.transaction.id}\n"
  //                   "Amount : ${settleResult.data.transaction.amount}",
  //                 ),
  //                 duration: Duration(seconds: 8),
  //                 backgroundColor: Colors.green,
  //               ));
  //
  //               paymentCompleted(paymentMethod: "Paypal");
  //             }
  //           } else {
  //             payPalCurrModel.PayPalCurrencyCodeErrorModel settleResult =
  //                 payPalCurrModel.PayPalCurrencyCodeErrorModel.fromJson(value);
  //             Navigator.pop(_scaffoldKey.currentContext!);
  //             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //               content:
  //                   Text("Status :".tr() + " ${settleResult.data.message}"),
  //               duration: Duration(seconds: 8),
  //               backgroundColor: Colors.red,
  //             ));
  //           }
  //         } else {
  //           PayPalErrorSettleModel settleResult =
  //               PayPalErrorSettleModel.fromJson(value);
  //           Navigator.pop(_scaffoldKey.currentContext!);
  //           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //             content: Text("Status :".tr() + " ${settleResult.data.message}"),
  //             duration: Duration(seconds: 8),
  //             backgroundColor: Colors.red,
  //           ));
  //         }
  //       });
  //     } else {
  //       Navigator.pop(_scaffoldKey.currentContext!);
  //       ScaffoldMessenger.of(_scaffoldKey.currentContext!)
  //           .showSnackBar(SnackBar(
  //         content: Text('Status : Payment Incomplete!!'.tr()),
  //         duration: Duration(seconds: 8),
  //         backgroundColor: Colors.red,
  //       ));
  //     }
  //   });
  // }

  /// Stripe Payment Gateway
  Future<void> stripeMakePayment({required String amount}) async {
    try {
      paymentIntentData = await createStripeIntent(
        amount,
      );
      if (paymentIntentData!.containsKey("error")) {
        Navigator.pop(context);
        showAlert(_scaffoldKey.currentContext,
            response: "Something went wrong, please contact admin.".tr(),
            colors: Colors.red);
      } else {
        await stripe1.Stripe.instance
            .initPaymentSheet(
                paymentSheetParameters: stripe1.SetupPaymentSheetParameters(
              paymentIntentClientSecret: paymentIntentData!['client_secret'],
              applePay: const stripe1.PaymentSheetApplePay(
                merchantCountryCode: 'US',
              ),
              allowsDelayedPaymentMethods: false,
              googlePay: stripe1.PaymentSheetGooglePay(
                merchantCountryCode: 'US',
                testEnv: true,
                currencyCode: currencyData!.code,
              ),
              style: ThemeMode.system,
              customFlow: true,
              appearance: stripe1.PaymentSheetAppearance(
                colors: stripe1.PaymentSheetAppearanceColors(
                  primary: Color(COLOR_PRIMARY),
                ),
              ),
              merchantDisplayName: 'Emart',
            ))
            .then((value) {});
        setState(() {});
        displayStripePaymentSheet();
      }
    } catch (e, s) {
      print('exception:$e$s');
    }
  }

  displayStripePaymentSheet() async {
    try {
      await stripe1.Stripe.instance.presentPaymentSheet().then((value) {
        paymentCompleted(paymentMethod: "Stripe");
        Navigator.pop(context);
        paymentIntentData = null;
      });
    } on stripe1.StripeException catch (e) {
      Navigator.pop(context);
      var lo1 = jsonEncode(e);
      var lo2 = jsonDecode(lo1);
      StripePayFailedModel lom = StripePayFailedModel.fromJson(lo2);
      showDialog(
          context: context,
          builder: (_) => AlertDialog(
                content: Text("${lom.error.message}"),
              ));
    } catch (e) {
      print('$e');
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("$e"),
        duration: Duration(seconds: 8),
        backgroundColor: Colors.red,
      ));
    }
  }

  createStripeIntent(
    String amount,
  ) async {
    try {
      Map<String, dynamic> body = {
        'amount': calculateAmount(amount),
        'currency': currencyData!.code,
        'payment_method_types[0]': 'card',
        // 'payment_method_types[1]': 'ideal',
        "description": "${MyAppState.currentUser?.userID} Wallet Topup",
        "shipping[name]":
            "${MyAppState.currentUser?.firstName} ${MyAppState.currentUser?.lastName}",
        "shipping[address][line1]": "510 Townsend St",
        "shipping[address][postal_code]": "98140",
        "shipping[address][city]": "San Francisco",
        "shipping[address][state]": "CA",
        "shipping[address][country]": "US",
      };
      var response = await http.post(
          Uri.parse('https://api.stripe.com/v1/payment_intents'),
          body: body,
          headers: {
            'Authorization': 'Bearer ${stripeData?.stripeSecret}',
            //$_paymentIntentClientSecret',
            'Content-Type': 'application/x-www-form-urlencoded'
          });
      return jsonDecode(response.body);
    } catch (err) {
      print('error charging user: ${err.toString()}');
    }
  }

  calculateAmount(String amount) {
    final a = (int.parse(amount)) * 100;
    return a.toString();
  }

  /// RazorPay Payment Gateway
  void openCheckout({required amount, required orderId}) async {
    var options = {
      'key': razorPayData!.razorpayKey,
      'amount': amount * 100,
      'name': 'Foodies',
      'order_id': orderId,
      "currency": currencyData?.code,
      'description': 'wallet Topup',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': MyAppState.currentUser!.phoneNumber,
        'email': MyAppState.currentUser!.email,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorPay.open(options);
    } catch (e) {
      debugPrint('error'.tr() + ': $e');
    }
  }

  ///MercadoPago Payment Method

  mercadoPagoMakePayment() async {
    try {
      final headers = {
        'Authorization': 'Bearer ${mercadoPagoSettingData!.accessToken}',
        'Content-Type': 'application/json',
      };

      final body = jsonEncode({
        "items": [
          {
            "title": "Test",
            "quantity": 1,
            "currency_id": "BRL", // Replace with the correct currency
            "unit_price": double.parse(_amountController.value.text),
          }
        ],
        "payer": {"email": MyAppState.currentUser!.email},
        "back_urls": {
          "failure": "${GlobalURL}payment/failure",
          "pending": "${GlobalURL}payment/pending",
          "success": "${GlobalURL}payment/success",
        },
        "auto_return":
            "approved" // Automatically return after payment is approved
      });

      final response = await http.post(
        Uri.parse("https://api.mercadopago.com/checkout/preferences"),
        headers: headers,
        body: body,
      );

      print(response.statusCode);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final bool isDone = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    MercadoPagoScreen(initialURl: data['init_point'])));

        if (isDone) {
          ShowToastDialog.showToast("Payment Successful!!");
          paymentCompleted(paymentMethod: "Mercoado");
        } else {
          ShowToastDialog.showToast("Payment UnSuccessful!!");
        }
      } else {
        print('Error creating preference: ${response.body}');
        return null;
      }
    } catch (e) {
      print("=======>");
      print(e);
    }
  }

  /// Paytm Payment Gateway
  bool isStaging = true;
  String callbackUrl =
      "http://162.241.125.167/~foodie/payments/paytmpaymentcallback?ORDER_ID=";
  bool restrictAppInvoke = false;
  bool enableAssist = true;
  String result = "";

  getPaytmCheckSum(
    context, {
    required double amount,
  }) async {
    final String orderId = UserPreference.getPaymentId();
    String getChecksum = "${GlobalURL}payments/getpaytmchecksum";

    final response = await http.post(
        Uri.parse(
          getChecksum,
        ),
        headers: {},
        body: {
          "mid": paytmSettingData?.paytmMID,
          "order_id": orderId,
          "key_secret": paytmSettingData?.paytmMerchantKey,
        });

    final data = jsonDecode(response.body);

    await verifyCheckSum(
            checkSum: data["code"], amount: amount, orderId: orderId)
        .then((value) {
      initiatePayment(context, amount: amount, orderId: orderId).then((value) {
        GetPaymentTxtTokenModel result = value;
        String callback = "";
        if (paytmSettingData!.isSandboxEnabled) {
          callback = callback +
              "https://securegw-stage.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
        } else {
          callback = callback +
              "https://securegw.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
        }

        _startTransaction(
          context,
          txnTokenBy: result.body.txnToken,
          orderId: orderId,
          amount: amount,
        );
      });
    });
  }

  Future<GetPaymentTxtTokenModel> initiatePayment(BuildContext context,
      {required double amount, required orderId}) async {
    String initiateURL = "${GlobalURL}payments/initiatepaytmpayment";
    String callback = "";
    if (paytmSettingData!.isSandboxEnabled) {
      callback = callback +
          "https://securegw-stage.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
    } else {
      callback = callback +
          "https://securegw.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
    }
    final response = await http.post(
        Uri.parse(
          initiateURL,
        ),
        headers: {},
        body: {
          "mid": paytmSettingData?.paytmMID,
          "order_id": orderId,
          "key_secret": paytmSettingData?.paytmMerchantKey.toString(),
          "amount": amount.toString(),
          "currency": currencyData!.code,
          "callback_url": callback,
          "custId": MyAppState.currentUser!.userID,
          "issandbox": paytmSettingData!.isSandboxEnabled ? "1" : "2",
        });
    final data = jsonDecode(response.body);
    if (data["body"]["txnToken"] == null ||
        data["body"]["txnToken"].toString().isEmpty) {
      Navigator.pop(_scaffoldKey.currentContext!);
      showAlert(_scaffoldKey.currentContext!,
          response: "something went wrong, please contact admin.".tr(),
          colors: Colors.red);
    }
    return GetPaymentTxtTokenModel.fromJson(data);
  }

  Future<void> _startTransaction(context,
      {required String txnTokenBy,
      required orderId,
      required double amount}) async {
    // try {
    //   var response = AllInOneSdk.startTransaction(
    //     paytmSettingData!.paytmMID,
    //     orderId,
    //     amount.toString(),
    //     txnTokenBy,
    //     "https://securegw-stage.paytm.in/theia/paytmCallback?ORDER_ID=$orderId",
    //     isStaging,
    //     true,
    //     enableAssist,
    //   );
    //
    //   response.then((value) {
    //     if (value!["RESPMSG"] == "Txn Success") {
    //       paymentCompleted(paymentMethod: "Paytm");
    //     }
    //   }).catchError((onError) {
    //     if (onError is PlatformException) {
    //       Navigator.pop(_scaffoldKey.currentContext!);
    //
    //       result = onError.message.toString() + " \n  " + onError.code.toString();
    //       showAlert(_scaffoldKey.currentContext!, response: onError.message.toString(), colors: Colors.red);
    //     } else {
    //       result = onError.toString();
    //       Navigator.pop(_scaffoldKey.currentContext!);
    //       showAlert(_scaffoldKey.currentContext!, response: result, colors: Colors.red);
    //     }
    //   });
    // } catch (err) {
    //   result = err.toString();
    //   Navigator.pop(_scaffoldKey.currentContext!);
    //   showAlert(_scaffoldKey.currentContext!, response: result, colors: Colors.red);
    // }
  }

  Future verifyCheckSum(
      {required String checkSum,
      required double amount,
      required orderId}) async {
    String getChecksum = "${GlobalURL}payments/validatechecksum";
    final response = await http.post(
        Uri.parse(
          getChecksum,
        ),
        headers: {},
        body: {
          "mid": paytmSettingData?.paytmMID,
          "order_id": orderId,
          "key_secret": paytmSettingData?.paytmMerchantKey,
          "checksum_value": checkSum,
        });
    final data = jsonDecode(response.body);
    return data['status'];
  }

  tabController() {
    return Expanded(
      child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Container(
                  height: 40,
                  child: TabBar(
                    //indicator: BoxDecoration(color: const Color(COLOR_PRIMARY), borderRadius: BorderRadius.circular(2.0)),
                    indicatorColor: Color(COLOR_PRIMARY),
                    labelColor: Color(COLOR_PRIMARY),
                    automaticIndicatorColorAdjustment: true,
                    dragStartBehavior: DragStartBehavior.start,
                    unselectedLabelColor:
                        isDarkMode(context) ? Colors.white70 : Colors.black54,
                    indicatorWeight: 1.5,
                    //indicatorPadding: EdgeInsets.symmetric(horizontal: 10),
                    enableFeedback: true,
                    //unselectedLabelColor: const Colors,
                    tabs: [
                      Tab(text: 'Daily'.tr()),
                      Tab(
                        text: 'Monthly'.tr(),
                      ),
                      Tab(
                        text: 'Yearly'.tr(),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: TabBarView(
                    children: [
                      showEarningsHistory(context, query: dailyEarningQuery),
                      showEarningsHistory(context, query: monthlyEarningQuery),
                      showEarningsHistory(context, query: yearlyEarningQuery),
                    ],
                  ),
                ),
              )
            ],
          )),
    );
  }

  Widget showEarningsHistory(BuildContext context,
      {required Stream<QuerySnapshot>? query}) {
    return StreamBuilder<QuerySnapshot>(
      stream: query,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: SizedBox(
                  height: 35, width: 35, child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          return ListView(
            shrinkWrap: true,
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              final earningData;
              print("-------->" + MyAppState.currentUser!.serviceType);
              if (MyAppState.currentUser!.serviceType == "cab-service") {
                earningData = CabOrderModel.fromJson(
                    document.data() as Map<String, dynamic>);
              } else if (MyAppState.currentUser!.serviceType ==
                  "parcel_delivery") {
                earningData = ParcelOrderModel.fromJson(
                    document.data() as Map<String, dynamic>);
              } else if (MyAppState.currentUser!.serviceType ==
                  "rental-service") {
                earningData = RentalOrderModel.fromJson(
                    document.data() as Map<String, dynamic>);
              } else {
                earningData = OrderModel.fromJson(
                    document.data() as Map<String, dynamic>);
              }

              return buildEarningCard(
                orderModel: earningData,
              );
            }).toList(),
          );
        } else {
          return Center(
              child: Text(
            "No Transaction History".tr(),
            style: TextStyle(fontSize: 18),
          ));
        }
      },
    );
  }

  Widget buildEarningCard({required var orderModel}) {
    final size = MediaQuery.of(context).size;
    double amount = 0;
    double adminComm = 0.0;
    if (MyAppState.currentUser!.serviceType == "cab-service") {
      double totalTax = 0.0;
      if (orderModel!.taxModel != null) {
        for (var element in orderModel!.taxModel!) {
          totalTax = totalTax +
              calculateTax(
                  amount: (double.parse(orderModel.subTotal.toString()) -
                          double.parse(orderModel.discount.toString()))
                      .toString(),
                  taxModel: element);
        }
      }
      print(totalTax);
      double subTotal = double.parse(orderModel.subTotal.toString()) -
          double.parse(orderModel.discount.toString());
      // double adminComm = 0.0;
      if (orderModel.adminCommission!.isNotEmpty) {
        adminComm = (orderModel.adminCommissionType!.toLowerCase() ==
                    'Percent'.toLowerCase() ||
                orderModel.adminCommissionType!.toLowerCase() ==
                    'percentage'.toLowerCase())
            ? (subTotal * double.parse(orderModel.adminCommission!)) / 100
            : double.parse(orderModel.adminCommission!);
      }

      print("--->finalAmount---- $subTotal");
      double tipValue = orderModel.tipValue!.isEmpty
          ? 0.0
          : double.parse(orderModel.tipValue.toString());
      amount = subTotal + totalTax + tipValue;
      adminComm = adminComm;
    } else if (MyAppState.currentUser!.serviceType == "parcel_delivery") {
      double totalTax = 0.0;
      if (orderModel!.taxModel != null) {
        for (var element in orderModel!.taxModel!) {
          totalTax = totalTax +
              calculateTax(
                  amount: (double.parse(orderModel.subTotal.toString()) -
                          double.parse(orderModel.discount.toString()))
                      .toString(),
                  taxModel: element);
        }
      }
      double subTotal = double.parse(orderModel.subTotal.toString()) -
          double.parse(orderModel.discount.toString());
      // double adminComm = 0.0;
      if (orderModel.adminCommission!.isNotEmpty) {
        adminComm = (orderModel.adminCommissionType == 'Percent' ||
                orderModel.adminCommissionType == 'percentage')
            ? (subTotal * double.parse(orderModel.adminCommission!)) / 100
            : double.parse(orderModel.adminCommission!);
      }

      print("--->finalAmount---- $subTotal");
      amount = subTotal + totalTax;
      adminComm = adminComm;
    } else if (MyAppState.currentUser!.serviceType == "rental-service") {
      double totalTax = 0.0;
      double subTotal = (double.parse(orderModel.subTotal.toString()) +
              double.parse(orderModel.driverRate.toString())) -
          double.parse(orderModel.discount.toString());

      if (orderModel!.taxModel != null) {
        for (var element in orderModel!.taxModel!) {
          totalTax = totalTax +
              calculateTax(amount: (subTotal.toString()), taxModel: element);
        }
      }
      // double adminComm = 0.0;
      if (orderModel.adminCommission!.isNotEmpty) {
        adminComm = (orderModel.adminCommissionType == 'Percent' ||
                orderModel.adminCommissionType == 'percentage')
            ? (subTotal * double.parse(orderModel.adminCommission!)) / 100
            : double.parse(orderModel.adminCommission!);
      }

      amount = subTotal + totalTax;
      adminComm = adminComm;
    } else {
      if (orderModel.deliveryCharge != null &&
          orderModel.deliveryCharge!.isNotEmpty) {
        amount += double.parse(orderModel.deliveryCharge!);
      }

      if (orderModel.tipValue != null && orderModel.tipValue!.isNotEmpty) {
        amount += double.parse(orderModel.tipValue!);
      }
    }
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3),
        child: MyAppState.currentUser!.serviceType == "delivery-service"
            ? Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15.0, vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: size.width * 0.52,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${DateFormat('dd-MM-yyyy, KK:mma').format(orderModel.createdAt.toDate()).toUpperCase()}",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 17,
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Opacity(
                              opacity: 0.75,
                              child: Text(
                                orderModel.status,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 17,
                                  color: orderModel.status == "Order Completed".tr()
                                      ? Colors.green
                                      : Colors.deepOrangeAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 3.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              " ${amountShow(amount: amount.toString())}",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: orderModel.status == "Order Completed".tr()
                                    ? amount < 0
                                        ? Colors.red
                                        : Colors.green
                                    : Colors.deepOrange,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            // Icon(
                            //   Icons.arrow_forward_ios,
                            //   size: 15,
                            // )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : GestureDetector(
                onTap: () => showTransactionDetails(orderModel: orderModel),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 2.0, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: Container(
                            color: Color(COLOR_PRIMARY).withOpacity(0.06),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Icon(Icons.account_balance_wallet_rounded,
                                  size: 28, color: Color(COLOR_PRIMARY)),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: size.width * 0.78,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: size.width * 0.48,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Order Amount".tr(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                      "Admin commission Deducted".tr(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Opacity(
                                      opacity: 0.65,
                                      child: Text(
                                        "${DateFormat('KK:mm:ss a, dd MMM yyyy').format(orderModel.createdAt.toDate()).toUpperCase()}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.only(right: 4.0, left: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      // "(${orderModel.paymentMethod.toLowerCase() != "cod" ? "+" : "-"} ${amountShow(amount: amount.toString())})",
                                      orderModel.paymentMethod.toLowerCase() !=
                                              "cod"
                                          ? "${"+"} ${amountShow(amount: amount.toString())}"
                                          : "(${"-"} ${amountShow(amount: amount.toString())})",

                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: orderModel.paymentMethod
                                                    .toLowerCase() !=
                                                "cod"
                                            ? Colors.green
                                            : Colors.red,
                                        fontSize: 18,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 8,
                                    ),
                                    Text(
                                      //  "${orderModel.paymentMethod.toLowerCase() != "cod" ? "+" : "-"} ${amountShow(amount: adminComm.toString())}",
                                      "(-${amountShow(amount: adminComm.toString())})",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red,
                                        fontSize: 18,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 8,
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 15,
                                    )
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
              ));
  }

  showTransactionDetails({required orderModel}) {
    double amount = 0;
    double adminComm = 0.0;
    if (MyAppState.currentUser!.serviceType == "cab-service") {
      double totalTax = 0.0;
      if (orderModel!.taxModel != null) {
        for (var element in orderModel!.taxModel!) {
          totalTax = totalTax +
              calculateTax(
                  amount: (double.parse(orderModel.subTotal.toString()) -
                          double.parse(orderModel.discount.toString()))
                      .toString(),
                  taxModel: element);
        }
      }
      print(totalTax);
      double subTotal = double.parse(orderModel.subTotal.toString()) -
          double.parse(orderModel.discount.toString());
      // double adminComm = 0.0;
      if (orderModel.adminCommission!.isNotEmpty) {
        adminComm = (orderModel.adminCommissionType == 'Percent' ||
                orderModel.adminCommissionType == 'percentage')
            ? (subTotal * double.parse(orderModel.adminCommission!)) / 100
            : double.parse(orderModel.adminCommission!);
      }

      print("--->finalAmount---- $subTotal");
      double tipValue = orderModel.tipValue!.isEmpty
          ? 0.0
          : double.parse(orderModel.tipValue.toString());

      amount = subTotal + totalTax + tipValue;
      adminComm = adminComm;
    } else if (MyAppState.currentUser!.serviceType == "parcel_delivery") {
      double totalTax = 0.0;
      if (orderModel!.taxModel != null) {
        for (var element in orderModel!.taxModel!) {
          totalTax = totalTax +
              calculateTax(
                  amount: (double.parse(orderModel.subTotal.toString()) -
                          double.parse(orderModel.discount.toString()))
                      .toString(),
                  taxModel: element);
        }
      }
      double subTotal = double.parse(orderModel.subTotal.toString()) -
          double.parse(orderModel.discount.toString());
      if (orderModel.adminCommission!.isNotEmpty) {
        adminComm = (orderModel.adminCommissionType == 'Percent' ||
                orderModel.adminCommissionType == 'percentage')
            ? (subTotal * double.parse(orderModel.adminCommission!)) / 100
            : double.parse(orderModel.adminCommission!);
      }

      amount = subTotal + totalTax;
      adminComm = adminComm;
    } else if (MyAppState.currentUser!.serviceType == "rental-service") {
      double totalTax = 0.0;
      double subTotal = (double.parse(orderModel.subTotal.toString()) +
              double.parse(orderModel.driverRate.toString())) -
          double.parse(orderModel.discount.toString());

      if (orderModel!.taxModel != null) {
        for (var element in orderModel!.taxModel!) {
          totalTax = totalTax +
              calculateTax(amount: (subTotal.toString()), taxModel: element);
        }
      }
      if (orderModel.adminCommission!.isNotEmpty) {
        adminComm = (orderModel.adminCommissionType == 'Percent' ||
                orderModel.adminCommissionType == 'percentage')
            ? (subTotal * double.parse(orderModel.adminCommission!)) / 100
            : double.parse(orderModel.adminCommission!);
      }

      amount = subTotal + totalTax;
      adminComm = adminComm;
    }
    final size = MediaQuery.of(context).size;
    return showModalBottomSheet(
        elevation: 5,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15), topRight: Radius.circular(15))),
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 25.0),
                  child: Text(
                    "Transaction Details".tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15.0,
                  ),
                  child: Card(
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Transaction ID".tr(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Opacity(
                                opacity: 0.8,
                                child: Text(
                                  orderModel.id,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 30),
                    child: Card(
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          //    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          // crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipOval(
                              child: Container(
                                color: Color(COLOR_PRIMARY).withOpacity(0.05),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                      Icons.account_balance_wallet_rounded,
                                      size: 28,
                                      color: Color(COLOR_PRIMARY)),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: size.width * 0.70,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: size.width * 0.40,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Order Amount".tr(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Text(
                                          "Admin commission Deducted".tr(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Opacity(
                                          opacity: 0.65,
                                          child: Text(
                                            "${DateFormat('KK:mm:ss a, dd MMM yyyy').format(orderModel.createdAt.toDate()).toUpperCase()}",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        right: 4.0, left: 4),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          //   "(${orderModel.paymentMethod.toLowerCase() != "cod" ? "+" : "-"} ${amountShow(amount: amount.toString())})",
                                          orderModel.paymentMethod
                                                      .toLowerCase() !=
                                                  "cod"
                                              ? "${"+"} ${amountShow(amount: amount.toString())}"
                                              : "(${"-"} ${amountShow(amount: amount.toString())})",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: orderModel.paymentMethod
                                                        .toLowerCase() !=
                                                    "cod"
                                                ? Colors.green
                                                : Colors.red,
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(
                                          height: 8,
                                        ),
                                        Text(
                                          "(-${amountShow(amount: adminComm.toString())})",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.red,
                                            fontSize: 18,
                                          ),
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
                    )),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 25.0, vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Date in UTC Format".tr(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Opacity(
                                      opacity: 0.7,
                                      child: Text(
                                        "${DateFormat('KK:mm:ss a, dd MMM yyyy').format(orderModel.createdAt.toDate()).toUpperCase()}",
                                        style: TextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            if (MyAppState.currentUser!.serviceType ==
                                "cab-service") {
                              await FireStoreUtils.firestore
                                  .collection(RIDESORDER)
                                  .doc(orderModel.id)
                                  .get()
                                  .then((value) {
                                CabOrderModel orderModel =
                                    CabOrderModel.fromJson(value.data()!);
                                push(
                                    context,
                                    CabOrderDetailScreen(
                                      orderModel: orderModel,
                                    ));
                              });
                            } else if (MyAppState.currentUser!.serviceType ==
                                "parcel_delivery") {
                              await FireStoreUtils.firestore
                                  .collection(PARCELORDER)
                                  .doc(orderModel.id)
                                  .get()
                                  .then((value) {
                                ParcelOrderModel orderModel =
                                    ParcelOrderModel.fromJson(value.data()!);
                                push(
                                    context,
                                    ParcelOrderDetailScreen(
                                      orderModel: orderModel,
                                    ));
                              });
                            } else if (MyAppState.currentUser!.serviceType ==
                                "rental-service") {
                              await FireStoreUtils.firestore
                                  .collection(RENTALORDER)
                                  .doc(orderModel.id)
                                  .get()
                                  .then((value) {
                                RentalOrderModel orderModel =
                                    RentalOrderModel.fromJson(value.data()!);
                                push(
                                    context,
                                    RenatalSummaryScreen(
                                      rentalOrderModel: orderModel,
                                    ));
                              });
                            }
                          },
                          child: Text(
                            "View Order".tr().toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(COLOR_PRIMARY),
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 10,
                )
              ],
            );
          });
        });
  }

  // Widget buildEarningCard({required var orderModel}) {
  //   final size = MediaQuery.of(context).size;
  //   double amount = 0;
  //   if (MyAppState.currentUser!.serviceType == "cab-service") {
  //     double totalTax = 0.0;
  //
  //   /*  if (orderModel.taxType!.isNotEmpty) {
  //       if (orderModel.taxType == "percent") {
  //         totalTax = (double.parse(orderModel.subTotal.toString()) - double.parse(orderModel.discount.toString())) * double.parse(orderModel.tax.toString()) / 100;
  //       } else {
  //         totalTax = double.parse(orderModel.tax.toString());
  //       }
  //     }*/
  //     if (orderModel!.taxModel != null) {
  //       for (var element in orderModel!.taxModel!) {
  //         totalTax = totalTax + calculateTax(amount: (double.parse(orderModel.subTotal.toString()) -
  //             double.parse(orderModel.discount.toString())).toString(),
  //             taxModel: element);
  //       }
  //     }
  //     print(totalTax);
  //     double subTotal = double.parse(orderModel.subTotal.toString()) - double.parse(orderModel.discount.toString());
  //     double adminComm = 0.0;
  //     if (orderModel.adminCommission!.isNotEmpty) {
  //       adminComm = (orderModel.adminCommissionType == 'Percent') ? (subTotal * double.parse(orderModel.adminCommission!)) / 100 : double.parse(orderModel.adminCommission!);
  //     }
  //
  //     print("--->finalAmount---- $subTotal");
  //     double tipValue = orderModel.tipValue!.isEmpty ? 0.0 : double.parse(orderModel.tipValue.toString());
  //     if (orderModel.paymentMethod.toLowerCase() != "cod") {
  //       amount = subTotal + totalTax + tipValue + adminComm;
  //     } else {
  //       amount = -(subTotal + totalTax + tipValue + adminComm);
  //     }
  //   } else if (MyAppState.currentUser!.serviceType == "parcel_delivery") {
  //     double totalTax = 0.0;
  //
  //    /* if (orderModel.taxType!.isNotEmpty) {
  //       if (orderModel.taxType == "percent") {
  //         totalTax = (double.parse(orderModel.subTotal.toString()) - double.parse(orderModel.discount.toString())) * double.parse(orderModel.tax.toString()) / 100;
  //       } else {
  //         totalTax = double.parse(orderModel.tax.toString());
  //       }
  //     */
  //     if (orderModel!.taxModel != null) {
  //       for (var element in orderModel!.taxModel!) {
  //         totalTax = totalTax + calculateTax(amount: (double.parse(orderModel.subTotal.toString()) -
  //             double.parse(orderModel.discount.toString())).toString(),
  //             taxModel: element);
  //       }
  //     }
  //     double subTotal = double.parse(orderModel.subTotal.toString()) - double.parse(orderModel.discount.toString());
  //     double adminComm = 0.0;
  //     if (orderModel.adminCommission!.isNotEmpty) {
  //       adminComm = (orderModel.adminCommissionType == 'Percent') ? (subTotal * double.parse(orderModel.adminCommission!)) / 100 : double.parse(orderModel.adminCommission!);
  //     }
  //
  //     print("--->finalAmount---- $subTotal");
  //     print("11111");
  //     print(orderModel.paymentMethod.toLowerCase());
  //     if (orderModel.paymentMethod.toLowerCase() != "cod") {
  //       amount = subTotal + totalTax + adminComm;
  //     } else {
  //       amount = -(subTotal + totalTax + adminComm);
  //     }
  //   } else if (MyAppState.currentUser!.serviceType == "rental-service") {
  //     double totalTax = 0.0;
  //     double subTotal = (double.parse(orderModel.subTotal.toString()) + double.parse(orderModel.driverRate.toString())) - double.parse(orderModel.discount.toString());
  //
  //     /*if (orderModel.taxType!.isNotEmpty) {
  //       if (orderModel.taxType == "percent") {
  //         totalTax = subTotal * double.parse(orderModel.tax.toString()) / 100;
  //       } else {
  //         totalTax = double.parse(orderModel.tax.toString());
  //       }
  //     }*/
  //     if (orderModel!.taxModel != null) {
  //       for (var element in orderModel!.taxModel!) {
  //         totalTax = totalTax + calculateTax(amount: (orderModel.subTotal.toString()),
  //             taxModel: element);
  //       }
  //     }
  //     double adminComm = 0.0;
  //     if (orderModel.adminCommission!.isNotEmpty) {
  //       adminComm = (orderModel.adminCommissionType == 'Percent')
  //           ? (double.parse(orderModel.subTotal.toString()) + double.parse(orderModel.driverRate.toString()) * double.parse(orderModel.adminCommission!)) / 100
  //           : double.parse(orderModel.adminCommission!);
  //     }
  //
  //     if (orderModel.paymentMethod.toLowerCase() != "cod") {
  //       amount = subTotal + totalTax + adminComm;
  //     } else {
  //       amount = -(subTotal + totalTax + adminComm);
  //     }
  //   } else {
  //     print("delv charge ${orderModel.deliveryCharge}");
  //     if (orderModel.deliveryCharge != null && orderModel.deliveryCharge!.isNotEmpty) {
  //       amount += double.parse(orderModel.deliveryCharge!);
  //     }
  //
  //     if (orderModel.tipValue != null && orderModel.tipValue!.isNotEmpty) {
  //       amount += double.parse(orderModel.tipValue!);
  //     }
  //   }
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3),
  //     child: Card(
  //       elevation: 2,
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //       child: Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           crossAxisAlignment: CrossAxisAlignment.center,
  //           children: [
  //             SizedBox(
  //               width: size.width * 0.52,
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     "${DateFormat('dd-MM-yyyy, KK:mma').format(orderModel.createdAt.toDate()).toUpperCase()}",
  //                     style: TextStyle(
  //                       fontWeight: FontWeight.w500,
  //                       fontSize: 17,
  //                     ),
  //                   ),
  //                   SizedBox(
  //                     height: 10,
  //                   ),
  //                   Opacity(
  //                     opacity: 0.75,
  //                     child: Text(
  //                       orderModel.status,
  //                       style: TextStyle(
  //                         fontWeight: FontWeight.w500,
  //                         fontSize: 17,
  //                         color: orderModel.status == "Order Completed" ? Colors.green : Colors.deepOrangeAccent,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             Padding(
  //               padding: const EdgeInsets.only(right: 3.0),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.end,
  //                 children: [
  //                   Text(
  //                     " ${amountShow(amount: amount.toString())}",
  //                     style: TextStyle(
  //                       fontWeight: FontWeight.w600,
  //                       color: orderModel.status == "Order Completed"
  //                           ? amount < 0
  //                               ? Colors.red
  //                               : Colors.green
  //                           : Colors.deepOrange,
  //                       fontSize: 18,
  //                     ),
  //                   ),
  //                   SizedBox(
  //                     height: 20,
  //                   ),
  //                   // Icon(
  //                   //   Icons.arrow_forward_ios,
  //                   //   size: 15,
  //                   // )
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget showWithdrawalHistory(BuildContext context,
      {required Stream<QuerySnapshot>? query}) {
    return StreamBuilder<QuerySnapshot>(
      stream: query,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong'.tr()));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: SizedBox(
                  height: 35, width: 35, child: CircularProgressIndicator()));
        }
        if (snapshot.data!.docs.isEmpty) {
          return Center(
              child: Text(
            "No Transaction History".tr(),
            style: TextStyle(fontSize: 18),
          ));
        } else {
          return ListView(
            shrinkWrap: true,
            physics: BouncingScrollPhysics(),
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              final topUpData = WithdrawHistoryModel.fromJson(
                  document.data() as Map<String, dynamic>);
              //Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
              return buildTransactionCard(
                withdrawHistory: topUpData,
                date: topUpData.paidDate.toDate(),
              );
            }).toList(),
          );
        }
      },
    );
  }

  Widget buildTransactionCard(
      {required WithdrawHistoryModel withdrawHistory, required DateTime date}) {
    final size = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3),
      child: GestureDetector(
        onTap: () => showWithdrawalModelSheet(context, withdrawHistory),
        child: Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipOval(
                  child: Container(
                    color: Colors.green.withOpacity(0.06),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Icon(Icons.account_balance_wallet_rounded,
                          size: 28, color: Color(0xFF00B761)),
                    ),
                  ),
                ),
                SizedBox(
                  width: size.width * 0.75,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: SizedBox(
                          width: size.width * 0.52,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${DateFormat('MMM dd, yyyy, KK:mma').format(withdrawHistory.paidDate.toDate()).toUpperCase()}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 17,
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Opacity(
                                opacity: 0.75,
                                child: Text(
                                  withdrawHistory.paymentStatus,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 17,
                                    color: withdrawHistory.paymentStatus ==
                                            "Success"
                                        ? Colors.green
                                        : Colors.deepOrangeAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 3.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              " ${amountShow(amount: withdrawHistory.amount.toString())}",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color:
                                    withdrawHistory.paymentStatus == "Success"
                                        ? Colors.green
                                        : Colors.deepOrangeAccent,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 15,
                            )
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
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    paymentCompleted(paymentMethod: "RazorPay");
  }

  void _handleExternalWaller(ExternalWalletResponse response) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        "Payment Processing Via".tr() + "\n" + response.walletName!,
      ),
      backgroundColor: Colors.blue.shade400,
      duration: Duration(seconds: 8),
    ));
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        "Payment Failed!!".tr() +
            "\n" +
            jsonDecode(response.message!)['error']['description'],
      ),
      backgroundColor: Colors.red.shade400,
      duration: Duration(seconds: 8),
    ));
  }

  //Midtrans payment
  midtransMakePayment(
      {required String amount, required BuildContext context}) async {
    await createPaymentLink(amount: amount).then((url) async {
      ShowToastDialog.closeLoader();
      if (url != '') {
        final bool isDone = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => MidtransScreen(initialURl: url)));
        if (isDone) {
          ShowToastDialog.showToast("Payment Successful!!");
          paymentCompleted(paymentMethod: "midtrans");
        } else {
          ShowToastDialog.showToast("Payment Unsuccessful!!");
        }
      }
    });
  }

  Future<String> createPaymentLink({required var amount}) async {
    var ordersId = const Uuid().v1();
    final url = Uri.parse(midTransModel!.isSandbox!
        ? 'https://api.sandbox.midtrans.com/v1/payment-links'
        : 'https://api.midtrans.com/v1/payment-links');

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': generateBasicAuthHeader(midTransModel!.serverKey!),
      },
      body: jsonEncode({
        'transaction_details': {
          'order_id': ordersId,
          'gross_amount': double.parse(amount.toString()).toInt(),
        },
        'usage_limit': 2,
        "callbacks": {
          "finish": "https://www.google.com?merchant_order_id=$ordersId"
        },
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return responseData['payment_url'];
    } else {
      ShowToastDialog.showToast("something went wrong, please contact admin.");
      return '';
    }
  }

  String generateBasicAuthHeader(String apiKey) {
    String credentials = '$apiKey:';
    String base64Encoded = base64Encode(utf8.encode(credentials));
    return 'Basic $base64Encoded';
  }

  //Orangepay payment

  static String accessToken = '';
  static String payToken = '';
  static String orderId = '';
  static String amount = '';

  orangeMakePayment(
      {required String amount, required BuildContext context}) async {
    reset();
    var id = const Uuid().v4();
    var paymentURL = await fetchToken(
        context: context, orderId: id, amount: amount, currency: 'USD');
    ShowToastDialog.closeLoader();
    if (paymentURL.toString() != '') {
      final bool isDone = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => OrangeMoneyScreen(
                    initialURl: paymentURL,
                    accessToken: accessToken,
                    amount: amount,
                    orangePay: orangeMoneyModel!,
                    orderId: orderId,
                    payToken: payToken,
                  )));

      if (isDone) {
        ShowToastDialog.showToast("Payment Successful!!");
        paymentCompleted(paymentMethod: "OrangeMoney");
      } else {
        ShowToastDialog.showToast("Payment Unsuccessful!!");
      }
    } else {
      ShowToastDialog.showToast("Payment Unsuccessful!!");
    }
  }

  Future fetchToken(
      {required String orderId,
      required String currency,
      required BuildContext context,
      required String amount}) async {
    String apiUrl = 'https://api.orange.com/oauth/v3/token';
    Map<String, String> requestBody = {
      'grant_type': 'client_credentials',
    };

    var response = await http.post(Uri.parse(apiUrl),
        headers: <String, String>{
          'Authorization': "Basic ${orangeMoneyModel!.auth!}",
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: requestBody);

    if (response.statusCode == 200) {
      Map<String, dynamic> responseData = jsonDecode(response.body);

      accessToken = responseData['access_token'];
      return await webpayment(
          context: context,
          amountData: amount,
          currency: currency,
          orderIdData: orderId);
    } else {
      ShowToastDialog.showToast("Something went wrong, please contact admin.");
      return '';
    }
  }

  Future webpayment(
      {required String orderIdData,
      required BuildContext context,
      required String currency,
      required String amountData}) async {
    orderId = orderIdData;
    amount = amountData;
    String apiUrl = orangeMoneyModel!.isSandbox! == true
        ? 'https://api.orange.com/orange-money-webpay/dev/v1/webpayment'
        : 'https://api.orange.com/orange-money-webpay/cm/v1/webpayment';
    Map<String, String> requestBody = {
      "merchant_key": orangeMoneyModel!.merchantKey ?? '',
      "currency": orangeMoneyModel!.isSandbox == true ? "OUV" : currency,
      "order_id": orderId,
      "amount": amount,
      "reference": 'Y-Note Test',
      "lang": "en",
      "return_url": orangeMoneyModel!.returnUrl!.toString(),
      "cancel_url": orangeMoneyModel!.cancelUrl!.toString(),
      "notif_url": orangeMoneyModel!.notifyUrl!.toString(),
    };

    var response = await http.post(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: json.encode(requestBody),
    );
    print(response.statusCode);
    print(response.body);

    // Handle the response
    if (response.statusCode == 201) {
      Map<String, dynamic> responseData = jsonDecode(response.body);
      if (responseData['message'] == 'OK') {
        payToken = responseData['pay_token'];
        return responseData['payment_url'];
      } else {
        return '';
      }
    } else {
      ShowToastDialog.showToast("Something went wrong, please contact admin.");
      return '';
    }
  }

  static reset() {
    accessToken = '';
    payToken = '';
    orderId = '';
    amount = '';
  }

  //XenditPayment
  xenditPayment(context, amount) async {
    await createXenditInvoice(amount: amount).then((model) async {
      ShowToastDialog.closeLoader();
      if (model.id != null) {
        final bool isDone = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => XenditScreen(
                  initialURl: model.invoiceUrl ?? '',
                  transId: model.id ?? '',
                  apiKey: xenditModel?.apiKey ?? ''),
            ));

        if (isDone) {
          ShowToastDialog.showToast("Payment Successful!!");
          paymentCompleted(paymentMethod: "Xendit");
        } else {
          ShowToastDialog.showToast("Payment Unsuccessful!!");
        }
      }
    });
  }

  Future<XenditModel> createXenditInvoice({required var amount}) async {
    const url = 'https://api.xendit.co/v2/invoices';
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': generateBasicAuthHeader(xenditModel!.apiKey!.toString()),
      // 'Cookie': '__cf_bm=yERkrx3xDITyFGiou0bbKY1bi7xEwovHNwxV1vCNbVc-1724155511-1.0.1.1-jekyYQmPCwY6vIJ524K0V6_CEw6O.dAwOmQnHtwmaXO_MfTrdnmZMka0KZvjukQgXu5B.K_6FJm47SGOPeWviQ',
    };

    final body = jsonEncode({
      'external_id': const Uuid().v1(),
      'amount': amount,
      'payer_email': 'customer@domain.com',
      'description': 'Test - VA Successful invoice payment',
      'currency': 'IDR', //IDR, PHP, THB, VND, MYR
    });

    try {
      final response =
          await http.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        XenditModel model = XenditModel.fromJson(jsonDecode(response.body));
        return model;
      } else {
        return XenditModel();
      }
    } catch (e) {
      return XenditModel();
    }
  }

  withdrawAmountBottomSheet(BuildContext context) {
    return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25), topRight: Radius.circular(25)),
        ),
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 5),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 25.0, bottom: 10),
                      child: Text(
                        "Withdraw".tr(),
                        style: TextStyle(
                          fontSize: 18,
                          color: isDarkMode(context)
                              ? Colors.white
                              : Color(DARK_COLOR),
                        ),
                      ),
                    ),
                    MyAppState
                            .currentUser!.userBankDetails.accountNumber.isEmpty
                        ? SizedBox()
                        : Card(
                            color: isDarkMode(context)
                                ? Color(DARK_CARD_BG_COLOR)
                                : Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10), // if you need this
                              side: BorderSide(
                                color: Colors.grey.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  selectedValue = 0;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 20),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Image.asset(
                                            "assets/images/ic_bank_line.png",
                                            height: 20,
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Text(
                                            "Bank Transfer",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontFamily:
                                                    AppThemeData.regular,
                                                color: Colors.black,
                                                fontSize: 16),
                                          )
                                        ],
                                      ),
                                      Radio(
                                        value: 0,
                                        visualDensity: const VisualDensity(
                                            horizontal:
                                                VisualDensity.minimumDensity,
                                            vertical:
                                                VisualDensity.minimumDensity),
                                        groupValue: selectedValue,
                                        onChanged: (value) {
                                          setState(() {
                                            selectedValue = 0;
                                          });
                                        },
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                    withdrawMethodModel == null ||
                            withdrawMethodModel!.flutterWave == null ||
                            (flutterWaveSettingData != null &&
                                flutterWaveSettingData!.isWithdrawEnabled ==
                                    false)
                        ? SizedBox()
                        : Card(
                            color: isDarkMode(context)
                                ? Color(DARK_CARD_BG_COLOR)
                                : Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10), // if you need this
                              side: BorderSide(
                                color: Colors.grey.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  selectedValue = 1;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 20),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Image.asset(
                                        "assets/images/flutterwave.png",
                                        height: 20,
                                      ),
                                      Radio(
                                        value: 1,
                                        visualDensity: const VisualDensity(
                                            horizontal:
                                                VisualDensity.minimumDensity,
                                            vertical:
                                                VisualDensity.minimumDensity),
                                        groupValue: selectedValue,
                                        onChanged: (value) {
                                          setState(() {
                                            selectedValue = 1;
                                          });
                                        },
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                    withdrawMethodModel == null ||
                            withdrawMethodModel!.paypal == null ||
                            (paypalSettingData != null &&
                                paypalSettingData!.isWithdrawEnabled == false)
                        ? SizedBox()
                        : Card(
                            color: isDarkMode(context)
                                ? Color(DARK_CARD_BG_COLOR)
                                : Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10), // if you need this
                              side: BorderSide(
                                color: Colors.grey.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  selectedValue = 2;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 20),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Image.asset(
                                        "assets/images/paypal.png",
                                        height: 20,
                                      ),
                                      Radio(
                                        value: 2,
                                        visualDensity: const VisualDensity(
                                            horizontal:
                                                VisualDensity.minimumDensity,
                                            vertical:
                                                VisualDensity.minimumDensity),
                                        groupValue: selectedValue,
                                        onChanged: (value) {
                                          setState(() {
                                            selectedValue = 2;
                                          });
                                        },
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                    withdrawMethodModel == null ||
                            withdrawMethodModel!.razorpay == null ||
                            (razorPayData != null &&
                                razorPayData!.isWithdrawEnabled == false)
                        ? SizedBox()
                        : Card(
                            color: isDarkMode(context)
                                ? Color(DARK_CARD_BG_COLOR)
                                : Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10), // if you need this
                              side: BorderSide(
                                color: Colors.grey.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 20),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedValue = 3;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Image.asset(
                                        "assets/images/razorpay.png",
                                        height: 20,
                                      ),
                                      Radio(
                                        value: 3,
                                        visualDensity: const VisualDensity(
                                            horizontal:
                                                VisualDensity.minimumDensity,
                                            vertical:
                                                VisualDensity.minimumDensity),
                                        groupValue: selectedValue,
                                        onChanged: (value) {
                                          setState(() {
                                            selectedValue = 3;
                                          });
                                        },
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                    withdrawMethodModel == null ||
                            withdrawMethodModel!.stripe == null ||
                            (stripeData != null &&
                                stripeData!.isWithdrawEnabled == false)
                        ? SizedBox()
                        : Card(
                            color: isDarkMode(context)
                                ? Color(DARK_CARD_BG_COLOR)
                                : Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10), // if you need this
                              side: BorderSide(
                                color: Colors.grey.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 20),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedValue = 4;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Image.asset(
                                        "assets/images/stripe.png",
                                        height: 20,
                                      ),
                                      Radio(
                                        value: 4,
                                        visualDensity: const VisualDensity(
                                            horizontal:
                                                VisualDensity.minimumDensity,
                                            vertical:
                                                VisualDensity.minimumDensity),
                                        groupValue: selectedValue,
                                        onChanged: (value) {
                                          setState(() {
                                            selectedValue = 4;
                                          });
                                        },
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 5),
                          child: RichText(
                            text: TextSpan(
                              text: "Amount to Withdraw".tr(),
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode(context)
                                    ? Colors.white70
                                    : Color(DARK_COLOR).withOpacity(0.7),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Form(
                      key: _globalKey,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 2),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 0.0, horizontal: 8),
                          child: TextFormField(
                            controller: _amountController,
                            style: TextStyle(
                              color: Color(COLOR_PRIMARY_DARK),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                            //initialValue:"50",
                            maxLines: 1,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "*required Field".tr();
                              } else {
                                if (double.parse(value) <= 0) {
                                  return "*Invalid Amount".tr();
                                } else if (double.parse(value) >
                                    double.parse(MyAppState
                                        .currentUser!.walletAmount
                                        .toString())) {
                                  return "*withdraw is more then wallet balance"
                                      .tr();
                                } else {
                                  return null;
                                }
                              }
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              prefix: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0, vertical: 2),
                                child: Text(
                                  "${currencyData!.symbol}",
                                  style: TextStyle(
                                    color: isDarkMode(context)
                                        ? Colors.white
                                        : Color(DARK_COLOR),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              fillColor: Colors.grey[200],
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                  borderSide: BorderSide(
                                      color: Color(COLOR_PRIMARY),
                                      width: 1.50)),
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.error),
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.error),
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 10),
                      child: TextFormField(
                        controller: _noteController,
                        style: TextStyle(
                          color: Color(COLOR_PRIMARY_DARK),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        //initialValue:"50",
                        maxLines: 1,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "*required Field".tr();
                          }
                          return null;
                        },
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          hintText: 'Add note'.tr(),
                          fillColor: Colors.grey[200],
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0),
                              borderSide: BorderSide(
                                  color: Color(COLOR_PRIMARY), width: 1.50)),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error),
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error),
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: buildButton(context, title: "WITHDRAW".tr(),
                          onPress: () {
                        if (_globalKey.currentState!.validate()) {
                          print("------->");
                          print(minimumAmountToWithdrawal);
                          print(_amountController.text);
                          if (double.parse(minimumAmountToWithdrawal) >
                              double.parse(_amountController.text)) {
                            showAlertDialog(
                                context,
                                "Failed!".tr(),
                                '${"Withdraw amount must be greater or equal to".tr()} ${amountShow(amount: minimumAmountToWithdrawal)}'
                                    .tr(),
                                true);
                          } else {
                            withdrawRequest();
                          }
                        }
                      }),
                    ),
                  ],
                ),
              ),
            );
          });
        });
  }

  withdrawRequest() {
    Navigator.pop(context);
    showLoadingAlert();
    FireStoreUtils.createPaymentId(collectionName: driverPayouts).then((value) {
      final paymentID = value;

      WithdrawHistoryModel withdrawHistory = WithdrawHistoryModel(
        amount: double.parse(_amountController.text),
        driverId: userId,
        paymentStatus: "Pending",
        paidDate: Timestamp.now(),
        id: paymentID.toString(),
        role: 'driver',
        note: _noteController.text,
        withdrawMethod: selectedValue == 0
            ? "bank"
            : selectedValue == 1
                ? "flutterwave"
                : selectedValue == 2
                    ? "paypal"
                    : selectedValue == 3
                        ? "razorpay"
                        : "stripe",
        vendorID: '',
      );

      FireStoreUtils.withdrawWalletAmount(withdrawHistory: withdrawHistory)
          .then((value) {
        FireStoreUtils.updateCurrentUserWallet(
                userId: userId, amount: -double.parse(_amountController.text))
            .whenComplete(() {
          Navigator.pop(_scaffoldKey.currentContext!);
          FireStoreUtils.sendPayoutMail(
              amount: _amountController.text,
              payoutrequestid: paymentID.toString());
          ScaffoldMessenger.of(_scaffoldKey.currentContext!)
              .showSnackBar(SnackBar(
            content: Text("Payment Successful!! \n".tr()),
            backgroundColor: Colors.green,
          ));
        });
      });
    });
  }

  withdrawalHistoryBottomSheet(BuildContext context) {
    return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25), topRight: Radius.circular(25)),
        ),
        backgroundColor: AppThemeData.grey50,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 55,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back_ios,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: showWithdrawalHistory(context,
                      query: withdrawalHistoryQuery),
                ),
              ],
            );
          });
        });
  }

  buildButton(context,
      {required String title,
      double width = 0.9,
      required Function()? onPress}) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width * width,
      child: MaterialButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        color: Color(0xFF00B761),
        height: 45,
        elevation: 0.0,
        onPressed: onPress,
        child: Text(
          title,
          style: TextStyle(fontSize: 15, color: Colors.white),
        ),
      ),
    );
  }

  buildTransButton(context,
      {required String title,
      double width = 0.9,
      required Function()? onPress}) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width * width,
      child: MaterialButton(
        shape: RoundedRectangleBorder(
            side: BorderSide(color: Color(0xFF00B761), width: 1),
            borderRadius: BorderRadius.circular(6)),
        color: Colors.transparent,
        height: 45,
        elevation: 0.0,
        onPressed: onPress,
        child: Text(
          title,
          style: TextStyle(fontSize: 15, color: Color(0xFF00B761)),
        ),
      ),
    );
  }

  showLoadingAlert() {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CircularProgressIndicator(),
              Text('Please wait!!'.tr()),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                SizedBox(
                  height: 15,
                ),
                Text(
                  'Please wait!! while completing Transaction'.tr(),
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(
                  height: 15,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
