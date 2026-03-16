import 'package:cloud_firestore/cloud_firestore.dart';

class WithdrawHistoryModel {
  String vendorID;

  num amount;

  String note;

  String paymentStatus;
  String withdrawMethod;

  Timestamp paidDate;

  String id, adminNote;

  WithdrawHistoryModel({
    required this.amount,
    required this.vendorID,
    required this.paymentStatus,
    required this.withdrawMethod,
    required this.paidDate,
    required this.id,
    required this.note,
    this.adminNote = "",
  });

  factory WithdrawHistoryModel.fromJson(Map<String, dynamic> parsedJson) {
    return WithdrawHistoryModel(
      amount: parsedJson['amount'],
      id: parsedJson['id'],
      paidDate: parsedJson['paidDate'] ?? '',
      paymentStatus: parsedJson['paymentStatus'] ?? 'Pending',
      withdrawMethod: parsedJson['withdrawMethod'] ?? '',
      vendorID: parsedJson['vendorID'],
      note: parsedJson['note'] ?? "",
      adminNote: parsedJson['adminNote'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'amount': this.amount,
      'id': this.id,
      'paidDate': this.paidDate,
      'paymentStatus': this.paymentStatus,
      'withdrawMethod': this.withdrawMethod,
      'vendorID': this.vendorID,
      'note': this.note,
      'adminNote': this.adminNote,
    };
    return json;
  }
}
