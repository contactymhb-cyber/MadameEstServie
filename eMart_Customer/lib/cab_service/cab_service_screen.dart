import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emartconsumer/cab_service/CabPaymentScreen.dart';
import 'package:emartconsumer/cab_service/cab_payment_selection_screen.dart';
import 'package:emartconsumer/cab_service/dashboard_cab_service.dart';
import 'package:emartconsumer/constants.dart';
import 'package:emartconsumer/main.dart';
import 'package:emartconsumer/model/CabOrderModel.dart';
import 'package:emartconsumer/model/User.dart';
import 'package:emartconsumer/model/VehicleType.dart';
import 'package:emartconsumer/services/FirebaseHelper.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/theme/app_them_data.dart';
import 'package:emartconsumer/theme/responsive.dart';
import 'package:emartconsumer/ui/auth_screen/login_screen.dart';
import 'package:emartconsumer/ui/chat_screen/chat_screen.dart';
import 'package:emartconsumer/widget/place_picker_osm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osmflutter;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as get_cord_address;
import 'package:url_launcher/url_launcher.dart' as UrlLauncher;
import 'package:http/http.dart' as http;
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';

class CabServiceScreen extends StatefulWidget {
  const CabServiceScreen({Key? key}) : super(key: key);

  @override
  State<CabServiceScreen> createState() => _CabServiceScreenState();
}

class _CabServiceScreenState extends State<CabServiceScreen> {
  final CameraPosition _kInitialPosition = const CameraPosition(target: LatLng(19.018255973653343, 72.84793849278007), zoom: 11.0, tilt: 0, bearing: 0);

  final TextEditingController departureController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();

  GoogleMapController? _controller;
  final Location currentLocation = Location();

  Map<String, osmflutter.GeoPoint> osmMarkers = <String, osmflutter.GeoPoint>{};

  final Map<String, Marker> _markers = {};
  late osmflutter.MapController mapOsmController;

  BitmapDescriptor? departureIcon;
  BitmapDescriptor? destinationIcon;
  BitmapDescriptor? taxiIcon;

  LatLng? departureLatLong;
  LatLng? destinationLatLong;

  Map<PolylineId, Polyline> polyLines = {};
  PolylinePoints polylinePoints = PolylinePoints();

  @override
  void initState() {
    if (selectedMapType == 'osm') {
      mapOsmController = osmflutter.MapController(initPosition: osmflutter.GeoPoint(latitude: 20.9153, longitude: -100.7439), useExternalTracking: false); //OSM
    }
    setIcons();
    getVehicleType();
    getCurrentOrder();
    super.initState();
  }

  List<VehicleType> vehicleType = [];

  getVehicleType() async {
    await FireStoreUtils.getVehicleType().then((value) {
      setState(() {
        vehicleType = value;
      });
    });
  }

  Image? departureOsmIcon; //OSM
  Image? destinationOsmIcon; //OSM
  Image? driverOsmIcon;

  setIcons() async {
    if (selectedMapType == 'google') {
      BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(10, 10)), "assets/icons/pickup.png").then((value) {
        departureIcon = value;
      });

      BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(10, 10)), "assets/icons/dropoff.png").then((value) {
        destinationIcon = value;
      });

      BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(10, 10)), "assets/icons/ic_taxi.png").then((value) {
        taxiIcon = value;
      });
    } else {
      departureOsmIcon = Image.asset("assets/icons/pickup.png", width: 30, height: 30); //OSM
      destinationOsmIcon = Image.asset("assets/icons/dropoff.png", width: 30, height: 30); //OSM
      driverOsmIcon = Image.asset("assets/icons/ic_taxi.png", width: 80, height: 80); //OSM
    }
  }

  @override
  void dispose() {
    // FireStoreUtils().cabOrdersStreamController.close();
    FireStoreUtils().cabOrdersStreamSub.cancel();
    FireStoreUtils().driverStreamController.close();
    FireStoreUtils().driverStreamSub.cancel();
    _controller!.dispose();
    super.dispose();
  }

  String statusOfOrder = "";
  late Stream<CabOrderModel> ordersFuture;
  CabOrderModel? _cabOrderModel;

  late Stream<User> driverStream;
  User? _driverModel;

  getCurrentOrder() {
    try {
      if (MyAppState.currentUser != null) {
        if (MyAppState.currentUser!.inProgressOrderID != null && MyAppState.currentUser!.inProgressOrderID!.isNotEmpty) {
          ordersFuture = FireStoreUtils().getCabOrder(MyAppState.currentUser!.inProgressOrderID.toString());
          ordersFuture.listen((event) {
            setState(() {
              _cabOrderModel = event;
              statusOfOrder = event.status;
            });
            if (_cabOrderModel!.driverID != null) {
              if (_cabOrderModel!.driverID!.isNotEmpty) {
                getDriverDetails();
              }
            }
            setState(() {});
          });
        }
        getDirections();
        setState(() {});
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  void getCurrentLocation(bool isDepartureSet) async {
    try {
      if (isDepartureSet) {
        LocationData location = await currentLocation.getLocation();
        List<get_cord_address.Placemark> placeMarks = await get_cord_address.placemarkFromCoordinates(location.latitude ?? 0.0, location.longitude ?? 0.0);

        final address = (placeMarks.first.subLocality!.isEmpty ? '' : "${placeMarks.first.subLocality}, ") +
            (placeMarks.first.street!.isEmpty ? '' : "${placeMarks.first.street}, ") +
            (placeMarks.first.name!.isEmpty ? '' : "${placeMarks.first.name}, ") +
            (placeMarks.first.subAdministrativeArea!.isEmpty ? '' : "${placeMarks.first.subAdministrativeArea}, ") +
            (placeMarks.first.administrativeArea!.isEmpty ? '' : "${placeMarks.first.administrativeArea}, ") +
            (placeMarks.first.country!.isEmpty ? '' : "${placeMarks.first.country}, ") +
            (placeMarks.first.postalCode!.isEmpty ? '' : "${placeMarks.first.postalCode}, ");
        departureController.text = address;
        setState(() {
          setDepartureMarker(LatLng(location.latitude ?? 0.0, location.longitude ?? 0.0));
        });
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode(context) ? AppThemeData.surfaceDark : AppThemeData.surface,
      body: Stack(
        children: [
          selectedMapType == 'osm'
              ? RepaintBoundary(
                  child: osmflutter.OSMFlutter(
                      controller: mapOsmController,
                      osmOption: osmflutter.OSMOption(
                        userLocationMarker: osmflutter.UserLocationMaker(
                          directionArrowMarker: osmflutter.MarkerIcon(
                            iconWidget: driverOsmIcon,
                          ),
                          personMarker: osmflutter.MarkerIcon(
                            iconWidget: driverOsmIcon,
                          ),
                        ),
                        userTrackingOption: const osmflutter.UserTrackingOption(
                          enableTracking: true,
                          unFollowUser: false,
                        ),
                        zoomOption: const osmflutter.ZoomOption(
                          initZoom: 16,
                          minZoomLevel: 2,
                          maxZoomLevel: 19,
                          stepZoom: 1.0,
                        ),
                        roadConfiguration: const osmflutter.RoadOption(
                          roadColor: Colors.yellowAccent,
                        ),
                      ),
                      onMapIsReady: (active) async {
                        setState(() {});
                      }),
                )
              : GoogleMap(
                  mapType: MapType.terrain,
                  zoomControlsEnabled: true,
                  myLocationButtonEnabled: true,
                  padding: const EdgeInsets.only(
                    top: 210.0,
                  ),
                  initialCameraPosition: _kInitialPosition,
                  onMapCreated: (GoogleMapController controller) async {
                    _controller = controller;

                    // LocationData location = await currentLocation.getLocation();
                    // _controller!.moveCamera(CameraUpdate.newLatLngZoom(LatLng(location.latitude ?? 0.0, location.longitude ?? 0.0), 14));
                  },
                  polylines: Set<Polyline>.of(polyLines.values),
                  myLocationEnabled: true,
                  markers: _markers.values.toSet(),
                ),
          Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: ElevatedButton(
                    onPressed: () {
                      push(context, DashBoardCabService(user: MyAppState.currentUser));
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(8),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_sharp,
                      color: Colors.black,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: isDarkMode(context) ? Colors.black87 : Colors.white),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                "assets/icons/ic_pic_drop_location.png",
                                height: 85,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: InkWell(
                                              onTap: () async {
                                                if (selectedMapType == 'osm') {
                                                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => LocationPicker())).then(
                                                    (value) {
                                                      if (value != null) {
                                                        setState(() {
                                                          departureController.text = value.displayName!.toString();
                                                          setDepartureMarker(LatLng(value.lat, value.lon));
                                                        });
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
                                                          setState(() {
                                                            departureController.text = result.formattedAddress.toString();
                                                            setDepartureMarker(LatLng(result.geometry!.location.lat, result.geometry!.location.lng));
                                                          });

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
                                              child: buildTextField(
                                                title: "Departure".tr(),
                                                textController: departureController,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              getCurrentLocation(true);
                                            },
                                            autofocus: false,
                                            icon: Icon(
                                              Icons.my_location_outlined,
                                              size: 18,
                                              color: isDarkMode(context) ? Colors.white : Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(),
                                      InkWell(
                                        onTap: () async {
                                          if (selectedMapType == 'osm') {
                                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => LocationPicker())).then(
                                              (value) {
                                                if (value != null) {
                                                  print("=====>");
                                                  print(value.displayName);
                                                  print(value.lat);
                                                  print(value.lon);
                                                  setState(() {
                                                    destinationController.text = value.displayName!.toString();
                                                    setDestinationMarker(LatLng(value.lat, value.lon));
                                                  });
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
                                                    setState(() {
                                                      destinationController.text = result.formattedAddress.toString();
                                                      setDestinationMarker(LatLng(result.geometry!.location.lat, result.geometry!.location.lng));
                                                    });

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
                                        child: buildTextField(
                                          title: "Where do you want to go ?".tr(),
                                          textController: destinationController,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: statusOfOrder == ORDER_STATUS_PLACED || statusOfOrder == ORDER_STATUS_DRIVER_PENDING || statusOfOrder == ORDER_STATUS_DRIVER_REJECTED
                ? waitingDialog()
                : statusOfOrder == ORDER_STATUS_DRIVER_ACCEPTED || statusOfOrder == ORDER_STATUS_SHIPPED || statusOfOrder == ORDER_STATUS_IN_TRANSIT
                    ? driverDialog(_cabOrderModel)
                    : statusOfOrder == ORDER_REACHED_DESTINATION
                        ? completeRide()
                        : statusOfOrder == "conformation"
                            ? conformationButton()
                            : statusOfOrder == "vehicleType"
                                ? vehicleSelection()
                                : Container(),
          )
        ],
      ),
    );
  }

  double distance = 0.0;
  String duration = "";

  VehicleType? selectedVehicleType;
  String selectedVehicleTypeName = "";

  conformationButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
      child: MaterialButton(
        onPressed: () async {
          if (selectedMapType == "osm") {
            await getDurationOsmDistance(departureLatLong!, destinationLatLong!).then((value) {
              if (value != {} && value.isNotEmpty) {
                int hours = value['routes'].first['duration'] ~/ 3600;
                int minutes = ((value['routes'].first['duration'] % 3600) / 60).round();
                setState(() {
                  distance = value['routes'].first['distance'] / 1000;
                  duration = '$hours hours $minutes minutes';
                  statusOfOrder = "vehicleType";
                });
              }
            });
          } else {
            await getDurationDistance(departureLatLong!, destinationLatLong!).then((durationValue) async {
              print("----->${durationValue.toString()}");
              if (durationValue != null) {
                setState(() {
                  distance = durationValue['rows'].first['elements'].first['distance']['value'] / 1000.00;
                  duration = durationValue['rows'].first['elements'].first['duration']['text'];
                  statusOfOrder = "vehicleType";
                });
              }
            });
          }
        },
        height: 50,
        minWidth: MediaQuery.of(context).size.width,
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        color: AppThemeData.primary300,
        child: const Text(
          "Continue",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: AppThemeData.medium),
        ).tr(),
      ),
    );
  }

  vehicleSelection() {
    return Container(
      height: Responsive.height(80, context),
      decoration: BoxDecoration(
        color: isDarkMode(context) ? Colors.black : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                "Select Your Vehicle Type".tr(),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: vehicleType.length,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                scrollDirection: Axis.vertical,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedVehicleType = vehicleType[index];
                          selectedVehicleTypeName = vehicleType[index].name.toString();
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isDarkMode(context)
                                  ? selectedVehicleTypeName == vehicleType[index].name.toString()
                                      ? Colors.white
                                      : const Color(DarkContainerBorderColor)
                                  : selectedVehicleTypeName == vehicleType[index].name.toString()
                                      ? Colors.black
                                      : Colors.grey.shade100,
                              width: 1),
                          color: isDarkMode(context) ? const Color(DarkContainerColor) : Colors.white,
                          boxShadow: [
                            isDarkMode(context)
                                ? const BoxShadow()
                                : BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    blurRadius: 5,
                                  ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: vehicleType[index].vehicleIcon.toString(),
                                  height: 60,
                                  width: 60,
                                  imageBuilder: (context, imageProvider) => Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                                    ),
                                  ),
                                  placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator.adaptive(
                                    valueColor: AlwaysStoppedAnimation(AppThemeData.primary300),
                                  )),
                                  errorWidget: (context, url, error) => ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.network(
                                        placeholderImage,
                                        fit: BoxFit.cover,
                                      )),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        vehicleType[index].name.toString() + " | " + distance.toStringAsFixed(currencyData!.decimal) + "km",
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2.0),
                                        child: Text(
                                          duration,
                                          style: const TextStyle(fontWeight: FontWeight.w400, letterSpacing: 1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Text(
                                // symbol + getAmount(vehicleType[index]).toStringAsFixed(decimal),
                                amountShow(amount: getAmount(vehicleType[index]).toString()),

                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            MaterialButton(
              onPressed: () async {
                if (selectedVehicleType!.name!.isNotEmpty) {
                  if (MyAppState.currentUser == null) {
                    push(context, const LoginScreen());
                  } else {
                    final result = await Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => CabPaymentSelectionScreen(
                            distance: distance.toString(),
                            duration: duration,
                            departureLatLong: departureLatLong,
                            destinationLatLong: destinationLatLong,
                            vehicleId: selectedVehicleType!.id,
                            vehicleType: selectedVehicleType,
                            departureName: departureController.text,
                            destinationName: destinationController.text,
                            subTotal: getAmount(selectedVehicleType!).toStringAsFixed(currencyData!.decimal))));
                    print("----->${result}");
                    if (result != null) {
                      getCurrentOrder();
                    }
                  }
                }
              },
              height: 50,
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              color: AppThemeData.primary300,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Book".tr() + " ${selectedVehicleType == null ? "" : selectedVehicleType!.name}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: AppThemeData.medium),
                  ),
                  Text(
                    selectedVehicleType == null ? amountShow(amount: "0.0") : amountShow(amount: getAmount(selectedVehicleType!).toString()),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: AppThemeData.medium),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double getAmount(VehicleType vehicleType) {
    double totalAmount = 0.0;
    if (distance <= vehicleType.minimum_delivery_charges_within_km!) {
      totalAmount = double.parse(vehicleType.minimum_delivery_charges.toString());
    } else {
      totalAmount = vehicleType.delivery_charges_per_km! * distance;
    }
    return totalAmount;
  }

  getDriverDetails() async {
    if (_cabOrderModel != null) {
      print("------->${_cabOrderModel!.driverID.toString()}");
      if (statusOfOrder == ORDER_STATUS_DRIVER_ACCEPTED) {
        await FireStoreUtils.sendRideBookEmail(orderModel: _cabOrderModel);
      }
      if (statusOfOrder == ORDER_STATUS_DRIVER_ACCEPTED || statusOfOrder == ORDER_STATUS_SHIPPED || statusOfOrder == ORDER_STATUS_IN_TRANSIT) {
        driverStream = FireStoreUtils().getDriver(_cabOrderModel!.driverID.toString());
        driverStream.listen((event) {
          setState(() {
            _driverModel = event;
          });
          getDirections();
        });

        if (selectedMapType == "osm") {
          await getDurationOsmDistance(departureLatLong!, destinationLatLong!).then((value) {
            if (value != {} && value.isNotEmpty) {
              int hours = value['routes'].first['duration'] ~/ 3600;
              int minutes = ((value['routes'].first['duration'] % 3600) / 60).round();
              setState(() {
                distance = value['routes'].first['distance'] / 1000;
                duration = '$hours hours $minutes minutes';
                statusOfOrder = "vehicleType";
              });
            }
          });
        } else {
          await getDurationDistance(LatLng(_cabOrderModel!.sourceLocation.latitude, _cabOrderModel!.sourceLocation.longitude),
                  LatLng(_cabOrderModel!.destinationLocation.latitude, _cabOrderModel!.destinationLocation.longitude))
              .then((durationValue) async {
            print("----->${durationValue.toString()}");
            if (durationValue != null) {
              setState(() {
                distance = durationValue['rows'].first['elements'].first['distance']['value'] / 1000.00;
                duration = durationValue['rows'].first['elements'].first['duration']['text'];
              });
            }
          });
        }
      }
    }
  }

  driverDialog(CabOrderModel? cabOrderModel) {
    return Container(
      decoration: BoxDecoration(
        color: AppThemeData.primary300,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: Image.asset(
                        "assets/images/car_icon.png",
                      )),
                ),
                Text(
                  "You will arrive at you destination in ".tr(),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                Text(
                  duration,
                  style: TextStyle(color: Colors.grey.shade800, fontSize: 15),
                ),
              ],
            ),
          ),
          _driverModel == null
              ? const CircularProgressIndicator()
              : Container(
                  decoration: BoxDecoration(
                      color: isDarkMode(context) ? const Color(DarkContainerColor) : Colors.white,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(26), topRight: Radius.circular(26))),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("${cabOrderModel!.driver!.carNumber} \n${cabOrderModel.driver!.carMakes} ${cabOrderModel.driver!.carName}",
                                      style: const TextStyle(fontSize: 18, fontFamily: AppThemeData.medium)),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 15),
                                    child: Text(
                                      "${cabOrderModel.driver!.firstName} ${cabOrderModel.driver!.lastName}",
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 20,
                                        color: AppThemeData.primary300,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(_driverModel!.reviewsCount != 0 ? (_driverModel!.reviewsSum / _driverModel!.reviewsCount).toStringAsFixed(1) : 0.toString(),
                                          style: const TextStyle(
                                            letterSpacing: 0.5,
                                            color: Color(0xff000000),
                                          )),
                                      const SizedBox(width: 3),
                                      Text('(${cabOrderModel.driver!.reviewsCount.toStringAsFixed(1)})',
                                          style: const TextStyle(
                                            letterSpacing: 0.5,
                                            color: Color(0xff666666),
                                          )),
                                      const SizedBox(width: 5),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: CachedNetworkImage(
                                    imageUrl: cabOrderModel.driver!.profilePictureURL,
                                    height: 80.0,
                                    width: 80.0,
                                    placeholder: (context, url) => Center(
                                        child: CircularProgressIndicator.adaptive(
                                      valueColor: AlwaysStoppedAnimation(AppThemeData.primary300),
                                    )),
                                    errorWidget: (context, url, error) => ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          placeholderImage,
                                          fit: BoxFit.cover,
                                        )),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                cabOrderModel.otpCode!.isEmpty
                                    ? Container()
                                    : DottedBorder(
                                        borderType: BorderType.RRect,
                                        radius: const Radius.circular(2),
                                        color: const Color(COUPON_DASH_COLOR),
                                        strokeWidth: 2,
                                        dashPattern: const [5],
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                          child: Text(
                                            cabOrderModel.otpCode.toString(),
                                            style: const TextStyle(color: Colors.black),
                                          ),
                                        ))
                              ],
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: MaterialButton(
                                  onPressed: () async {
                                    if (cabOrderModel.driver!.phoneNumber.isNotEmpty) {
                                      UrlLauncher.launch("tel://${cabOrderModel.driver!.phoneNumber}");
                                    } else {
                                      SnackBar snack = SnackBar(
                                        content: Text(
                                          "Driver Phone number is not available".tr(),
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: Colors.black,
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(snack);
                                    }
                                  },
                                  height: 42,
                                  elevation: 0.5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  color: AppThemeData.primary300,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.wifi_calling_3, color: Colors.white),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      const Text(
                                        "Call",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: AppThemeData.medium),
                                      ).tr(),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Expanded(
                                child: MaterialButton(
                                  onPressed: () async {
                                    await showProgress("Please wait...".tr(), false);

                                    User? customer = await FireStoreUtils.getCurrentUser(cabOrderModel.authorID);
                                    User? driver = await FireStoreUtils.getCurrentUser(cabOrderModel.driverID.toString());

                                    await hideProgress();
                                    push(
                                        context,
                                        ChatScreens(
                                          type: "cab_parcel_chat",
                                          customerName: customer!.firstName + " " + customer.lastName,
                                          restaurantName: driver!.firstName + " " + driver.lastName,
                                          orderId: cabOrderModel.id,
                                          restaurantId: driver.userID,
                                          customerId: customer.userID,
                                          customerProfileImage: customer.profilePictureURL,
                                          restaurantProfileImage: driver.profilePictureURL,
                                          token: driver.fcmToken,
                                          chatType: 'Driver',
                                        ));
                                  },
                                  height: 42,
                                  elevation: 0.5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  color: Colors.red.withOpacity(0.50),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.message_sharp,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        "Message".tr(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: AppThemeData.medium),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        MaterialButton(
                          onPressed: () async {
                            await showProgress("Please wait...".tr(), false);

                            LocationData location = await currentLocation.getLocation();

                            await FireStoreUtils().getSOS(_cabOrderModel!.id).then((value) async {
                              if (value == false) {
                                await FireStoreUtils().setSos(_cabOrderModel!.id, UserLocation(latitude: location.latitude!, longitude: location.longitude!)).then((value) {
                                  hideProgress();
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Builder(builder: (context) {
                                      return const Text(
                                        "Your SOS request has been submitted to admin ",
                                      ).tr();
                                    }),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 3),
                                  ));
                                });
                              } else {
                                hideProgress();
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Builder(builder: (context) {
                                    return const Text(
                                      "Your SOS request is already submitted",
                                    ).tr();
                                  }),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 3),
                                ));
                              }
                            });
                          },
                          height: 42,
                          elevation: 0.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          color: Colors.red.withOpacity(0.50),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.call,
                                color: Colors.white,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              const Text(
                                "SOS",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: AppThemeData.medium),
                              ).tr(),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  setDepartureMarker(LatLng departure) {
    if (selectedMapType == "osm") {
      if (osmMarkers.containsKey('Departure')) {
        mapOsmController.removeMarker(osmMarkers['Departure']!);
      }

      mapOsmController
          .addMarker(osmflutter.GeoPoint(latitude: departure.latitude, longitude: departure.longitude),
              markerIcon: osmflutter.MarkerIcon(iconWidget: departureOsmIcon), angle: pi / 3, iconAnchor: osmflutter.IconAnchor(anchor: osmflutter.Anchor.top))
          .then((v) {
        osmMarkers['Departure'] = osmflutter.GeoPoint(latitude: departure.latitude, longitude: departure.longitude);
      });
      departureLatLong = departure;

      mapOsmController.moveTo(
        osmflutter.GeoPoint(latitude: departure.latitude, longitude: departure.longitude),
        animate: true,
      );

      if (departureLatLong != null && destinationLatLong != null) {
        setState(() {
          statusOfOrder = "conformation";
        });
        getDirections();
      }
    } else {
      setState(() {
        _markers.remove("Departure");
        _markers['Departure'] = Marker(
          markerId: const MarkerId('Departure'),
          infoWindow: const InfoWindow(title: "Departure"),
          position: departure,
          icon: departureIcon!,
        );
        departureLatLong = departure;
        _controller!.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(departure.latitude, departure.longitude), zoom: 14)));

        // _controller?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(departure.latitude, departure.longitude), zoom: 18)));
        if (departureLatLong != null && destinationLatLong != null) {
          setState(() {
            statusOfOrder = "conformation";
          });
          getDirections();
        }
      });
    }
  }

  setDestinationMarker(LatLng destination) {
    if (selectedMapType == "osm") {
      if (osmMarkers.containsKey('Destination')) {
        mapOsmController.removeMarker(osmMarkers['Destination']!);
      }

      mapOsmController
          .addMarker(osmflutter.GeoPoint(latitude: destination.latitude, longitude: destination.longitude),
              markerIcon: osmflutter.MarkerIcon(iconWidget: destinationOsmIcon), angle: pi / 3, iconAnchor: osmflutter.IconAnchor(anchor: osmflutter.Anchor.top))
          .then((v) {
        osmMarkers['Destination'] = osmflutter.GeoPoint(latitude: destination.latitude, longitude: destination.longitude);
      });
      destinationLatLong = destination;
      mapOsmController.moveTo(
        osmflutter.GeoPoint(latitude: destination.latitude, longitude: destination.longitude),
        animate: true,
      );
      if (departureLatLong != null && destinationLatLong != null) {
        setState(() {
          statusOfOrder = "conformation";
        });
        getDirections();
      }
    } else {
      setState(() {
        _markers['Destination'] = Marker(
          markerId: const MarkerId('Destination'),
          infoWindow: const InfoWindow(title: "Destination"),
          position: destination,
          icon: destinationIcon!,
        );
        destinationLatLong = destination;

        if (departureLatLong != null && destinationLatLong != null) {
          setState(() {
            statusOfOrder = "conformation";
          });
          getDirections();
        }
      });
    }
  }

  waitingDialog() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/loader.gif',
                  width: 250,
                ),
                const Text(
                  "Waiting for driver",
                  style: TextStyle(color: Colors.black),
                ).tr(),
                const SizedBox(
                  height: 20,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.90,
                  child: MaterialButton(
                    onPressed: () async {
                      _cabOrderModel!.status = ORDER_STATUS_REJECTED;
                      FireStoreUtils.updateCabOrder(_cabOrderModel!);
                      setState(() {
                        statusOfOrder = "";
                        polyLines.clear();
                        _markers.clear();
                        destinationController.clear();
                        departureController.clear();
                        departureLatLong = null;
                        destinationLatLong = null;
                        MyAppState.currentUser!.inProgressOrderID = null;
                        FireStoreUtils.updateCurrentUser(MyAppState.currentUser!);
                      });
                    },
                    height: 42,
                    elevation: 0.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    color: AppThemeData.primary300,
                    child: const Text(
                      "Cancel Ride",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: AppThemeData.medium),
                    ).tr(),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  completeRide() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: MaterialButton(
              onPressed: () async {
                final result = await Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => CabPaymentScreen(
                          cabOrderModel: _cabOrderModel,
                          taxModel: taxList,
                        )));
                if (result != null) {
                  statusOfOrder = "";
                  polyLines.clear();
                  _markers.clear();
                  departureController.clear();
                  destinationController.clear();
                  departureLatLong = null;
                  destinationLatLong = null;
                  MyAppState.currentUser!.inProgressOrderID = null;
                  FireStoreUtils.updateCurrentUser(MyAppState.currentUser!);
                  setState(() {});
                }
              },
              height: 45,
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              color: AppThemeData.primary300,
              child: Text(
                "Complete Your Payment".tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: AppThemeData.medium),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTextField({required title, required TextEditingController textController}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: TextField(
        controller: textController,
        style: TextStyle(color: isDarkMode(context) ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: title,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabled: false,
        ),
      ),
    );
  }

  getDirections() async {
    if (selectedMapType == "osm") {
      if (statusOfOrder == ORDER_STATUS_DRIVER_ACCEPTED) {
        osmflutter.GeoPoint sourceLocation = osmflutter.GeoPoint(
          latitude: _cabOrderModel!.sourceLocation.latitude,
          longitude: _cabOrderModel!.sourceLocation.longitude,
        );
        osmflutter.GeoPoint destinationLocation = osmflutter.GeoPoint(
          latitude: _cabOrderModel!.destinationLocation.latitude,
          longitude: _cabOrderModel!.destinationLocation.longitude,
        );
        await mapOsmController.removeLastRoad();
        if (osmMarkers.containsKey('Driver')) {
          mapOsmController.removeMarker(osmMarkers['Driver']!);
        }

        await mapOsmController
            .addMarker(osmflutter.GeoPoint(latitude: _driverModel!.location.latitude, longitude: _driverModel!.location.longitude),
                markerIcon: osmflutter.MarkerIcon(iconWidget: driverOsmIcon),
                angle: pi / 3,
                iconAnchor: osmflutter.IconAnchor(
                  anchor: osmflutter.Anchor.top,
                ))
            .then((v) {
          osmMarkers['Driver'] = osmflutter.GeoPoint(latitude: _driverModel!.location.latitude, longitude: _driverModel!.location.longitude);
        });
        setOsmMarker(departure: sourceLocation, destination: destinationLocation);
        mapOsmController.drawRoad(
          sourceLocation,
          destinationLocation,
          roadType: osmflutter.RoadType.car,
          roadOption: osmflutter.RoadOption(
            roadWidth: Platform.isIOS ? 50 : 15,
            roadColor: Colors.blue,
            roadBorderWidth: Platform.isIOS ? 15 : 15, // Set the road border width (outline)
            roadBorderColor: Colors.black, // Border color
            zoomInto: true,
          ),
        );
        mapOsmController.moveTo(
          osmflutter.GeoPoint(
            latitude: _cabOrderModel!.sourceLocation.latitude,
            longitude: _cabOrderModel!.sourceLocation.longitude,
          ),
          animate: true,
        );
      } else if (statusOfOrder == ORDER_STATUS_SHIPPED) {
        osmflutter.GeoPoint sourceLocation = osmflutter.GeoPoint(
          latitude: _driverModel!.location.latitude,
          longitude: _driverModel!.location.longitude,
        );
        osmflutter.GeoPoint destinationLocation = osmflutter.GeoPoint(
          latitude: _cabOrderModel!.sourceLocation.latitude,
          longitude: _cabOrderModel!.sourceLocation.longitude,
        );
        await mapOsmController.removeLastRoad();
        if (osmMarkers.containsKey('Driver')) {
          mapOsmController.removeMarker(osmMarkers['Driver']!);
        }
        await mapOsmController
            .addMarker(osmflutter.GeoPoint(latitude: _driverModel!.location.latitude, longitude: _driverModel!.location.longitude),
                markerIcon: osmflutter.MarkerIcon(iconWidget: driverOsmIcon),
                angle: pi / 3,
                iconAnchor: osmflutter.IconAnchor(
                  anchor: osmflutter.Anchor.top,
                ))
            .then((v) {
          osmMarkers['Driver'] = osmflutter.GeoPoint(latitude: _driverModel!.location.latitude, longitude: _driverModel!.location.longitude);
        });

        setOsmMarker(departure: sourceLocation, destination: destinationLocation);
        mapOsmController.drawRoad(
          sourceLocation,
          destinationLocation,
          roadType: osmflutter.RoadType.car,
          roadOption: osmflutter.RoadOption(
            roadWidth: Platform.isIOS ? 50 : 15,
            roadColor: Colors.blue,
            roadBorderWidth: Platform.isIOS ? 15 : 15, // Set the road border width (outline)
            roadBorderColor: Colors.black, // Border color
            zoomInto: true,
          ),
        );
        mapOsmController.moveTo(
          osmflutter.GeoPoint(latitude: _driverModel!.location.latitude, longitude: _driverModel!.location.longitude),
          animate: true,
        );
      } else if (statusOfOrder == ORDER_STATUS_IN_TRANSIT || statusOfOrder == ORDER_REACHED_DESTINATION) {
        osmflutter.GeoPoint sourceLocation = osmflutter.GeoPoint(
          latitude: _driverModel!.location.latitude,
          longitude: _driverModel!.location.longitude,
        );
        osmflutter.GeoPoint destinationLocation = osmflutter.GeoPoint(
          latitude: _cabOrderModel!.destinationLocation.latitude,
          longitude: _cabOrderModel!.destinationLocation.longitude,
        );
        await mapOsmController.removeLastRoad();
        if (osmMarkers.containsKey('Driver')) {
          mapOsmController.removeMarker(osmMarkers['Driver']!);
        }

        await mapOsmController
            .addMarker(osmflutter.GeoPoint(latitude: _driverModel!.location.latitude, longitude: _driverModel!.location.longitude),
                markerIcon: osmflutter.MarkerIcon(iconWidget: driverOsmIcon),
                angle: pi / 3,
                iconAnchor: osmflutter.IconAnchor(
                  anchor: osmflutter.Anchor.top,
                ))
            .then((v) {
          osmMarkers['Driver'] = osmflutter.GeoPoint(latitude: _driverModel!.location.latitude, longitude: _driverModel!.location.longitude);
        });
        setOsmMarker(departure: sourceLocation, destination: destinationLocation);
        mapOsmController.drawRoad(
          sourceLocation,
          destinationLocation,
          roadType: osmflutter.RoadType.car,
          roadOption: osmflutter.RoadOption(
            roadWidth: Platform.isIOS ? 50 : 15,
            roadColor: Colors.blue,
            roadBorderWidth: Platform.isIOS ? 15 : 15, // Set the road border width (outline)
            roadBorderColor: Colors.black, // Border color
            zoomInto: true,
          ),
        );
        mapOsmController.moveTo(
          osmflutter.GeoPoint(latitude: _driverModel!.location.latitude, longitude: _driverModel!.location.longitude),
          animate: true,
        );
      } else if (statusOfOrder == "conformation" || statusOfOrder == "vehicleType") {
        osmflutter.GeoPoint sourceLocation = osmflutter.GeoPoint(
          latitude: departureLatLong!.latitude,
          longitude: departureLatLong!.longitude,
        );
        osmflutter.GeoPoint destinationLocation = osmflutter.GeoPoint(
          latitude: destinationLatLong!.latitude,
          longitude: destinationLatLong!.longitude,
        );
        await mapOsmController.removeLastRoad();
        setOsmMarker(departure: sourceLocation, destination: destinationLocation);
        mapOsmController.drawRoad(
          sourceLocation,
          destinationLocation,
          roadType: osmflutter.RoadType.car,
          roadOption: osmflutter.RoadOption(
            roadWidth: Platform.isIOS ? 50 : 15,
            roadColor: Colors.blue,
            roadBorderWidth: Platform.isIOS ? 15 : 15, // Set the road border width (outline)
            roadBorderColor: Colors.black, // Border color
            zoomInto: true,
          ),
        );
        mapOsmController.moveTo(
          osmflutter.GeoPoint(latitude: departureLatLong!.latitude, longitude: departureLatLong!.longitude),
          animate: true,
        );
      }
    } else {
      if (statusOfOrder == ORDER_STATUS_DRIVER_ACCEPTED) {
        List<LatLng> polylineCoordinates = [];

        PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
          googleApiKey: GOOGLE_API_KEY,
          request: PolylineRequest(
              origin: PointLatLng(_cabOrderModel!.sourceLocation.latitude, _cabOrderModel!.sourceLocation.longitude),
              destination: PointLatLng(_cabOrderModel!.destinationLocation.latitude, _cabOrderModel!.destinationLocation.longitude),
              mode: TravelMode.driving),
        );

        if (result.points.isNotEmpty) {
          for (var point in result.points) {
            polylineCoordinates.add(LatLng(point.latitude, point.longitude));
          }
        }
        _markers.remove("Departure");
        _markers['Departure'] = Marker(
          markerId: const MarkerId('Departure'),
          infoWindow: const InfoWindow(title: "Departure"),
          position: LatLng(_cabOrderModel!.sourceLocation.latitude, _cabOrderModel!.sourceLocation.longitude),
          icon: departureIcon!,
        );
        _markers.remove("Destination");
        _markers['Destination'] = Marker(
          markerId: const MarkerId('Destination'),
          infoWindow: const InfoWindow(title: "Destination"),
          position: LatLng(_cabOrderModel!.destinationLocation.latitude, _cabOrderModel!.destinationLocation.longitude),
          icon: destinationIcon!,
        );
        addPolyLine(polylineCoordinates);
      } else if (statusOfOrder == ORDER_STATUS_SHIPPED) {
        List<LatLng> polylineCoordinates = [];

        PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
          googleApiKey: GOOGLE_API_KEY,
          request: PolylineRequest(
              origin: PointLatLng(_driverModel!.location.latitude, _driverModel!.location.longitude),
              destination: PointLatLng(_cabOrderModel!.sourceLocation.latitude, _cabOrderModel!.sourceLocation.longitude),
              mode: TravelMode.driving),
        );

        if (result.points.isNotEmpty) {
          for (var point in result.points) {
            polylineCoordinates.add(LatLng(point.latitude, point.longitude));
          }
        }

        _markers.remove("Driver");
        _markers['Driver'] = Marker(
            markerId: const MarkerId('Driver'),
            infoWindow: const InfoWindow(title: "Driver"),
            position: LatLng(_driverModel!.location.latitude, _driverModel!.location.longitude),
            icon: taxiIcon!,
            rotation: double.parse(_driverModel!.rotation.toString()));

        _markers.remove("Departure");
        _markers['Departure'] = Marker(
          markerId: const MarkerId('Departure'),
          infoWindow: const InfoWindow(title: "Departure"),
          position: LatLng(_cabOrderModel!.sourceLocation.latitude, _cabOrderModel!.sourceLocation.longitude),
          icon: departureIcon!,
        );

        _markers.remove("Destination");
        _markers['Destination'] = Marker(
          markerId: const MarkerId('Destination'),
          infoWindow: const InfoWindow(title: "Destination"),
          position: LatLng(_cabOrderModel!.destinationLocation.latitude, _cabOrderModel!.destinationLocation.longitude),
          icon: destinationIcon!,
        );

        addPolyLine(polylineCoordinates);
      } else if (statusOfOrder == ORDER_STATUS_IN_TRANSIT || statusOfOrder == ORDER_REACHED_DESTINATION) {
        List<LatLng> polylineCoordinates = [];

        PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
          googleApiKey: GOOGLE_API_KEY,
          request: PolylineRequest(
              origin: PointLatLng(_driverModel!.location.latitude, _driverModel!.location.longitude),
              destination: PointLatLng(_cabOrderModel!.destinationLocation.latitude, _cabOrderModel!.destinationLocation.longitude),
              mode: TravelMode.driving),
        );

        print("----?${result.points}");
        if (result.points.isNotEmpty) {
          for (var point in result.points) {
            polylineCoordinates.add(LatLng(point.latitude, point.longitude));
          }
        }
        setState(() {
          _markers.remove("Driver");
          _markers['Driver'] = Marker(
              markerId: const MarkerId('Driver'),
              infoWindow: const InfoWindow(title: "Driver"),
              position: LatLng(_driverModel!.location.latitude, _driverModel!.location.longitude),
              icon: taxiIcon!,
              rotation: double.parse(_driverModel!.rotation.toString()));
        });

        _markers.remove("Departure");
        _markers['Departure'] = Marker(
          markerId: const MarkerId('Departure'),
          infoWindow: const InfoWindow(title: "Departure"),
          position: LatLng(_cabOrderModel!.sourceLocation.latitude, _cabOrderModel!.sourceLocation.longitude),
          icon: departureIcon!,
        );
        _markers.remove("Destination");
        _markers['Destination'] = Marker(
          markerId: const MarkerId('Destination'),
          infoWindow: const InfoWindow(title: "Destination"),
          position: LatLng(_cabOrderModel!.destinationLocation.latitude, _cabOrderModel!.destinationLocation.longitude),
          icon: destinationIcon!,
        );
        addPolyLine(polylineCoordinates);
      } else if (statusOfOrder == "conformation" || statusOfOrder == "vehicleType") {
        List<LatLng> polylineCoordinates = [];
        PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
          googleApiKey: GOOGLE_API_KEY,
          request: PolylineRequest(
              origin: PointLatLng(departureLatLong!.latitude, departureLatLong!.longitude),
              destination: PointLatLng(destinationLatLong!.latitude, destinationLatLong!.longitude),
              mode: TravelMode.driving),
        );

        if (result.points.isNotEmpty) {
          for (var point in result.points) {
            polylineCoordinates.add(LatLng(point.latitude, point.longitude));
          }
        }
        addPolyLine(polylineCoordinates);
      }
    }
  }

  setOsmMarker({required osmflutter.GeoPoint departure, required osmflutter.GeoPoint destination}) async {
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (osmMarkers.containsKey('Departure')) {
          mapOsmController.removeMarker(osmMarkers['Departure']!);
        }
        await mapOsmController
            .addMarker(departure,
                markerIcon: osmflutter.MarkerIcon(iconWidget: departureOsmIcon),
                angle: pi / 3,
                iconAnchor: osmflutter.IconAnchor(
                  anchor: osmflutter.Anchor.top,
                ))
            .then((v) {
          osmMarkers['Departure'] = departure;
        });

        if (osmMarkers.containsKey('Destination')) {
          mapOsmController.removeMarker(osmMarkers['Destination']!);
        }

        await mapOsmController
            .addMarker(destination,
                markerIcon: osmflutter.MarkerIcon(iconWidget: destinationOsmIcon),
                angle: pi / 3,
                iconAnchor: osmflutter.IconAnchor(
                  anchor: osmflutter.Anchor.top,
                ))
            .then((v) {
          osmMarkers['Destination'] = destination;
        });
      });
    } catch (e) {
      print("=====>${e}");
      throw Exception(e);
    }
  }

  addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: AppThemeData.primary300,
      points: polylineCoordinates,
      width: 4,
      geodesic: true,
    );
    polyLines[id] = polyline;
    updateCameraLocation(polylineCoordinates.first, polylineCoordinates.last, _controller);
    setState(() {});
  }

  Future<void> updateCameraLocation(
    LatLng source,
    LatLng destination,
    GoogleMapController? mapController,
  ) async {
    if (mapController == null) return;

    LatLngBounds bounds;

    if (source.latitude > destination.latitude && source.longitude > destination.longitude) {
      bounds = LatLngBounds(southwest: destination, northeast: source);
    } else if (source.longitude > destination.longitude) {
      bounds = LatLngBounds(southwest: LatLng(source.latitude, destination.longitude), northeast: LatLng(destination.latitude, source.longitude));
    } else if (source.latitude > destination.latitude) {
      bounds = LatLngBounds(southwest: LatLng(destination.latitude, source.longitude), northeast: LatLng(source.latitude, destination.longitude));
    } else {
      bounds = LatLngBounds(southwest: source, northeast: destination);
    }

    CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 100);

    return checkCameraLocation(cameraUpdate, mapController);
  }

  Future<void> checkCameraLocation(CameraUpdate cameraUpdate, GoogleMapController mapController) async {
    mapController.animateCamera(cameraUpdate);
    LatLngBounds l1 = await mapController.getVisibleRegion();
    LatLngBounds l2 = await mapController.getVisibleRegion();

    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90) {
      return checkCameraLocation(cameraUpdate, mapController);
    }
  }

  Future<dynamic> getDurationDistance(LatLng departureLatLong, LatLng destinationLatLong) async {
    double originLat, originLong, destLat, destLong;
    originLat = departureLatLong.latitude;
    originLong = departureLatLong.longitude;
    destLat = destinationLatLong.latitude;
    destLong = destinationLatLong.longitude;

    String url = 'https://maps.googleapis.com/maps/api/distancematrix/json';
    http.Response restaurantToCustomerTime = await http.get(Uri.parse('$url?units=metric&origins=$originLat,'
        '$originLong&destinations=$destLat,$destLong&key=$GOOGLE_API_KEY'));

    var decodedResponse = jsonDecode(restaurantToCustomerTime.body);

    print(decodedResponse);
    if (decodedResponse['status'] == 'OK' && decodedResponse['rows'].first['elements'].first['status'] == 'OK') {
      return decodedResponse;
    }
    return null;
  }

  static Future<Map<String, dynamic>> getDurationOsmDistance(LatLng departureLatLong, LatLng destinationLatLong) async {
    String url = 'http://router.project-osrm.org/route/v1/driving';
    String coordinates = '${departureLatLong.longitude},${departureLatLong.latitude};${destinationLatLong.longitude},${destinationLatLong.latitude}';

    http.Response response = await http.get(Uri.parse('$url/$coordinates?overview=false&steps=false'));

    return jsonDecode(response.body);
  }
}
