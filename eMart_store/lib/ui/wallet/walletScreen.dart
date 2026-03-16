import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emartstore/model/FlutterWaveSettingDataModel.dart';
import 'package:emartstore/model/OrderModel.dart';
import 'package:emartstore/model/paypalSettingData.dart';
import 'package:emartstore/model/razorpayKeyModel.dart';
import 'package:emartstore/model/stripeSettingData.dart';
import 'package:emartstore/model/topupTranHistory.dart';
import 'package:emartstore/model/withdrawHistoryModel.dart';
import 'package:emartstore/model/withdraw_method_model.dart';
import 'package:emartstore/services/FirebaseHelper.dart';
import 'package:emartstore/services/helper.dart';
import 'package:emartstore/services/show_toast_dailog.dart';
import 'package:emartstore/theme/app_them_data.dart';
import 'package:emartstore/theme/round_button_fill.dart';
import 'package:emartstore/ui/ordersScreen/OrderDetailsScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../constants.dart';
import '../../main.dart';
import '../../model/User.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  WalletScreenState createState() => WalletScreenState();
}

class WalletScreenState extends State<WalletScreen> {
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;
  Stream<QuerySnapshot>? withdrawHistoryQuery;

  String? selectedRadioTile;

  GlobalKey<FormState> _globalKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  TextEditingController _amountController =
      TextEditingController(text: 50.toString());
  TextEditingController _noteController = TextEditingController(text: '');

