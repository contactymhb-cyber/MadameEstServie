import 'package:easy_localization/easy_localization.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/theme/app_them_data.dart';
import 'package:emartconsumer/utils/DarkThemeProvider.dart';
import 'package:emartconsumer/widget/osm_map_search_place.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';
import 'package:osm_nominatim/osm_nominatim.dart';
import 'package:provider/provider.dart';

class LocationPicker extends StatefulWidget {
  const LocationPicker({super.key});

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  GeoPoint? selectedLocation;
  late MapController mapController;
  Place? place;
  TextEditingController textController = TextEditingController();
  final List<GeoPoint> _markers = [];

  @override
  void initState() {
    super.initState();
    mapController = MapController(initMapWithUserPosition: const UserTrackingOption(enableTracking: false, unFollowUser: true));
    setState(() {});
  }

  _listerTapPosition() async {
    mapController.listenerMapSingleTapping.addListener(() async {
      if (mapController.listenerMapSingleTapping.value != null) {
        GeoPoint position = mapController.listenerMapSingleTapping.value!;
        addMarker(position);
        place = await Nominatim.reverseSearch(
          lat: position.latitude,
          lon: position.longitude,
          zoom: 14,
          addressDetails: true,
          extraTags: true,
          nameDetails: true,
        );
      }
    });
  }

  addMarker(GeoPoint? position) async {
    if (position != null) {
      for (var marker in _markers) {
        await mapController.removeMarker(marker);
      }
      setState(() {
        _markers.clear();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await mapController
            .addMarker(position,
                markerIcon: const MarkerIcon(
                  icon: Icon(Icons.location_on, size: 26),
                ))
            .then((v) {
          _markers.add(position);
        });

        place = await Nominatim.reverseSearch(
          lat: position.latitude,
          lon: position.longitude,
          zoom: 14,
          addressDetails: true,
          extraTags: true,
          nameDetails: true,
        );
        setState(() {});
        mapController.goToLocation(position);
      });
    }
  }

  Future<void> _setUserLocation() async {
    try {
      final locationData = await getCurrentLocation();
      setState(() async {
        selectedLocation = GeoPoint(
          latitude: locationData!.latitude,
          longitude: locationData.longitude,
        );
        await addMarker(selectedLocation!);
        mapController.goToLocation(selectedLocation!);
        place = await Nominatim.reverseSearch(
          lat: selectedLocation!.latitude,
          lon: selectedLocation!.longitude,
          zoom: 14,
          addressDetails: true,
          extraTags: true,
          nameDetails: true,
        );
      });
    } catch (e) {
      print("Error getting location: $e");
      // Handle error (e.g., show a snackbar to the user)
    }
  }

  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      await Location().requestService();
      return null;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Stack(
        children: [
          OSMFlutter(
            controller: mapController,
            mapIsLoading: const Center(child: CircularProgressIndicator()),
            osmOption: OSMOption(
              userLocationMarker: UserLocationMaker(
                  personMarker: MarkerIcon(iconWidget: Image.asset("assets/images/pickup.png")),
                  directionArrowMarker: MarkerIcon(iconWidget: Image.asset("assets/images/pickup.png"))),
              isPicker: true,
              zoomOption: const ZoomOption(initZoom: 14),
            ),
            onMapIsReady: (active) {
              if (active) {
                _setUserLocation();
                _listerTapPosition();
              }
            },
          ),
          if (place?.displayName != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 100, left: 40, right: 40),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDarkMode(context) ? AppThemeData.grey900 : AppThemeData.grey50,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        place?.displayName ?? '',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    IconButton(
                        onPressed: () {
                          Navigator.pop(context, place);
                        },
                        icon: const Icon(
                          Icons.check_circle,
                          size: 40,
                        ))
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 00),
                  child: InkWell(
                    onTap: () async {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => OsmSearchPlacesApi())).then(
                        (value) async {
                          if (value != null) {
                            SearchInfo place = value;
                            textController = TextEditingController(text: place.address.toString());
                            await addMarker(place.point);
                            setState(() {});
                            print("Search :: ${place.point.toString()}");
                          }
                        },
                      );
                    },
                    child: buildTextField(
                      title: "Search Address".tr(),
                      textController: textController,
                    ),
                  ),
                )),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _setUserLocation,
        child: Icon(Icons.my_location, color: isDarkMode(context) ? AppThemeData.primary300 : AppThemeData.primary300),
      ),
    );
  }

  Widget buildTextField({required title, required TextEditingController textController}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: TextField(
        controller: textController,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          prefixIcon: IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: () {},
          ),
          fillColor: Colors.white,
          filled: true,
          hintText: title,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          enabled: false,
        ),
      ),
    );
  }
}
