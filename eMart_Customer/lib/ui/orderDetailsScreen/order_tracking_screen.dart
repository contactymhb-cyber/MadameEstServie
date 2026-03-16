import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:emartconsumer/constants.dart';
import 'package:emartconsumer/model/OrderModel.dart';
import 'package:emartconsumer/model/User.dart';
import 'package:emartconsumer/services/FirebaseHelper.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/theme/app_them_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osmflutter;

class OrderTrackingScreen extends StatefulWidget {
  final OrderModel orderModel;

  const OrderTrackingScreen({Key? key, required this.orderModel})
      : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<OrderTrackingScreen> {
  final fireStoreUtils = FireStoreUtils();

  GoogleMapController? _mapController;

  BitmapDescriptor? departureIcon;
  BitmapDescriptor? destinationIcon;
  BitmapDescriptor? taxiIcon;

  Map<PolylineId, Polyline> polyLines = {};
  PolylinePoints polylinePoints = PolylinePoints();
  final Map<String, Marker> _markers = {};

  Image? departureOsmIcon; //OSM
  Image? destinationOsmIcon; //OSM
  Image? driverOsmIcon;

  setIcons() async {
    if (selectedMapType == 'google') {
      BitmapDescriptor.fromAssetImage(
              const ImageConfiguration(size: Size(10, 10)),
              "assets/images/location_black3x.png")
          .then((value) {
        departureIcon = value;
      });

      BitmapDescriptor.fromAssetImage(
              const ImageConfiguration(size: Size(10, 10)),
              "assets/images/location_orange3x.png")
          .then((value) {
        destinationIcon = value;
      });

      BitmapDescriptor.fromAssetImage(
              const ImageConfiguration(size: Size(10, 10)),
              "assets/images/food_delivery.png")
          .then((value) {
        taxiIcon = value;
      });
    } else {
      departureOsmIcon =
          Image.asset("assets/images/pickup.png", width: 40, height: 40); //OSM
      destinationOsmIcon =
          Image.asset("assets/images/dropoff.png", width: 40, height: 40); //OSM
      driverOsmIcon = Image.asset("assets/images/food_delivery.png",
          width: 40, height: 40); //OSM
    }
  }

  late osmflutter.MapController mapOsmController;

  @override
  void initState() {
    if (selectedMapType == 'osm') {
      setState(() {
        mapOsmController = osmflutter.MapController(
            initPosition:
                osmflutter.GeoPoint(latitude: 20.9153, longitude: -100.7439),
            useExternalTracking: false); //OSM
      });
    }
    getCurrentOrder();
    getDriver();

    setIcons();
    super.initState();
  }

  late Stream<OrderModel?> ordersFuture;
  OrderModel? currentOrder;

  late Stream<User> driverStream;
  User? _driverModel = User();

  getCurrentOrder() async {
    ordersFuture =
        FireStoreUtils().getOrderByID(widget.orderModel.id.toString());
    ordersFuture.listen((event) {
      print("------->${event!.status}");

      setState(() {
        currentOrder = event;
        if (selectedMapType == "osm") {
          getOSMPolyline();
        } else {
          getDirections();
        }
      });
    });
  }

  getDriver() {
    driverStream =
        FireStoreUtils().getDriver(widget.orderModel.driverID.toString());
    driverStream.listen((event) {
      _driverModel = event;
      if (selectedMapType == "osm") {
        getOSMPolyline();
      } else {
        getDirections();
      }
    });
  }

  @override
  void dispose() {
    _mapController!.dispose();
    FireStoreUtils().driverStreamSub.cancel();
    FireStoreUtils().ordersStreamController.close();
    FireStoreUtils().ordersStreamSub.cancel();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    if (isDarkMode(context))
      _mapController?.setMapStyle('[{"featureType": "all","'
          'elementType": "'
          'geo'
          'met'
          'ry","stylers": [{"color": "#242f3e"}]},{"featureType": "all","elementType": "labels.text.stroke","stylers": [{"lightness": -80}]},{"featureType": "administrative","elementType": "labels.text.fill","stylers": [{"color": "#746855"}]},{"featureType": "administrative.locality","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "poi","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "poi.park","elementType": "geometry","stylers": [{"color": "#263c3f"}]},{"featureType": "poi.park","elementType": "labels.text.fill","stylers": [{"color": "#6b9a76"}]},{"featureType": "road","elementType": "geometry.fill","stylers": [{"color": "#2b3544"}]},{"featureType": "road","elementType": "labels.text.fill","stylers": [{"color": "#9ca5b3"}]},{"featureType": "road.arterial","elementType": "geometry.fill","stylers": [{"color": "#38414e"}]},{"featureType": "road.arterial","elementType": "geometry.stroke","stylers": [{"color": "#212a37"}]},{"featureType": "road.highway","elementType": "geometry.fill","stylers": [{"color": "#746855"}]},{"featureType": "road.highway","elementType": "geometry.stroke","stylers": [{"color": "#1f2835"}]},{"featureType": "road.highway","elementType": "labels.text.fill","stylers": [{"color": "#f3d19c"}]},{"featureType": "road.local","elementType": "geometry.fill","stylers": [{"color": "#38414e"}]},{"featureType": "road.local","elementType": "geometry.stroke","stylers": [{"color": "#212a37"}]},{"featureType": "transit","elementType": "geometry","stylers": [{"color": "#2f3948"}]},{"featureType": "transit.station","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "water","elementType": "geometry","stylers": [{"color": "#17263c"}]},{"featureType": "water","elementType": "labels.text.fill","stylers": [{"color": "#515c6d"}]},{"featureType": "water","elementType": "labels.text.stroke","stylers": [{"lightness": -20}]}]');
  }

  bool isShow = false;

  @override
  Widget build(BuildContext context) {
    isDarkMode(context)
        ? _mapController?.setMapStyle('[{"featureType": "all","'
            'elementType": "'
            'geo'
            'met'
            'ry","stylers": [{"color": "#242f3e"}]},{"featureType": "all","elementType": "labels.text.stroke","stylers": [{"lightness": -80}]},{"featureType": "administrative","elementType": "labels.text.fill","stylers": [{"color": "#746855"}]},{"featureType": "administrative.locality","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "poi","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "poi.park","elementType": "geometry","stylers": [{"color": "#263c3f"}]},{"featureType": "poi.park","elementType": "labels.text.fill","stylers": [{"color": "#6b9a76"}]},{"featureType": "road","elementType": "geometry.fill","stylers": [{"color": "#2b3544"}]},{"featureType": "road","elementType": "labels.text.fill","stylers": [{"color": "#9ca5b3"}]},{"featureType": "road.arterial","elementType": "geometry.fill","stylers": [{"color": "#38414e"}]},{"featureType": "road.arterial","elementType": "geometry.stroke","stylers": [{"color": "#212a37"}]},{"featureType": "road.highway","elementType": "geometry.fill","stylers": [{"color": "#746855"}]},{"featureType": "road.highway","elementType": "geometry.stroke","stylers": [{"color": "#1f2835"}]},{"featureType": "road.highway","elementType": "labels.text.fill","stylers": [{"color": "#f3d19c"}]},{"featureType": "road.local","elementType": "geometry.fill","stylers": [{"color": "#38414e"}]},{"featureType": "road.local","elementType": "geometry.stroke","stylers": [{"color": "#212a37"}]},{"featureType": "transit","elementType": "geometry","stylers": [{"color": "#2f3948"}]},{"featureType": "transit.station","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "water","elementType": "geometry","stylers": [{"color": "#17263c"}]},{"featureType": "water","elementType": "labels.text.fill","stylers": [{"color": "#515c6d"}]},{"featureType": "water","elementType": "labels.text.stroke","stylers": [{"lightness": -20}]}]')
        : _mapController?.setMapStyle(null);

    return Scaffold(
      backgroundColor:
          isDarkMode(context) ? AppThemeData.surfaceDark : AppThemeData.surface,
      appBar: AppBar(title: Text("Track")),
      body: selectedMapType == 'osm'
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
                      enableTracking: false,
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
              onMapCreated: _onMapCreated,
              myLocationEnabled:
                  _driverModel!.inProgressOrderID != null ? false : true,
              myLocationButtonEnabled: true,
              mapType: MapType.terrain,
              zoomControlsEnabled: false,
              polylines: Set<Polyline>.of(polyLines.values),
              markers: _markers.values.toSet(),
              padding: EdgeInsets.only(
                top: 10.0,
              ),
              initialCameraPosition: CameraPosition(
                zoom: 15,
                target: LatLng(_driverModel!.location.latitude,
                    _driverModel!.location.longitude),
              ),
            ),
    );
  }

