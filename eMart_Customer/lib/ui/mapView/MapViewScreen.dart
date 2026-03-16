import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emartconsumer/constants.dart';
import 'package:emartconsumer/main.dart';
import 'package:emartconsumer/model/User.dart';
import 'package:emartconsumer/model/VendorModel.dart';
import 'package:emartconsumer/services/FirebaseHelper.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/theme/app_them_data.dart';
import 'package:emartconsumer/ui/vendorProductsScreen/NewVendorProductsScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osmMap;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapViewScreen extends StatefulWidget {
  final bool isShowAppBar;

  const MapViewScreen({super.key, required this.isShowAppBar});

  @override
  _MapViewScreenState createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  UserLocation? locationData;
  Stream<List<VendorModel>>? _mapFuture;
  Stream<List<VendorModel>>? vendorsFuture;
  late BitmapDescriptor mapMarker;
  late BitmapDescriptor mapMarkerSelect;
  int selected = 0;
  ScrollController contro = ScrollController();

  void setCustomMaker() async {
    if (selectedMapType == "osm") {
      departureOsmIcon = Image.asset("assets/images/map_selected3x.png", width: 30, height: 30); //OSM
    } else {
      mapMarker = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(),
        'assets/images/map_unselected2x.png',
      );
      mapMarkerSelect = await BitmapDescriptor.fromAssetImage(const ImageConfiguration(), 'assets/images/map_selected3x.png');
    }
  }

  GoogleMapController? _mapController;
  FireStoreUtils fireStoreUtils = FireStoreUtils();
  List<VendorModel> vendors = [];

  var id, inx, latpos, lotpos;
  final itemKey = GlobalKey();

  // var controller = IndexedScrollController();
  late osmMap.MapController mapOsmController;
  Map<String, osmMap.GeoPoint> osmMarkers = <String, osmMap.GeoPoint>{};
  Image? departureOsmIcon; //OSM

  @override
  void initState() {
    // _getLocation();
    super.initState();
    if (selectedMapType == 'osm') {
      mapOsmController = osmMap.MapController(initPosition: osmMap.GeoPoint(latitude: 20.9153, longitude: -100.7439), useExternalTracking: false); //OSM
    }
    setState(() {
      _mapFuture = fireStoreUtils.getVendors1().asBroadcastStream();
      vendorsFuture = _mapFuture;
    });
    
    setCustomMaker();
  }

  @override
  void dispose() {
    _mapController!.dispose();
    super.dispose();
  }

  scrollable() {
    if (contro.hasClients) {
      // id = id+1;
      //  var _width =MediaQuery.of(context).size.width*1;
      var size = 355 * id;

      contro.jumpTo(size.toDouble());
    } else {
      print('no');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isShowAppBar == true ? AppBar() : null,
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: StreamBuilder<List<VendorModel>>(
                stream: _mapFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container(
                      child: Center(
                        child: CircularProgressIndicator.adaptive(
                          valueColor: AlwaysStoppedAnimation(AppThemeData.primary300),
                        ),
                      ),
                    );
                  }
                  vendors = snapshot.data!;
                  return selectedMapType == "osm"
                      ? RepaintBoundary(
                          child: osmMap.OSMFlutter(
                              controller: mapOsmController,
                              osmOption: osmMap.OSMOption(
                                userTrackingOption: const osmMap.UserTrackingOption(
                                  enableTracking: true,
                                  unFollowUser: false,
                                ),
                                zoomOption: const osmMap.ZoomOption(
                                  initZoom: 14,
                                  minZoomLevel: 2,
                                  maxZoomLevel: 19,
                                  stepZoom: 1.0,
                                ),
                                roadConfiguration: const osmMap.RoadOption(
                                  roadColor: Colors.yellowAccent,
                                ),
                              ),
                              onMapIsReady: (active) async {
                                if (active) {
                                  vendors.forEach(
                                    (element) {
                                      mapOsmController
                                          .addMarker(osmMap.GeoPoint(latitude: element.latitude, longitude: element.longitude),
                                              markerIcon: osmMap.MarkerIcon(iconWidget: departureOsmIcon),
                                              angle: pi / 3,
                                              iconAnchor: osmMap.IconAnchor(
                                                anchor: osmMap.Anchor.top,
                                              ))
                                          .then((v) {
                                        osmMarkers['marker_${element.id}'] = osmMap.GeoPoint(latitude: element.latitude, longitude: element.longitude);
                                      });
                                      setState(() {});
                                    },
                                  );
                                }
                              }),
                        )
                      : GoogleMap(
                          zoomControlsEnabled: false,
                          myLocationEnabled: true,
                          buildingsEnabled: false,
                          markers: List.generate(
                            vendors.length,
                            (index) => Marker(
                              onDrag: (latLng) {
                                setState(() {
                                  latpos = vendors[index].latitude;
                                  lotpos = vendors[index].longitude;
                                  CameraUpdate.newLatLngZoom(latLng, 10);
                                  move();
                                });
                              },
                              markerId: MarkerId('marker_$index'),
                              position: LatLng(vendors[index].latitude, vendors[index].longitude),
                              icon: selected == index ? mapMarkerSelect : mapMarker,
                              onTap: () {
                                setState(() {
                                  selected = index;
                                  id = index;
                                  inx = index;
                                  scrollable();
                                  //  locationData.
                                });
                              },
                              infoWindow: InfoWindow(
                                onTap: () {
                                  push(
                                    context,
                                    NewVendorProductsScreen(
                                      vendorModel: vendors[index],
                                    ),
                                  );
                                },
                                title: vendors[index].title,
                              ),
                            ),
                          ).toSet(),
                          mapType: MapType.normal,
                          initialCameraPosition: CameraPosition(
                            target: locationData == null
                                ? vendors.isNotEmpty
                                    ? LatLng(vendors.first.latitude, vendors.first.longitude)
                                    : const LatLng(0, 0)
                                : LatLng(locationData!.latitude, locationData!.longitude),
                            zoom: 14,
                          ),
                          onMapCreated: _onMapCreated,
                        );
                }),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              height: 150,
              margin: const EdgeInsets.only(bottom: 80),
              child: StreamBuilder<List<VendorModel>>(
                  stream: vendorsFuture,
                  initialData: const [],
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator.adaptive(
                          valueColor: AlwaysStoppedAnimation(AppThemeData.primary300),
                        ),
                      );
                    }

                    if (snapshot.hasData || (snapshot.data?.isNotEmpty ?? false)) {
                      vendors = snapshot.data!;
                      return NotificationListener(
                          onNotification: (change) {
                            if (change is ScrollNotification) {
                              setState(() {
                                selected = contro.position.pixels ~/ 300.toInt();
                                latpos = vendors[selected].latitude;
                                lotpos = vendors[selected].longitude;
                                move();
                              });
                            }
                            return true;
                          },
                          child: ListView.builder(
                            controller: contro,
                            itemCount: vendors.length,
                            scrollDirection: Axis.horizontal,
                            key: itemKey,
                            itemBuilder: (context, index) {
                              return InkWell(
                                onTap: () {
                                  push(
                                    context,
                                    NewVendorProductsScreen(
                                      vendorModel: vendors[index],
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Card(
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Container(
                                      height: 150,
                                      width: 330,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        color: isDarkMode(context) ? const Color(0XFF0a0a0a) : Colors.grey.shade100,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                              flex: 3,
                                              child: Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: CachedNetworkImage(
                                                  imageUrl: getImageVAlidUrl(vendors[index].photo),
                                                  imageBuilder: (context, imageProvider) => Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(15),
                                                      image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                                                    ),
                                                  ),
                                                  placeholder: (context, url) => Center(
                                                      child: CircularProgressIndicator.adaptive(
                                                    valueColor: AlwaysStoppedAnimation(AppThemeData.primary300),
                                                  )),
                                                  errorWidget: (context, url, error) => ClipRRect(
                                                      borderRadius: BorderRadius.circular(15),
                                                      child: Image.network(
                                                        placeholderImage,
                                                        fit: BoxFit.cover,
                                                        width: MediaQuery.of(context).size.width,
                                                        height: MediaQuery.of(context).size.height,
                                                      )),
                                                  fit: BoxFit.cover,
                                                ),
                                              )),
                                          Expanded(
                                            flex: 5,
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    vendors[index].title,
                                                    style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode(context) ? Colors.white70 : Colors.black, fontSize: 17),
                                                  ),
                                                  Row(
                                                    children: [
                                                      Icon(Icons.star, color: AppThemeData.primary300),
                                                      const SizedBox(width: 5),
                                                      Text(
                                                        vendors[index].reviewsCount.toStringAsFixed(1),
                                                        style: TextStyle(
                                                          color: isDarkMode(context) ? Colors.white70 : Colors.black,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        "(${vendors[index].reviewsSum.toString()})",
                                                        style: TextStyle(
                                                          color: isDarkMode(context) ? Colors.white70 : Colors.black,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    vendors[index].location,
                                                    maxLines: 2,
                                                    style: TextStyle(
                                                      color: isDarkMode(context) ? Colors.white70 : Colors.black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ));
                    } else {
                      return showEmptyState('No Vendors'.tr(), context);
                    }
                  }),
            ),
          )
        ],
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    if (isDarkMode(context)) {
      _mapController!.setMapStyle('[{"featureType": "all","'
          'elementType": "'
          'geo'
          'met'
          'ry","stylers": [{"color": "#242f3e"}]},{"featureType": "all","elementType": "labels.text.stroke","stylers": [{"lightness": -80}]},{"featureType": "administrative","elementType": "labels.text.fill","stylers": [{"color": "#746855"}]},{"featureType": "administrative.locality","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "poi","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "poi.park","elementType": "geometry","stylers": [{"color": "#263c3f"}]},{"featureType": "poi.park","elementType": "labels.text.fill","stylers": [{"color": "#6b9a76"}]},{"featureType": "road","elementType": "geometry.fill","stylers": [{"color": "#2b3544"}]},{"featureType": "road","elementType": "labels.text.fill","stylers": [{"color": "#9ca5b3"}]},{"featureType": "road.arterial","elementType": "geometry.fill","stylers": [{"color": "#38414e"}]},{"featureType": "road.arterial","elementType": "geometry.stroke","stylers": [{"color": "#212a37"}]},{"featureType": "road.highway","elementType": "geometry.fill","stylers": [{"color": "#746855"}]},{"featureType": "road.highway","elementType": "geometry.stroke","stylers": [{"color": "#1f2835"}]},{"featureType": "road.highway","elementType": "labels.text.fill","stylers": [{"color": "#f3d19c"}]},{"featureType": "road.local","elementType": "geometry.fill","stylers": [{"color": "#38414e"}]},{"featureType": "road.local","elementType": "geometry.stroke","stylers": [{"color": "#212a37"}]},{"featureType": "transit","elementType": "geometry","stylers": [{"color": "#2f3948"}]},{"featureType": "transit.station","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "water","elementType": "geometry","stylers": [{"color": "#17263c"}]},{"featureType": "water","elementType": "labels.text.fill","stylers": [{"color": "#515c6d"}]},{"featureType": "water","elementType": "labels.text.stroke","stylers": [{"lightness": -20}]}]');
    }

    if (locationData != null) {
      _mapController!.moveCamera(
        CameraUpdate.newLatLng(
          LatLng(locationData!.latitude, locationData!.longitude),
        ),
      );
    }
  }

  Future<void> getTempLocation() async {
    debugPrint('location map: ${MyAppState.selectedPosotion.location}');
    if (MyAppState.currentUser == null && MyAppState.selectedPosotion.location!.latitude != 0 && MyAppState.selectedPosotion.location!.longitude != 0) {
      locationData = MyAppState.selectedPosotion.location;
      setState(() {});
    }
  }

  void move() {
    if (selectedMapType == "osm") {
      mapOsmController.moveTo(
        osmMap.GeoPoint(latitude: latpos, longitude: lotpos),
        animate: true,
      );
    } else {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(latpos, lotpos), 13),
      );
    }
  }
}
