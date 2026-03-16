import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:emartconsumer/theme/app_them_data.dart';
import 'package:emartconsumer/theme/round_button_fill.dart';
import 'package:emartconsumer/ui/service_list_screen.dart';
import 'package:emartconsumer/widget/place_picker_osm.dart';
import 'package:flutter/material.dart';
import 'package:emartconsumer/constants.dart';
import 'package:emartconsumer/main.dart';
import 'package:emartconsumer/model/AddressModel.dart';
import 'package:emartconsumer/model/User.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:uuid/uuid.dart';
import 'deliveryAddressScreen/DeliveryAddressScreen.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({Key? key}) : super(key: key);

  @override
  _LocationPermissionScreenState createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode(context) ? AppThemeData.surfaceDark : AppThemeData.surface,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Image.asset("assets/images/location_screen.png"),
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              "Enable Location for a Personalized Experience".tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppThemeData.semiBold,
                fontSize: 24,
                color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900,
              ),
            ),
            SizedBox(
              height: 5,
            ),
            Text(
              "Allow location access to discover beauty stores and services near you.".tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppThemeData.regular,
                fontSize: 16,
                color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900,
              ),
            ),
            SizedBox(
              height: 20,
            ),
            RoundedButtonFill(
              title: "Use current location".tr(),
              color: AppThemeData.primary300,
              textColor: AppThemeData.grey50,
              onPress: () async {
                checkPermission(() async {
                  await showProgress("Please wait...".tr(), false);
                  AddressModel addressModel = AddressModel();
                  try {
                    await Geolocator.requestPermission();
                    await Geolocator.getCurrentPosition();
                    await hideProgress();
                    Position newLocalData = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                    await placemarkFromCoordinates(newLocalData.latitude, newLocalData.longitude).then((valuePlaceMaker) {
                      Placemark placeMark = valuePlaceMaker[0];

                      setState(() {
                        addressModel.id = Uuid().v4();
                        addressModel.location = UserLocation(latitude: newLocalData.latitude, longitude: newLocalData.longitude);
                        String currentLocation =
                            "${placeMark.name}, ${placeMark.subLocality}, ${placeMark.locality}, ${placeMark.administrativeArea}, ${placeMark.postalCode}, ${placeMark.country}";
                        addressModel.locality = currentLocation;
                      });
                    });
                    setState(() {});

                    MyAppState.selectedPosotion = addressModel;

                    pushAndRemoveUntil(context, ServiceListScreen());
                  } catch (e) {
                    await placemarkFromCoordinates(19.228825, 72.854118).then((valuePlaceMaker) {
                      Placemark placeMark = valuePlaceMaker[0];
                      setState(() {
                        addressModel.id = Uuid().v4();
                        addressModel.location = UserLocation(latitude: 19.228825, longitude: 72.854118);
                        String currentLocation =
                            "${placeMark.name}, ${placeMark.subLocality}, ${placeMark.locality}, ${placeMark.administrativeArea}, ${placeMark.postalCode}, ${placeMark.country}";
                        addressModel.locality = currentLocation;
                      });
                    });

                    MyAppState.selectedPosotion = addressModel;
                    await hideProgress();
                    pushAndRemoveUntil(context, ServiceListScreen());
                  }
                }, context);
              },
            ),
            SizedBox(
              height: 10,
            ),
            RoundedButtonFill(
              title: "Set from map".tr(),
              color: AppThemeData.grey50,
              textColor: AppThemeData.primary300,
              onPress: () async {
                checkPermission(() async {
                   await showProgress("Please wait...".tr(), false);
                  AddressModel addressModel = AddressModel();
                  try {
                    await Geolocator.requestPermission();
                    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                    await hideProgress();
                    if (selectedMapType == 'osm') {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => LocationPicker())).then(
                        (value) async {
                          await hideProgress();
                          if (value != null) {
                            addressModel.locality = value.displayName!.toString();
                            addressModel.location = UserLocation(latitude: value.lat, longitude: value.lon);
                            MyAppState.selectedPosotion = addressModel;
                            setState(() {});
                            pushAndRemoveUntil(context, ServiceListScreen());
                          }
                        },
                      );
                    }
                    else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlacePicker(
                            apiKey: GOOGLE_API_KEY,
                            onPlacePicked: (result) {
                              addressModel.locality = result.formattedAddress!.toString();
                              addressModel.location = UserLocation(latitude: result.geometry!.location.lat, longitude: result.geometry!.location.lng);
                              log(result.toString());
                              MyAppState.selectedPosotion = addressModel;
                              setState(() {});
                              pushAndRemoveUntil(context, ServiceListScreen());
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
                  } catch (e) {
                    await placemarkFromCoordinates(19.228825, 72.854118).then((valuePlaceMaker) {
                      Placemark placeMark = valuePlaceMaker[0];
                      setState(() {
                        addressModel.id = Uuid().v4();
                        addressModel.location = UserLocation(latitude: 19.228825, longitude: 72.854118);
                        String currentLocation =
                            "${placeMark.name}, ${placeMark.subLocality}, ${placeMark.locality}, ${placeMark.administrativeArea}, ${placeMark.postalCode}, ${placeMark.country}";
                        addressModel.locality = currentLocation;
                      });
                    });

                    MyAppState.selectedPosotion = addressModel;
                    await hideProgress();
                    pushAndRemoveUntil(context, ServiceListScreen());
                  }
                }, context);
              },
            ),
            MyAppState.currentUser != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 40.0, left: 40.0, top: 10),
                    child: TextButton(
                      child: Text(
                        "Enter Manually location",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppThemeData.primary300),
                      ).tr(),
                      onPressed: () async {
                        await Navigator.of(context).push(MaterialPageRoute(builder: (context) => DeliveryAddressScreen())).then((value) {
                          if (value != null) {
                            AddressModel addressModel = value;
                            MyAppState.selectedPosotion = addressModel;
                            pushAndRemoveUntil(context, ServiceListScreen());
                          }
                        });
                      },
                    ),
                  )
                : Container()
          ],
        ),
      ),
    );
  }
}
