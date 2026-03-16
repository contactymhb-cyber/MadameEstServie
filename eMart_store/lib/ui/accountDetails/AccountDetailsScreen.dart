import 'package:easy_localization/easy_localization.dart';
import 'package:emartstore/constants.dart';
import 'package:emartstore/main.dart';
import 'package:emartstore/services/FirebaseHelper.dart';
import 'package:emartstore/services/helper.dart';
import 'package:emartstore/services/show_toast_dailog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class AccountDetailsScreen extends StatefulWidget {
  // final User user;
  AccountDetailsScreen({Key? key}) : super(key: key);

  @override
  _AccountDetailsScreenState createState() {
    return _AccountDetailsScreenState();
  }
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  GlobalKey<FormState> _key = new GlobalKey();
  AutovalidateMode _validate = AutovalidateMode.disabled;
  final TextEditingController firstName = TextEditingController();
  final TextEditingController lastName = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController mobile = TextEditingController();
  FireStoreUtils fireStoreUtils = FireStoreUtils();
  @override
  void initState() {
    super.initState();
    FireStoreUtils.getCurrentUser(MyAppState.currentUser!.userID).then((value) {
      setState(() {
        firstName.text = MyAppState.currentUser!.firstName;
        lastName.text = MyAppState.currentUser!.lastName;
        email.text = MyAppState.currentUser!.email;
        mobile.text = MyAppState.currentUser!.phoneNumber;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            'Account Details'.tr(),
            style: TextStyle(
              color: isDarkMode(context) ? Color(0xFFFFFFFF) : Color(0Xff333333),
            ),
          ),
          automaticallyImplyLeading: false,
          leading: GestureDetector(
              onTap: () {
                Navigator.pop(context, true);
              },
              child: Icon(Icons.arrow_back)),
        ),
        body: Form(
          key: _key,
          autovalidateMode: _validate,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16, bottom: 8, top: 24),
              child: Text(
                'PUBLIC INFO'.tr(),
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ).tr(),
            ),
            Material(
                elevation: 2,
                color: isDarkMode(context) ? Colors.black12 : Colors.white,
                child: ListView(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: ListTile.divideTiles(context: context, tiles: [
                      ListTile(
                        title: Text(
                          'First Name'.tr(),
                          style: TextStyle(
                            color: isDarkMode(context) ? Colors.white : Colors.black,
                          ),
                        ).tr(),
                        trailing: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 100),
                          child: TextFormField(
                            controller: firstName,
                            validator: validateName,
                            textInputAction: TextInputAction.next,
                            textAlign: TextAlign.end,
                            style: TextStyle(fontSize: 18, color: isDarkMode(context) ? Colors.white : Colors.black),
                            cursorColor: Color(COLOR_ACCENT),
                            textCapitalization: TextCapitalization.words,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(border: InputBorder.none, hintText: 'First Name'.tr(), contentPadding: EdgeInsets.symmetric(vertical: 5)),
                          ),
                        ),
                      ),
                      ListTile(
                        title: Text(
                          'Last Name'.tr(),
                          style: TextStyle(color: isDarkMode(context) ? Colors.white : Colors.black),
                        ).tr(),
                        trailing: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 100),
                          child: TextFormField(
                            controller: lastName,
                            validator: validateName,
                            textInputAction: TextInputAction.next,
                            textAlign: TextAlign.end,
                            style: TextStyle(fontSize: 18, color: isDarkMode(context) ? Colors.white : Colors.black),
                            cursorColor: Color(COLOR_ACCENT),
                            textCapitalization: TextCapitalization.words,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(border: InputBorder.none, hintText: 'Last Name'.tr(), contentPadding: EdgeInsets.symmetric(vertical: 5)),
                          ),
                        ),
                      ),
                    ]).toList())),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16, bottom: 8, top: 24),
              child: Text(
                'PRIVATE DETAILS'.tr(),
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ).tr(),
            ),
            Material(
              elevation: 2,
              color: isDarkMode(context) ? Colors.black12 : Colors.white,
              child: ListView(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  children: ListTile.divideTiles(
                    context: context,
                    tiles: [
                      ListTile(
                        title: Text(
                          'Email Address'.tr(),
                          style: TextStyle(color: isDarkMode(context) ? Colors.white : Colors.black),
                        ).tr(),
                        trailing: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 200),
                          child: TextFormField(
                            controller: email,
                            validator: validateEmail,
                            textInputAction: TextInputAction.next,
                            textAlign: TextAlign.end,
                            enabled: false,
                            style: TextStyle(fontSize: 18, color: isDarkMode(context) ? Colors.white : Colors.black),
                            cursorColor: Color(COLOR_ACCENT),
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(border: InputBorder.none, hintText: 'Email Address'.tr(), contentPadding: EdgeInsets.symmetric(vertical: 5)),
                          ),
                        ),
                      ),
                      ListTile(
                        title: Text(
                          'phoneNumber'.tr(),
                          style: TextStyle(color: isDarkMode(context) ? Colors.white : Colors.black),
                        ).tr(),
                        trailing: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 200),
                          child: TextFormField(
                            controller: mobile,
                            validator: validateEmail,
                            textInputAction: TextInputAction.next,
                            textAlign: TextAlign.end,
                            enabled: false,
                            style: TextStyle(fontSize: 18, color: isDarkMode(context) ? Colors.white : Colors.black),
                            cursorColor: Color(COLOR_ACCENT),
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(border: InputBorder.none, hintText: 'Email Address'.tr(), contentPadding: EdgeInsets.symmetric(vertical: 5)),
                          ),
                        ),
                      ),

                      // ListTile(
                      //   title: Text(
                      //     'phoneNumber'.tr(),
                      //     style: TextStyle(color: isDarkMode(context) ? Colors.white : Colors.black),
                      //   ).tr(),
                      //   trailing: InkWell(
                      //     onTap: () {
                      //       showAlertDialog(context);
                      //     },
                      //     child: Text(MyAppState.currentUser!.phoneNumber),
                      //   ),
                      // ),
                    ],
                  ).toList()),
            ),
            Padding(
                padding: const EdgeInsets.only(top: 32.0, bottom: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: double.infinity),
                  child: Material(
                    elevation: 2,
                    color: isDarkMode(context) ? Colors.black12 : Colors.white,
                    child: CupertinoButton(
                      padding: const EdgeInsets.all(12.0),
                      onPressed: () async {
                        _validateAndSave(context);
                      },
                      child: Text(
                        'Save'.tr(),
                        style: TextStyle(fontSize: 18, color: Color(COLOR_PRIMARY)),
                      ).tr(),
                    ),
                  ),
                )),
          ]),
        ));
  }

  _validateAndSave(BuildContext buildContext) async {
    if (_key.currentState?.validate() ?? false) {
      _key.currentState?.save();
      ShowToastDialog.showLoader('Saving details...'.tr());
      await _updateUser(buildContext);
    } else {
      setState(() {
        _validate = AutovalidateMode.onUserInteraction;
      });
    }
  }

  _updateUser(BuildContext buildContext) async {
    MyAppState.currentUser!.firstName = firstName.text;
    MyAppState.currentUser!.lastName = lastName.text;
    MyAppState.currentUser!.email = email.text;
    MyAppState.currentUser!.phoneNumber = mobile.text;
    var updatedUser = await FireStoreUtils.updateCurrentUser(MyAppState.currentUser!);

    if (updatedUser != null) {
      ShowToastDialog.closeLoader();
      ScaffoldMessenger.of(buildContext).showSnackBar(SnackBar(
          content: Text(
        'Details saved successfully',
        style: TextStyle(fontSize: 17),
      ).tr()));
    } else {
      ShowToastDialog.closeLoader();
      ScaffoldMessenger.of(buildContext).showSnackBar(SnackBar(
          content: Text(
        "Couldn't save details, Please try again.",
        style: TextStyle(fontSize: 17),
      ).tr()));
    }
  }

  bool _isPhoneValid = false;
  String? _phoneNumber = "";

  showAlertDialog(BuildContext context) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: const Text("Cancel").tr(),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = TextButton(
      child: const Text("continue").tr(),
      onPressed: () {
        if (_isPhoneValid) {
          setState(() {
            MyAppState.currentUser!.phoneNumber = _phoneNumber.toString();
            mobile.text = _phoneNumber.toString();
          });
          Navigator.pop(context);
        }
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Change Phone Number").tr(),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), shape: BoxShape.rectangle, border: Border.all(color: Colors.grey.shade200)),
        child: InternationalPhoneNumberInput(
          onInputChanged: (value) {
            _phoneNumber = "${value.phoneNumber}";
          },
          onInputValidated: (bool value) => _isPhoneValid = value,
          ignoreBlank: true,
          autoValidateMode: AutovalidateMode.onUserInteraction,
          inputDecoration: InputDecoration(
            hintText: 'Phone Number'.tr(),
            border: const OutlineInputBorder(
              borderSide: BorderSide.none,
            ),
            isDense: true,
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide.none,
            ),
          ),
          inputBorder: const OutlineInputBorder(
            borderSide: BorderSide.none,
          ),
          initialValue: PhoneNumber(isoCode: 'US'),
          selectorConfig: const SelectorConfig(selectorType: PhoneInputSelectorType.DIALOG),
          searchBoxDecoration: InputDecoration(
            hintText: 'Search by country name or dial code'.tr(),
          ),
        ),
      ),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
