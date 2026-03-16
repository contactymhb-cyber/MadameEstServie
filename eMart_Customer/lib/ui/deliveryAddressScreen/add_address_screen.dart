import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:emartconsumer/constants.dart';
import 'package:emartconsumer/main.dart';
import 'package:emartconsumer/model/AddressModel.dart';
import 'package:emartconsumer/model/User.dart';
import 'package:emartconsumer/services/FirebaseHelper.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/services/show_toast_dialog.dart';
import 'package:emartconsumer/theme/app_them_data.dart';
import 'package:emartconsumer/theme/round_button_fill.dart';
import 'package:emartconsumer/widget/place_picker_osm.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:uuid/uuid.dart';

class AddAddressScreen extends StatefulWidget {
  final int? index;

  const AddAddressScreen({super.key, this.index});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  TextEditingController address = TextEditingController();
  TextEditingController landmark = TextEditingController();
  TextEditingController locality = TextEditingController();
  List saveAsList = ['Home'.tr(), 'Work'.tr(), 'Hotel'.tr(), 'other'.tr()];
  String selectedSaveAs = "Home";

  UserLocation? userLocation;
  AddressModel addressModel = AddressModel();

  List<AddressModel> shippingAddress = [];

  @override
  void initState() {
    // TODO: implement initState
    getData();
    super.initState();
  }

