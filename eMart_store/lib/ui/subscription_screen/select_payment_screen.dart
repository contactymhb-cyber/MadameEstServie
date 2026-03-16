import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:emartstore/constants.dart';
import 'package:emartstore/main.dart';
import 'package:emartstore/model/User.dart';
import 'package:emartstore/model/VendorModel.dart';
import 'package:emartstore/model/createRazorPayOrderModel.dart';
import 'package:emartstore/model/payment_model/flutter_wave_model.dart';
import 'package:emartstore/model/payment_model/getPaytmTxtToken.dart';
import 'package:emartstore/model/payment_model/mercado_pago_model.dart';
import 'package:emartstore/model/payment_model/mid_trans.dart';
import 'package:emartstore/model/payment_model/orange_money.dart';
import 'package:emartstore/model/payment_model/pay_fast_model.dart';
import 'package:emartstore/model/payment_model/pay_stack_model.dart';
import 'package:emartstore/model/payment_model/paypal_model.dart';
import 'package:emartstore/model/payment_model/paytm_model.dart';
import 'package:emartstore/model/payment_model/razorpay_model.dart';
import 'package:emartstore/model/payment_model/wallet_setting_model.dart';
import 'package:emartstore/model/payment_model/xendit.dart';
import 'package:emartstore/model/stripeSettingData.dart';
import 'package:emartstore/model/stripe_failed_model.dart';
import 'package:emartstore/model/subscription_history.dart';
import 'package:emartstore/model/subscription_plan_model.dart';
import 'package:emartstore/model/topupTranHistory.dart';
import 'package:emartstore/payment/MercadoPagoScreen.dart';
import 'package:emartstore/payment/PayFastScreen.dart';
import 'package:emartstore/payment/midtrans_screen.dart';
import 'package:emartstore/payment/orangePayScreen.dart';
import 'package:emartstore/payment/paystack/pay_stack_screen.dart';
import 'package:emartstore/payment/paystack/pay_stack_url_model.dart';
import 'package:emartstore/payment/paystack/paystack_url_genrater.dart';
import 'package:emartstore/payment/xenditModel.dart';
import 'package:emartstore/payment/xenditScreen.dart';
import 'package:emartstore/services/FirebaseHelper.dart';
import 'package:emartstore/services/helper.dart';
import 'package:emartstore/services/rozorpayConroller.dart';
import 'package:emartstore/services/show_toast_dailog.dart';
import 'package:emartstore/theme/app_them_data.dart';
import 'package:emartstore/theme/round_button_fill.dart';
import 'package:emartstore/ui/container/ContainerScreen.dart';
import 'package:emartstore/ui/ordersScreen/OrdersScreen.dart';
import 'package:emartstore/ui/subscription_screen/app_not_access_screen.dart';
import 'package:emartstore/utils/Preferences.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_paypal/flutter_paypal.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'dart:math' as maths;
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

class SelectPaymentScreen extends StatefulWidget {
  final bool isShowAppBar;
  final SubscriptionPlanModel subscriptionPlanModel;

  const SelectPaymentScreen({super.key, required this.subscriptionPlanModel, required this.isShowAppBar});

  @override
  State<SelectPaymentScreen> createState() => _SelectPaymentScreenState();
}

class _SelectPaymentScreenState extends State<SelectPaymentScreen> {
  String selectedPaymentMethod = '';

  bool isLoading = true;
  WalletSettingModel? walletSettingModel;

  RazorPayModel? razorPayModel;
  StripeSettingData? stripeModel;
  PaytmModel? paytmModel;
  PayPalModel? payPalModel;
  PayStackModel? payStackModel;
  FlutterWaveModel? flutterWaveModel;
  PayFastModel? payFastModel;
  MercadoPagoModel? mercadoPagoModel;
  MidTrans? midTransModel;
  OrangeMoney? orangeMoneyModel;
  Xendit? xenditModel;
  SubscriptionPlanModel? selectedSubscriptionPlan;
  double totalAmount = 0.0;

  User? userModel;

  final Razorpay razorPay = Razorpay();

  @override
  void initState() {
    // TODO: implement initState
    setState(() {
      selectedSubscriptionPlan = widget.subscriptionPlanModel;
      totalAmount = double.parse(widget.subscriptionPlanModel.price ?? '0.0');
      userModel = MyAppState.currentUser;
    });
    getPaymentSettings();
    super.initState();
  }

