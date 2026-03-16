class PaypalSettingData {
  bool isEnabled;
  bool isLive;
  bool isWithdrawEnabled;
  String paypalSecret;
  String paypalClient;

  PaypalSettingData({required this.isLive, required this.isEnabled, required this.paypalSecret, required this.paypalClient,required this.isWithdrawEnabled});

  factory PaypalSettingData.fromJson(Map<String, dynamic> parsedJson) {
    return PaypalSettingData(
      paypalSecret: parsedJson['paypalSecret'] ?? '',
      paypalClient: parsedJson['paypalClient'] ?? '',
      isLive: parsedJson['isLive'],
      isEnabled: parsedJson['isEnabled'],
      isWithdrawEnabled: parsedJson['isWithdrawEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'isLive': isLive,
      'paypalSecret': paypalSecret,
      'paypalClient': paypalClient,
      'isWithdrawEnabled': isWithdrawEnabled,
    };
  }
}
