import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emartconsumer/constants.dart';
import 'package:emartconsumer/main.dart';
import 'package:emartconsumer/model/AddressModel.dart';
import 'package:emartconsumer/model/CodModel.dart';
import 'package:emartconsumer/model/FlutterWaveSettingDataModel.dart';
import 'package:emartconsumer/model/PayFastSettingData.dart';
import 'package:emartconsumer/model/PayStackSettingsModel.dart';
import 'package:emartconsumer/model/ProductModel.dart';
import 'package:emartconsumer/model/createRazorPayOrderModel.dart';
import 'package:emartconsumer/model/payStackURLModel.dart';
import 'package:emartconsumer/model/payment_model/mid_trans.dart';
import 'package:emartconsumer/model/payment_model/orange_money.dart';
import 'package:emartconsumer/model/payment_model/xendit.dart';
import 'package:emartconsumer/model/razorpayKeyModel.dart';
import 'package:emartconsumer/model/stripeSettingData.dart';
import 'package:emartconsumer/model/topupTranHistory.dart';
import 'package:emartconsumer/payment/midtrans_screen.dart';
import 'package:emartconsumer/payment/orangePayScreen.dart';
import 'package:emartconsumer/payment/xenditModel.dart';
import 'package:emartconsumer/payment/xenditScreen.dart';
import 'package:emartconsumer/services/FirebaseHelper.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/services/localDatabase.dart';
import 'package:emartconsumer/services/paystack_url_genrater.dart';
import 'package:emartconsumer/services/rozorpayConroller.dart';
import 'package:emartconsumer/services/show_toast_dialog.dart';
import 'package:emartconsumer/theme/app_them_data.dart';
import 'package:emartconsumer/theme/round_button_fill.dart';
import 'package:emartconsumer/ui/checkoutScreen/CheckoutScreen.dart';
import 'package:emartconsumer/ui/wallet/MercadoPagoScreen.dart';
import 'package:emartconsumer/ui/wallet/PayFastScreen.dart';
import 'package:emartconsumer/ui/wallet/payStackScreen.dart';
import 'package:emartconsumer/userPrefrence.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_paypal/flutter_paypal.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe1;

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;

import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../model/MercadoPagoSettingsModel.dart';
import '../../model/OrderModel.dart';
import '../../model/RazorPayFailedModel.dart';

import '../../model/TaxModel.dart';
import '../../model/User.dart';
import '../../model/VendorModel.dart';
import '../../model/getPaytmTxtToken.dart';
import '../../model/paypalSettingData.dart';
import '../../model/paytmSettingData.dart';
import '../placeOrderScreen/PlaceOrderScreen.dart';

class PaymentScreen extends StatefulWidget {
  final double total;
  final double? discount;
  final String? couponCode;
  final String? couponId, notes;
  final List<CartProduct> products;

  final List<String>? extra_addons;
  final String? tipValue;
  final bool? take_away;
  final String? deliveryCharge;
  final List<TaxModel>? taxModel;
  final Map<String, dynamic>? specialDiscountMap;
  final Timestamp? scheduleTime;
  final AddressModel? addressModel;

  const PaymentScreen(
      {Key? key,
      required this.total,
      this.discount,
      this.couponCode,
      this.couponId,
      required this.products,
      this.extra_addons,
      this.tipValue,
      this.take_away,
      this.deliveryCharge,
      this.notes,
      this.taxModel,
      this.specialDiscountMap,
      this.scheduleTime,
      this.addressModel})
      : super(key: key);

  @override
  PaymentScreenState createState() => PaymentScreenState();
}

class PaymentScreenState extends State<PaymentScreen> {
  final fireStoreUtils = FireStoreUtils();
  late Future<bool> hasNativePay;

  //List<PaymentMethod> _cards = [];
  late Future<CodModel?> futurecod;

  Stream<DocumentSnapshot<Map<String, dynamic>>>? userQuery;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String paymentOption = 'Pay Via Wallet'.tr();
  RazorPayModel? razorPayData = UserPreference.getRazorPayData();

  final Razorpay _razorPay = Razorpay();
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

  bool walletBalanceError = false;

  bool isStaging = true;
  String callbackUrl =
      "http://162.241.125.167/~foodie/payments/paytmpaymentcallback?ORDER_ID=";
  bool restrictAppInvoke = false;
  bool enableAssist = true;
  String result = "";
  String paymentType = "";

  String orderId = '';
  getPaymentSettingData() async {
    orderId = Uuid().v4();
    userQuery = FireStoreUtils.firestore
        .collection(USERS)
        .doc(MyAppState.currentUser!.userID)
        .snapshots();
    await UserPreference.getStripeData().then((value) async {
      stripeData = value;
      if (stripeData!.clientpublishableKey != '' &&
          stripeData!.clientpublishableKey.isNotEmpty) {
        stripe1.Stripe.publishableKey = stripeData!.clientpublishableKey;
        stripe1.Stripe.merchantIdentifier = 'Emart';
        await stripe1.Stripe.instance.applySettings();
      }
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

    ///set Refrence for FlutterWave
    setRef();
  }

  showAlert(context, {required String response, required Color colors}) {
    return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(response),
      backgroundColor: colors,
    ));
  }

