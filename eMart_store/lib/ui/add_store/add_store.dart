import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emartstore/main.dart';
import 'package:emartstore/model/DeliveryChargeModel.dart';
import 'package:emartstore/model/VendorModel.dart';
import 'package:emartstore/model/categoryModel.dart';
import 'package:emartstore/services/FirebaseHelper.dart';
import 'package:emartstore/services/helper.dart';
import 'package:emartstore/services/show_toast_dailog.dart';
import 'package:emartstore/theme/app_them_data.dart';
import 'package:emartstore/ui/QrCodeGenerator/QrCodeGenerator.dart';
import 'package:emartstore/ui/subscription_screen/subscription_screens.dart';
import 'package:emartstore/utils/network_image_widget.dart';
import 'package:emartstore/widget/geoflutterfire/src/geoflutterfire.dart';
import 'package:emartstore/widget/permission_dialog.dart';
import 'package:emartstore/widget/place_picker_osm.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:image/image.dart' as ImageVar;
import 'package:image_picker/image_picker.dart';
import 'package:osm_nominatim/osm_nominatim.dart';
import 'package:path_provider/path_provider.dart';
import '../../constants.dart';
import '../../model/SectionModel.dart';import 'package:emartstore/ui/container/ContainerScreen.dart';
import 'package:emartstore/services/helper.dart';

class AddStoreScreen extends StatefulWidget {
  AddStoreScreen({Key? key}) : super(key: key);

  @override
  _AddStoreScreenState createState() => _AddStoreScreenState();
}

class _AddStoreScreenState extends State<AddStoreScreen> {
  final storeName = TextEditingController();
  final description = TextEditingController();
  final phonenumber = TextEditingController();
  final deliverChargeKm = TextEditingController(text: "0");
  final minDeliveryCharge = TextEditingController(text: "0");
  final minDeliveryChargewkm = TextEditingController(text: "0");
  final _formKey = GlobalKey<FormState>();
  List<VendorCategoryModel> categoryLst = [];
  VendorCategoryModel? selectedCategory;
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
  DeliveryChargeModel? deliveryChargeModel;

  LatLng? selectedLocation;
  final address = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  List images = <dynamic>[];

  bool isLoading = true;

  @override
  void dispose() {
    storeName.dispose();
    description.dispose();
    phonenumber.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    getVendorData();
  }

  List<SectionModel> sectionsVal = [];
  SectionModel? selectedModel;

  String selectCategoryName = "";

  VendorModel? vendorData;
  bool? autoApproveStore = false;

