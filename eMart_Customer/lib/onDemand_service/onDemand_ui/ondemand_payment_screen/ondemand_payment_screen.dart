// ignore_for_file: unused_local_variable

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emartconsumer/constants.dart';
import 'package:emartconsumer/main.dart';
import 'package:emartconsumer/model/CodModel.dart';
import 'package:emartconsumer/model/FlutterWaveSettingDataModel.dart';
import 'package:emartconsumer/model/MercadoPagoSettingsModel.dart';
import 'package:emartconsumer/model/PayFastSettingData.dart';
import 'package:emartconsumer/model/PayStackSettingsModel.dart';
import 'package:emartconsumer/model/RazorPayFailedModel.dart';

import 'package:emartconsumer/model/User.dart';
import 'package:emartconsumer/model/createRazorPayOrderModel.dart';
import 'package:emartconsumer/model/getPaytmTxtToken.dart';
import 'package:emartconsumer/model/payStackURLModel.dart';
import 'package:emartconsumer/model/payment_model/mid_trans.dart';
import 'package:emartconsumer/model/payment_model/orange_money.dart';
import 'package:emartconsumer/model/payment_model/xendit.dart';
import 'package:emartconsumer/model/paypalSettingData.dart';
import 'package:emartconsumer/model/paytmSettingData.dart';
import 'package:emartconsumer/model/razorpayKeyModel.dart';
import 'package:emartconsumer/model/stripeSettingData.dart';
import 'package:emartconsumer/model/topupTranHistory.dart';
import 'package:emartconsumer/onDemand_service/onDemand_model/onprovider_order_model.dart';
import 'package:emartconsumer/onDemand_service/onDemand_ui/onDemand_dashboard.dart';
import 'package:emartconsumer/onDemand_service/onDemand_ui/order_screen/ondemand_order_screen.dart';
import 'package:emartconsumer/payment/midtrans_screen.dart';
import 'package:emartconsumer/payment/orangePayScreen.dart';
import 'package:emartconsumer/payment/xenditModel.dart';
import 'package:emartconsumer/payment/xenditScreen.dart';
import 'package:emartconsumer/send_notification.dart';
import 'package:emartconsumer/services/FirebaseHelper.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/services/paystack_url_genrater.dart';
import 'package:emartconsumer/services/rozorpayConroller.dart';
import 'package:emartconsumer/services/show_toast_dialog.dart';
import 'package:emartconsumer/theme/app_them_data.dart';
import 'package:emartconsumer/theme/round_button_fill.dart';
import 'package:emartconsumer/ui/wallet/MercadoPagoScreen.dart';
import 'package:emartconsumer/ui/wallet/PayFastScreen.dart';
import 'package:emartconsumer/ui/wallet/payStackScreen.dart';
import 'package:emartconsumer/userPrefrence.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_paypal/flutter_paypal.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe1;

import 'package:http/http.dart' as http;

import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:uuid/uuid.dart';

class OnDemandPaymentScreen extends StatefulWidget {
  final OnProviderOrderModel? onDemandOrderModel;
  final double totalAmount;
  final bool isExtra;

  OnDemandPaymentScreen({Key? key, this.onDemandOrderModel, this.totalAmount = 0, required this.isExtra}) : super(key: key);

  @override
  State<OnDemandPaymentScreen> createState() => _OnDemandPaymentScreenState();
}

class _OnDemandPaymentScreenState extends State<OnDemandPaymentScreen> {
  OnProviderOrderModel? onDemandOrderModel;