  getDirections() async {
    if (currentOrder != null) {
      if (currentOrder!.status == ORDER_STATUS_SHIPPED) {
        List<LatLng> polylineCoordinates = [];

        PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
          googleApiKey: GOOGLE_API_KEY,
          request: PolylineRequest(
              origin: PointLatLng(_driverModel!.location.latitude,
                  _driverModel!.location.longitude),
              destination: PointLatLng(
                  currentOrder!.address!.location!.latitude,
                  currentOrder!.address!.location!.longitude),
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
              position: LatLng(_driverModel!.location.latitude,
                  _driverModel!.location.longitude),
              icon: taxiIcon!,
              rotation: double.parse(_driverModel!.rotation.toString()));
        });

        _markers.remove("Destination");
        _markers['Destination'] = Marker(
          markerId: const MarkerId('Destination'),
          infoWindow: const InfoWindow(title: "Destination"),
          position: LatLng(
              currentOrder!.vendor.latitude, currentOrder!.vendor.longitude),
          icon: destinationIcon!,
        );
        addPolyLine(polylineCoordinates);
      } else if (currentOrder!.status == ORDER_STATUS_IN_TRANSIT) {
        List<LatLng> polylineCoordinates = [];

        PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
          googleApiKey: GOOGLE_API_KEY,
          request: PolylineRequest(
              origin: PointLatLng(_driverModel!.location.latitude,
                  _driverModel!.location.longitude),
              destination: PointLatLng(
                  currentOrder!.address!.location!.latitude,
                  currentOrder!.address!.location!.longitude),
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
            position: LatLng(_driverModel!.location.latitude,
                _driverModel!.location.longitude),
            rotation: double.parse(_driverModel!.rotation.toString()),
            icon: taxiIcon!,
          );
        });

        _markers.remove("Destination");
        _markers['Destination'] = Marker(
          markerId: const MarkerId('Destination'),
          infoWindow: const InfoWindow(title: "Destination"),
          position: LatLng(currentOrder!.address!.location!.latitude,
              currentOrder!.address!.location!.longitude),
          icon: destinationIcon!,
        );
        addPolyLine(polylineCoordinates);
      }
    } else {
      if (_driverModel!.orderRequestData != null) {
        List<LatLng> polylineCoordinates = [];

        PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
          googleApiKey: GOOGLE_API_KEY,
          request: PolylineRequest(
              origin: PointLatLng(_driverModel!.location.latitude,
                  _driverModel!.location.longitude),
              destination: PointLatLng(
                  _driverModel!.orderRequestData!.vendor.latitude,
                  _driverModel!.orderRequestData!.vendor.longitude),
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
              position: LatLng(_driverModel!.location.latitude,
                  _driverModel!.location.longitude),
              icon: taxiIcon!,
              rotation: double.parse(_driverModel!.rotation.toString()));
        });

        _markers.remove("Destination");
        _markers['Destination'] = Marker(
            markerId: const MarkerId('Destination'),
            infoWindow: const InfoWindow(title: "Destination"),
            position: LatLng(_driverModel!.orderRequestData!.vendor.latitude,
                _driverModel!.orderRequestData!.vendor.longitude),
            icon: destinationIcon!);
        addPolyLine(polylineCoordinates);
      }
    }
  }

  //OSM
  osmflutter.RoadInfo roadInfo = osmflutter.RoadInfo();
  Map<String, osmflutter.GeoPoint> osmMarkers = <String, osmflutter.GeoPoint>{};

  void getOSMPolyline() async {
    try {
      if (currentOrder!.status != ORDER_STATUS_DRIVER_PENDING) {
        if (currentOrder!.status == ORDER_STATUS_SHIPPED) {
          osmflutter.GeoPoint sourceLocation = osmflutter.GeoPoint(
              latitude: _driverModel?.location.latitude ?? 0.01,
              longitude: _driverModel?.location.longitude ?? 0.01);
          osmflutter.GeoPoint destinationLocation = osmflutter.GeoPoint(
              latitude: currentOrder!.vendor.latitude,
              longitude: currentOrder!.vendor.longitude);
          await mapOsmController.removeLastRoad();
          setOsmMarker(
              isDriverLocationIcon: true,
              departure: sourceLocation,
              destination: destinationLocation);
        } else if (currentOrder!.status == ORDER_STATUS_IN_TRANSIT) {
          if (currentOrder != null) {
            osmflutter.GeoPoint sourceLocation = osmflutter.GeoPoint(
                latitude: _driverModel?.location.latitude ?? 0.01,
                longitude: _driverModel?.location.longitude ?? 0.01);

            osmflutter.GeoPoint destinationLocation = osmflutter.GeoPoint(
                latitude: currentOrder!.address!.location!.latitude,
                longitude: currentOrder!.address!.location!.longitude);
            await mapOsmController.removeLastRoad();
            setOsmMarker(
                isDriverLocationIcon: true,
                departure: sourceLocation,
                destination: destinationLocation);
          }
        } else {
          print("====>5");
          osmflutter.GeoPoint sourceLocation = osmflutter.GeoPoint(
              latitude: currentOrder?.author.location.latitude ?? 0.01,
              longitude: currentOrder?.author.location.longitude ?? 0.01);

          osmflutter.GeoPoint destinationLocation = osmflutter.GeoPoint(
              latitude: currentOrder!.vendor.latitude,
              longitude: currentOrder!.vendor.longitude);
          await mapOsmController.removeLastRoad();
          setOsmMarker(
              isDriverLocationIcon: false,
              departure: sourceLocation,
              destination: destinationLocation);
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  setOsmMarker(
      {required osmflutter.GeoPoint departure,
      required osmflutter.GeoPoint destination,
      required bool isDriverLocationIcon}) async {
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if ((departure.latitude != 0.01 && departure.longitude != 0.01)) {
          if (osmMarkers.containsKey('Source')) {
            await mapOsmController.removeMarker(osmMarkers['Source']!);
          }
          await mapOsmController
              .addMarker(departure,
                  markerIcon: osmflutter.MarkerIcon(
                      iconWidget: isDriverLocationIcon
                          ? driverOsmIcon
                          : departureOsmIcon),
                  angle: pi / 3,
                  iconAnchor: osmflutter.IconAnchor(
                    anchor: osmflutter.Anchor.top,
                  ))
              .then((v) {
            osmMarkers['Source'] = departure;
          });

          if (osmMarkers.containsKey('Destination')) {
            await mapOsmController.removeMarker(osmMarkers['Destination']!);
          }
          await mapOsmController
              .addMarker(destination,
                  markerIcon:
                      osmflutter.MarkerIcon(iconWidget: destinationOsmIcon),
                  angle: pi / 3,
                  iconAnchor: osmflutter.IconAnchor(
                    anchor: osmflutter.Anchor.top,
                  ))
              .then((v) {
            osmMarkers['Destination'] = destination;
          });

          roadInfo = await mapOsmController.drawRoad(
            departure,
            destination,
            roadType: osmflutter.RoadType.car,
            roadOption: osmflutter.RoadOption(
              roadWidth: Platform.isIOS ? 50 : 15,
              roadColor: Colors.blue,
              roadBorderWidth: Platform.isIOS
                  ? 15
                  : 15, // Set the road border width (outline)
              roadBorderColor: Colors.blue, // Border color
              zoomInto: true,
            ),
          );
          mapOsmController.moveTo(
              osmflutter.GeoPoint(
                  latitude: departure.latitude, longitude: departure.longitude),
              animate: true);
        }
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
    updateCameraLocation(
        polylineCoordinates.first, polylineCoordinates.last, _mapController);
    setState(() {});
  }

  Future<void> updateCameraLocation(
    LatLng source,
    LatLng destination,
    GoogleMapController? mapController,
  ) async {
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: source,
          zoom: 20,
          bearing: double.parse(_driverModel!.rotation.toString()),
        ),
      ),
    );
  }
}