  @override
  void initState() {
    getPaymentSettingData();
    futurecod = fireStoreUtils.getCod();
    _razorPay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorPay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWaller);
    _razorPay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    print("delvery charge ${widget.deliveryCharge}");
    super.initState();
  }

  String? selectedRadioTile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: false,
      key: _scaffoldKey,
      appBar: AppBar(),
      backgroundColor:
          isDarkMode(context) ? AppThemeData.surfaceDark : AppThemeData.surface,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            children: [
              Visibility(
                visible: UserPreference.getWalletData() ?? false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 3.0, horizontal: 20),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: wallet ? 0 : 2,
                    child: RadioListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                              color: wallet
                                  ? AppThemeData.primary300
                                  : Colors.transparent)),
                      controlAffinity: ListTileControlAffinity.trailing,
                      value: "Wallet",
                      groupValue: selectedRadioTile,
                      onChanged: (String? value) {
                        print(value);
                        setState(() {
                          mercadoPago = false;
                          payStack = false;
                          flutterWave = false;
                          razorPay = false;
                          wallet = true;
                          codPay = false; //codPay ? false : true;
                          payTm = false;
                          payFast = false;
                          paypal = false;
                          stripe = false;
                          xendit = false;
                          orange = false;
                          Midtrans = false;

                          selectedRadioTile = value!;
                        });
                      },
                      selected: wallet,
                      //selectedRadioTile == "strip" ? true : false,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6,
                      ),
                      title: Column(
                        children: [
                          Row(
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
                                            "assets/images/wallet_icons.png",
                                            color: AppThemeData.secondary300),
                                      ),
                                    ),
                                  )),
                              const SizedBox(
                                width: 20,
                              ),
                              const Text("Wallet").tr(),
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                              stream: userQuery,
                              builder: (context,
                                  AsyncSnapshot<
                                          DocumentSnapshot<
                                              Map<String, dynamic>>>
                                      asyncSnapshot) {
                                if (asyncSnapshot.hasError) {
                                  return Text(
                                    "error".tr(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  );
                                }
                                if (asyncSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 0.8,
                                            color: Colors.white,
                                            backgroundColor: Colors.transparent,
                                          )));
                                }
                                if (asyncSnapshot.data == null) {
                                  return Container();
                                }
                                User userData = User.fromJson(
                                    asyncSnapshot.data?.data() ?? {});

                                walletBalanceError =
                                    userData.wallet_amount == null ||
                                        userData.wallet_amount == 0.0 ||
                                        userData.wallet_amount == 0.00 ||
                                        userData.wallet_amount <= 0 ||
                                        userData.wallet_amount < widget.total;

                                return Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          amountShow(
                                              amount: userData.wallet_amount
                                                  .toString()),
                                          style: TextStyle(
                                              color: walletBalanceError
                                                  ? Colors.red
                                                  : Colors.green,
                                              fontFamily: AppThemeData.medium,
                                              fontSize: 14),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.only(left: 10),
                                            child: walletBalanceError
                                                ? Text(
                                                    "Insufficient balance".tr(),
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.red),
                                                  )
                                                : Text(
                                                    'Sufficient Balance'.tr(),
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.green),
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              }),
                        ],
                      ),
                      //toggleable: true,
                    ),
                  ),
                ),
              ),
              FutureBuilder<CodModel?>(
                  future: futurecod,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator.adaptive(
                          valueColor:
                              AlwaysStoppedAnimation(AppThemeData.primary300),
                        ),
                      );
                    }
                    if (snapshot.hasData) {
                      if (snapshot.data!.cod == true) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 3.0, horizontal: 20),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: codPay ? 0 : 2,
                            child: RadioListTile(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                      color: codPay
                                          ? AppThemeData.primary300
                                          : Colors.transparent)),
                              controlAffinity: ListTileControlAffinity.trailing,
                              value: "cod",
                              groupValue: selectedRadioTile,
                              onChanged: (String? value) {
                                print(value);
                                setState(() {
                                  mercadoPago = false;
                                  payStack = false;
                                  flutterWave = false;
                                  razorPay = false;
                                  wallet = false;
                                  codPay = true; //codPay ? false : true;
                                  payTm = false;
                                  payFast = false;
                                  paypal = false;
                                  stripe = false;
                                  xendit = false;
                                  orange = false;
                                  Midtrans = false;

                                  selectedRadioTile = value!;
                                });
                              },
                              selected: codPay,
                              //selectedRadioTile == "strip" ? true : false,
                              contentPadding: const EdgeInsets.symmetric(
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
                                            child: Center(
                                                child: const FaIcon(
                                                    FontAwesomeIcons
                                                        .handHoldingUsd)),
                                          ),
                                        ),
                                      )),
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  const Text("Cash on delivery").tr(),
                                ],
                              ),
                              //toggleable: true,
                            ),
                          ),
                        );
                      } else {
                        return const Center();
                      }
                    }
                    return const Center();
                  }),
              Visibility(
                visible: stripeData?.isEnabled == true,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 3.0, horizontal: 20),
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
                                  ? AppThemeData.primary300
                                  : Colors.transparent)),
                      controlAffinity: ListTileControlAffinity.trailing,
                      value: "Stripe",
                      groupValue: selectedRadioTile,
                      onChanged: (String? value) {
                        print(value);
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
                          Midtrans = false;
                          xendit = false;
                          wallet = false;
                          codPay = false; //codPay ? false : true;

                          selectedRadioTile = value!;
                        });
                      },
                      selected: stripe,
                      //selectedRadioTile == "strip" ? true : false,
                      contentPadding: const EdgeInsets.symmetric(
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
                          const SizedBox(
                            width: 20,
                          ),
                          const Text("Stripe").tr(),
                        ],
                      ),
                      //toggleable: true,
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: payStackSettingData?.isEnabled == true,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 3.0, horizontal: 20),
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
                                  ? AppThemeData.primary300
                                  : Colors.transparent)),
                      controlAffinity: ListTileControlAffinity.trailing,
                      value: "PayStack",
                      groupValue: selectedRadioTile,
                      onChanged: (String? value) {
                        print(value);
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
                          Midtrans = false;
                          xendit = false;
                          wallet = false;
                          codPay = false; //codPay ? false : true;
                          selectedRadioTile = value!;
                        });
                      },
                      selected: payStack,
                      //selectedRadioTile == "strip" ? true : false,
                      contentPadding: const EdgeInsets.symmetric(
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
                          const SizedBox(
                            width: 20,
                          ),
                          const Text("PayStack").tr(),
                        ],
                      ),
                      //toggleable: true,
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: flutterWaveSettingData?.isEnable == true,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 3.0, horizontal: 20),
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
                                  ? AppThemeData.primary300
                                  : Colors.transparent)),
                      controlAffinity: ListTileControlAffinity.trailing,
                      value: "FlutterWave",
                      groupValue: selectedRadioTile,
                      onChanged: (String? value) {
                        print(value);
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
                          Midtrans = false;
                          xendit = false;
                          wallet = false;
                          codPay = false; //codPay ? false : true;
                          selectedRadioTile = value!;
                        });
                      },
                      selected: flutterWave,
                      contentPadding: const EdgeInsets.symmetric(
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
                          const SizedBox(
                            width: 20,
                          ),
                          const Text("FlutterWave").tr(),
                        ],
                      ),
                      //toggleable: true,
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: razorPayData?.isEnabled == true,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 3.0, horizontal: 20),
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
                                  ? AppThemeData.primary300
                                  : Colors.transparent)),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6,
                      ),
                      controlAffinity: ListTileControlAffinity.trailing,
                      value: "RazorPay",
                      groupValue: selectedRadioTile,
                      onChanged: (String? value) {
                        print(value);
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
                          Midtrans = false;
                          xendit = false;
                          wallet = false;
                          codPay = false; //codPay ? false : true;
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
                          const SizedBox(
                            width: 20,
                          ),
                          const Text("RazorPay").tr(),
                        ],
                      ),
                      //toggleable: true,
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: payFastSettingData?.isEnable == true,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4.0, horizontal: 20),
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
                                  ? AppThemeData.primary300
                                  : Colors.transparent)),
                      controlAffinity: ListTileControlAffinity.trailing,
                      value: "payFast",
                      groupValue: selectedRadioTile,
                      onChanged: (String? value) {
                        print(value);
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
                          Midtrans = false;
                          xendit = false;
                          wallet = false;
                          codPay = false; //codPay ? false : true;
                          selectedRadioTile = value!;
                        });
                      },
                      selected: payFast,
                      //selectedRadioTile == "strip" ? true : false,
                      contentPadding: const EdgeInsets.symmetric(
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
                          const SizedBox(
                            width: 20,
                          ),
                          const Text("Payfast").tr(),
                        ],
                      ),
                      //toggleable: true,
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: paytmSettingData?.isEnabled == true,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 3.0, horizontal: 20),
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
                                  ? AppThemeData.primary300
                                  : Colors.transparent)),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6,
                      ),
                      controlAffinity: ListTileControlAffinity.trailing,
                      value: "PayTm",
                      groupValue: selectedRadioTile,
                      onChanged: (String? value) {
                        print(value);
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
                          Midtrans = false;
                          xendit = false;
                          wallet = false;
                          codPay = false; //codPay ? false : true;
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
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 3.0),
                                      child: Image.asset(
                                        "assets/images/paytm_@3x.png",
                                      ),
                                    )),
                              )),
                          const SizedBox(
                            width: 20,
                          ),
                          const Text("Paytm").tr(),
                        ],
                      ),
                      //toggleable: true,
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: mercadoPagoSettingData?.isEnabled == true,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4.0, horizontal: 20),
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
                                  ? AppThemeData.primary300
                                  : Colors.transparent)),
                      controlAffinity: ListTileControlAffinity.trailing,
                      value: "MercadoPago",
                      groupValue: selectedRadioTile,
                      onChanged: (String? value) {
                        print(value);
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
                          Midtrans = false;
                          xendit = false;
                          wallet = false;
                          codPay = false; //codPay ? false : true;
                          selectedRadioTile = value!;
                        });
                      },
                      selected: mercadoPago,
                      //selectedRadioTile == "strip" ? true : false,
                      contentPadding: const EdgeInsets.symmetric(
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
                          const SizedBox(
                            width: 20,
                          ),
                          const Text("Mercado Pago").tr(),
                        ],
                      ),
                      //toggleable: true,
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: paypalSettingData?.isEnabled == true,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 3.0, horizontal: 20),
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
                                  ? AppThemeData.primary300
                                  : Colors.transparent)),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6,
                      ),
                      controlAffinity: ListTileControlAffinity.trailing,
                      value: "PayPal",
                      groupValue: selectedRadioTile,
                      onChanged: (String? value) {
                        print(value);
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
                          Midtrans = false;
                          xendit = false;
                          wallet = false;
                          codPay = false; //codPay ? false : true;
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
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 3.0),
                                      child: Image.asset(
                                          "assets/images/paypal_@3x.png"),
                                    )),
                              )),
                          const SizedBox(
                            width: 20,
                          ),
                          const Text("PayPal").tr(),
                        ],
                      ),
                      //toggleable: true,
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: xenditModel?.enable == true,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 3.0, horizontal: 20),
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
                          Midtrans = false;
                          xendit = true;
                          wallet = false;
                          codPay = false; //codPay ? false : true;
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
                                      padding: const EdgeInsets.symmetric(
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
                visible: orangeMoneyModel?.enable == true,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 3.0, horizontal: 20),
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
                          Midtrans = false;
                          xendit = false;
                          wallet = false;
                          codPay = false; //codPay ? false : true;
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
                                      padding: const EdgeInsets.symmetric(
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
                visible: midTransModel?.enable == true,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 3.0, horizontal: 20),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: Midtrans ? 0 : 2,
                    child: RadioListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                              color: Midtrans
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
                          Midtrans = true;
                          xendit = false;
                          wallet = false;
                          codPay = false; //codPay ? false : true;
                          selectedRadioTile = value!;
                        });
                      },
                      selected: Midtrans,
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
                                      padding: const EdgeInsets.symmetric(
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
              const SizedBox(
                height: 20,
              ),
              RoundedButtonFill(
                title: "PROCEED".tr(),
                color: AppThemeData.primary300,
                textColor: AppThemeData.grey50,
                width: 80,
                onPress: () async {
                  if (razorPay) {
                    paymentType = 'razorpay';
                    showLoadingAlert();
                    RazorPayController()
                        .createOrderRazorPay(amount: widget.total.toInt())
                        .then((value) {
                      if (value == null) {
                        Navigator.pop(context);
                        showAlert(_scaffoldKey.currentContext!,
                            response:
                                "Something went wrong, please contact admin."
                                    .tr(),
                            colors: Colors.red);
                      } else {
                        CreateRazorPayOrderModel result = value;
                        openCheckout(
                          amount: widget.total,
                          orderId: result.id,
                        );
                      }
                    });
                  } else if (payFast) {
                    paymentType = 'payfast';
                    showLoadingAlert();
                    PayStackURLGen.getPayHTML(
                            payFastSettingData: payFastSettingData!,
                            amount: widget.total.toString())
                        .then((value) async {
                      bool isDone =
                          await Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => PayFastScreen(
                                    htmlData: value,
                                    payFastSettingData: payFastSettingData!,
                                  )));

                      print(isDone);
                      if (isDone) {
                        if (widget.take_away!) {
                          placeOrder(_scaffoldKey.currentContext!,
                              oid: orderId);
                        } else {
                          toCheckOutScreen(true, context, oid: orderId);
                        }

                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            "Payment Successful!!".tr() + "\n",
                          ),
                          backgroundColor: Colors.green.shade400,
                          duration: const Duration(seconds: 6),
                        ));
                      } else {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            "Payment Unsuccessful!!".tr() + "\n",
                          ),
                          backgroundColor: Colors.red.shade400,
                          duration: const Duration(seconds: 6),
                        ));
                      }
                    });
                  } else if (stripe) {
                    paymentType = 'stripe';
                    showLoadingAlert();
                    stripeMakePayment(amount: widget.total.toString());
                  } else if (payStack) {
                    paymentType = 'paystack';
                    showLoadingAlert();
                    payStackPayment(context);
                  } else if (mercadoPago) {
                    paymentType = 'mercadoPago';
                    mercadoPagoMakePayment();
                  } else if (flutterWave) {
                    paymentType = 'flutterwave';
                    _flutterWaveInitiatePayment(context);
                  } else if (paypal) {
                    paymentType = 'paypal';
                    showLoadingAlert();
                    paypalPaymentSheet();
                    //  _makePaypalPayment(amount: widget.total.toString());
                  } else if (wallet) {
                    User userData = await fireStoreUtils.fetchUserByID();
                    walletBalanceError =
                        userData.wallet_amount < widget.total ? false : true;
                    if (userData.wallet_amount == null ||
                        userData.wallet_amount == 0.0 ||
                        userData.wallet_amount == 0.00 ||
                        userData.wallet_amount <= 0 ||
                        userData.wallet_amount < widget.total) {
                      ShowToastDialog.showToast('Insufficient Balance');
                    } else {
                      paymentType = 'wallet';
                      showLoadingAlert();
                      TopupTranHistoryModel wallet = TopupTranHistoryModel(
                          amount: widget.total,
                          order_id: orderId,
                          serviceType: 'delivery-service',
                          id: Uuid().v4(),
                          user_id: MyAppState.currentUser!.userID,
                          date: Timestamp.now(),
                          isTopup: false,
                          payment_method: "wallet",
                          payment_status: "success",
                          transactionUser: "customer",
                          note: 'Order Amount Payment');

                      await FireStoreUtils.firestore
                          .collection("wallet")
                          .doc(wallet.id)
                          .set(wallet.toJson())
                          .then((value) async {
                        await FireStoreUtils.updateWalletAmount(
                                amount: -widget.total)
                            .then((value) {
                          showAlert(_scaffoldKey.currentContext!,
                              response: "Payment Successful Via".tr() +
                                  " " "Wallet".tr(),
                              colors: Colors.green);
                          if (widget.take_away!) {
                            placeOrder(_scaffoldKey.currentContext!,
                                oid: wallet.order_id);
                          } else {
                            Navigator.pop(context);
                            toCheckOutScreen(true, context, oid: orderId);
                          }
                        });
                      });
                    }
                  } else if (codPay) {
                    paymentType = 'cod';
                    paymentOption = 'Pay Via Cash On delivery'.tr();

                    if (widget.take_away!) {
                      placeOrder(_scaffoldKey.currentContext!, oid: orderId);
                    } else {
                      toCheckOutScreen(false, context, oid: orderId);
                    }
                  } else if (Midtrans) {
                    paymentType = 'midtrans';
                    midtransMakePayment(
                        context: context, amount: widget.total.toString());
                  } else if (orange) {
                    paymentType = 'orangepay';
                    orangeMakePayment(
                        context: context, amount: widget.total.toString());
                  } else if (xendit) {
                    paymentType = 'xendit';
                    xenditPayment(context, widget.total);
                  } else {
                    final SnackBar snackBar = SnackBar(
                      content: Text(
                        "Select Payment Method".tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: AppThemeData.primary300,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  bool payStack = false;
  bool flutterWave = false;
  bool wallet = false;
  bool razorPay = false;
  bool payFast = false;
  bool mercadoPago = false;
  bool codPay = false;
  bool payTm = false;
  bool stripe = false;
  bool paypal = false;
  bool xendit = false;
  bool orange = false;
  bool Midtrans = false;

  ///RazorPay payment function
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
      debugPrint('Error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    Navigator.pop(_scaffoldKey.currentContext!);
    print(response.orderId);
    print(response.paymentId);
    if (widget.take_away!) {
      placeOrder(_scaffoldKey.currentContext!, oid: orderId);
    } else {
      toCheckOutScreen(true, _scaffoldKey.currentContext!, oid: orderId);
    }

    ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(SnackBar(
      content: Text(
        "Payment Successful!!".tr() + "\n" + response.orderId!,
      ),
      backgroundColor: Colors.green.shade400,
      duration: const Duration(seconds: 6),
    ));
  }

  void _handleExternalWaller(ExternalWalletResponse response) {
    Navigator.pop(_scaffoldKey.currentContext!);
    ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(SnackBar(
      content: Text(
        "Payment Processing!! via".tr() + "\n" + response.walletName!,
      ),
      backgroundColor: Colors.blue.shade400,
      duration: const Duration(seconds: 8),
    ));
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Navigator.pop(_scaffoldKey.currentContext!);
    print(response.code);
    RazorPayFailedModel lom =
        RazorPayFailedModel.fromJson(jsonDecode(response.message!.toString()));
    ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(SnackBar(
      content: Text(
        "Payment Failed!!".tr() + "\n" + lom.error.description,
      ),
      backgroundColor: Colors.red.shade400,
      duration: const Duration(seconds: 8),
    ));
  }

  ///Stripe payment function
  Map<String, dynamic>? paymentIntentData;

  Future<void> stripeMakePayment({required String amount}) async {
    try {
      paymentIntentData = await createStripeIntent(amount);
      if (paymentIntentData!.containsKey("error")) {
        Navigator.pop(context);
        showAlert(_scaffoldKey.currentContext!,
            response: "Something went wrong, please contact admin.".tr(),
            colors: Colors.red);
      } else {
        await stripe1.Stripe.instance
            .initPaymentSheet(
                paymentSheetParameters: stripe1.SetupPaymentSheetParameters(
              paymentIntentClientSecret: paymentIntentData!['client_secret'],
              applePay: const stripe1.PaymentSheetApplePay(
                merchantCountryCode: 'FR',
              ),
              allowsDelayedPaymentMethods: false,
              googlePay: stripe1.PaymentSheetGooglePay(
                merchantCountryCode: 'FR',
                testEnv: true,
                currencyCode: currencyData!.code,
              ),
              style: ThemeMode.system,
              customFlow: true,
              appearance: stripe1.PaymentSheetAppearance(
                colors: stripe1.PaymentSheetAppearanceColors(
                  primary: AppThemeData.primary300,
                ),
              ),
              merchantDisplayName: 'madameestservie',
            ))
            .then((value) {});
        setState(() {});
        displayStripePaymentSheet(amount: amount);
      }
    } catch (e, s) {
      print('exception:$e$s');
    }
  }

  displayStripePaymentSheet({required amount}) async {
    try {
      await stripe1.Stripe.instance.presentPaymentSheet().then((value) async {
        print("wee are in");
        if (widget.take_away!) {
          placeOrder(_scaffoldKey.currentContext!, oid: orderId);
        } else {
          toCheckOutScreen(true, _scaffoldKey.currentContext!, oid: orderId);
        }

        ScaffoldMessenger.of(_scaffoldKey.currentContext!)
            .showSnackBar(SnackBar(
          content: Text("Payment Successful!!".tr()),
          duration: const Duration(seconds: 8),
          backgroundColor: Colors.green,
        ));
        paymentIntentData = null;
      }).onError((error, stackTrace) {
        Navigator.pop(_scaffoldKey.currentContext!);
        var lo1 = jsonEncode(error);
        var lo2 = jsonDecode(lo1);
        showDialog(
            context: context,
            builder: (_) => AlertDialog(content: Text("Payment Failed".tr())));
      });
    } on stripe1.StripeException catch (e) {
      Navigator.pop(_scaffoldKey.currentContext!);
      var lo1 = jsonEncode(e);
      var lo2 = jsonDecode(lo1);
      showDialog(
          context: context,
          builder: (_) => AlertDialog(content: Text("Payment Failed".tr())));
    } catch (e) {
      print('$e');
      Navigator.pop(_scaffoldKey.currentContext!);
      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(SnackBar(
        content: Text("$e"),
        duration: const Duration(seconds: 8),
        backgroundColor: Colors.red,
      ));
    }
  }

  createStripeIntent(String amount) async {
    try {
      Map<String, dynamic> body = {
        'amount': calculateAmount(amount),
        'currency': currencyData!.code,
      };
      print(body);
      var response = await http.post(
          Uri.parse('https://api.stripe.com/v1/payment_intents'),
          body: body,
          headers: {
            'Authorization': 'Bearer ${stripeData?.stripeSecret}',
            'Content-Type': 'application/x-www-form-urlencoded'
          });
      print('Create Intent response ===> ${response.body.toString()}');
      return jsonDecode(response.body);
    } catch (err) {
      print('error charging user: ${err.toString()}');
    }
  }

  calculateAmount(String amount) {
    final a = ((double.parse(amount)) * 100).toInt();
    print(a);
    return a.toString();
  }

  ///PayPal payment function
  paypalPaymentSheet() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => UsePaypal(
            sandboxMode: paypalSettingData!.isLive == true ? false : true,
            clientId: paypalSettingData!.paypalClient ?? '',
            secretKey: paypalSettingData!.paypalSecret ?? '',
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
              if (widget.take_away!) {
                placeOrder(_scaffoldKey.currentContext!, oid: orderId);
              } else {
                toCheckOutScreen(true, _scaffoldKey.currentContext!,
                    oid: orderId);
              }
              ShowToastDialog.showToast("Payment Successful!!");
            },
            onError: (error) {
              Navigator.pop(context);
              ShowToastDialog.showToast("Payment UnSuccessful!!");
            },
            onCancel: (params) {
              Navigator.pop(context);
              ShowToastDialog.showToast("Payment UnSuccessful!!");
            }),
      ),
    );
  }

  // _makePaypalPayment({required amount}) async {
  //   PayPalClientTokenGen.paypalClientToken(
  //           paypalSettingData: paypalSettingData!)
  //       .then((value) async {
  //     final String tokenizationKey =
  //         paypalSettingData!.braintree_tokenizationKey;
  //
  //     var request = BraintreePayPalRequest(
  //         amount: amount,
  //         currencyCode: currencyData!.code,
  //         billingAgreementDescription: "djsghxghf",
  //         displayName: 'Foodies company');
  //
  //     BraintreePaymentMethodNonce? resultData;
  //     try {
  //       resultData =
  //           await Braintree.requestPaypalNonce(tokenizationKey, request);
  //     } on Exception catch (ex) {
  //       print("Stripe error");
  //       showAlert(_scaffoldKey.currentContext!,
  //           response: "Something went wrong, please contact admin.".tr(),
  //           colors: Colors.red);
  //     }
  //     print(resultData?.nonce);
  //     print(resultData?.paypalPayerId);
  //     if (resultData?.nonce != null) {
  //       PayPalClientTokenGen.paypalSettleAmount(
  //         paypalSettingData: paypalSettingData!,
  //         nonceFromTheClient: resultData?.nonce,
  //         amount: amount,
  //         deviceDataFromTheClient: resultData?.typeLabel,
  //       ).then((value) {
  //         print('payment done!!');
  //         if (value['success'] == "true" || value['success'] == true) {
  //           if (value['data']['success'] == "true" ||
  //               value['data']['success'] == true) {
  //             payPalSettel.PayPalClientSettleModel settleResult =
  //                 payPalSettel.PayPalClientSettleModel.fromJson(value);
  //
  //             if (widget.take_away!) {
  //               placeOrder(_scaffoldKey.currentContext!);
  //             } else {
  //               toCheckOutScreen(true, _scaffoldKey.currentContext!);
  //             }
  //
  //             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //               content: Text(
  //                 "Status : ${settleResult.data.transaction.status}\n"
  //                 "Transaction id : ${settleResult.data.transaction.id}\n"
  //                 "Amount : ${settleResult.data.transaction.amount}",
  //               ),
  //               duration: const Duration(seconds: 8),
  //               backgroundColor: Colors.green,
  //             ));
  //           } else {
  //             print(value);
  //             payPalCurrModel.PayPalCurrencyCodeErrorModel settleResult =
  //                 payPalCurrModel.PayPalCurrencyCodeErrorModel.fromJson(value);
  //             Navigator.pop(_scaffoldKey.currentContext!);
  //             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //               content:
  //                   Text("Status :".tr() + " ${settleResult.data.message}"),
  //               duration: const Duration(seconds: 8),
  //               backgroundColor: Colors.red,
  //             ));
  //           }
  //         } else {
  //           PayPalErrorSettleModel settleResult =
  //               PayPalErrorSettleModel.fromJson(value);
  //           Navigator.pop(_scaffoldKey.currentContext!);
  //           ScaffoldMessenger.of(_scaffoldKey.currentContext!)
  //               .showSnackBar(SnackBar(
  //             content: Text("Status :".tr() + " ${settleResult.data.message}"),
  //             duration: const Duration(seconds: 8),
  //             backgroundColor: Colors.red,
  //           ));
  //         }
  //       });
  //     } else {
  //       Navigator.pop(_scaffoldKey.currentContext!);
  //       ScaffoldMessenger.of(_scaffoldKey.currentContext!)
  //           .showSnackBar(SnackBar(
  //         content: Text("Status :".tr() + "Payment Unsuccessful!!".tr()),
  //         duration: const Duration(seconds: 8),
  //         backgroundColor: Colors.red,
  //       ));
  //     }
  //   });
  // }

  showLoadingAlert() {
    return showDialog<void>(
      context: _scaffoldKey.currentContext!,
      useRootNavigator: true,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const CircularProgressIndicator(),
              Text('Please wait!!'.tr()),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const SizedBox(
                  height: 15,
                ),
                Text(
                  'Please wait!! while completing Transaction'.tr(),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(
                  height: 15,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  ///Paytm payment function
  getPaytmCheckSum(
    context, {
    required double amount,
  }) async {
    final String orderId = await UserPreference.getPaymentId();
    print(orderId);
    print('here order ID');
    String getChecksum = "${GlobalURL}payments/getpaytmchecksum";

    final response = await http.post(
        Uri.parse(
          getChecksum,
        ),
        headers: {},
        body: {
          "mid": paytmSettingData?.PaytmMID,
          "order_id": orderId,
          "key_secret": paytmSettingData?.PAYTM_MERCHANT_KEY,
        });

    final data = jsonDecode(response.body);
    print(data);
    await verifyCheckSum(
            checkSum: data["code"], amount: amount, orderId: orderId)
        .then((value) {
      initiatePayment(amount: amount, orderId: orderId).then((value) {
        String callback = "";
        if (paytmSettingData!.isSandboxEnabled) {
          callback = callback +
              "https://securegw-stage.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
        } else {
          callback = callback +
              "https://securegw.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
        }

        GetPaymentTxtTokenModel result = value;
        _startTransaction(context,
            txnTokenBy: result.body.txnToken,
            orderId: orderId,
            amount: amount,
            callBackURL: callback);
      });
    });
  }

  Future<void> _startTransaction(
    context, {
    required String txnTokenBy,
    required orderId,
    required double amount,
    required callBackURL,
  }) async {
    /* try {
      var response = AllInOneSdk.startTransaction(
        paytmSettingData!.PaytmMID,
        orderId,
        amount.toString(),
        txnTokenBy,
        callbackUrl,
        //"https://securegw-stage.paytm.in/theia/paytmCallback?ORDER_ID=$orderId",
        isStaging,
        true,
        enableAssist,
      );

      response.then((value) {
        if (value!["RESPMSG"] == "Txn Success") {
          print("txt done!!");
          print(amount);
          if (widget.take_away!) {
            placeOrder(_scaffoldKey.currentContext!, oid: Uuid().v4());
          } else {
            toCheckOutScreen(true, context, oid: Uuid().v4());
            print(amount);
          }
          showAlert(context, response: "Payment Successful!!".tr() + "\n ${value['RESPMSG']}", colors: Colors.green);
        }
      }).catchError((onError) {
        if (onError is PlatformException) {
          print("======>>1");
          Navigator.pop(_scaffoldKey.currentContext!);

          print("Error124 : $onError");
          result = onError.message.toString() + " \n  " + onError.code.toString();
          showAlert(_scaffoldKey.currentContext!, response: onError.message.toString(), colors: Colors.red);
        } else {
          print("======>>2");

          result = onError.toString();
          Navigator.pop(_scaffoldKey.currentContext!);
          showAlert(_scaffoldKey.currentContext!, response: result, colors: Colors.red);
        }
      });
    } catch (err) {
      print("======>>3");
      result = err.toString();
      Navigator.pop(_scaffoldKey.currentContext!);
      showAlert(_scaffoldKey.currentContext!, response: result, colors: Colors.red);
    }*/
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
          "mid": paytmSettingData?.PaytmMID,
          "order_id": orderId,
          "key_secret": paytmSettingData?.PAYTM_MERCHANT_KEY,
          "checksum_value": checkSum,
        });
    final data = jsonDecode(response.body);
    print(data);
    print('here one');
    print(checkSum);
    print(data['status']);
    return data['status'];
  }

  Future<GetPaymentTxtTokenModel> initiatePayment(
      {required double amount, required orderId}) async {
    String initiateURL = "${GlobalURL}payments/initiatepaytmpayment";
    print('payment initiated now!@!');
    String callback = "";
    if (paytmSettingData!.isSandboxEnabled) {
      callback = callback +
          "https://securegw-stage.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
    } else {
      callback = callback +
          "https://securegw.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
    }
    final response =
        await http.post(Uri.parse(initiateURL), headers: {}, body: {
      "mid": paytmSettingData?.PaytmMID,
      "order_id": orderId,
      "key_secret": paytmSettingData?.PAYTM_MERCHANT_KEY.toString(),
      "amount": amount.toString(),
      "currency": currencyData!.code,
      "callback_url": callback,
      "custId": MyAppState.currentUser!.userID,
      "issandbox": paytmSettingData!.isSandboxEnabled ? "1" : "2",
    });
    print(response.body);
    final data = jsonDecode(response.body);
    print(data);
    if (data["body"]["txnToken"] == null ||
        data["body"]["txnToken"].toString().isEmpty) {
      Navigator.pop(_scaffoldKey.currentContext!);
      showAlert(_scaffoldKey.currentContext!,
          response: "something went wrong, please contact admin.".tr(),
          colors: Colors.red);
    }
    return GetPaymentTxtTokenModel.fromJson(data);
  }

  ///PayStack Payment Method
  payStackPayment(BuildContext context) async {
    await PayStackURLGen.payStackURLGen(
      amount: (widget.total * 100).toString(),
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
                  amount: widget.total.toString(),
                  reference: _payStackModel.data.reference,
                )));
        //Navigator.pop(_globalKey.currentContext!);

        if (isDone) {
          if (widget.take_away!) {
            placeOrder(_scaffoldKey.currentContext!, oid: orderId);
          } else {
            toCheckOutScreen(true, _scaffoldKey.currentContext!, oid: orderId);
          }
          ScaffoldMessenger.of(_scaffoldKey.currentContext!)
              .showSnackBar(SnackBar(
            content: Text("Payment Successful!!".tr() + "\n"),
            backgroundColor: Colors.green,
          ));
        } else {
          Navigator.pop(_scaffoldKey.currentContext!);
          ScaffoldMessenger.of(_scaffoldKey.currentContext!)
              .showSnackBar(SnackBar(
            content: Text("Payment UnSuccessful!!".tr() + "\n"),
            backgroundColor: Colors.red,
          ));
        }
      } else {
        Navigator.pop(_scaffoldKey.currentContext!);
        showAlert(_scaffoldKey.currentContext!,
            response: "something went wrong, please contact admin.".tr(),
            colors: Colors.red);
      }
    });
  }

  ///MercadoPago Payment Method

  mercadoPagoMakePayment() async {
    final headers = {
      'Authorization': 'Bearer ${mercadoPagoSettingData!.accessToken}',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "items": [
        {
          "title": "Test",
          "description": "Test Payment",
          "quantity": 1,
          "currency_id": "BRL", // or your preferred currency
          "unit_price": double.parse(amount),
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

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final bool isDone = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  MercadoPagoScreen(initialURl: data['init_point'])));

      if (isDone) {
        ShowToastDialog.showToast("Payment Successful!!");
        if (widget.take_away!) {
          placeOrder(_scaffoldKey.currentContext!, oid: orderId);
        } else {
          toCheckOutScreen(true, _scaffoldKey.currentContext!, oid: orderId);
        }
      } else {
        ShowToastDialog.showToast("Payment UnSuccessful!!");
      }
    } else {
      print('Error creating preference: ${response.body}');
      return null;
    }
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
      "amount": amount,
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
        if (widget.take_away!) {
          placeOrder(_scaffoldKey.currentContext!, oid: orderId);
        } else {
          toCheckOutScreen(true, _scaffoldKey.currentContext!, oid: orderId);
        }
      } else {
        ShowToastDialog.showToast("Payment UnSuccessful!!");
      }
    } else {
      print('Payment initialization failed: ${response.body}');
      return null;
    }
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
          if (widget.take_away!) {
            placeOrder(_scaffoldKey.currentContext!, oid: orderId);
          } else {
            toCheckOutScreen(true, _scaffoldKey.currentContext!, oid: orderId);
          }
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
  String accessToken = '';
  String payToken = '';
  String amount = '';

  orangeMakePayment(
      {required String amount, required BuildContext context}) async {
    reset();
    var id = orderId;
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
        if (widget.take_away!) {
          placeOrder(_scaffoldKey.currentContext!, oid: orderId);
        } else {
          toCheckOutScreen(true, _scaffoldKey.currentContext!, oid: orderId);
        }
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

  reset() {
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
                      apiKey: xenditModel!.apiKey!.toString() ?? "",
                    )));

        if (isDone) {
          ShowToastDialog.showToast("Payment Successful!!");
          if (widget.take_away!) {
            placeOrder(_scaffoldKey.currentContext!, oid: orderId);
          } else {
            toCheckOutScreen(true, _scaffoldKey.currentContext!, oid: orderId);
          }
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

  Future<void> showLoading(
      {required String message, Color txtColor = Colors.black}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Container(
            margin: const EdgeInsets.fromLTRB(30, 20, 30, 20),
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

  placeOrder(BuildContext buildContext, {required String oid}) async {
    FireStoreUtils fireStoreUtils = FireStoreUtils();
    List<CartProduct> tempProduc = [];
    if (paymentType.isEmpty) {
      ShowDialogToDismiss(
          title: "Empty payment type".tr(),
          buttonText: "ok".tr(),
          content: "Select payment type".tr());
      return;
    }

    for (CartProduct cartProduct in widget.products) {
      CartProduct tempCart = cartProduct;
      tempProduc.add(tempCart);
    }

    //place order
    showProgress('Placing Order...'.tr(), false);
    VendorModel vendorModel = await fireStoreUtils
        .getVendorByVendorID(widget.products.first.vendorID)
        .whenComplete(() => setPrefData());
    OrderModel orderModel = OrderModel(
      id: oid.toString(),
      address: widget.addressModel,
      author: MyAppState.currentUser,
      authorID: MyAppState.currentUser!.userID,
      createdAt: Timestamp.now(),
      products: tempProduc,
      status: ORDER_STATUS_PLACED,
      vendor: vendorModel,
      payment_method: paymentType,
      notes: widget.notes,
      taxModel: widget.taxModel,
      vendorID: widget.products.first.vendorID,
      discount: widget.discount,
      couponCode: widget.couponCode,
      couponId: widget.couponId,
      sectionId: sectionConstantModel!.id,
      adminCommission: sectionConstantModel?.adminCommision?.enable == false
          ? '0'
          : vendorModel.adminCommission != null
              ? vendorModel.adminCommission!.commission.toString()
              : sectionConstantModel!.adminCommision!.commission.toString(),
      adminCommissionType: sectionConstantModel?.adminCommision?.enable == false
          ? 'fixed'
          : vendorModel.adminCommission != null
              ? vendorModel.adminCommission!.type
              : sectionConstantModel!.adminCommision!.type,
      specialDiscount: widget.specialDiscountMap,
      takeAway: true,
      scheduleTime: widget.scheduleTime,
    );

    OrderModel placedOrder =
        await fireStoreUtils.placeOrderWithTakeAWay(orderModel);

    for (int i = 0; i < tempProduc.length; i++) {
      await FireStoreUtils()
          .getProductByID(tempProduc[i].id.split('~').first)
          .then((value) async {
        ProductModel? productModel = value;
        if (tempProduc[i].variant_info != null) {
          for (int j = 0;
              j < productModel.itemAttributes!.variants!.length;
              j++) {
            if (productModel.itemAttributes!.variants![j].variant_id ==
                tempProduc[i].id.split('~').last) {
              if (productModel.itemAttributes!.variants![j].variant_quantity !=
                  "-1") {
                productModel.itemAttributes!.variants![j].variant_quantity =
                    (int.parse(productModel
                                .itemAttributes!.variants![j].variant_quantity
                                .toString()) -
                            tempProduc[i].quantity)
                        .toString();
              }
            }
          }
        } else {
          if (productModel.quantity != -1) {
            productModel.quantity =
                productModel.quantity - tempProduc[i].quantity;
          }
        }

        await FireStoreUtils.updateProduct(productModel).then((value) {});
      });
    }

    hideProgress();

    showModalBottomSheet(
      isScrollControlled: true,
      isDismissible: false,
      context: buildContext,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => PlaceOrderScreen(orderModel: placedOrder),
    );
  }

  Future<void> setPrefData() async {
    SharedPreferences sp = await SharedPreferences.getInstance();

    sp.setString("musics_key", "");
    sp.setString("addsize", "");
  }

  toCheckOutScreen(bool val, BuildContext context, {required String oid}) {
    print("======>1");
    push(
      context,
      CheckoutScreen(
        id: oid,
        isPaymentDone: val,
        paymentType: paymentType,
        total: widget.total,
        discount: widget.discount!,
        couponCode: widget.couponCode!,
        couponId: widget.couponId!,
        notes: widget.notes!,
        paymentOption: paymentOption,
        products: widget.products,
        deliveryCharge: widget.deliveryCharge,
        tipValue: widget.tipValue,
        take_away: widget.take_away,
        taxModel: widget.taxModel,
        specialDiscountMap: widget.specialDiscountMap,
        scheduleTime: widget.scheduleTime,
        address: widget.addressModel,
      ),
    );
  }
}