  @override
  void initState() {
    super.initState();
    setState(() {
      onDemandOrderModel = widget.onDemandOrderModel;
    });
    getPaymentSettingData();
    _razorPay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorPay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWaller);
    _razorPay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  placeOnDemandOrder(context) async {
    if (widget.isExtra == false) {
      await showProgress("Please wait...".tr(), false);
      onDemandOrderModel!.payment_method = paymentType;
      onDemandOrderModel!.paymentStatus = onDemandOrderModel!.provider.priceUnit == "Fixed" && paymentType == "cod" ? false : true;
      onDemandOrderModel!.extraPaymentStatus = true;
      await FireStoreUtils().onDemandOrderPlace(onDemandOrderModel!, double.parse(widget.totalAmount.toString())).then((value) async {});

      if (onDemandOrderModel!.status == ORDER_STATUS_PLACED) {
        await FireStoreUtils.sendOrderOnDemandServiceEmail(orderModel: onDemandOrderModel!);

        User? providerUser = await FireStoreUtils.getCurrentUser(onDemandOrderModel!.provider.author.toString());

        Map<String, dynamic> payLoad = <String, dynamic>{"type": 'provider_order', "orderId": onDemandOrderModel!.id};
        if (providerUser != null) {
          await SendNotification.sendFcmMessage(providerBookingPlaced, providerUser.fcmToken.toString(), payLoad);
        }
        ShowToastDialog.showToast("OnDemand Service successfully booked".tr());
      }
      await hideProgress();
      await push(
          context,
          OnDemandDahBoard(
            user: MyAppState.currentUser!,
            currentWidget: OnDemandOrderScreen(),
            appBarTitle: 'Booking'.tr(),
            drawerSelection: DrawerSelection.Order,
          ));
    } else {
      // ExtraCharges payment
      // onDemandOrderModel!.payment_method = paymentType;
      onDemandOrderModel!.createdAt = Timestamp.now();
      onDemandOrderModel!.extraPaymentStatus = true;
      if (paymentType != 'cod') {
        TopupTranHistoryModel extraPayment = TopupTranHistoryModel(
            amount: widget.totalAmount.toString(),
            id: Uuid().v4(),
            order_id: widget.onDemandOrderModel!.id.toString(),
            user_id: widget.onDemandOrderModel!.provider.author.toString(),
            date: Timestamp.now(),
            isTopup: true,
            payment_method: "Wallet",
            payment_status: "success",
            serviceType: 'ondemand-service',
            note: 'Extra Charge Amount Credited',
            transactionUser: "provider");

        await FireStoreUtils.firestore.collection(Wallet).doc(extraPayment.id).set(extraPayment.toJson());
        await FireStoreUtils.updateProviderWalletAmount(amount: extraPayment, userId: widget.onDemandOrderModel!.provider.author.toString());
      }
      await FireStoreUtils.updateOnDemandOrder(onDemandOrderModel!);
      await hideProgress();
      await push(
          context,
          OnDemandDahBoard(
            user: MyAppState.currentUser!,
            currentWidget: OnDemandOrderScreen(),
            appBarTitle: 'Booking'.tr(),
            drawerSelection: DrawerSelection.Order,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode(context) ? AppThemeData.surfaceDark : AppThemeData.surface,
      key: _globalKey,
      appBar: AppBar(
        leading: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
            )),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: [paymentListView()],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: RoundedButtonFill(
            title: "Continue".tr(),
            color: AppThemeData.primary300,
            textColor: AppThemeData.grey50,
            onPress: () async {
              if (razorPay) {
                paymentType = 'razorpay';
                showLoadingAlert();
                RazorPayController().createOrderRazorPay(amount: double.parse(widget.totalAmount.toString()).toInt()).then((value) {
                  if (value == null) {
                    Navigator.pop(context);
                    showAlert(_globalKey.currentContext!, response: "contact-admin".tr(), colors: Colors.red);
                  } else {
                    CreateRazorPayOrderModel result = value;
                    openCheckout(
                      amount: double.parse(widget.totalAmount.toString()),
                      orderId: result.id,
                    );
                  }
                });
              } else if (stripe) {
                paymentType = 'stripe';
                showLoadingAlert();
                stripeMakePayment(amount: widget.totalAmount.toString(), context: context);
              } else if (payFast) {
                paymentType = 'payfast';
                showLoadingAlert();
                PayStackURLGen.getPayHTML(payFastSettingData: payFastSettingData!, amount: double.parse(widget.totalAmount.toString()).toStringAsFixed(currencyData!.decimal))
                    .then((value) async {
                  bool isDone = await Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => PayFastScreen(
                            htmlData: value,
                            payFastSettingData: payFastSettingData!,
                          )));

                  print(isDone);
                  if (isDone) {
                    Navigator.pop(context);
                    placeOnDemandOrder(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text(
                        "Payment Successful!!\n",
                      ).tr(),
                      backgroundColor: Colors.green.shade400,
                      duration: const Duration(seconds: 6),
                    ));
                  } else {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Builder(builder: (context) {
                        return const Text(
                          "Payment UnSuccessful!!\n",
                        ).tr();
                      }),
                      backgroundColor: Colors.red.shade400,
                      duration: const Duration(seconds: 6),
                    ));
                  }
                });
              } else if (cod) {
                paymentType = 'cod';
                placeOnDemandOrder(context);
              } else if (payStack) {
                paymentType = 'paystack';
                showLoadingAlert();
                payStackPayment(context);
              } else if (flutterWave) {
                setRef();
                paymentType = 'flutterwave';
                _flutterWaveInitiatePayment(context);
              } else if (paypal) {
                paymentType = 'paypal';
                showLoadingAlert();
                //  _makePaypalPayment(amount: getTotalAmount().toString());
                paypalPaymentSheet(amount: widget.totalAmount.toString());
              } else if (wallet && walletBalanceError == false) {
                paymentType = 'wallet';
                showLoadingAlert();

                TopupTranHistoryModel wallet = TopupTranHistoryModel(
                    amount: widget.totalAmount,
                    id: Uuid().v4(),
                    order_id: onDemandOrderModel!.id,
                    user_id: MyAppState.currentUser!.userID,
                    date: Timestamp.now(),
                    isTopup: false,
                    payment_method: "Wallet",
                    payment_status: "success",
                    transactionUser: "customer",
                    note: widget.isExtra ? 'Extra Booking Payment' : 'Booking amount payment',
                    serviceType: 'ondemand-service');

                await FireStoreUtils.firestore.collection("wallet").doc(wallet.id).set(wallet.toJson()).then((value) {
                  FireStoreUtils.updateWalletAmount(amount: -widget.totalAmount).then((value) {
                    placeOnDemandOrder(context);
                  }).whenComplete(() {
                    showAlert(context, response: "Payment Successful Via".tr() + " " "Wallet".tr(), colors: Colors.green);
                  });
                });
              } else if (mercadoPago) {
                paymentType = 'mercadoPago';
                mercadoPagoMakePayment(context);
              } else if (Midtrans) {
                paymentType = 'midtrans';
                midtransMakePayment(context: context, amount: widget.totalAmount.toString());
              } else if (orange) {
                paymentType = 'orangepay';
                orangeMakePayment(context: context, amount: widget.totalAmount.toString());
              } else if (xendit) {
                paymentType = 'xendit';
                xenditPayment(context, widget.totalAmount);
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
          )),
    );
  }

  final Razorpay _razorPay = Razorpay();

  Stream<DocumentSnapshot<Map<String, dynamic>>>? userQuery;
  final fireStoreUtils = FireStoreUtils();
  static FirebaseFirestore fireStore = FireStoreUtils.firestore;
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
  CodModel? codModel;

  bool walletBalanceError = false;
  RazorPayModel? razorPayData = UserPreference.getRazorPayData();
  bool cod = false;
  bool payStack = false;
  bool flutterWave = false;
  bool wallet = false;
  bool razorPay = false;
  bool payTm = false;
  bool pay = false;
  bool stripe = false;
  bool paypal = false;
  bool payFast = false;
  bool mercadoPago = false;
  bool xendit = false;
  bool orange = false;
  bool Midtrans = false;

  String selectedCardID = '';
  bool isStaging = true;
  bool enableAssist = true;
  bool restrictAppInvoke = false;

  String result = "";

  String paymentOption = 'Pay Via Wallet'.tr();
  String paymentType = "";

  showAlert(BuildContext context123, {required String response, required Color colors}) {
    return ScaffoldMessenger.of(context123).showSnackBar(SnackBar(
      content: Text(response),
      backgroundColor: colors,
    ));
  }

  getPaymentSettingData() async {
    userQuery = fireStore.collection(USERS).doc(MyAppState.currentUser!.userID).snapshots();
    await UserPreference.getStripeData().then((value) async {
      stripeData = value;
      stripe1.Stripe.publishableKey = stripeData!.clientpublishableKey;
      stripe1.Stripe.merchantIdentifier = PAYID;
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

    codModel = await fireStoreUtils.getCod();
    setState(() {});
  }

  Widget paymentListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
            margin: const EdgeInsets.only(left: 15),
            child: Text("Select Payment Method".tr(), style: TextStyle(fontSize: 16, color: Colors.black, letterSpacing: 1, fontFamily: AppThemeData.medium))),
        Visibility(
          visible: UserPreference.getWalletData() ?? false,
          child: Column(
            children: [
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: userQuery,
                  builder: (context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> asyncSnapshot) {
                    if (asyncSnapshot.hasError) {
                      return const Text(
                        "error",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ).tr();
                    }
                    if (asyncSnapshot.connectionState == ConnectionState.waiting) {
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
                    User userData = User.fromJson(asyncSnapshot.data!.data()!);

                    walletBalanceError = userData.wallet_amount < double.parse(widget.totalAmount.toString()) ? true : false;
                    return Column(
                      children: [
                        buildPaymentTile(
                            isVisible: UserPreference.getWalletData() ?? false,
                            selectedPayment: wallet,
                            walletError: walletBalanceError,
                            image: "assets/images/wallet_icons.png",
                            value: "Wallet".tr(),
                            childWidget: Text(
                              amountShow(amount: userData.wallet_amount.toString()),
                              style: TextStyle(
                                color: walletBalanceError ? Colors.red : Colors.green,
                                fontFamily: AppThemeData.medium,
                              ),
                            )),
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Visibility(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 0.0),
                                  child: walletBalanceError
                                      ? Text(
                                          "Your wallet doesn't have sufficient balance".tr(),
                                          style: const TextStyle(fontSize: 14, color: Colors.red),
                                        )
                                      : Text(
                                          'Sufficient Balance'.tr(),
                                          style: const TextStyle(fontSize: 14, color: Colors.green),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
            ],
          ),
        ),
        buildPaymentTile(
          isVisible: codModel != null ? codModel!.cod : false,
          selectedPayment: cod,
          image: "assets/images/cash.png",
          value: "Cash".tr(),
        ),
        buildPaymentTile(
          isVisible: (stripeData == null) ? false : stripeData!.isEnabled,
          selectedPayment: stripe,
          value: "Stripe".tr(),
        ),
        buildPaymentTile(
          isVisible: razorPayData!.isEnabled,
          selectedPayment: razorPay,
          image: "assets/images/razorpay_@3x.png",
          value: "RazorPay".tr(),
        ),
        buildPaymentTile(
          isVisible: (paytmSettingData == null) ? false : paytmSettingData!.isEnabled,
          selectedPayment: payTm,
          image: "assets/images/paytm_@3x.png",
          value: "PayTm".tr(),
        ),
        buildPaymentTile(
          isVisible: (paypalSettingData == null) ? false : paypalSettingData!.isEnabled,
          selectedPayment: paypal,
          image: "assets/images/paypal_@3x.png",
          value: "PayPal".tr(),
        ),
        buildPaymentTile(
          isVisible: (payFastSettingData == null) ? false : payFastSettingData!.isEnable,
          selectedPayment: payFast,
          image: "assets/images/payfast.png",
          value: "PayFast".tr(),
        ),
        buildPaymentTile(
          isVisible: (payStackSettingData == null) ? false : payStackSettingData!.isEnabled,
          selectedPayment: payStack,
          image: "assets/images/paystack.png",
          value: "PayStack".tr(),
        ),
        buildPaymentTile(
          isVisible: (flutterWaveSettingData == null) ? false : flutterWaveSettingData!.isEnable,
          selectedPayment: paypal,
          image: "assets/images/flutterwave.png",
          value: "FlutterWave".tr(),
        ),
        buildPaymentTile(
          isVisible: (mercadoPagoSettingData == null) ? false : mercadoPagoSettingData!.isEnabled,
          selectedPayment: mercadoPago,
          image: "assets/images/mercadopago.png",
          value: "Mercado Pago".tr(),
        ),
        buildPaymentTile(
          isVisible: (xenditModel == null) ? false : xenditModel!.enable ?? false,
          selectedPayment: xendit,
          image: "assets/images/xendit.png",
          value: "Xendit".tr(),
        ),
        buildPaymentTile(
          isVisible: (orangeMoneyModel == null) ? false : orangeMoneyModel!.enable ?? false,
          selectedPayment: orange,
          image: "assets/images/orange_money.png",
          value: "OrangeMoney".tr(),
        ),
        buildPaymentTile(
          isVisible: (midTransModel == null) ? false : midTransModel!.enable ?? false,
          selectedPayment: Midtrans,
          image: "assets/images/midtrans.png",
          value: "Midtrans".tr(),
        ),
      ],
    );
  }

  setAllFalse({required String value}) {
    print(value);
    setState(() {
      cod = false;
      stripe = false;
      wallet = false;
      payTm = false;
      razorPay = false;
      payStack = false;
      flutterWave = false;
      pay = false;
      paypal = false;
      payFast = false;
      mercadoPago = false;
      Midtrans = false;
      orange = false;
      xendit = false;

      if (value == "Cash") {
        cod = true;
      }
      if (value == "Stripe") {
        stripe = true;
      }
      if (value == "PayTm") {
        payTm = true;
      }
      if (value == "RazorPay") {
        razorPay = true;
      }
      if (value == "Wallet") {
        wallet = true;
      }
      if (value == "PayPal") {
        paypal = true;
      }
      if (value == "PayFast") {
        payFast = true;
      }
      if (value == "PayStack") {
        payStack = true;
      }
      if (value == "FlutterWave") {
        flutterWave = true;
      }
      if (value == "Google Pay") {
        pay = true;
      }
      if (value == "Mercado Pago") {
        mercadoPago = true;
      }

      if (value == "Midtrans" || value == "Midtrans") {
        Midtrans = true;
      }

      if (value == "OrangeMoney" || value == "orangeMoney") {
        orange = true;
      }

      if (value == "Xendit" || value == "Xendit") {
        xendit = true;
      }
    });
  }

  String? selectedRadioTile;

  ///show payment Options
  buildPaymentTile({
    bool walletError = false,
    Widget childWidget = const Center(),
    required bool isVisible,
    String value = "Stripe",
    image = "assets/images/stripe.png",
    required selectedPayment,
  }) {
    return Visibility(
      visible: isVisible,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4),
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
          child: RadioListTile(
            controlAffinity: ListTileControlAffinity.trailing,
            value: value,
            groupValue: selectedRadioTile,
            onChanged: walletError != true
                ? (String? value) {
                    setState(() {
                      setAllFalse(value: value!);
                      selectedPayment = true;
                      selectedRadioTile = value;
                    });
                  }
                : (String? value) {},
            selected: selectedPayment,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 6,
            ),

            toggleable: true,
            activeColor: AppThemeData.primary300,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10),
                          child: SizedBox(
                            width: 80,
                            height: 35,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Image.asset(
                                image,
                                color: selectedPayment == 'Wallet' ? AppThemeData.secondary300 : null,
                              ),
                            ),
                          ),
                        )),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(value,
                        style: TextStyle(
                          color: isDarkMode(context) ? const Color(0xffFFFFFF) : Colors.black,
                        )),
                  ],
                ),
                childWidget
              ],
            ),
            //toggleable: true,
          ),
        ),
      ),
    );
  }

  //RazorPay payment function
  void openCheckout({required amount, required orderId}) async {
    var options = {
      'key': razorPayData!.razorpayKey,
      'amount': amount * 100,
      'name': PAYID,
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

  ///Stripe payment function

  Map<String, dynamic>? paymentIntentData;

  Future<void> stripeMakePayment({required String amount, context}) async {
    try {
      paymentIntentData = await createStripeIntent(amount);
      if (paymentIntentData!.containsKey("error")) {
        Navigator.pop(_globalKey.currentContext!);
        showAlert(_globalKey.currentContext!, response: "Something went wrong, please contact admin.".tr(), colors: Colors.red);
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
                  primary: AppThemeData.primary300,
                ),
              ),
              merchantDisplayName: 'Emart',
            ))
            .then((value) {});
        setState(() {});
        displayStripePaymentSheet(amount: amount, context: context);
      }
    } catch (e, s) {
      print('exception:$e$s');
    }
  }

  displayStripePaymentSheet({required amount, context}) async {
    try {
      await stripe1.Stripe.instance.presentPaymentSheet().then((value) async {
        placeOnDemandOrder(context);
        ScaffoldMessenger.of(_globalKey.currentContext!).showSnackBar(SnackBar(
          content: Text("paid successfully".tr()),
          duration: const Duration(seconds: 8),
          backgroundColor: Colors.green,
        ));
        paymentIntentData = null;
        Navigator.pop(context);
      }).onError((error, stackTrace) {
        Navigator.pop(context);
        var lo1 = jsonEncode(error);

        print(lo1);
        showDialog(context: context, builder: (_) => AlertDialog(content: Text("Payment Failed")));
      });
    } on stripe1.StripeException catch (e) {
      Navigator.pop(context);
      var lo1 = jsonEncode(e);
      var lo2 = jsonDecode(lo1);
      print("========>");
      print(lo1);
      print(lo2);
      showDialog(context: context, builder: (_) => AlertDialog(content: Text("Payment Failed")));
    } catch (e) {
      print('$e');
      Navigator.pop(_globalKey.currentContext!);
      ScaffoldMessenger.of(_globalKey.currentContext!).showSnackBar(SnackBar(
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
      var response = await http.post(Uri.parse('https://api.stripe.com/v1/payment_intents'),
          body: body, headers: {'Authorization': 'Bearer ${stripeData?.stripeSecret}', 'Content-Type': 'application/x-www-form-urlencoded'});
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

  ///MercadoPago Payment Method
  mercadoPagoMakePayment(context) async {
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
          "currency_id": "USD", // or your preferred currency
          "unit_price": double.parse(amount),
        }
      ],
      "payer": {"email": MyAppState.currentUser!.email},
      "back_urls": {
        "failure": "${GlobalURL}payment/failure",
        "pending": "${GlobalURL}payment/pending",
        "success": "${GlobalURL}payment/success",
      },
      "auto_return": "approved" // Automatically return after payment is approved
    });

    final response = await http.post(
      Uri.parse("https://api.mercadopago.com/checkout/preferences"),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final bool isDone = await Navigator.push(context, MaterialPageRoute(builder: (context) => MercadoPagoScreen(initialURl: data['init_point'])));

      if (isDone) {
        ShowToastDialog.showToast("Payment Successful!!");
        placeOnDemandOrder(context);
      } else {
        ShowToastDialog.showToast("Payment UnSuccessful!!");
      }
    } else {
      print('Error creating preference: ${response.body}');
      return null;
    }
  }

  ///PayPal payment function

  paypalPaymentSheet({required amount}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => UsePaypal(
            sandboxMode: paypalSettingData!.isLive == true ? false : true,
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
              placeOnDemandOrder(context);
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
    await verifyCheckSum(checkSum: data["code"], amount: amount, orderId: orderId).then((value) {
      initiatePayment(amount: amount, orderId: orderId).then((value) {
        print(value);
        GetPaymentTxtTokenModel result = value;
        String callback = "";
        if (paytmSettingData!.isSandboxEnabled) {
          callback = callback + "https://securegw-stage.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
        } else {
          callback = callback + "https://securegw.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
        }

        _startTransaction(context, txnTokenBy: result.body.txnToken, orderId: orderId, amount: amount, callBackURL: callback);
      });
    });
  }

  Future<void> _startTransaction(context, {required String txnTokenBy, required orderId, required double amount, required callBackURL}) async {
    // try {
    //   var response = AllInOneSdk.startTransaction(
    //     paytmSettingData!.PaytmMID,
    //     orderId,
    //     amount.toString(),
    //     txnTokenBy,
    //     callBackURL,
    //     isStaging,
    //     true,
    //     enableAssist,
    //   );
    //
    //   response.then((value) {
    //     if (value!["RESPMSG"] == "Txn Success") {
    //       print("txt done!!");
    //       print(amount);
    //       placeOnDemandOrder(context);
    //       showAlert(context, response: "Payment Successful!!\n".tr() + "${value['RESPMSG']}", colors: Colors.green);
    //     }
    //   }).catchError((onError) {
    //     if (onError is PlatformException) {
    //       print("======>>1");
    //       Navigator.pop(_globalKey.currentContext!);
    //
    //       print("Error124 : $onError");
    //       result = onError.message.toString() + " \n  " + onError.code.toString();
    //       showAlert(_globalKey.currentContext!, response: onError.message.toString(), colors: Colors.red);
    //     } else {
    //       print("======>>2");
    //
    //       result = onError.toString();
    //       Navigator.pop(_globalKey.currentContext!);
    //       showAlert(_globalKey.currentContext!, response: result, colors: Colors.red);
    //     }
    //   });
    // } catch (err) {
    //   print("======>>3");
    //   result = err.toString();
    //   Navigator.pop(_globalKey.currentContext!);
    //   showAlert(_globalKey.currentContext!, response: result, colors: Colors.red);
    // }
  }

  Future<GetPaymentTxtTokenModel> initiatePayment({required double amount, required orderId}) async {
    String initiateURL = "${GlobalURL}payments/initiatepaytmpayment";

    String callback = "";
    if (paytmSettingData!.isSandboxEnabled) {
      callback = callback + "https://securegw-stage.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
    } else {
      callback = callback + "https://securegw.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
    }
    final response = await http.post(Uri.parse(initiateURL), headers: {}, body: {
      "mid": paytmSettingData?.PaytmMID,
      "order_id": orderId,
      "key_secret": paytmSettingData?.PAYTM_MERCHANT_KEY.toString(),
      "amount": amount.toString(),
      "currency": currencyData!.code,
      "callback_url": callback,
      "custId": MyAppState.currentUser!.userID,
      "issandbox": paytmSettingData!.isSandboxEnabled ? "1" : "2",
    });
    // print(response.body);
    final data = jsonDecode(response.body);
    if (data["body"]["txnToken"] == null || data["body"]["txnToken"].toString().isEmpty) {
      Navigator.pop(_globalKey.currentContext!);
      showAlert(_globalKey.currentContext!, response: "contact-admin", colors: Colors.red);
    }
    return GetPaymentTxtTokenModel.fromJson(data);
  }

  Future verifyCheckSum({required String checkSum, required double amount, required orderId}) async {
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
    return data['status'];
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    Navigator.pop(_globalKey.currentContext!);
    print(response.orderId);
    print(response.paymentId);

    placeOnDemandOrder(context);
    ScaffoldMessenger.of(_globalKey.currentContext!).showSnackBar(SnackBar(
      content: Text(
        "Payment Successful!!\n".tr() + response.orderId!,
      ),
      backgroundColor: Colors.green.shade400,
      duration: const Duration(seconds: 6),
    ));
  }

  void _handleExternalWaller(ExternalWalletResponse response) {
    Navigator.pop(_globalKey.currentContext!);
    ScaffoldMessenger.of(_globalKey.currentContext!).showSnackBar(SnackBar(
      content: Text(
        "Payment Proccessing Via\n".tr() + response.walletName!,
      ),
      backgroundColor: Colors.blue.shade400,
      duration: const Duration(seconds: 8),
    ));
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Navigator.pop(_globalKey.currentContext!);
    print(response.code);
    RazorPayFailedModel lom = RazorPayFailedModel.fromJson(jsonDecode(response.message!.toString()));
    ScaffoldMessenger.of(_globalKey.currentContext!).showSnackBar(SnackBar(
      content: Text(
        "Payment Failed!!\n".tr() + lom.error.description,
      ),
      backgroundColor: Colors.red.shade400,
      duration: const Duration(seconds: 8),
    ));
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
        "phonenumber": MyAppState.currentUser!.phoneNumber, // Add a real phone number
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
      final bool isDone = await Navigator.push(context, MaterialPageRoute(builder: (context) => MercadoPagoScreen(initialURl: data['data']['link'])));

      if (isDone) {
        ShowToastDialog.showToast("Payment Successful!!");
        placeOnDemandOrder(context);
      } else {
        ShowToastDialog.showToast("Payment UnSuccessful!!");
      }
    } else {
      print('Payment initialization failed: ${response.body}');
      return null;
    }
  }

  Future<void> showLoading({required String message, Color txtColor = Colors.black}) {
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

  ///PayStack Payment Method
  payStackPayment(BuildContext context) async {
    await PayStackURLGen.payStackURLGen(
      amount: (double.parse(widget.totalAmount.toString()) * 100).toString(),
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
                  amount: double.parse(widget.totalAmount.toString()).toString(),
                  reference: _payStackModel.data.reference,
                )));

        if (isDone) {
          placeOnDemandOrder(context);
          ScaffoldMessenger.of(_globalKey.currentContext!).showSnackBar(SnackBar(
            content: Text("Payment Successful!!\n".tr()),
            backgroundColor: Colors.green,
          ));
        } else {
          Navigator.pop(_globalKey.currentContext!);
          ScaffoldMessenger.of(_globalKey.currentContext!).showSnackBar(SnackBar(
            content: Text("Payment UnSuccessful!!\n".tr()),
            backgroundColor: Colors.red,
          ));
        }
      } else {
        Navigator.pop(_globalKey.currentContext!);
        showAlert(_globalKey.currentContext!, response: "Something went wrong, please contact admin.".tr(), colors: Colors.red);
      }
    });
  }

  //Midtrans payment
  midtransMakePayment({required String amount, required BuildContext context}) async {
    await createPaymentLink(amount: amount).then((url) async {
      ShowToastDialog.closeLoader();
      if (url != '') {
        final bool isDone = await Navigator.push(context, MaterialPageRoute(builder: (context) => MidtransScreen(initialURl: url)));
        if (isDone) {
          ShowToastDialog.showToast("Payment Successful!!");
          placeOnDemandOrder(context);
        } else {
          ShowToastDialog.showToast("Payment Unsuccessful!!");
        }
      }
    });
  }

  Future<String> createPaymentLink({required var amount}) async {
    var ordersId = const Uuid().v1();
    final url = Uri.parse(midTransModel!.isSandbox! ? 'https://api.sandbox.midtrans.com/v1/payment-links' : 'https://api.midtrans.com/v1/payment-links');

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
        "callbacks": {"finish": "https://www.google.com?merchant_order_id=$ordersId"},
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

  orangeMakePayment({required String amount, required BuildContext context}) async {
    reset();
    var id = const Uuid().v4();
    var paymentURL = await fetchToken(context: context, orderId: id, amount: amount, currency: 'USD');
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
        placeOnDemandOrder(context);
      } else {
        ShowToastDialog.showToast("Payment Unsuccessful!!");
      }
    } else {
      ShowToastDialog.showToast("Payment Unsuccessful!!");
    }
  }

  Future fetchToken({required String orderId, required String currency, required BuildContext context, required String amount}) async {
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
      return await webpayment(context: context, amountData: amount, currency: currency, orderIdData: orderId);
    } else {
      ShowToastDialog.showToast("Something went wrong, please contact admin.");
      return '';
    }
  }

  Future webpayment({required String orderIdData, required BuildContext context, required String currency, required String amountData}) async {
    orderId = orderIdData;
    amount = amountData;
    String apiUrl =
        orangeMoneyModel!.isSandbox! == true ? 'https://api.orange.com/orange-money-webpay/dev/v1/webpayment' : 'https://api.orange.com/orange-money-webpay/cm/v1/webpayment';
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
      headers: <String, String>{'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json', 'Accept': 'application/json'},
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
                      apiKey: xenditModel?.apiKey ?? "",
                    )));

        if (isDone) {
          ShowToastDialog.showToast("Payment Successful!!");
          placeOnDemandOrder(context);
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
      final response = await http.post(Uri.parse(url), headers: headers, body: body);

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

  final GlobalKey<ScaffoldState> _globalKey = GlobalKey<ScaffoldState>();

  showLoadingAlert() {
    return showDialog<void>(
      context: _globalKey.currentContext!,
      useRootNavigator: true,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const CircularProgressIndicator(),
              const Text('Please wait!!').tr(),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
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
}