  getData() {
    if (MyAppState.currentUser != null) {
      if (MyAppState.currentUser!.shippingAddress != null) {
        shippingAddress = MyAppState.currentUser!.shippingAddress!;
      }
    }
    if (widget.index != null) {
      addressModel = shippingAddress[widget.index!];
      address.text = addressModel.address.toString();
      landmark.text = addressModel.landmark.toString();
      locality.text = addressModel.locality.toString();
      selectedSaveAs = addressModel.addressAs.toString();
      userLocation = addressModel.location;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode(context) ? AppThemeData.surfaceDark : AppThemeData.surface,
      appBar: AppBar(
        backgroundColor: isDarkMode(context) ? AppThemeData.surfaceDark : AppThemeData.surface,
        centerTitle: false,
        title: Text(
          'Add Address'.tr(),
          style: TextStyle(fontFamily: AppThemeData.regular, color: isDarkMode(context) ? Colors.white : Colors.black),
        ).tr(),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            children: [
              Container(
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          if (selectedMapType == 'osm') {
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => LocationPicker())).then(
                              (value) {
                                if (value != null) {
                                  locality.text = value.displayName!.toString();
                                  userLocation = UserLocation(latitude: value.lat, longitude: value.lon);
                                }
                              },
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlacePicker(
                                  apiKey: GOOGLE_API_KEY,
                                  onPlacePicked: (result) {
                                    locality.text = result.formattedAddress!.toString();
                                    userLocation = UserLocation(latitude: result.geometry!.location.lat, longitude: result.geometry!.location.lng);
                                    log(result.toString());

                                    Navigator.of(context).pop();
                                  },
                                  initialPosition: LatLng(-33.8567844, 151.213108),
                                  useCurrentLocation: true,
                                  selectInitialPosition: true,
                                  usePinPointingSearch: true,
                                  usePlaceDetailSearch: true,
                                  zoomGesturesEnabled: true,
                                  zoomControlsEnabled: true,
                                  initialMapType: MapType.terrain,
                                  resizeToAvoidBottomInset: false, // only works in page mode, less flickery, remove if wrong offsets
                                ),
                              ),
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Icon(Icons.location_searching_sharp, color: AppThemeData.primary300),
                              SizedBox(
                                width: 10,
                              ),
                              Text(
                                "Choose location *".tr(),
                                style: TextStyle(color: AppThemeData.primary300, fontFamily: AppThemeData.regular, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Container(
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Save address as *".tr(),
                          style: TextStyle(fontFamily: AppThemeData.regular, fontSize: 14),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        height: 34,
                        child: ListView.builder(
                          itemCount: saveAsList.length,
                          shrinkWrap: true,
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  selectedSaveAs = saveAsList[index].toString().tr();
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 5),
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: selectedSaveAs == saveAsList[index].toString()
                                          ? AppThemeData.primary300
                                          : isDarkMode(context)
                                              ? Colors.black
                                              : Colors.grey.withOpacity(0.20),
                                      borderRadius: const BorderRadius.all(Radius.circular(10))),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 30),
                                    child: Center(
                                      child: Text(
                                        saveAsList[index].toString().tr(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: selectedSaveAs == saveAsList[index].toString()
                                              ? Colors.white
                                              : isDarkMode(context)
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextFormField(
                          textCapitalization: TextCapitalization.sentences,
                          controller: address,
                          maxLines: 1,
                          style: TextStyle(color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900, fontFamily: AppThemeData.medium),
                          decoration: InputDecoration(
                            errorStyle: const TextStyle(color: Colors.red),
                            filled: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                            fillColor: isDarkMode(context) ? AppThemeData.grey800 : AppThemeData.grey100,
                            disabledBorder: UnderlineInputBorder(
                              borderRadius: const BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: isDarkMode(context) ? AppThemeData.grey900 : AppThemeData.grey50, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: const BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: isDarkMode(context) ? AppThemeData.primary300 : AppThemeData.primary300, width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: const BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: isDarkMode(context) ? AppThemeData.grey900 : AppThemeData.grey50, width: 1),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: const BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: isDarkMode(context) ? AppThemeData.grey900 : AppThemeData.grey50, width: 1),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: const BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: isDarkMode(context) ? AppThemeData.grey900 : AppThemeData.grey50, width: 1),
                            ),
                            hintText: "flat/house/floor/building *".tr(),
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: isDarkMode(context) ? AppThemeData.grey600 : AppThemeData.grey400,
                              fontFamily: AppThemeData.regular,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextFormField(
                          textCapitalization: TextCapitalization.sentences,
                          controller: locality,
                          maxLines: 1,
                          style: TextStyle(color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900, fontFamily: AppThemeData.medium),
                          decoration: InputDecoration(
                            errorStyle: const TextStyle(color: Colors.red),
                            filled: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                            fillColor: isDarkMode(context) ? AppThemeData.grey800 : AppThemeData.grey100,
                            disabledBorder: UnderlineInputBorder(
                              borderRadius: const BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: isDarkMode(context) ? AppThemeData.grey900 : AppThemeData.grey50, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: const BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: isDarkMode(context) ? AppThemeData.primary300 : AppThemeData.primary300, width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: const BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: isDarkMode(context) ? AppThemeData.grey900 : AppThemeData.grey50, width: 1),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: const BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: isDarkMode(context) ? AppThemeData.grey900 : AppThemeData.grey50, width: 1),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: const BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: isDarkMode(context) ? AppThemeData.grey900 : AppThemeData.grey50, width: 1),
                            ),
                            hintText: "Area/sector/locality*".tr(),
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: isDarkMode(context) ? AppThemeData.grey600 : AppThemeData.grey400,
                              fontFamily: AppThemeData.regular,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextFormField(
                          textCapitalization: TextCapitalization.sentences,
                          controller: landmark,
                          maxLines: 1,
                          style: TextStyle(color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900, fontFamily: AppThemeData.medium),
                          decoration: InputDecoration(
                            errorStyle: const TextStyle(color: Colors.red),
                            filled: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                            fillColor: isDarkMode(context) ? AppThemeData.grey800 : AppThemeData.grey100,
                            disabledBorder: UnderlineInputBorder(
                              borderRadius: const BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: isDarkMode(context) ? AppThemeData.grey900 : AppThemeData.grey50, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: const BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: isDarkMode(context) ? AppThemeData.primary300 : AppThemeData.primary300, width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: const BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: isDarkMode(context) ? AppThemeData.grey900 : AppThemeData.grey50, width: 1),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: const BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: isDarkMode(context) ? AppThemeData.grey900 : AppThemeData.grey50, width: 1),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: const BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: isDarkMode(context) ? AppThemeData.grey900 : AppThemeData.grey50, width: 1),
                            ),
                            hintText: "Nearby landmark (Optional)".tr(),
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: isDarkMode(context) ? AppThemeData.grey600 : AppThemeData.grey400,
                              fontFamily: AppThemeData.regular,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 40,
              ),
              RoundedButtonFill(
                title: "Save".tr(),
                width: 60,
                color: AppThemeData.primary300,
                textColor: AppThemeData.grey50,
                onPress: () async {
                  if (userLocation == null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                        "Please select Location".tr(),
                      ),
                      backgroundColor: Colors.red.shade400,
                      duration: Duration(seconds: 1),
                    ));
                  } else if (address.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                        "Please Enter Flat / House / Flore / Building".tr(),
                      ),
                      backgroundColor: Colors.red.shade400,
                      duration: Duration(seconds: 1),
                    ));
                  } else if (locality.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                        "Please Enter Area / Sector / locality".tr(),
                      ),
                      backgroundColor: Colors.red.shade400,
                      duration: Duration(seconds: 1),
                    ));
                  } else {
                    ShowToastDialog.showLoader("Please wait".tr());
                    if (widget.index != null) {
                      addressModel.location = userLocation;
                      addressModel.addressAs = selectedSaveAs;
                      addressModel.locality = locality.text;
                      addressModel.address = address.text;
                      addressModel.landmark = landmark.text;

                      shippingAddress.removeAt(widget.index!);
                      shippingAddress.insert(widget.index!, addressModel);
                    } else {
                      addressModel.id = Uuid().v4();
                      addressModel.location = userLocation;
                      addressModel.addressAs = selectedSaveAs;
                      addressModel.locality = locality.text;
                      addressModel.address = address.text;
                      addressModel.landmark = landmark.text;
                      addressModel.isDefault = false;
                      shippingAddress.add(addressModel);
                    }
                    setState(() {});

                    print(MyAppState.currentUser!.userID);
                    MyAppState.currentUser!.shippingAddress = shippingAddress;
                    await FireStoreUtils.updateCurrentUser(MyAppState.currentUser!);
                    ShowToastDialog.closeLoader();
                    Navigator.pop(context, true);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