  getPaymentSettings() async {
    walletSettingModel = WalletSettingModel.fromJson(jsonDecode(Preferences.getString(Preferences.walletPref)));
    razorPayModel = RazorPayModel.fromJson(jsonDecode(Preferences.getString(Preferences.razorpayPref)));
    payPalModel = PayPalModel.fromJson(jsonDecode(Preferences.getString(Preferences.paypalPref)));
    stripeModel = StripeSettingData.fromJson(jsonDecode(Preferences.getString(Preferences.stripePref)));
    payStackModel = PayStackModel.fromJson(jsonDecode(Preferences.getString(Preferences.paystackPref)));
    flutterWaveModel = FlutterWaveModel.fromJson(jsonDecode(Preferences.getString(Preferences.flutterwavePref)));
    paytmModel = PaytmModel.fromJson(jsonDecode(Preferences.getString(Preferences.paytmPref)));
    payFastModel = PayFastModel.fromJson(jsonDecode(Preferences.getString(Preferences.payfastPref)));
    mercadoPagoModel = MercadoPagoModel.fromJson(jsonDecode(Preferences.getString(Preferences.mercadoPagoPref)));
    orangeMoneyModel = OrangeMoney.fromJson(jsonDecode(Preferences.getString(Preferences.orangeMoneyPref)));
    xenditModel = Xendit.fromJson(jsonDecode(Preferences.getString(Preferences.xenditPref)));
    midTransModel = MidTrans.fromJson(jsonDecode(Preferences.getString(Preferences.midTransPref)));
    isLoading = false;
    setState(() {});
    log("Stripe :: ${stripeModel?.toJson()}");
    if (stripeModel?.isEnabled == true) {
      Stripe.publishableKey = stripeModel?.clientpublishableKey ?? '';
      Stripe.merchantIdentifier = 'eMart';
      await Stripe.instance.applySettings();
    }
    razorPay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccess);
    razorPay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWaller);
    razorPay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentError);
    setRef();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode(context) ? AppThemeData.surfaceDark : AppThemeData.surface,
      appBar: AppBar(
        backgroundColor: isDarkMode(context) ? AppThemeData.surfaceDark : AppThemeData.surface,
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          "Payment Option",
          textAlign: TextAlign.start,
          style: TextStyle(
            fontFamily: AppThemeData.medium,
            fontSize: 16,
            color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900,
          ),
        ),
      ),
      body: isLoading
          ? loader()
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Preferred Payment",
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontFamily: AppThemeData.semiBold,
                        fontSize: 16,
                        color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    if (walletSettingModel?.isEnabled == true)
                      Container(
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
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Visibility(
                                visible: walletSettingModel?.isEnabled == true,
                                child: cardDecoration(PaymentGateway.wallet, "assets/images/walltet_icons.png"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Column(
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          "Other Payment Options",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontFamily: AppThemeData.semiBold,
                            fontSize: 16,
                            color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
                    Container(
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
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Visibility(
                              visible: flutterWaveModel!.isEnable == true,
                              child: cardDecoration(PaymentGateway.stripe, "assets/images/stripe.png"),
                            ),
                            Visibility(
                              visible: paytmModel!.isEnabled == true,
                              child: cardDecoration(PaymentGateway.paypal, "assets/images/paypal.png"),
                            ),
                            Visibility(
                              visible: payStackModel!.isEnable == true,
                              child: cardDecoration(PaymentGateway.payStack, "assets/images/paystack.png"),
                            ),
                            Visibility(
                              visible: mercadoPagoModel!.isEnabled == true,
                              child: cardDecoration(PaymentGateway.mercadoPago, "assets/images/mercado-pago.png"),
                            ),
                            Visibility(
                              visible: flutterWaveModel!.isEnable == true,
                              child: cardDecoration(PaymentGateway.flutterWave, "assets/images/flutterwave_logo.png"),
                            ),
                            Visibility(
                              visible: payFastModel!.isEnable == true,
                              child: cardDecoration(PaymentGateway.payFast, "assets/images/payfast.png"),
                            ),
                            Visibility(
                              visible: razorPayModel!.isEnabled == true,
                              child: cardDecoration(PaymentGateway.razorpay, "assets/images/razorpay.png"),
                            ),
                            Visibility(
                              visible: midTransModel!.enable == true,
                              child: cardDecoration(PaymentGateway.midTrans, "assets/images/midtrans.png"),
                            ),
                            Visibility(
                              visible: orangeMoneyModel!.enable == true,
                              child: cardDecoration(PaymentGateway.orangeMoney, "assets/images/orange_money.png"),
                            ),
                            Visibility(
                              visible: xenditModel!.enable == true,
                              child: cardDecoration(PaymentGateway.xendit, "assets/images/xendit.png"),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
            color: isDarkMode(context) ? AppThemeData.grey900 : AppThemeData.grey50,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: RoundedButtonFill(
            title: "Pay Now".tr(),
            height: 5,
            color: AppThemeData.primary300,
            textColor: AppThemeData.grey50,
            fontSizes: 16,
            onPress: () {
              if (selectedPaymentMethod == PaymentGateway.stripe.name) {
                stripeMakePayment(amount: totalAmount.toString());
              } else if (selectedPaymentMethod == PaymentGateway.paypal.name) {
                paypalPaymentSheet(totalAmount.toString(), context);
              } else if (selectedPaymentMethod == PaymentGateway.payStack.name) {
                payStackPayment(totalAmount.toString());
              } else if (selectedPaymentMethod == PaymentGateway.mercadoPago.name) {
                mercadoPagoMakePayment(context: context, amount: totalAmount.toString());
              } else if (selectedPaymentMethod == PaymentGateway.flutterWave.name) {
                flutterWaveInitiatePayment(context: context, amount: totalAmount.toString());
              } else if (selectedPaymentMethod == PaymentGateway.payFast.name) {
                payFastPayment(context: context, amount: totalAmount.toString());
              } else if (selectedPaymentMethod == PaymentGateway.paytm.name) {
                getPaytmCheckSum(context, amount: double.parse(totalAmount.toString()));
              } else if (selectedPaymentMethod == PaymentGateway.wallet.name) {
                if ((MyAppState.currentUser!.walletAmount ?? 0.0) >= totalAmount) {
                  setOrder();
                } else {
                  ShowToastDialog.showToast("You don't have sufficient wallet balance to purchase the subscription plan");
                }
              } else if (selectedPaymentMethod == PaymentGateway.midTrans.name) {
                midtransMakePayment(context: context, amount: totalAmount.toString());
              } else if (selectedPaymentMethod == PaymentGateway.orangeMoney.name) {
                orangeMakePayment(context: context, amount: totalAmount.toString());
              } else if (selectedPaymentMethod == PaymentGateway.xendit.name) {
                xenditPayment(context, totalAmount.toString());
              } else if (selectedPaymentMethod == PaymentGateway.razorpay.name) {
                RazorPayController().createOrderRazorPay(amount: totalAmount, razorPayData: razorPayModel!).then((value) {
                  if (value == null) {
                    Navigator.pop(context);
                    ShowToastDialog.showToast("Something went wrong, please contact admin.".tr());
                  } else {
                    CreateRazorPayOrderModel result = value;
                    openCheckout(amount: totalAmount.toString(), orderId: result.id);
                  }
                });
              } else {
                ShowToastDialog.showToast("Please select payment method".tr());
              }
            },
          ),
        ),
      ),
    );
  }

  setOrder() async {
    ShowToastDialog.showLoader("Please wait".tr());
    userModel!.subscriptionPlanId = selectedSubscriptionPlan!.id;
    userModel!.subscriptionPlan = selectedSubscriptionPlan;
    userModel!.subscriptionPlan?.createdAt = Timestamp.now();
    userModel!.subscriptionExpiryDate = selectedSubscriptionPlan!.expiryDay == '-1' ? null : addDayInTimestamp(days: selectedSubscriptionPlan!.expiryDay, date: Timestamp.now());
    userModel!.section_id = selectedSectionModel?.id ?? '';
    log("userModel.section_id :: ${userModel?.section_id}");

    if (userModel?.vendorID.isNotEmpty == true) {
      VendorModel? vendorModel = await FireStoreUtils.getVendor(userModel!.vendorID.toString());
      if (vendorModel.id.isNotEmpty) {
        vendorModel.subscriptionPlanId = selectedSubscriptionPlan!.id;
        vendorModel.subscriptionPlan = selectedSubscriptionPlan;
        vendorModel.subscriptionPlan?.createdAt = Timestamp.now();
        vendorModel.subscriptionExpiryDate =
            selectedSubscriptionPlan!.expiryDay == '-1' ? null : addDayInTimestamp(days: selectedSubscriptionPlan!.expiryDay, date: Timestamp.now());
        vendorModel.subscriptionTotalOrders = selectedSubscriptionPlan!.orderLimit;
        if (vendorModel.adminCommission?.commission == null || vendorModel.adminCommission?.commission == '') {
          vendorModel.adminCommission = selectedSectionModel!.adminCommision;
        }
      }

      await FireStoreUtils.updateVendor(vendorModel);
    }
    var subcriptionHistoryId = getUuid();
    SubscriptionHistoryModel subscriptionHistoryData = SubscriptionHistoryModel(
        id: subcriptionHistoryId,
        createdAt: Timestamp.now(),
        expiryDate: userModel!.subscriptionExpiryDate,
        subscriptionPlan: userModel!.subscriptionPlan,
        paymentType: selectedPaymentMethod,
        userId: userModel!.userID);

    await FireStoreUtils.setSubscriptionTransaction(subscriptionHistoryData);

    if (selectedPaymentMethod == PaymentGateway.wallet.name) {
      TopupTranHistoryModel wallet = TopupTranHistoryModel(
          amount: totalAmount,
          orderId: getUuid(),
          serviceType: 'delivery-service',
          id: subcriptionHistoryId,
          userId: MyAppState.currentUser!.userID,
          date: Timestamp.now(),
          isTopup: false,
          paymentMethod: "wallet",
          paymentStatus: "success",
          transactionUser: "customer",
          note: 'Subscription amount debit');

      await FireStoreUtils.firestore.collection("wallet").doc(wallet.id).set(wallet.toJson()).then((value) async {
        await FireStoreUtils.updateWalletAmount(userId: MyAppState.currentUser!.userID, amount: -totalAmount);
      });
    }

    if (userModel?.userID != null) {
      await FireStoreUtils.updateCurrentUser(userModel!).then(
        (value) async {
          log("userModel.section_id :: ${userModel?.section_id}");
          MyAppState.currentUser = userModel;
          ShowToastDialog.closeLoader();
          log("userModel?.subscriptionPlan?.features?.ownerMobileApp :: ${userModel?.subscriptionPlan?.features?.ownerMobileApp}");
          if (mounted) {
            if (userModel?.subscriptionPlan?.features?.ownerMobileApp == true) {
              log("userModel?.subscriptionPlan?.features?.ownerMobileApp :: 22 :: ${userModel?.subscriptionPlan?.features?.ownerMobileApp}");
              pushAndRemoveUntil(
                  context,
                  ContainerScreen(
                    user: MyAppState.currentUser!,
                    currentWidget: OrdersScreen(),
                    appBarTitle: 'Orders'.tr(),
                    drawerSelection: DrawerSelection.Orders,
                  ),
                  false);
              ShowToastDialog.showToast("Success! You’ve unlocked your subscription benefits starting today.".tr());
            } else {
              pushAndRemoveUntil(context, AppNotAccessScreen(), false);
            }
          }
        },
      );
    }
  }

  cardDecoration(PaymentGateway value, String image) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                selectedPaymentMethod = value.name;
              });
            },
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(width: 1, color: Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(value.name == "payFast" ? 0 : 8.0),
                    child: Image.asset(image, color: value.name == "wallet" ? AppThemeData.secondary300 : null),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                value.name == "wallet"
                    ? Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              value.name.capitalizeString(),
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontFamily: AppThemeData.medium,
                                fontSize: 16,
                                color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900,
                              ),
                            ),
                            Text(
                              amountShow(amount: MyAppState.currentUser!.walletAmount == null ? '0.0' : MyAppState.currentUser!.walletAmount.toString()),
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontFamily: AppThemeData.semiBold,
                                fontSize: 16,
                                color: isDarkMode(context) ? AppThemeData.primary300 : AppThemeData.primary300,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Expanded(
                        child: Text(
                          value.name.capitalizeString(),
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontFamily: AppThemeData.medium,
                            fontSize: 16,
                            color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900,
                          ),
                        ),
                      ),
                const Expanded(
                  child: SizedBox(),
                ),
                Radio(
                  value: value.name,
                  groupValue: selectedPaymentMethod,
                  activeColor: isDarkMode(context) ? AppThemeData.primary300 : AppThemeData.primary300,
                  onChanged: (value) {
                    setState(() {
                      selectedPaymentMethod = value.toString();
                    });
                  },
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void handlePaymentSuccess(PaymentSuccessResponse response) {
    ShowToastDialog.showToast("Payment Successful!!");
    setOrder();
  }

  void handleExternalWaller(ExternalWalletResponse response) {
    Navigator.pop(context);
    ShowToastDialog.showToast("Payment Processing!! via");
  }

  void handlePaymentError(PaymentFailureResponse response) {
    Navigator.pop(context);
    ShowToastDialog.showToast("Payment Failed!!");
  }

//stripe
  Future<void> stripeMakePayment({required String amount}) async {
    try {
      Map<String, dynamic>? paymentIntentData = await createStripeIntent(amount: amount);

      if (paymentIntentData!.containsKey("error")) {
        Navigator.pop(context);
        ShowToastDialog.showToast("Something went wrong, please contact admin.");
      } else {
        await Stripe.instance.initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
                paymentIntentClientSecret: paymentIntentData['client_secret'],
                allowsDelayedPaymentMethods: false,
                googlePay: const PaymentSheetGooglePay(
                  merchantCountryCode: 'US',
                  testEnv: true,
                  currencyCode: "USD",
                ),
                customFlow: true,
                style: ThemeMode.system,
                appearance: const PaymentSheetAppearance(
                  colors: PaymentSheetAppearanceColors(
                    primary: AppThemeData.primary300,
                  ),
                ),
                merchantDisplayName: 'eMart'));
        displayStripePaymentSheet(amount: amount);
      }
    } catch (e, s) {
      ShowToastDialog.showToast("exception:$e \n$s");
    }
  }

  displayStripePaymentSheet({required String amount}) async {
    try {
      await Stripe.instance.presentPaymentSheet().then((value) {
        ShowToastDialog.showToast("Payment successfully");
        setOrder();
      });
    } on StripeException catch (e) {
      var lo1 = jsonEncode(e);
      var lo2 = jsonDecode(lo1);
      StripePayFailedModel lom = StripePayFailedModel.fromJson(lo2);
      ShowToastDialog.showToast(lom.error.message);
    } catch (e) {
      ShowToastDialog.showToast(e.toString());
    }
  }

  createStripeIntent({required String amount}) async {
    try {
      Map<String, dynamic> body = {
        'amount': ((double.parse(amount) * 100).round()).toString(),
        'currency': "USD",
        'payment_method_types[]': 'card',
        "description": "Strip Payment",
        "shipping[name]": userModel!.fullName(),
        "shipping[address][line1]": "510 Townsend St",
        "shipping[address][postal_code]": "98140",
        "shipping[address][city]": "San Francisco",
        "shipping[address][state]": "CA",
        "shipping[address][country]": "US",
      };
      var stripeSecret = stripeModel!.stripeSecret;
      var response = await http.post(Uri.parse('https://api.stripe.com/v1/payment_intents'),
          body: body, headers: {'Authorization': 'Bearer $stripeSecret', 'Content-Type': 'application/x-www-form-urlencoded'});

      return jsonDecode(response.body);
    } catch (e) {
      print(e.toString());
    }
  }

  //mercadoo
  mercadoPagoMakePayment({required BuildContext context, required String amount}) async {
    final headers = {
      'Authorization': 'Bearer ${mercadoPagoModel!.accessToken}',
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
      "payer": {"email": userModel!.email},
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

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final bool isDone = await Navigator.push(context, MaterialPageRoute(builder: (context) => MercadoPagoScreen(initialURl: data['init_point'])));
      if (isDone) {
        ShowToastDialog.showToast("Payment Successful!!");
        setOrder();
      } else {
        ShowToastDialog.showToast("Payment UnSuccessful!!");
      }
    } else {
      print('Error creating preference: ${response.body}');
      return null;
    }
  }