  getVendorData() async {
    await FireStoreUtils.getDelivery().then((value) {
      setState(() {
        deliveryChargeModel = value;
        if (value.vendor_can_modify == true) {
          if (vendorData != null && vendorData!.DeliveryCharge != null) {
            deliverChargeKm.text =
                vendorData!.DeliveryCharge!.delivery_charges_per_km.toString();
            minDeliveryCharge.text =
                vendorData!.DeliveryCharge!.minimum_delivery_charges.toString();
            minDeliveryChargewkm.text = vendorData!
                .DeliveryCharge!.minimum_delivery_charges_within_km
                .toString();
          }
        } else {
          deliverChargeKm.text =
              deliveryChargeModel!.delivery_charges_per_km.toString();
          minDeliveryCharge.text =
              deliveryChargeModel!.minimum_delivery_charges.toString();
          minDeliveryChargewkm.text = deliveryChargeModel!
              .minimum_delivery_charges_within_km
              .toString();
        }
      });
    });

    await FireStoreUtils.getSections().then((value) {
      sectionsVal.clear();
      value.forEach((element) {
        if (element.serviceTypeFlag == "ecommerce-service" ||
            element.serviceTypeFlag == "delivery-service") {
          sectionsVal.add(element);
        }
      });
      setState(() {});
    });

    if (MyAppState.currentUser?.section_id.isNotEmpty == true) {
      selectedModel = sectionsVal.firstWhere(
          (element) => element.id == MyAppState.currentUser!.section_id);
      categoryLst = await FireStoreUtils.getVendorCategoryById(
          selectedModel!.id.toString());
      setState(() {
        if (categoryLst.length > 0) {
        } else {
          final snackBar = SnackBar(
            content: Text(
              'No category for this section'.tr(),
              style: TextStyle(
                  color: !isDarkMode(context) ? Colors.white : Colors.black),
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      });
    }

    await FirebaseFirestore.instance
        .collection(Setting)
        .doc('vendor')
        .get()
        .then((value) {
      setState(() {
        autoApproveStore = value.data()!['auto_approve_store'];
      });
    });

    if (MyAppState.currentUser!.vendorID != '') {
      await FireStoreUtils.getVendor(MyAppState.currentUser!.vendorID)
          .then((value) async {
        vendorData = value;

        print(vendorData!.toJson());
        VendorCategoryModel vendorCategoryModel = VendorCategoryModel(
            id: vendorData!.categoryID, title: vendorData!.categoryTitle);

        await FireStoreUtils.getVendorCategoryById(value.section_id)
            .then((value) {
          categoryLst.clear();
          categoryLst.addAll(value);

          selectedModel = sectionsVal
              .firstWhere((element) => element.id == vendorData!.section_id);

          for (int a = 0; a < value.length; a++) {
            if (value[a].id == vendorCategoryModel.id &&
                vendorData!.section_id == value[a].section_id) {
              selectedCategory = value[a];
            }
          }
          if (selectedCategory != null) {
            selectedCategory = categoryLst
                .firstWhere((element) => element.id == selectedCategory!.id);
          }
        });

        if (deliveryChargeModel != null &&
            deliveryChargeModel!.vendor_can_modify &&
            vendorData!.DeliveryCharge != null) {
          deliverChargeKm.text =
              vendorData!.DeliveryCharge!.delivery_charges_per_km.toString();
          minDeliveryCharge.text =
              vendorData!.DeliveryCharge!.minimum_delivery_charges.toString();
          minDeliveryChargewkm.text = vendorData!
              .DeliveryCharge!.minimum_delivery_charges_within_km
              .toString();
        }

        storeName.text = vendorData!.title;
        description.text = vendorData!.description;
        phonenumber.text = vendorData!.phonenumber;
        address.text = vendorData!.location;
        selectedLocation = LatLng(vendorData!.latitude, vendorData!.longitude);
        images = vendorData!.photos;
      });
    }

    isLoading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode(context) ? Color(COLOR_DARK) : null,
      body: SingleChildScrollView(
        child: Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 10),
            child: isLoading == true
                ? Container(
                    alignment: Alignment.center,
                    child: CircularProgressIndicator.adaptive(
                      valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                    ),
                  )
                : Form(
                    key: _formKey,
                    autovalidateMode: _autoValidateMode,
                    child: MyAppState.currentUser!.vendorID == ''
                        ? Column(
                            children: [
                              Container(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Store Name".tr(),
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontFamily: AppThemeData.medium,
                                        color: isDarkMode(context)
                                            ? Colors.white
                                            : Color(0Xff696A75)),
                                  )),
                              Container(
                                padding: const EdgeInsetsDirectional.only(
                                    bottom: 10),
                                child: TextFormField(
                                    controller: storeName,
                                    textAlignVertical: TextAlignVertical.center,
                                    textInputAction: TextInputAction.next,
                                    validator: validateEmptyField,
                                    // onSaved: (text) => line1 = text,
                                    keyboardType: TextInputType.streetAddress,
                                    cursorColor: Color(COLOR_PRIMARY),
                                    // initialValue: MyAppState.currentUser!.shippingAddress.line1,
                                    decoration: InputDecoration(
                                      // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                                      contentPadding:
                                          EdgeInsets.fromLTRB(10, 2, 10, 2),
                                      hintText: 'Store Name'.tr(),
                                      hintStyle: TextStyle(
                                        color: isDarkMode(context)
                                            ? Colors.white
                                            : Color(0Xff333333),
                                        fontSize: 14,
                                        fontFamily: AppThemeData.medium,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(7.0),
                                          borderSide: BorderSide(
                                              color: Color(COLOR_PRIMARY),
                                              width: 2.0)),
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error),
                                        borderRadius:
                                            BorderRadius.circular(7.0),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error),
                                        borderRadius:
                                            BorderRadius.circular(7.0),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade400),
                                        borderRadius:
                                            BorderRadius.circular(7.0),
                                      ),
                                    )),
                              ),
                              Container(
                                  padding: EdgeInsets.only(top: 10),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Sections".tr(),
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontFamily: AppThemeData.medium,
                                        color: isDarkMode(context)
                                            ? Colors.white
                                            : Color(0Xff696A75)),
                                  )),
                              ((MyAppState.currentUser?.subscriptionPlan ==
                                              null ||
                                          MyAppState.currentUser?.section_id ==
                                              null) ||
                                      (isSubscriptionModelApplied == false &&
                                          selectedSectionModel
                                                  ?.adminCommision?.enable ==
                                              false))
                                  ? DropdownButtonFormField<SectionModel>(
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        contentPadding:
                                            EdgeInsets.fromLTRB(10, 2, 10, 2),
                                        focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(7.0),
                                            borderSide: BorderSide(
                                                color: Color(COLOR_PRIMARY),
                                                width: 2.0)),
                                        errorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error),
                                          borderRadius:
                                              BorderRadius.circular(7.0),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error),
                                          borderRadius:
                                              BorderRadius.circular(7.0),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade400),
                                          borderRadius:
                                              BorderRadius.circular(7.0),
                                        ),
                                      ),
                                      validator: (value) => value == null
                                          ? 'field required'.tr()
                                          : null,
                                      value: selectedModel,
                                      onChanged: (value) async {
                                        if (value != selectedModel) {
                                          categoryLst.clear();
                                        }
                                        selectedModel = value;
                                        selectedCategory = null;
                                        selectCategoryName = "";
                                        categoryLst = await FireStoreUtils
                                            .getVendorCategoryById(
                                                selectedModel!.id.toString());
                                        setState(() {
                                          if (categoryLst.length > 0) {
                                          } else {
                                            final snackBar = SnackBar(
                                              content: Text(
                                                'No category for this section'
                                                    .tr(),
                                                style: TextStyle(
                                                    color: !isDarkMode(context)
                                                        ? Colors.white
                                                        : Colors.black),
                                              ),
                                            );
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(snackBar);
                                          }
                                        });
                                        // if (selectedModel!.id == MyAppState.currentUser!.section_id) {
                                        //   setState(() {
                                        //     selectedModel = sectionsVal.firstWhere((element) => element.id == MyAppState.currentUser!.section_id);
                                        //   });
                                        //   ShowToastDialog.showToast("You are not able to change section. because of your plan is purchased on ${selectedModel!.name} section".tr());
                                        // } else {
                                        //
                                        // }
                                      },
                                      hint: Text('Select Section'.tr()),
                                      items:
                                          sectionsVal.map((SectionModel item) {
                                        return DropdownMenuItem<SectionModel>(
                                          child: Text(item.name.toString() +
                                              " (${item.serviceType})"),
                                          value: item,
                                        );
                                      }).toList())
                                  : Container(
                                      padding: const EdgeInsetsDirectional.only(
                                          bottom: 10),
                                      child: InkWell(
                                        onTap: () {
                                          ShowToastDialog.showToast(
                                              "You are not able to change section. because of your plan is purchased on {} section".tr(args: [selectedModel?.name ?? '']));
                                        },
                                        child: TextFormField(
                                            initialValue: selectedModel?.name ??
                                                '' +
                                                    " (${selectedModel?.serviceType ?? ''})",
                                            textAlignVertical:
                                                TextAlignVertical.center,
                                            textInputAction:
                                                TextInputAction.next,
                                            validator: validateEmptyField,
                                            // onSaved: (text) => line1 = text,
                                            keyboardType:
                                                TextInputType.streetAddress,
                                            enabled: false,
                                            cursorColor: Color(COLOR_PRIMARY),
                                            // initialValue: MyAppState.currentUser!.shippingAddress.line1,
                                            decoration: InputDecoration(
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 16),
                                                hintText: 'Section'.tr(),
                                                hintStyle: TextStyle(
                                                  color: isDarkMode(context)
                                                      ? Colors.white
                                                      : Color(0Xff333333),
                                                  fontSize: 14,
                                                  fontFamily:
                                                      AppThemeData.medium,
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            7.0),
                                                    borderSide: BorderSide(
                                                        color: Color(
                                                            COLOR_PRIMARY),
                                                        width: 2.0)),
                                                errorBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .error),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          7.0),
                                                ),
                                                focusedErrorBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .error),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          7.0),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color:
                                                          Colors.grey.shade400),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          7.0),
                                                ),
                                                disabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color:
                                                          Colors.grey.shade400),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          7.0),
                                                ))),
                                      ),
                                    ),
                              Container(
                                  padding: EdgeInsets.only(top: 10, bottom: 10),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Categories".tr(),
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontFamily: AppThemeData.medium,
                                        color: isDarkMode(context)
                                            ? Colors.white
                                            : Color(0Xff696A75)),
                                  )),
                              Container(
                                height: 60,
                                child: DropdownButtonFormField<
                                        VendorCategoryModel>(
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          EdgeInsets.fromLTRB(10, 2, 10, 2),
                                      focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(7.0),
                                          borderSide: BorderSide(
                                              color: Color(COLOR_PRIMARY),
                                              width: 2.0)),
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error),
                                        borderRadius:
                                            BorderRadius.circular(7.0),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error),
                                        borderRadius:
                                            BorderRadius.circular(7.0),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade400),
                                        borderRadius:
                                            BorderRadius.circular(7.0),
                                      ),
                                    ),
                                    value: selectedCategory,
                                    validator: (value) => value == null
                                        ? 'field required'.tr()
                                        : null,
                                    disabledHint: Text("Select Category".tr()),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedCategory = value;
                                        selectCategoryName =
                                            value!.title.toString();
                                      });
                                    },
                                    hint: Text('Select Category'.tr()),
                                    items: categoryLst
                                        .map((VendorCategoryModel item) {
                                      return DropdownMenuItem<
                                          VendorCategoryModel>(
                                        child: Text(item.title.toString()),
                                        value: item,
                                      );
                                    }).toList()),
                              ),
                              Container(
                                  padding: EdgeInsets.only(top: 10),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Description".tr(),
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontFamily: AppThemeData.medium,
                                        color: isDarkMode(context)
                                            ? Colors.white
                                            : Color(0Xff696A75)),
                                  )),
                              Container(
                                padding: const EdgeInsetsDirectional.only(
                                    bottom: 10),
                                child: TextFormField(
                                    controller: description,
                                    textAlignVertical: TextAlignVertical.center,
                                    textInputAction: TextInputAction.next,
                                    validator: validateEmptyField,
                                    // onSaved: (text) => line1 = text,
                                    keyboardType: TextInputType.streetAddress,
                                    cursorColor: Color(COLOR_PRIMARY),
                                    // initialValue: MyAppState.currentUser!.shippingAddress.line1,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          EdgeInsets.symmetric(horizontal: 16),
                                      hintText: 'Description'.tr(),
                                      hintStyle: TextStyle(
                                        color: isDarkMode(context)
                                            ? Colors.white
                                            : Color(0Xff333333),
                                        fontSize: 14,
                                        fontFamily: AppThemeData.medium,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(7.0),
                                          borderSide: BorderSide(
                                              color: Color(COLOR_PRIMARY),
                                              width: 2.0)),
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error),
                                        borderRadius:
                                            BorderRadius.circular(7.0),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error),
                                        borderRadius:
                                            BorderRadius.circular(7.0),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade400),
                                        borderRadius:
                                            BorderRadius.circular(7.0),
                                      ),
                                    )),
                              ),
                              Container(
                                  padding: EdgeInsets.only(top: 5),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Phone Number".tr(),
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontFamily: AppThemeData.medium,
                                        color: isDarkMode(context)
                                            ? Colors.white
                                            : Color(0Xff696A75)),
                                  )),
                              Container(
                                padding: const EdgeInsetsDirectional.only(
                                    bottom: 10),
                                child: TextFormField(
                                    controller: phonenumber,
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'[0-9]')),
                                    ],
                                    textAlignVertical: TextAlignVertical.center,
                                    textInputAction: TextInputAction.next,
                                    validator: validateEmptyField,
                                    // onSaved: (text) => line1 = text,
                                    keyboardType: TextInputType.number,
                                    cursorColor: Color(COLOR_PRIMARY),
                                    // initialValue: MyAppState.currentUser!.shippingAddress.line1,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          EdgeInsets.symmetric(horizontal: 16),
                                      hintText: 'Phone Number'.tr(),
                                      hintStyle: TextStyle(
                                        color: isDarkMode(context)
                                            ? Colors.white
                                            : Color(0Xff333333),
                                        fontSize: 14,
                                        fontFamily: AppThemeData.medium,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(7.0),
                                          borderSide: BorderSide(
                                              color: Color(COLOR_PRIMARY),
                                              width: 2.0)),
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error),
                                        borderRadius:
                                            BorderRadius.circular(7.0),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error),
                                        borderRadius:
                                            BorderRadius.circular(7.0),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade400),
                                        borderRadius:
                                            BorderRadius.circular(7.0),
                                      ),
                                    )),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Container(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Address".tr(),
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontFamily: AppThemeData.medium,
                                              color: isDarkMode(context)
                                                  ? Colors.white
                                                  : Colors.black),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () async {
                                          checkPermission(
                                            () async {
                                              ShowToastDialog.showLoader(
                                                  "Please wait".tr());
                                              try {
                                                await Geolocator
                                                    .requestPermission();
                                                await Geolocator
                                                    .getCurrentPosition(
                                                        desiredAccuracy:
                                                            LocationAccuracy
                                                                .high);
                                                ShowToastDialog.closeLoader();
                                                if (selectedMapType == 'osm') {
                                                  Navigator.of(context)
                                                      .push(MaterialPageRoute(
                                                          builder: (context) =>
                                                              LocationPicker()))
                                                      .then(
                                                    (value) async {
                                                      if (value != null) {
                                                        Place result = value;
                                                        selectedLocation =
                                                            LatLng(result.lat,
                                                                result.lon);
                                                        address.text = result
                                                            .displayName
                                                            .toString();
                                                      }
                                                    },
                                                  );
                                                } else {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          PlacePicker(
                                                        apiKey: GOOGLE_API_KEY,
                                                        onPlacePicked:
                                                            (result) {
                                                          selectedLocation =
                                                              LatLng(
                                                                  result
                                                                      .geometry!
                                                                      .location
                                                                      .lat,
                                                                  result
                                                                      .geometry!
                                                                      .location
                                                                      .lng);
                                                          address.text = result
                                                              .formattedAddress
                                                              .toString();
                                                          setState(() {});
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                        initialPosition: LatLng(
                                                            -33.8567844,
                                                            151.213108),
                                                        useCurrentLocation:
                                                            true,
                                                        selectInitialPosition:
                                                            true,
                                                        usePinPointingSearch:
                                                            true,
                                                        usePlaceDetailSearch:
                                                            true,
                                                        zoomGesturesEnabled:
                                                            true,
                                                        zoomControlsEnabled:
                                                            true,
                                                        resizeToAvoidBottomInset:
                                                            false, // only works in page mode, less flickery, remove if wrong offsets
                                                      ),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                print(e.toString());
                                              }
                                            },
                                          );
                                        },
                                        child: Text(
                                          "Change".tr(),
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontFamily: AppThemeData.medium,
                                              color: Color(COLOR_PRIMARY)),
                                        ),
                                      ),
                                    ],
                                  )),
                              InkWell(
                                onTap: () {
                                  if (selectedLocation == null) {
                                    if (selectedMapType == 'osm') {
                                      Navigator.of(context)
                                          .push(MaterialPageRoute(
                                              builder: (context) =>
                                                  LocationPicker()))
                                          .then(
                                        (value) async {
                                          if (value != null) {
                                            Place result = value;
                                            selectedLocation =
                                                LatLng(result.lat, result.lon);
                                            address.text =
                                                result.displayName.toString();
                                            setState(() {});
                                          }
                                        },
                                      );
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PlacePicker(
                                            apiKey: GOOGLE_API_KEY,
                                            onPlacePicked: (result) async {
                                              selectedLocation = LatLng(
                                                  result.geometry!.location.lat,
                                                  result
                                                      .geometry!.location.lng);
                                              address.text = result
                                                  .formattedAddress
                                                  .toString();
                                              setState(() {});
                                              Navigator.of(context).pop();
                                            },
                                            initialPosition:
                                                LatLng(-33.8567844, 151.213108),
                                            useCurrentLocation: true,
                                            selectInitialPosition: true,
                                            usePinPointingSearch: true,
                                            usePlaceDetailSearch: true,
                                            zoomGesturesEnabled: true,
                                            zoomControlsEnabled: true,
                                            resizeToAvoidBottomInset:
                                                false, // only works in page mode, less flickery, remove if wrong offsets
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: TextFormField(
                                    controller: address,
                                    textAlignVertical: TextAlignVertical.center,
                                    textInputAction: TextInputAction.next,
                                    onSaved: (text) => address.text = text!,
                                    enabled:
                                        selectedLocation == null ? false : true,
                                    cursorColor: Color(COLOR_PRIMARY),
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 5),
                                      hintText: 'Address'.tr(),
                                      hintStyle: TextStyle(
                                          color: isDarkMode(context)
                                              ? Colors.white
                                              : Color(0Xff333333),
                                          fontFamily: AppThemeData.medium,
                                          fontSize: 16),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Color(COLOR_PRIMARY)),
                                      ),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Color(COLOR_PRIMARY)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Color(0XFFB1BCCA)),
                                        // borderRadius: BorderRadius.circular(8.0),
                                      ),
                                    )),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              selectedModel != null &&
                                      selectedModel!.serviceTypeFlag ==
                                          "ecommerce-service"
                                  ? Container()
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SwitchListTile.adaptive(
                                          dense: true,
                                          activeColor: Color(COLOR_ACCENT),
                                          title: Text(
                                            'Delivery Settings'.tr(),
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: isDarkMode(context)
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontFamily: AppThemeData.medium,
                                            ),
                                          ),
                                          value: deliveryChargeModel != null
                                              ? deliveryChargeModel!
                                                  .vendor_can_modify
                                              : false,
                                          onChanged: (value) {},
                                        ),
                                        Container(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              "Delivery Charge Per km".tr(),
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  fontFamily:
                                                      AppThemeData.medium,
                                                  color: isDarkMode(context)
                                                      ? Colors.white
                                                      : Color(0Xff696A75)),
                                            )),
                                        Container(
                                          padding:
                                              const EdgeInsetsDirectional.only(
                                                  bottom: 10),
                                          child: TextFormField(
                                              controller: deliverChargeKm,
                                              textAlignVertical:
                                                  TextAlignVertical.center,
                                              textInputAction:
                                                  TextInputAction.next,
                                              validator: (value) {
                                                print("value os $value");
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return "Invalid value".tr();
                                                }
                                                return null;
                                              },
                                              enabled: deliveryChargeModel !=
                                                      null
                                                  ? deliveryChargeModel!
                                                      .vendor_can_modify
                                                  : false,
                                              onSaved: (text) =>
                                                  deliverChargeKm.text = text!,
                                              keyboardType:
                                                  TextInputType.number,
                                              cursorColor: Color(COLOR_PRIMARY),
                                              // initialValue: vendor.phonenumber,
                                              decoration: InputDecoration(
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 16),
                                                hintText:
                                                    'Delivery Charge Per km'
                                                        .tr(),
                                                hintStyle: TextStyle(
                                                  color: isDarkMode(context)
                                                      ? Colors.white
                                                      : Color(0Xff333333),
                                                  fontSize: 14,
                                                  fontFamily:
                                                      AppThemeData.medium,
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(7.0),
                                                        borderSide: BorderSide(
                                                            color: Color(
                                                                COLOR_PRIMARY),
                                                            width: 2.0)),
                                                errorBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .error),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          7.0),
                                                ),
                                                focusedErrorBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .error),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          7.0),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color:
                                                          Colors.grey.shade400),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          7.0),
                                                ),
                                              )),
                                        ),
                                        Container(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              "Min Delivery Charge".tr(),
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  fontFamily:
                                                      AppThemeData.medium,
                                                  color: isDarkMode(context)
                                                      ? Colors.white
                                                      : Color(0Xff696A75)),
                                            )),
                                        Container(
                                          padding:
                                              const EdgeInsetsDirectional.only(
                                                  bottom: 10),
                                          child: TextFormField(
                                              enabled:
                                                  deliveryChargeModel != null
                                                      ? deliveryChargeModel!
                                                          .vendor_can_modify
                                                      : false,
                                              controller: minDeliveryCharge,
                                              textAlignVertical:
                                                  TextAlignVertical.center,
                                              textInputAction:
                                                  TextInputAction.next,
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return "Invalid value".tr();
                                                }
                                                return null;
                                              },
                                              onSaved: (text) =>
                                                  minDeliveryCharge.text =
                                                      text!,
                                              keyboardType:
                                                  TextInputType.number,
                                              cursorColor: Color(COLOR_PRIMARY),
                                              // initialValue: vendor.phonenumber,
                                              decoration: InputDecoration(
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 16),
                                                hintText:
                                                    'Min Delivery Charge'.tr(),
                                                hintStyle: TextStyle(
                                                  color: isDarkMode(context)
                                                      ? Colors.white
                                                      : Color(0Xff333333),
                                                  fontSize: 14,
                                                  fontFamily:
                                                      AppThemeData.medium,
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(7.0),
                                                        borderSide: BorderSide(
                                                            color: Color(
                                                                COLOR_PRIMARY),
                                                            width: 2.0)),
                                                errorBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .error),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          7.0),
                                                ),
                                                focusedErrorBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .error),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          7.0),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color:
                                                          Colors.grey.shade400),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          7.0),
                                                ),
                                              )),
                                        ),
                                        Container(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              "Min Delivery Charge within km"
                                                  .tr(),
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  fontFamily:
                                                      AppThemeData.medium,
                                                  color: isDarkMode(context)
                                                      ? Colors.white
                                                      : Color(0Xff696A75)),
                                            )),
                                        Container(
                                          padding:
                                              const EdgeInsetsDirectional.only(
                                                  bottom: 10),
                                          child: TextFormField(
                                              controller: minDeliveryChargewkm,
                                              enabled:
                                                  deliveryChargeModel != null
                                                      ? deliveryChargeModel!
                                                          .vendor_can_modify
                                                      : false,
                                              textAlignVertical:
                                                  TextAlignVertical.center,
                                              textInputAction:
                                                  TextInputAction.next,
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return "Invalid value".tr();
                                                }
                                                return null;
                                              },
                                              onSaved: (text) =>
                                                  minDeliveryChargewkm.text =
                                                      text!,
                                              keyboardType:
                                                  TextInputType.number,
                                              cursorColor: Color(COLOR_PRIMARY),
                                              // initialValue: vendor.phonenumber,
                                              decoration: InputDecoration(
                                                  hintText:
                                                      'Min Delivery Charge within km'
                                                          .tr(),
                                                  hintStyle: TextStyle(
                                                    color: isDarkMode(context)
                                                        ? Colors.white
                                                        : Color(0Xff333333),
                                                    fontSize: 14,
                                                    fontFamily:
                                                        AppThemeData.medium,
                                                  ),
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                          horizontal: 16),
                                                  focusedBorder: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              7.0),
                                                      borderSide: BorderSide(
                                                          color:
                                                              Color(
                                                                  COLOR_PRIMARY),
                                                          width: 2.0)),
                                                  errorBorder:
                                                      OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .error),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            7.0),
                                                  ),
                                                  focusedErrorBorder:
                                                      OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .error),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            7.0),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Colors
                                                            .grey.shade400),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            7.0),
                                                  ),
                                                  disabledBorder:
                                                      OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Colors
                                                            .grey.shade400),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            7.0),
                                                  ))),
                                        ),
                                      ],
                                    ),
                              SizedBox(
                                height: 10,
                              ),
                              InkWell(
                                onTap: () {
                                  changeimg();
                                },
                                child: Image(
                                  image:
                                      AssetImage("assets/images/add_img.png"),
                                  width: MediaQuery.of(context).size.width * 1,
                                  height:
                                      MediaQuery.of(context).size.height * 0.2,
                                ),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              images.isEmpty
                                  ? const SizedBox()
                                  : SizedBox(
                                      height: 90,
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: ListView.builder(
                                              itemCount: images.length,
                                              shrinkWrap: true,
                                              scrollDirection: Axis.horizontal,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemBuilder: (context, index) {
                                                return Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 5),
                                                  child: Stack(
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius:
                                                            const BorderRadius
                                                                .all(
                                                                Radius.circular(
                                                                    10)),
                                                        child: images[index]
                                                                    .runtimeType ==
                                                                XFile
                                                            ? Image.file(
                                                                File(images[
                                                                        index]
                                                                    .path),
                                                                fit: BoxFit
                                                                    .cover,
                                                                width: 80,
                                                                height: 80,
                                                              )
                                                            : NetworkImageWidget(
                                                                imageUrl:
                                                                    images[
                                                                        index],
                                                                fit: BoxFit
                                                                    .cover,
                                                                width: 80,
                                                                height: 80,
                                                              ),
                                                      ),
                                                      Positioned(
                                                        bottom: 0,
                                                        top: 0,
                                                        left: 0,
                                                        right: 0,
                                                        child: InkWell(
                                                          onTap: () {
                                                            setState(() {
                                                              images.removeAt(
                                                                  index);
                                                            });
                                                          },
                                                          child: const Icon(
                                                            Icons.remove_circle,
                                                            size: 28,
                                                            color: AppThemeData
                                                                .danger300,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                        ],
                                      ),
                                    ),
                            ],
                          )
                        : buildrow())),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.only(top: 12, bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: BorderSide(
                    color: Color(COLOR_PRIMARY),
                  ),
                ),
                backgroundColor: Color(COLOR_PRIMARY),
              ),
              onPressed: () {
                validate();
              },
              child: Text(
                'Save'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            if (((isSubscriptionModelApplied == true ||
                        selectedSectionModel?.adminCommision?.enable == true) &&
                    vendorData?.subscriptionPlan?.features?.qrCodeGenerate ==
                        true) ||
                (isSubscriptionModelApplied == false &&
                    selectedSectionModel?.adminCommision?.enable == false))
              Visibility(
                visible: MyAppState.currentUser!.vendorID != '',
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.only(top: 12, bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        side: BorderSide(
                          color: Color(COLOR_PRIMARY),
                        ),
                      ),
                      backgroundColor: Color(COLOR_PRIMARY),
                    ),
                    onPressed: () async {
                      final image = ImageVar.Image(600, 600);
                      ImageVar.fill(image, ImageVar.getColor(255, 255, 255));
                      // drawBarcode(
                      //     image, Barcode.qrCode(), '{"vendorid":"${MyAppState.currentUser!.vendorID}","vendorname":"${vendorData!.title}","sectionid":"${vendorData!.section_id}"}',
                      //     font: ImageVar.arial_24);

                      // Save the image
                      Directory appDocDir =
                          await getApplicationDocumentsDirectory();
                      String appDocPath = appDocDir.path;

                      print("path $appDocPath");
                      File file = File(
                          '$appDocPath/barcode${MyAppState.currentUser!.vendorID}.png');
                      if (!await file.exists()) {
                        await file.create();
                      } else {
                        await file.delete();
                        await file.create();
                      }
                      file.writeAsBytesSync(ImageVar.encodePng(image));
                      push(context, QrCodeGenerator(vendorModel: vendorData!));
                    },
                    child: Text(
                      'Generate QR Code'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  buildrow() {
    print("draw vieww");

    return Column(children: [
      Container(
          width: MediaQuery.of(context).size.width,
          child: Text(
            "Store Name".tr(),
            textAlign: TextAlign.start,
            style: TextStyle(
                fontSize: 17,
                fontFamily: AppThemeData.medium,
                color: isDarkMode(context) ? Colors.white : Color(0Xff696A75)),
          )),
      Container(
        padding: const EdgeInsetsDirectional.only(top: 5),
        child: TextFormField(
            controller: storeName,
            textAlignVertical: TextAlignVertical.center,
            textInputAction: TextInputAction.next,
            validator: validateEmptyField,
            onSaved: (text) => storeName.text = text!,
            keyboardType: TextInputType.streetAddress,
            cursorColor: Color(COLOR_PRIMARY),
            decoration: InputDecoration(
              hintText: 'Store Name'.tr(),
              contentPadding: new EdgeInsets.only(left: 8, right: 8),
              hintStyle: TextStyle(
                color: isDarkMode(context) ? Colors.white : Color(0Xff696A75),
                fontSize: 14,
                fontFamily: AppThemeData.medium,
              ),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.0),
                  borderSide:
                      BorderSide(color: Color(COLOR_PRIMARY), width: 2.0)),
              errorBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: Theme.of(context).colorScheme.error),
                borderRadius: BorderRadius.circular(7.0),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: Theme.of(context).colorScheme.error),
                borderRadius: BorderRadius.circular(7.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(7.0),
              ),
            )),
      ),
      Container(
          padding: EdgeInsets.only(top: 10),
          alignment: Alignment.centerLeft,
          child: Text(
            "Sections".tr(),
            style: TextStyle(
                fontSize: 17,
                fontFamily: AppThemeData.medium,
                color: isDarkMode(context) ? Colors.white : Color(0Xff696A75)),
          )),
      Container(
        padding: const EdgeInsetsDirectional.only(bottom: 10),
        child: InkWell(
          onTap: () {
            ShowToastDialog.showToast(
                "You are not able to change section. because of your plan is purchased on {} section".tr(args: [selectedModel!.name ?? '']));
          },
          child: TextFormField(
              initialValue: selectedModel!.name.toString() +
                  " (${selectedModel!.serviceType})",
              textAlignVertical: TextAlignVertical.center,
              textInputAction: TextInputAction.next,
              validator: validateEmptyField,
              // onSaved: (text) => line1 = text,
              keyboardType: TextInputType.streetAddress,
              enabled: false,
              cursorColor: Color(COLOR_PRIMARY),
              // initialValue: MyAppState.currentUser!.shippingAddress.line1,
              decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  hintText: 'Section'.tr(),
                  hintStyle: TextStyle(
                    color:
                        isDarkMode(context) ? Colors.white : Color(0Xff333333),
                    fontSize: 14,
                    fontFamily: AppThemeData.medium,
                  ),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7.0),
                      borderSide:
                          BorderSide(color: Color(COLOR_PRIMARY), width: 2.0)),
                  errorBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Theme.of(context).colorScheme.error),
                    borderRadius: BorderRadius.circular(7.0),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Theme.of(context).colorScheme.error),
                    borderRadius: BorderRadius.circular(7.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(7.0),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(7.0),
                  ))),
        ),
      ),
      Container(
          padding: EdgeInsets.only(top: 10, bottom: 10),
          alignment: Alignment.centerLeft,
          child: Text(
            "Categories".tr(),
            style: TextStyle(
                fontSize: 17,
                fontFamily: AppThemeData.medium,
                color: isDarkMode(context) ? Colors.white : Color(0Xff696A75)),
          )),
      Container(
        height: 60,
        child: DropdownButtonFormField<VendorCategoryModel>(
            decoration: InputDecoration(
              contentPadding: EdgeInsets.fromLTRB(10, 2, 10, 2),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            value: selectedCategory,
            validator: (value) => value == null ? 'field required' : null,
            disabledHint: Text("Select category First".tr()),
            onChanged: (value) {
              setState(() {
                selectedCategory = value;
                selectCategoryName = value!.title.toString();
              });
            },
            hint: Text('Select category'.tr()),
            items: categoryLst.map((VendorCategoryModel item) {
              return DropdownMenuItem<VendorCategoryModel>(
                child: Text(item.title.toString()),
                value: item,
              );
            }).toList()),
      ),
      Container(
          padding: EdgeInsets.only(top: 10),
          width: MediaQuery.of(context).size.width,
          child: Text(
            "Description".tr(),
            textAlign: TextAlign.start,
            style: TextStyle(
                fontSize: 17,
                fontFamily: AppThemeData.medium,
                color: isDarkMode(context) ? Colors.white : Color(0Xff696A75)),
          )),
      Container(
        padding: const EdgeInsetsDirectional.only(top: 5),
        child: TextFormField(
            controller: description,
            textAlignVertical: TextAlignVertical.center,
            textInputAction: TextInputAction.next,
            validator: validateEmptyField,
            onSaved: (text) => description.text = text!,
            keyboardType: TextInputType.streetAddress,
            cursorColor: Color(COLOR_PRIMARY),
            // initialValue: vendor.description,
            decoration: InputDecoration(
              // contentPadding: EdgeInsets.symmetric(horizontal: 24),
              hintText: 'Description'.tr(),
              hintStyle: TextStyle(
                color: isDarkMode(context) ? Colors.white : Color(0Xff333333),
                fontSize: 14,
                fontFamily: AppThemeData.medium,
              ),
              contentPadding: new EdgeInsets.only(left: 8, right: 8),

              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.0),
                  borderSide:
                      BorderSide(color: Color(COLOR_PRIMARY), width: 2.0)),
              errorBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: Theme.of(context).colorScheme.error),
                borderRadius: BorderRadius.circular(7.0),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: Theme.of(context).colorScheme.error),
                borderRadius: BorderRadius.circular(7.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(7.0),
              ),
            )),
      ),
      Container(
          padding: EdgeInsets.only(top: 10),
          width: MediaQuery.of(context).size.width,
          child: Text(
            "Phone Number".tr(),
            textAlign: TextAlign.start,
            style: TextStyle(
                fontSize: 17,
                fontFamily: AppThemeData.medium,
                color: isDarkMode(context) ? Colors.white : Color(0Xff696A75)),
          )),
      Container(
        padding: const EdgeInsetsDirectional.only(top: 5),
        child: TextFormField(
            controller: phonenumber,
            textAlignVertical: TextAlignVertical.center,
            textInputAction: TextInputAction.next,
            validator: validateMobile,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
            ],
            onSaved: (text) => phonenumber.text = text!,
            keyboardType: TextInputType.streetAddress,
            cursorColor: Color(COLOR_PRIMARY),
            // initialValue: vendor.phonenumber,
            decoration: InputDecoration(
              // contentPadding: EdgeInsets.symmetric(horizontal: 24),
              hintText: 'Phone Number'.tr(),
              hintStyle: TextStyle(
                  color: isDarkMode(context) ? Colors.white : Color(0Xff333333),
                  fontSize: 14,
                  fontFamily: "Poppinsm"),
              contentPadding: new EdgeInsets.only(left: 8, right: 8),

              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.0),
                  borderSide:
                      BorderSide(color: Color(COLOR_PRIMARY), width: 2.0)),
              errorBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: Theme.of(context).colorScheme.error),
                borderRadius: BorderRadius.circular(7.0),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: Theme.of(context).colorScheme.error),
                borderRadius: BorderRadius.circular(7.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(7.0),
              ),
            )),
      ),
      Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          alignment: AlignmentDirectional.centerStart,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "Address".tr(),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: AppThemeData.medium,
                      color: isDarkMode(context) ? Colors.white : Colors.black),
                ),
              ),
              InkWell(
                onTap: () async {
                  checkPermission(
                    () async {
                      ShowToastDialog.showLoader("Please wait".tr());
                      try {
                        await Geolocator.requestPermission();
                        await Geolocator.getCurrentPosition(
                            desiredAccuracy: LocationAccuracy.high);
                        ShowToastDialog.closeLoader();
                        if (selectedMapType == 'osm') {
                          Navigator.of(context)
                              .push(MaterialPageRoute(
                                  builder: (context) => LocationPicker()))
                              .then(
                            (value) async {
                              if (value != null) {
                                Place result = value;
                                selectedLocation =
                                    LatLng(result.lat, result.lon);
                                address.text = result.displayName.toString();
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
                                  selectedLocation = LatLng(
                                      result.geometry!.location.lat,
                                      result.geometry!.location.lng);
                                  address.text =
                                      result.formattedAddress.toString();
                                  setState(() {});
                                  Navigator.of(context).pop();
                                },
                                initialPosition:
                                    LatLng(-33.8567844, 151.213108),
                                useCurrentLocation: true,
                                selectInitialPosition: true,
                                usePinPointingSearch: true,
                                usePlaceDetailSearch: true,
                                zoomGesturesEnabled: true,
                                zoomControlsEnabled: true,
                                resizeToAvoidBottomInset:
                                    false, // only works in page mode, less flickery, remove if wrong offsets
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        print(e.toString());
                      }
                    },
                  );
                },
                child: Text(
                  "Change".tr(),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: AppThemeData.medium,
                      color: Color(COLOR_PRIMARY)),
                ),
              ),
            ],
          )),
      InkWell(
        onTap: () {
          if (selectedLocation == null) {
            if (selectedMapType == 'osm') {
              Navigator.of(context)
                  .push(
                      MaterialPageRoute(builder: (context) => LocationPicker()))
                  .then(
                (value) async {
                  if (value != null) {
                    Place result = value;
                    selectedLocation = LatLng(result.lat, result.lon);
                    address.text = result.displayName.toString();
                    setState(() {});
                  }
                },
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlacePicker(
                    apiKey: GOOGLE_API_KEY,
                    onPlacePicked: (result) async {
                      selectedLocation = LatLng(result.geometry!.location.lat,
                          result.geometry!.location.lng);
                      address.text = result.formattedAddress.toString();
                      setState(() {});
                      Navigator.of(context).pop();
                    },
                    initialPosition: LatLng(-33.8567844, 151.213108),
                    useCurrentLocation: true,
                    selectInitialPosition: true,
                    usePinPointingSearch: true,
                    usePlaceDetailSearch: true,
                    zoomGesturesEnabled: true,
                    zoomControlsEnabled: true,
                    resizeToAvoidBottomInset:
                        false, // only works in page mode, less flickery, remove if wrong offsets
                  ),
                ),
              );
            }
          }
        },
        child: TextFormField(
            controller: address,
            textAlignVertical: TextAlignVertical.center,
            textInputAction: TextInputAction.next,
            onSaved: (text) => address.text = text!,
            enabled: selectedLocation == null ? false : true,
            cursorColor: Color(COLOR_PRIMARY),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              hintText: 'Address'.tr(),
              hintStyle: TextStyle(
                  color: isDarkMode(context) ? Colors.white : Color(0Xff333333),
                  fontFamily: AppThemeData.medium,
                  fontSize: 16),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(COLOR_PRIMARY)),
              ),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Color(COLOR_PRIMARY)),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0XFFB1BCCA)),
                // borderRadius: BorderRadius.circular(8.0),
              ),
            )),
      ),
      SizedBox(
        height: 10,
      ),
      SizedBox(
        height: 10,
      ),
      selectedModel != null &&
              selectedModel!.serviceTypeFlag == "ecommerce-service"
          ? Container()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile.adaptive(
                  dense: true,
                  activeColor: Color(COLOR_ACCENT),
                  title: Text(
                    'Delivery Settings'.tr(),
                    style: TextStyle(
                        fontSize: 16,
                        color:
                            isDarkMode(context) ? Colors.white : Colors.black,
                        fontFamily: "Poppinsm"),
                  ),
                  value: deliveryChargeModel != null
                      ? deliveryChargeModel!.vendor_can_modify
                      : false,
                  onChanged: (value) {},
                ),
                Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Delivery Charge Per km".tr(),
                      style: TextStyle(
                          fontSize: 15,
                          fontFamily: AppThemeData.medium,
                          color: isDarkMode(context)
                              ? Colors.white
                              : Color(0Xff696A75)),
                    )),
                Container(
                  padding: const EdgeInsetsDirectional.only(top: 5),
                  child: TextFormField(
                      controller: deliverChargeKm,
                      textAlignVertical: TextAlignVertical.center,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        print("value os $value");
                        if (value == null || value.isEmpty) {
                          return "Invalid value".tr();
                        }
                        return null;
                      },
                      enabled: deliveryChargeModel != null
                          ? deliveryChargeModel!.vendor_can_modify
                          : false,
                      onSaved: (text) => deliverChargeKm.text = text!,
                      keyboardType: TextInputType.number,
                      cursorColor: Color(COLOR_PRIMARY),
                      // initialValue: vendor.phonenumber,
                      decoration: InputDecoration(
                          // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                          hintText: 'Delivery Charge Per km'.tr(),
                          hintStyle: TextStyle(
                              color: isDarkMode(context)
                                  ? Colors.white
                                  : Color(0Xff333333),
                              fontSize: 14,
                              fontFamily: "Poppinsm"),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(7.0),
                              borderSide: BorderSide(
                                  color: Color(COLOR_PRIMARY), width: 2.0)),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error),
                            borderRadius: BorderRadius.circular(7.0),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error),
                            borderRadius: BorderRadius.circular(7.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(7.0),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(7.0),
                          ))),
                ),
                Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Min Delivery Charge".tr(),
                      style: TextStyle(
                          fontSize: 15,
                          fontFamily: AppThemeData.medium,
                          color: isDarkMode(context)
                              ? Colors.white
                              : Color(0Xff696A75)),
                    )),
                Container(
                  padding: const EdgeInsetsDirectional.only(top: 5),
                  child: TextFormField(
                      enabled: deliveryChargeModel != null
                          ? deliveryChargeModel!.vendor_can_modify
                          : false,
                      controller: minDeliveryCharge,
                      textAlignVertical: TextAlignVertical.center,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Invalid value".tr();
                        }
                        return null;
                      },
                      onSaved: (text) => minDeliveryCharge.text = text!,
                      keyboardType: TextInputType.number,
                      cursorColor: Color(COLOR_PRIMARY),
                      // initialValue: vendor.phonenumber,
                      decoration: InputDecoration(
                          // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                          hintText: 'Min Delivery Charge'.tr(),
                          hintStyle: TextStyle(
                              color: isDarkMode(context)
                                  ? Colors.white
                                  : Color(0Xff333333),
                              fontSize: 14,
                              fontFamily: "Poppinsm"),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(7.0),
                              borderSide: BorderSide(
                                  color: Color(COLOR_PRIMARY), width: 2.0)),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error),
                            borderRadius: BorderRadius.circular(7.0),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error),
                            borderRadius: BorderRadius.circular(7.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(7.0),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(7.0),
                          ))),
                ),
                Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Min Delivery Charge within km".tr(),
                      style: TextStyle(
                          fontSize: 15,
                          fontFamily: AppThemeData.medium,
                          color: isDarkMode(context)
                              ? Colors.white
                              : Color(0Xff696A75)),
                    )),
                Container(
                  padding: const EdgeInsetsDirectional.only(top: 5),
                  child: TextFormField(
                      controller: minDeliveryChargewkm,
                      enabled: deliveryChargeModel != null
                          ? deliveryChargeModel!.vendor_can_modify
                          : false,
                      textAlignVertical: TextAlignVertical.center,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Invalid value".tr();
                        }
                        return null;
                      },
                      onSaved: (text) => minDeliveryChargewkm.text = text!,
                      keyboardType: TextInputType.number,
                      cursorColor: Color(COLOR_PRIMARY),
                      // initialValue: vendor.phonenumber,
                      decoration: InputDecoration(
                          // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                          hintText: 'Min Delivery Charge within km'.tr(),
                          hintStyle: TextStyle(
                              color: isDarkMode(context)
                                  ? Colors.white
                                  : Color(0Xff333333),
                              fontSize: 14,
                              fontFamily: "Poppinsm"),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(7.0),
                              borderSide: BorderSide(
                                  color: Color(COLOR_PRIMARY), width: 2.0)),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error),
                            borderRadius: BorderRadius.circular(7.0),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error),
                            borderRadius: BorderRadius.circular(7.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(7.0),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(7.0),
                          ))),
                ),
              ],
            ),
      SizedBox(
        height: 10,
      ),
      InkWell(
        onTap: () {
          changeimg();
        },
        child: Image(
          image: AssetImage("assets/images/add_img.png"),
          fit: BoxFit.fill,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.2,
        ),
      ),
      SizedBox(
        height: 5,
      ),
      images.isEmpty
          ? const SizedBox()
          : SizedBox(
              height: 90,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: images.length,
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(10)),
                                child: images[index].runtimeType == XFile
                                    ? Image.file(
                                        File(images[index].path),
                                        fit: BoxFit.cover,
                                        width: 80,
                                        height: 80,
                                      )
                                    : NetworkImageWidget(
                                        imageUrl: images[index],
                                        fit: BoxFit.cover,
                                        width: 80,
                                        height: 80,
                                      ),
                              ),
                              Positioned(
                                bottom: 0,
                                top: 0,
                                left: 0,
                                right: 0,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      images.removeAt(index);
                                    });
                                  },
                                  child: const Icon(
                                    Icons.remove_circle,
                                    size: 28,
                                    color: AppThemeData.danger300,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              ),
            ),
    ]);
    // return selectedModel == null
    //     ? Container()
    //     : FutureBuilder<List<VendorCategoryModel>>(
    //         future: FireStoreUtils.getVendorCategoryById(selectedModel!.sectionId),
    //         builder: (context, AsyncSnapshot<List<VendorCategoryModel>> value) {
    //           if (value.connectionState != ConnectionState.done) {
    //             return Container();
    //           }
    //           categoryLst.clear();
    //           categoryLst.addAll(value.data!);
    //           if (!isReselect) {
    //             print("cat cahnge");
    //             for (int a = 0; a < value.data!.length; a++) {
    //               if (value.data![a].id == vendorCategoryModel.id && selectedModel!.sectionId == value.data![a].section_id) {
    //                 selectedCategory = value.data![a];
    //               }
    //             }
    //           }
    //
    //           isReselect = false;
    //           if (selectedCategory != null) {
    //             for (VendorCategoryModel vendorCategoryModel in categoryLst) {
    //               if (vendorCategoryModel.id == selectedCategory!.id) {
    //                 selectedCategory = vendorCategoryModel;
    //               }
    //             }
    //           }
    //
    //
    //         });
  }

  changeimg() {
    final action = CupertinoActionSheet(
      message: Text(
        'Change Picture'.tr(),
        style: TextStyle(fontSize: 15.0),
      ),
      actions: [
        CupertinoActionSheetAction(
          child: Text('Choose image from gallery'.tr()),
          isDefaultAction: false,
          onPressed: () async {
            Navigator.pop(context);
            XFile? image =
                await _imagePicker.pickImage(source: ImageSource.gallery);
            if (image != null) {
              // _mediaFiles.removeLast();
              setState(() {
                images.add(image);
              });

              // _mediaFiles.add(null);
            }
          },
        ),
        CupertinoActionSheetAction(
          child: Text('Take a picture'.tr()),
          isDestructiveAction: false,
          onPressed: () async {
            Navigator.pop(context);
            XFile? image =
                await _imagePicker.pickImage(source: ImageSource.camera);
            if (image != null) {
              // _mediaFiles.removeLast();

              setState(() {
                images.add(image);
              });
              // _mediaFiles.add(null);
            }
          },
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text('Cancel'.tr()),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  showAlertDialog(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK".tr()),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Store Field".tr()),
      content: Text("Please Select Image to Continue.".tr()),
      actions: [
        okButton,
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

  validate() async {
    if (storeName.text.isEmpty) {
      ShowToastDialog.showToast("Please enter store name".tr());
    } else if (selectedModel == null) {
      ShowToastDialog.showToast("Please select section".tr());
    } else if (selectedCategory == null) {
      ShowToastDialog.showToast("Please select category".tr());
    } else if (description.text.isEmpty) {
      ShowToastDialog.showToast("Please enter Description".tr());
    } else if (phonenumber.text.isEmpty) {
      ShowToastDialog.showToast("Please enter phone number".tr());
    } else if (address.text.isEmpty) {
      ShowToastDialog.showToast("Please enter address".tr());
    } else {
      ShowToastDialog.showLoader("Please wait".tr());
      ();
      if (selectedModel!.serviceTypeFlag != "ecommerce-service") {
        deliveryChargeModel!.vendor_can_modify = true;
        deliveryChargeModel!.delivery_charges_per_km =
            num.parse(deliverChargeKm.text);
        deliveryChargeModel!.minimum_delivery_charges =
            num.parse(minDeliveryCharge.text);
        deliveryChargeModel!.minimum_delivery_charges_within_km =
            num.parse(minDeliveryChargewkm.text);
      }

      if (vendorData == null) {
        vendorData = VendorModel();
        vendorData!.createdAt = Timestamp.now();
        vendorData!.subscriptionPlanId =
            MyAppState.currentUser?.subscriptionPlanId;
        vendorData?.subscriptionPlan = MyAppState.currentUser?.subscriptionPlan;
        vendorData?.subscriptionPlan?.createdAt = Timestamp.now();
        vendorData?.subscriptionExpiryDate =
            MyAppState.currentUser?.subscriptionExpiryDate;
        vendorData!.subscriptionTotalOrders =
            MyAppState.currentUser?.subscriptionPlan?.orderLimit;
      }

      for (int i = 0; i < images.length; i++) {
        if (images[i].runtimeType == XFile) {
          String url = await FireStoreUtils.uploadUserImageToFireStorage(
            File(images[i].path),
            "${i}${DateTime.now().millisecondsSinceEpoch.toString()}",
          );
          images.removeAt(i);
          images.insert(i, url);
        }
      }

      vendorData!.id = MyAppState.currentUser!.vendorID;
      vendorData!.author = MyAppState.currentUser!.userID;
      vendorData!.authorName = MyAppState.currentUser!.firstName;
      vendorData!.photos = images;
      vendorData!.photo = images.isEmpty ? "" : images.first;

      vendorData!.categoryID = selectedCategory!.id.toString();
      vendorData!.categoryTitle = selectedCategory!.title.toString();
      vendorData!.geoFireData = GeoFireData(
          geohash: Geoflutterfire()
              .point(
                  latitude: selectedLocation!.latitude,
                  longitude: selectedLocation!.longitude)
              .hash,
          geoPoint: GeoPoint(
              selectedLocation!.latitude, selectedLocation!.longitude));
      vendorData!.description = description.text;
      vendorData!.phonenumber = phonenumber.text;
      vendorData!.section_id = selectedModel!.id.toString();
      vendorData!.location = address.text;
      vendorData!.latitude = selectedLocation!.latitude;
      vendorData!.longitude = selectedLocation!.longitude;
      vendorData!.fcmToken = MyAppState.currentUser!.fcmToken;
      vendorData!.reststatus = true;

      vendorData!.DeliveryCharge = deliveryChargeModel;
      vendorData!.title = storeName.text;
      if (vendorData?.adminCommission?.commission == null) {
        vendorData?.adminCommission = selectedModel?.adminCommision;
      }
      print("===========>");
      MyAppState.currentUser?.section_id = vendorData!.section_id;
      await FireStoreUtils.updateCurrentUser(MyAppState.currentUser!);
      if (MyAppState.currentUser?.vendorID.isNotEmpty == true) {
        await FireStoreUtils.updateVendor(vendorData!);
      } else {
        await FireStoreUtils.firebaseCreateNewVendor(vendorData!);
      }
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Store details save successfully".tr());
      pushAndRemoveUntil(
          context, ContainerScreen(user: MyAppState.currentUser!), false);

//      if ((selectedModel?.adminCommision?.enable == true ||
//              isSubscriptionModelApplied == true) &&
//          (vendorData?.subscriptionPlanId == null ||
//              vendorData?.subscriptionPlanId == '')) {
//        pushAndRemoveUntil(
//            context,
//            SubscriptionScreens(isShowAppBar: false, isDropDownDisble: true),
//            false);
//      }
    }
  }

  bool isPhoneNoValid(String? phoneNo) {
    if (phoneNo == null) return false;
    final regExp = RegExp(r'(^(?:[+0]9)?[0-9]{10,12}$)');
    return regExp.hasMatch(phoneNo);
  }

  showimgAlertDialog(
      BuildContext context, String title, String content, bool addOkButton) {
    Widget? okButton;
    if (addOkButton) {
      okButton = TextButton(
        child: Text('OK'.tr()),
        onPressed: () {
          Navigator.pop(context);
        },
      );
    }

    if (Platform.isIOS) {
      CupertinoAlertDialog alert = CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [if (okButton != null) okButton],
      );
      showCupertinoDialog(
          context: context,
          builder: (context) {
            return alert;
          });
    } else {
      AlertDialog alert = AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [if (okButton != null) okButton]);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return alert;
        },
      );
    }
  }

  showAlertDialog1(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK".tr()),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("My title".tr()),
      content: Text("This is my message.".tr()),
      actions: [
        okButton,
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

  void checkPermission(Function() onTap) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      SnackBar snack = SnackBar(
        content: const Text(
          'You have to allow location permission to use your location',
          style: TextStyle(color: Colors.white),
        ).tr(),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.black,
      );
      ScaffoldMessenger.of(context).showSnackBar(snack);
    } else if (permission == LocationPermission.deniedForever) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return PermissionDialog();
        },
      );
    } else {
      onTap();
    }
  }
}
