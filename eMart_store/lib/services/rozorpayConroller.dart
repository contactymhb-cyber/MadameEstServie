import 'dart:convert';

import 'package:emartstore/constants.dart';
import 'package:emartstore/model/createRazorPayOrderModel.dart';
import 'package:emartstore/model/payment_model/razorpay_model.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class RazorPayController {
  Future<CreateRazorPayOrderModel?> createOrderRazorPay({required double amount, bool isTopup = false, required RazorPayModel razorPayData}) async {
    print(razorPayData.razorpayKey);
    print("we Enter In");
    const url = "${GlobalURL}payments/razorpay/createorder";
    final response = await http.post(
      Uri.parse(url),
      body: {
        "amount": (amount * 100).round().toString(),
        "receipt_id": Uuid().v4(),
        "currency": currencyData?.code,
        "razorpaykey": razorPayData.razorpayKey,
        "razorPaySecret": razorPayData.razorpaySecret,
        "isSandBoxEnabled": razorPayData.isSandboxEnabled.toString(),
      },
    );

    if (response.statusCode == 500) {
      return null;
    } else {
      final data = jsonDecode(response.body);
      print(data);

      return CreateRazorPayOrderModel.fromJson(data);
    }
  }
}