//Paypal
  paypalPaymentSheet(String amount, context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => UsePaypal(
            sandboxMode: payPalModel!.isLive == true ? false : true,
            clientId: payPalModel!.paypalClient ?? '',
            secretKey: payPalModel!.paypalSecret ?? '',
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
              setOrder();
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

  ///PayStack Payment Method
  payStackPayment(String totalAmount) async {
    await PayStackURLGen.payStackURLGen(
            amount: (double.parse(totalAmount) * 100).toString(), currency: "ZAR", secretKey: payStackModel!.secretKey.toString(), userModel: userModel!)
        .then((value) async {
      if (value != null) {
        PayStackUrlModel payStackModel0 = value;

        bool isDone = await Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => PayStackScreen(
                  secretKey: payStackModel!.secretKey.toString(),
                  callBackUrl: payStackModel!.callbackURL.toString(),
                  initialURl: payStackModel0.data.authorizationUrl,
                  amount: totalAmount,
                  reference: payStackModel0.data.reference,
                )));

        if (isDone) {
          ShowToastDialog.showToast("Payment Successful!!");
          setOrder();
        } else {
          ShowToastDialog.showToast("Payment UnSuccessful!!");
        }
      } else {
        ShowToastDialog.showToast("Something went wrong, please contact admin.");
      }
    });
  }

  String? _ref;

  setRef() {
    maths.Random numRef = maths.Random();
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

  //flutter wave Payment Method
  flutterWaveInitiatePayment({required BuildContext context, required String amount}) async {
    final url = Uri.parse('https://api.flutterwave.com/v3/payments');
    final headers = {
      'Authorization': 'Bearer ${flutterWaveModel!.secretKey}',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "tx_ref": _ref,
      "amount": amount,
      "currency": "NGN",
      "redirect_url": "${GlobalURL}payment/success",
      "payment_options": "ussd, card, barter, payattitude",
      "customer": {
        "email": userModel!.email.toString(),
        "phonenumber": userModel!.phoneNumber, // Add a real phone number
        "name": userModel!.fullName(), // Add a real customer name
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
        setOrder();
      } else {
        ShowToastDialog.showToast("Payment UnSuccessful!!");
      }
    } else {
      print('Payment initialization failed: ${response.body}');
      return null;
    }
  }

  // payFast
  payFastPayment({required BuildContext context, required String amount}) {
    PayStackURLGen.getPayHTML(payFastSettingData: payFastModel!, amount: amount.toString(), userModel: userModel!).then((String? value) async {
      bool isDone = await Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => PayFastScreen(
                htmlData: value!,
                payFastSettingData: payFastModel!,
              )));
      if (isDone) {
        ShowToastDialog.showToast("Payment successfully");
        setOrder();
      } else {
        Navigator.pop(context);
        ShowToastDialog.showToast("Payment Failed");
      }
    });
  }

  ///Paytm payment function
  getPaytmCheckSum(context, {required double amount}) async {
    final String orderId = DateTime.now().millisecondsSinceEpoch.toString();
    String getChecksum = "${GlobalURL}payments/getpaytmchecksum";

    final response = await http.post(
        Uri.parse(
          getChecksum,
        ),
        headers: {},
        body: {
          "mid": paytmModel!.paytmMID.toString(),
          "order_id": orderId,
          "key_secret": paytmModel!.pAYTMMERCHANTKEY.toString(),
        });

    final data = jsonDecode(response.body);
    await verifyCheckSum(checkSum: data["code"], amount: amount, orderId: orderId).then((value) {
      initiatePayment(amount: amount, orderId: orderId).then((value) {
        String callback = "";
        if (paytmModel!.isSandboxEnabled == true) {
          callback = "${callback}https://securegw-stage.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
        } else {
          callback = "${callback}https://securegw.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
        }

        GetPaymentTxtTokenModel result = value;
        startTransaction(context, txnTokenBy: result.body.txnToken, orderId: orderId, amount: amount, callBackURL: callback, isStaging: paytmModel!.isSandboxEnabled);
      });
    });
  }

  Future<void> startTransaction(context, {required String txnTokenBy, required orderId, required double amount, required callBackURL, required isStaging}) async {
    // try {
    //   var response = AllInOneSdk.startTransaction(
    //     paytmModel.paytmMID.toString(),
    //     orderId,
    //     amount.toString(),
    //     txnTokenBy,
    //     callBackURL,
    //     isStaging,
    //     true,
    //     true,
    //   );
    //
    //   response.then((value) {
    //     if (value!["RESPMSG"] == "Txn Success") {
    //       print("txt done!!");
    //       ShowToastDialog.showToast("Payment Successful!!");
    //       setOrder(;
    //     }
    //   }).catchError((onError) {
    //     if (onError is PlatformException) {
    //       Navigator.pop(context);
    //
    //       ShowToastDialog.showToast(onError.message.toString());
    //     } else {
    //       log("======>>2");
    //       Navigator.pop(context);
    //       ShowToastDialog.showToast(onError.message.toString());
    //     }
    //   });
    // } catch (err) {
    //   Navigator.pop(context);
    //   ShowToastDialog.showToast(err.toString());
    // }
  }

  Future verifyCheckSum({required String checkSum, required double amount, required orderId}) async {
    String getChecksum = "${GlobalURL}payments/validatechecksum";
    final response = await http.post(
        Uri.parse(
          getChecksum,
        ),
        headers: {},
        body: {
          "mid": paytmModel!.paytmMID.toString(),
          "order_id": orderId,
          "key_secret": paytmModel!.pAYTMMERCHANTKEY.toString(),
          "checksum_value": checkSum,
        });
    final data = jsonDecode(response.body);
    return data['status'];
  }

  Future<GetPaymentTxtTokenModel> initiatePayment({required double amount, required orderId}) async {
    String initiateURL = "${GlobalURL}payments/initiatepaytmpayment";
    String callback = "";
    if (paytmModel!.isSandboxEnabled == true) {
      callback = "${callback}https://securegw-stage.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
    } else {
      callback = "${callback}https://securegw.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
    }
    final response = await http.post(Uri.parse(initiateURL), headers: {}, body: {
      "mid": paytmModel!.paytmMID,
      "order_id": orderId,
      "key_secret": paytmModel!.pAYTMMERCHANTKEY,
      "amount": amount.toString(),
      "currency": "INR",
      "callback_url": callback,
      "custId": MyAppState.currentUser!.userID,
      "issandbox": paytmModel!.isSandboxEnabled == true ? "1" : "2",
    });

    final data = jsonDecode(response.body);
    if (data["body"]["txnToken"] == null || data["body"]["txnToken"].toString().isEmpty) {
      Navigator.pop(context);
      ShowToastDialog.showToast("something went wrong, please contact admin.");
    }
    return GetPaymentTxtTokenModel.fromJson(data);
  }

  void openCheckout({required amount, required orderId}) async {
    var options = {
      'key': razorPayModel!.razorpayKey,
      'amount': amount * 100,
      'name': 'GoRide',
      'order_id': orderId,
      "currency": "INR",
      'description': 'wallet Topup',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': userModel!.phoneNumber,
        'email': userModel!.email,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      razorPay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  //Midtrans payment
  midtransMakePayment({required String amount, required BuildContext context}) async {
    await createPaymentLink(amount: amount).then((url) async {
      ShowToastDialog.closeLoader();
      if (url != '') {
        final bool isDone = await Navigator.push(context, MaterialPageRoute(builder: (context) => MidtransScreen(initialURl: url)));
        if (isDone) {
          ShowToastDialog.showToast("Payment Successful!!");
          setOrder();
        } else {
          ShowToastDialog.showToast("Payment Unsuccessful!!");
        }
      }
    });
  }

  Future<String> createPaymentLink({required var amount}) async {
    var ordersId = getUuid();
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
    var id = getUuid();
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
        setOrder();
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

    // Handle the response

    if (response.statusCode == 200) {
      Map<String, dynamic> responseData = jsonDecode(response.body);

      accessToken = responseData['access_token'];
      // ignore: use_build_context_synchronously
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
                      apiKey: xenditModel!.apiKey!.toString() ?? "",
                    )));

        if (isDone) {
          ShowToastDialog.showToast("Payment Successful!!");
          setOrder();
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
      'external_id': getUuid(),
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
}

enum PaymentGateway { payFast, mercadoPago, paypal, stripe, flutterWave, payStack, paytm, razorpay, cod, wallet, midTrans, orangeMoney, xendit }