  getData() async {
    withdrawHistoryQuery = fireStore
        .collection(Payouts)
        .where('vendorID', isEqualTo: vendorId)
        .orderBy('paidDate', descending: true)
        .snapshots();
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
  final vendorId = MyAppState.currentUser!.vendorID;
  UserBankDetails? userBankDetail = MyAppState.currentUser!.userBankDetails;

  @override
  void initState() {
    getWalletTransaction(false);
    getData();
    // TODO: implement initState
    super.initState();
  }

  WithdrawMethodModel? withdrawMethodModel;
  int selectedValue = 0;
  RazorPayModel? razorPayModel;
  PaypalSettingData? paypalDataModel;
  StripeSettingData? stripeSettingData;
  FlutterWaveSettingData? flutterWaveSettingData;

  getPaymentMethod() async {
    await FireStoreUtils.firestore
        .collection(Setting)
        .doc("razorpaySettings")
        .get()
        .then((user) {
      debugPrint(user.data().toString());
      try {
        razorPayModel = RazorPayModel.fromJson(user.data() ?? {});
      } catch (e) {
        debugPrint(
            'FireStoreUtils.getUserByID failed to parse user object ${user.id}');
      }
    });

    await FireStoreUtils.firestore
        .collection(Setting)
        .doc("paypalSettings")
        .get()
        .then((paypalData) {
      try {
        paypalDataModel = PaypalSettingData.fromJson(paypalData.data() ?? {});
      } catch (error) {
        debugPrint(error.toString());
      }
    });

    await FireStoreUtils.firestore
        .collection(Setting)
        .doc("stripeSettings")
        .get()
        .then((paypalData) {
      try {
        stripeSettingData = StripeSettingData.fromJson(paypalData.data() ?? {});
      } catch (error) {
        debugPrint(error.toString());
      }
    });

    await FireStoreUtils.firestore
        .collection(Setting)
        .doc("flutterWave")
        .get()
        .then((paypalData) {
      try {
        flutterWaveSettingData =
            FlutterWaveSettingData.fromJson(paypalData.data() ?? {});
      } catch (error) {
        debugPrint(error.toString());
      }
    });

    await FireStoreUtils.getWithdrawMethod().then(
      (value) {
        if (value != null) {
          setState(() {
            withdrawMethodModel = value;
          });
        }
      },
    );
  }

  double orderAmount = 0.0;
  double taxAmount = 0.0;

  DateTime startDate = DateTime.now().subtract(const Duration(days: 1));
  DateTime endDate = DateTime.now();

  List<TopupTranHistoryModel> walletTransactionList = <TopupTranHistoryModel>[];
  User userModel = User();
  bool isLoading = true;

  Future<void> createAndSavePdf() async {
    if (await Permission.manageExternalStorage.request().isGranted) {
      // Create a new PDF document
      final PdfDocument document = PdfDocument();

      // Add a page to the document
      final PdfPage page = document.pages.add();

      // Create a PDF grid (table)
      final PdfGrid grid = PdfGrid();

      // Add columns to the grid
      grid.columns.add(count: 4);

      // Add headers to the grid
      grid.headers.add(1);
      final PdfGridRow header = grid.headers[0];
      header.cells[0].value = 'Description';
      header.cells[1].value = 'Order Id';
      header.cells[2].value = 'Amount';
      header.cells[3].value = 'Date';

      // Add rows to the grid
      PdfGridRow row = grid.rows.add();
      for (var element in walletTransactionList) {
        row.cells[0].value = element.note.toString();
        row.cells[1].value = orderId(orderId: element.orderId.toString());
        row.cells[2].value = amountShow(amount: element.amount.toString());
        row.cells[3].value = timestampToDateTime(element.date);
        row = grid.rows.add();
      }

      // Draw the grid on the page
      grid.draw(
        page: page,
        bounds: const Rect.fromLTWH(0, 0, 0, 0),
      );

      // Save the document
      final List<int> bytes = document.saveSync();

      // Dispose of the document
      document.dispose();
      Directory? downloadsDirectory;
      if (Platform.isAndroid) {
        // Get the application directory
        downloadsDirectory = Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS) {
        downloadsDirectory =
            await getApplicationDocumentsDirectory(); // iOS storage
      }
      if (!downloadsDirectory!.existsSync()) {
        downloadsDirectory.createSync(recursive: true);
      }
      final String path = '${downloadsDirectory.path}/statement.pdf';
      final File file = File(path);
      await file.writeAsBytes(bytes, flush: true);
      ShowToastDialog.showToast(
          "${"The statement has been successfully downloaded to the".tr()} ${path} ${"folder.".tr()}.");
      print('PDF saved at: $path');
    } else {
      ShowToastDialog.showToast("Storage permission denied".tr());
    }
  }

  datePicker(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 440, // Height of the bottom sheet
          color: AppThemeData.grey50,
          child: Column(
            children: [
              SfDateRangePicker(
                backgroundColor: AppThemeData.grey50,
                onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
                  // Store the selected date range
                  if (args.value is PickerDateRange) {
                    startDate = args.value.startDate;
                    endDate = args.value.endDate;
                  }
                },
                selectionMode: DateRangePickerSelectionMode.range,
                maxDate: DateTime.now(),
                initialSelectedRange: PickerDateRange(
                  startDate,
                  endDate,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RoundedButtonFill(
                  title: "Filter".tr(),
                  color: AppThemeData.secondary300,
                  textColor: AppThemeData.grey50,
                  onPress: () async {
                    Navigator.of(context).pop();
                    ShowToastDialog.showLoader("Please wait");
                    await getWalletTransaction(true);
                    ShowToastDialog.closeLoader();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RoundedButtonFill(
                  title: "Clear".tr(),
                  color: AppThemeData.grey50,
                  textColor: AppThemeData.secondary300,
                  onPress: () async {
                    Navigator.of(context).pop();
                    await getWalletTransaction(false);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  getWalletTransaction(bool isFilter) async {
    if (isFilter) {
      await FireStoreUtils.getFilterWalletTransaction(
              Timestamp.fromDate(DateTime(
                  startDate.year, startDate.month, startDate.day, 00, 00)),
              Timestamp.fromDate(
                  DateTime(endDate.year, endDate.month, endDate.day, 23, 59)))
          .then(
        (value) {
          if (value != null) {
            taxAmount = 0;
            orderAmount = 0;
            walletTransactionList = value;

            walletTransactionList
                .where((element) => element.paymentMethod == "tax")
                .toList();
            walletTransactionList.forEach(
              (element) {
                if (element.paymentMethod == "tax") {
                  taxAmount += double.parse(element.amount.toString());
                } else {
                  if (element.note != "Subscription amount debit")
                    orderAmount += double.parse(element.amount.toString());
                }
              },
            );
          }
        },
      );
    } else {
      await FireStoreUtils.getWalletTransaction().then(
        (value) {
          if (value != null) {
            taxAmount = 0;
            orderAmount = 0;
            walletTransactionList = value;

            walletTransactionList
                .where((element) => element.paymentMethod == "tax")
                .toList();
            walletTransactionList.forEach(
              (element) {
                if (element.paymentMethod == "tax") {
                  taxAmount += double.parse(element.amount.toString());
                } else {
                  if (element.note != "Subscription amount debit")
                    orderAmount += double.parse(element.amount.toString());
                }
              },
            );
          }
        },
      );
    }
    await FireStoreUtils.getCurrentUser(MyAppState.currentUser!.userID).then(
      (value) {
        if (value != null) {
          userModel = value;
          MyAppState.currentUser = userModel;
        }
      },
    );
    await getPaymentMethod();
    isLoading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      key: _scaffoldKey,
      body: Container(
        color: Colors.black.withOpacity(0.03),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                  image: DecorationImage(
                      fit: BoxFit.cover,
                      image: AssetImage("assets/images/wallet_img_@3x.png"))),
              width: size.width,
              height: size.height * 0.34,
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Total Wallet amount".tr(),
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16),
                          ),
                          Padding(
                              padding:
                                  const EdgeInsets.only(top: 5.0, bottom: 0.0),
                              child: Text(
                                "${amountShow(amount: userModel.walletAmount.toString())}",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18),
                              )),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                "Order Amount".tr(),
                                maxLines: 1,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  overflow: TextOverflow.ellipsis,
                                  fontFamily: AppThemeData.regular,
                                ),
                              ),
                              Text(
                                amountShow(amount: orderAmount.toString()),
                                maxLines: 1,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  overflow: TextOverflow.ellipsis,
                                  fontFamily: AppThemeData.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                "Total Tax.".tr(),
                                maxLines: 1,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  overflow: TextOverflow.ellipsis,
                                  fontFamily: AppThemeData.regular,
                                ),
                              ),
                              Text(
                                amountShow(amount: taxAmount.toString()),
                                maxLines: 1,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  overflow: TextOverflow.ellipsis,
                                  fontFamily: AppThemeData.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      children: [
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: RoundedButtonFill(
                            title: "Download Statement".tr(),
                            height: 5,
                            color: AppThemeData.success500,
                            textColor: AppThemeData.grey50,
                            onPress: () async {
                              await createAndSavePdf();
                            },
                          ),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: InkWell(
                            onTap: () {
                              datePicker(context);
                            },
                            child: const Icon(
                              Icons.filter_alt,
                              size: 32,
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: showTopupHistory(context)),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: Row(
          children: [
            Expanded(
                child:
                    buildButton(context, title: 'WITHDRAW'.tr(), onPress: () {
              if (MyAppState.currentUser!.vendorID.isNotEmpty) {
                if (MyAppState.currentUser!.userBankDetails.accountNumber
                        .isNotEmpty ||
                    (withdrawMethodModel != null &&
                        (withdrawMethodModel!.flutterWave != null ||
                            withdrawMethodModel!.paypal != null ||
                            withdrawMethodModel!.razorpay != null ||
                            withdrawMethodModel!.stripe != null))) {
                  withdrawAmount(context);
                } else {
                  ShowToastDialog.showToast("Please add payment method".tr());
                }
              } else {
                final snackBar = SnackBar(
                  backgroundColor: Colors.red[400],
                  content: Text(
                    'Please add your Store first'.tr(),
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              }
            })),
            SizedBox(
              width: 10,
            ),
            Expanded(
              child: buildButton(
                context,
                title: 'Withdraw history'.tr(),
                onPress: () {
                  withdrawalHistoryBottomSheet(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  withdrawalHistoryBottomSheet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return showModalBottomSheet(
        backgroundColor:
            isDarkMode(context) ? Color(DARK_CARD_BG_COLOR) : Colors.white,
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25), topRight: Radius.circular(25)),
        ),
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Container(
              height: size.height,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 80.0),
                    child: showWithdrawHistory(context),
                  ),
                  Positioned(
                    top: 40,
                    left: 15,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios,
                      ),
                    ),
                  ),
                ],
              ),
            );
          });
        });
  }

  Widget showWithdrawHistory(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: withdrawHistoryQuery,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong'.tr()));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: SizedBox(
                  height: 35, width: 35, child: CircularProgressIndicator()));
        }
        if (snapshot.data == null || snapshot.data?.docs.isEmpty == true) {
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
              return buildWithdrawTransactionCard(
                withdrawHistory: topUpData,
                date: topUpData.paidDate.toDate(),
              );
            }).toList(),
          );
        }
      },
    );
  }

  Widget buildWithdrawTransactionCard(
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
          color: isDarkMode(context) ? Color(DARK_CARD_BG_COLOR) : Colors.white,
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
                          width: size.width * 0.48,
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
                              "- ${amountShow(amount: withdrawHistory.amount.toString())}",
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

  Widget showTopupHistory(BuildContext context) {
    return isLoading == true
        ? Center(
            child: SizedBox(
                height: 35, width: 35, child: CircularProgressIndicator()))
        : walletTransactionList.isEmpty == true
            ? Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Center(
                    child: Text(
                  "No Transaction History".tr(),
                  style: TextStyle(fontSize: 18),
                )))
            : ListView.builder(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: walletTransactionList.length,
                itemBuilder: (context, index) {
                  final topupTranHistory = walletTransactionList[index];
                  final size = MediaQuery.of(context).size;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6.0, vertical: 3),
                    child: GestureDetector(
                      onTap: () => showTransactionDetails(
                          topupTranHistory: topupTranHistory),
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
                                    child: Icon(
                                        Icons.account_balance_wallet_rounded,
                                        size: 28,
                                        color: Color(COLOR_PRIMARY)),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: size.width * 0.78,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: size.width * 0.48,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            topupTranHistory.note != null ||
                                                    topupTranHistory
                                                            .note?.isEmpty ==
                                                        true
                                                ? topupTranHistory.note
                                                    .toString()
                                                : topupTranHistory.isTopup
                                                    ? "Order Amount".tr()
                                                    : "Admin commission Deducted"
                                                        .tr(),
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
                                              "${DateFormat('KK:mm:ss a, dd MMM yyyy').format(topupTranHistory.date.toDate()).toUpperCase()}",
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
                                            //  "${topupTranHistory.isTopup ? "+" : "-"} ${amountShow(amount: topupTranHistory.amount.toString())}",
                                            topupTranHistory.isTopup
                                                ? "${"+"} ${amountShow(amount: topupTranHistory.amount.toString())}"
                                                : "(${"-"} ${amountShow(amount: topupTranHistory.amount.toString())})",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: topupTranHistory.isTopup
                                                  ? Colors.green
                                                  : Colors.red,
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
                    ),
                  );
                });
  }

  showTransactionDetails({
    required TopupTranHistoryModel topupTranHistory,
  }) {
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
                                  topupTranHistory.id,
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
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
                              width: size.width * 0.48,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${DateFormat('KK:mm:ss a, dd MMM yyyy').format(topupTranHistory.date.toDate())}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Opacity(
                                    opacity: 0.7,
                                    child: Text(
                                      topupTranHistory.note != null ||
                                              topupTranHistory.note != ''
                                          ? topupTranHistory.note!
                                          : topupTranHistory.isTopup
                                              ? "Order Amount".tr()
                                              : "Admin commission Deducted"
                                                  .tr(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  //  "${topupTranHistory.isTopup ? "+" : "-"} ${amountShow(amount: topupTranHistory.amount.toString())}",
                                  topupTranHistory.isTopup
                                      ? "${"+"} ${amountShow(amount: topupTranHistory.amount.toString())}"
                                      : "(${"-"} ${amountShow(amount: topupTranHistory.amount.toString())})",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: topupTranHistory.isTopup
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(
                                  height: 8,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )),
                if (topupTranHistory.note != 'Subscription amount debit')
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          "${DateFormat('KK:mm:ss a, dd MMM yyyy').format(topupTranHistory.date.toDate()).toUpperCase()}",
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
                              await FireStoreUtils.firestore
                                  .collection(ORDERS)
                                  .doc(topupTranHistory.orderId)
                                  .get()
                                  .then((value) {
                                OrderModel orderModel =
                                    OrderModel.fromJson(value.data()!);
                                push(
                                    context,
                                    OrderDetailsScreen(
                                      orderModel: orderModel,
                                    ));
                              });
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

  Widget buildTransactionCard({
    required WithdrawHistoryModel withdrawHistory,
    required DateTime date,
  }) {
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
                              "- ${amountShow(amount: withdrawHistory.amount.toString())}",
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

  withdrawAmount(BuildContext context) {
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
                          color:
                              isDarkMode(context) ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15.0, vertical: 25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MyAppState.currentUser!.userBankDetails.accountNumber
                                  .isEmpty
                              ? SizedBox()
                              : Card(
                                  color: isDarkMode(context)
                                      ? Color(DARK_CARD_BG_COLOR)
                                      : Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        10), // if you need this
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
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontFamily:
                                                          AppThemeData.medium,
                                                      color: Colors.black,
                                                      fontSize: 16),
                                                )
                                              ],
                                            ),
                                            Radio(
                                              value: 0,
                                              visualDensity:
                                                  const VisualDensity(
                                                      horizontal: VisualDensity
                                                          .minimumDensity,
                                                      vertical: VisualDensity
                                                          .minimumDensity),
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
                                      flutterWaveSettingData!
                                              .isWithdrawEnabled ==
                                          false)
                              ? SizedBox()
                              : Card(
                                  color: isDarkMode(context)
                                      ? Color(DARK_CARD_BG_COLOR)
                                      : Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        10), // if you need this
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
                                              visualDensity:
                                                  const VisualDensity(
                                                      horizontal: VisualDensity
                                                          .minimumDensity,
                                                      vertical: VisualDensity
                                                          .minimumDensity),
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
                                  (paypalDataModel != null &&
                                      paypalDataModel!.isWithdrawEnabled ==
                                          false)
                              ? SizedBox()
                              : Card(
                                  color: isDarkMode(context)
                                      ? Color(DARK_CARD_BG_COLOR)
                                      : Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        10), // if you need this
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
                                              visualDensity:
                                                  const VisualDensity(
                                                      horizontal: VisualDensity
                                                          .minimumDensity,
                                                      vertical: VisualDensity
                                                          .minimumDensity),
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
                                  (razorPayModel != null &&
                                      razorPayModel!.isWithdrawEnabled == false)
                              ? SizedBox()
                              : Card(
                                  color: isDarkMode(context)
                                      ? Color(DARK_CARD_BG_COLOR)
                                      : Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        10), // if you need this
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
                                              visualDensity:
                                                  const VisualDensity(
                                                      horizontal: VisualDensity
                                                          .minimumDensity,
                                                      vertical: VisualDensity
                                                          .minimumDensity),
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
                                  (stripeSettingData != null &&
                                      stripeSettingData!.isWithdrawEnabled ==
                                          false)
                              ? SizedBox()
                              : Card(
                                  color: isDarkMode(context)
                                      ? Color(DARK_CARD_BG_COLOR)
                                      : Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        10), // if you need this
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
                                              visualDensity:
                                                  const VisualDensity(
                                                      horizontal: VisualDensity
                                                          .minimumDensity,
                                                      vertical: VisualDensity
                                                          .minimumDensity),
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
                              text: "Amount to Withdraw".tr(),
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode(context)
                                    ? Colors.white70
                                    : Colors.black.withOpacity(0.7),
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
                              log("validator :: ${value} :: ${userModel.walletAmount}");
                              if (value!.isEmpty) {
                                return "*required Field".tr();
                              } else {
                                if (double.parse(value) <= 0) {
                                  return "*Invalid Amount".tr();
                                } else if (double.parse(value) >
                                    userModel.walletAmount) {
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
                                  currencyData!.symbol,
                                  style: TextStyle(
                                    color: isDarkMode(context)
                                        ? Colors.white
                                        : Colors.black,
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
                          withdrawRequest();
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
    FireStoreUtils.createPaymentId(collectionName: Payouts).then((value) async {
      final paymentID = value;

      WithdrawHistoryModel withdrawHistory = WithdrawHistoryModel(
        amount: double.parse(_amountController.text),
        vendorID: vendorId,
        paymentStatus: "Pending",
        paidDate: Timestamp.now(),
        id: paymentID.toString(),
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
      );

      print(withdrawHistory.vendorID);

      await FireStoreUtils.withdrawWalletAmount(
              withdrawHistory: withdrawHistory)
          .then((value) async {
        await FireStoreUtils.updateWalletAmount(
                userId: userId, amount: -double.parse(_amountController.text))
            .whenComplete(() async {
          User? userdata = await FireStoreUtils.getCurrentUser(
              MyAppState.currentUser!.userID);
          if (userdata?.userID != null) {
            userModel = userdata!;
            MyAppState.currentUser = userModel;
            setState(() {});
          }
          Navigator.pop(_scaffoldKey.currentContext!);
          FireStoreUtils.sendPayoutMail(
              amount: _amountController.text,
              payoutrequestid: paymentID.toString());
          ScaffoldMessenger.of(_scaffoldKey.currentContext!)
              .showSnackBar(SnackBar(
            content: Text("Payment Successful!!".tr()),
            backgroundColor: Colors.green,
          ));
        });
      });
    });
  }

  buildButton(context, {required String title, required Function()? onPress}) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width * 0.9,
      child: MaterialButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        color: Color(0xFF00B761),
        height: 45,
        onPressed: onPress,
        child: Text(
          title,
          style: TextStyle(fontSize: 16, color: Colors.white),
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
              const Text('Please wait!!').tr(),
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
