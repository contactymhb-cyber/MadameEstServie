class StripeSettingData {
  String clientpublishableKey;
  String stripeSecret;
  String stripeKey;
  bool isEnabled;
  bool isSandboxEnabled;
  bool isWithdrawEnabled;

  StripeSettingData({
    this.stripeKey = '',
    this.clientpublishableKey = '',
    this.stripeSecret = '',
    required this.isSandboxEnabled,
    required this.isEnabled,
    required this.isWithdrawEnabled,
  });

  factory StripeSettingData.fromJson(Map<String, dynamic> parsedJson) {
    return StripeSettingData(
      clientpublishableKey: parsedJson['clientpublishableKey'] ?? '',
      stripeSecret: parsedJson['stripeSecret'] ?? '',
      isSandboxEnabled: parsedJson['isSandboxEnabled'],
      isEnabled: parsedJson['isEnabled'],
      stripeKey: parsedJson['stripeKey'] ?? '',
      isWithdrawEnabled: parsedJson['isWithdrawEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stripeSecret': this.stripeSecret,
      'clientpublishableKey': this.clientpublishableKey,
      'isEnabled': this.isEnabled,
      'isSandboxEnabled': this.isSandboxEnabled,
      'stripeKey': this.stripeKey,
      'isWithdrawEnabled': this.isWithdrawEnabled,
    };
  }
}
