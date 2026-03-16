import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emartconsumer/constants.dart';
import 'package:emartconsumer/main.dart';
import 'package:emartconsumer/model/User.dart';
import 'package:emartconsumer/rental_service/model/rental_order_model.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/theme/app_them_data.dart';
import 'package:emartconsumer/theme/round_button_fill.dart';
import 'package:emartconsumer/theme/text_field_widget.dart';
import 'package:emartconsumer/widget/place_picker_osm.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import 'vehicle_type_screens.dart';

class RentalServiceHomeScreen extends StatefulWidget {
  final User? user;

  const RentalServiceHomeScreen({Key? key, this.user}) : super(key: key);

  @override
  State<RentalServiceHomeScreen> createState() => _RentalServiceHomeScreenState();
}

class _RentalServiceHomeScreenState extends State<RentalServiceHomeScreen> {
  final _formKey = GlobalKey<FormState>();

  final startTimeController = TextEditingController();
  final endTimeController = TextEditingController();
  final pickupLocationController = TextEditingController();
  final dropLocationController = TextEditingController();

  UserLocation? pickUpLocation;
  UserLocation? dropLocation;

  DateTime? startDate = DateTime.now();
  DateTime? endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode(context) ? AppThemeData.surfaceDark : AppThemeData.surface,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: SingleChildScrollView(
          child: Column(
            children: [
              buildBookWithDriver(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                margin: const EdgeInsets.only(left: 10, top: 10, right: 10, bottom: 10),
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
                child: SfDateRangePicker(
                  selectionMode: DateRangePickerSelectionMode.range,
                  view: DateRangePickerView.month,
                  onSelectionChanged: _onSelectionChanged,
                  minDate: DateTime.now(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  if (startDate != null) {
                                    selectTime(context, isStart: true);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: const Text(
                                        "Please select Date",
                                      ).tr(),
                                      backgroundColor: Colors.green.shade400,
                                      duration: const Duration(seconds: 6),
                                    ));
                                  }
                                },
                                child: TextFieldWidget(
                                  enable: false,
                                  title: 'Start Time'.tr(),
                                  controller: startTimeController,
                                  hintText: 'Start Time'.tr(),
                                  prefix: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Icon(
                                      Icons.access_time,
                                      color: isDarkMode(context) ? AppThemeData.grey300 : AppThemeData.grey600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  if (startDate != null) {
                                    selectTime(context, isStart: false);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text(
                                        "Please select Date".tr(),
                                      ),
                                      backgroundColor: Colors.green.shade400,
                                      duration: const Duration(seconds: 6),
                                    ));
                                  }
                                },
                                child: TextFieldWidget(
                                  enable: false,
                                  title: 'End Time'.tr(),
                                  controller: endTimeController,
                                  hintText: 'End Time'.tr(),
                                  prefix: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Icon(
                                      Icons.access_time,
                                      color: isDarkMode(context) ? AppThemeData.grey300 : AppThemeData.grey600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        InkWell(
                          onTap: () {
                            if (selectedMapType == 'osm') {
                              Navigator.of(context).push(MaterialPageRoute(builder: (context) => LocationPicker())).then(
                                    (value) {
                                  if (value != null) {
                                    pickupLocationController.text = value.displayName!.toString();
                                    pickUpLocation = UserLocation(latitude: value.lat, longitude: value.lon);
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
                                      pickupLocationController.text = result.formattedAddress!;
                                      pickUpLocation = UserLocation(latitude: result.geometry!.location.lat, longitude: result.geometry!.location.lng);
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
                          child: TextFieldWidget(
                            enable: false,
                            title: 'Pickup location'.tr(),
                            controller: pickupLocationController,
                            hintText: 'Pickup location'.tr(),
                            prefix: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.location_on,
                                color: isDarkMode(context) ? AppThemeData.grey300 : AppThemeData.grey600,
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text("Drop off at same location".tr(),
                                  style: TextStyle(fontFamily: AppThemeData.medium, fontSize: 14, color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey900)),
                            ),
                            Transform.scale(
                              transformHitTests: false,
                              scale: 0.70,
                              child: CupertinoSwitch(
                                value: dropOfAtSameLocation,
                                onChanged: (bool isOn) {
                                  setState(() {
                                    dropOfAtSameLocation = isOn;
                                  });
                                },
                                activeColor: AppThemeData.primary300,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        dropOfAtSameLocation
                            ? Container()
                            : InkWell(
                                onTap: () {
                                  if (selectedMapType == 'osm') {
                                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => LocationPicker())).then(
                                          (value) {
                                        if (value != null) {
                                          dropLocationController.text = value.displayName!.toString();
                                          dropLocation = UserLocation(latitude: value.lat, longitude: value.lon);
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
                                            dropLocationController.text = result.formattedAddress!;
                                            dropLocation = UserLocation(latitude: result.geometry!.location.lat, longitude: result.geometry!.location.lng);
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
                                child: TextFieldWidget(
                                  enable: false,
                                  title: 'Drop up location'.tr(),
                                  controller: dropLocationController,
                                  hintText: 'Drop up location'.tr(),
                                  prefix: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Icon(
                                      Icons.location_on,
                                      color: isDarkMode(context) ? AppThemeData.grey300 : AppThemeData.grey600,
                                    ),
                                  ),
                                ),
                              ),
                        const SizedBox(
                          height: 10,
                        ),
                        RoundedButtonFill(
                          title: "Find Car".tr(),
                          color: AppThemeData.primary300,
                          textColor: AppThemeData.grey50,
                          onPress: () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              _formKey.currentState!.save();
                              RentalOrderModel rentalOrderModel = RentalOrderModel(
                                  authorID: MyAppState.currentUser!.userID,
                                  author: MyAppState.currentUser,
                                  pickupDateTime:
                                  Timestamp.fromDate(DateTime(startDate!.year, startDate!.month, startDate!.day, selectedTimeStart.hour, selectedTimeStart.minute)),
                                  dropDateTime: Timestamp.fromDate(DateTime(endDate!.year, endDate!.month, endDate!.day, selectedTimeEnd.hour, selectedTimeEnd.minute)),
                                  bookWithDriver: isDriverWant,
                                  pickupAddress: pickupLocationController.text.toString(),
                                  dropAddress: dropOfAtSameLocation ? pickupLocationController.text.toString() : dropLocationController.text.toString(),
                                  pickupLatLong: pickUpLocation,
                                  dropLatLong: dropOfAtSameLocation ? pickUpLocation : dropLocation,
                                  sectionId: sectionConstantModel!.id);

                              print(pickUpLocation!.toJson());
                              push(
                                  context,
                                  VehicleTypeScreen(
                                    rentalOrderModel: rentalOrderModel,
                                  ));
                            }
                          },
                        ),

                        // SizedBox(
                        //   width: MediaQuery.of(context).size.width,
                        //   height: MediaQuery.of(context).size.height * 0.06,
                        //   child: ElevatedButton(
                        //     style: ElevatedButton.styleFrom(
                        //       foregroundColor: Colors.white,
                        //       backgroundColor: AppThemeData.primary300, // foreground
                        //     ),
                        //     onPressed: () {
                        //
                        //     },
                        //     child: Text(
                        //       'Find Car'.tr().toUpperCase(),
                        //       style: const TextStyle(fontSize: 16),
                        //     ),
                        //   ),
                        // ),
                        const SizedBox(
                          height: 10,
                        ),
                      ],
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    setState(() {
      startDate = args.value.startDate;
      endDate = args.value.endDate ?? args.value.startDate;
    });
  }

  bool isDriverWant = false;
  bool dropOfAtSameLocation = true;

  Widget buildBookWithDriver() {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        margin: const EdgeInsets.only(left: 10, top: 10, right: 10, bottom: 10),
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Book With Driver".tr(),
                    style: const TextStyle(),
                  ),
                  Text("Don't have  a driver ? Book car with a Driver".tr(), style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            Transform.scale(
              transformHitTests: false,
              scale: 0.70,
              child: CupertinoSwitch(
                value: isDriverWant,
                onChanged: (bool isOn) {
                  setState(() {
                    isDriverWant = isOn;
                  });
                },
                activeColor: AppThemeData.primary300,
              ),
            ),
          ],
        ));
  }

  TimeOfDay selectedTimeStart = TimeOfDay.now();
  TimeOfDay selectedTimeEnd = TimeOfDay.now();

  selectTime(BuildContext context, {bool isStart = true}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTimeStart,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          selectedTimeStart = picked;
          print(DateTime(startDate!.year, startDate!.month, startDate!.day, selectedTimeStart.hour, selectedTimeStart.minute));
          print(DateTime(endDate!.year, endDate!.month, endDate!.day, selectedTimeEnd.hour, selectedTimeEnd.minute));

          if (DateTime(startDate!.year, startDate!.month, startDate!.day, selectedTimeStart.hour, selectedTimeStart.minute).isAfter(DateTime.now())) {
            startTimeController.text = DateFormat('HH:mm').format(DateTime(startDate!.year, startDate!.month, startDate!.day, selectedTimeStart.hour, selectedTimeStart.minute));
          } else {
            showAlertDialog(context, "Alert".tr(), "Start time should be greater than current time", true);
          }
        } else {
          selectedTimeEnd = picked;
          print(DateTime(startDate!.year, startDate!.month, startDate!.day, selectedTimeStart.hour, selectedTimeStart.minute));
          print(DateTime(endDate!.year, endDate!.month, endDate!.day, selectedTimeEnd.hour, selectedTimeEnd.minute));

          if (DateTime(startDate!.year, startDate!.month, startDate!.day, selectedTimeStart.hour, selectedTimeStart.minute)
              .isBefore(DateTime(endDate!.year, endDate!.month, endDate!.day, selectedTimeEnd.hour, selectedTimeEnd.minute))) {
            endTimeController.text = DateFormat('HH:mm').format(DateTime(endDate!.year, endDate!.month, endDate!.day, selectedTimeEnd.hour, selectedTimeEnd.minute));
          } else {
            showAlertDialog(context, "Alert".tr(), "End time should be greater than start time".tr(), true);
          }
        }
      });
    }
  }
}
