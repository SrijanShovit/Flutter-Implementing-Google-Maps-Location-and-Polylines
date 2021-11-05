import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:location_tracking/google_map_api.dart';

class LocationTracking extends StatefulWidget {
  // const LocationTracking({Key key}) : super(key: key);

  @override
  _LocationTrackingState createState() => _LocationTrackingState();
}

class _LocationTrackingState extends State<LocationTracking> {
  LatLng sourceLocation = LatLng(28.432864, 77.002653);
  LatLng destinationLatlng = LatLng(25.6104, 85.1490);

  // A way to produce Future objects and to complete them later with a value or error.
  Completer<GoogleMapController> _controller = Completer();

  //set is like list which doesn't accept duplicate values
  Set<Marker> _marker = Set<Marker>();

  Set<Polyline> _polylines = Set<Polyline>();

  List<LatLng> polylineCoordinates = [];
  late PolylinePoints polylinePoints;

  //for listening to live updates
  late StreamSubscription<LocationData> subscription;

  LocationData? currentLocation;
  late LocationData destinationLocation;
  late Location location;

  @override
  void initState() {
    super.initState();

    location = Location();
    polylinePoints = PolylinePoints();

    //to listen to change in current location
    subscription = location.onLocationChanged.listen((clocation) {
      //listen fn returns us a parameter of Location data type
      //in which we get updated location of user

      //current location is updated to updated location so as to see pins moving on map
      currentLocation = clocation;
      updatePinsOnMap();
    });

    setInitialLocation(); //this will get starting and destination points
  }

  void setInitialLocation() async {
    //initialising current location
    currentLocation = await location.getLocation().then((value) {
      currentLocation = value;
      setState(() {});
    });

    //initialising destination location
    destinationLocation = LocationData.fromMap({
      "latitude": destinationLatlng.latitude,
      "longitude": destinationLatlng.longitude
    });
  }

  void showLocationPin() {
    var sourceposition = LatLng(
        currentLocation!.latitude ?? 0.0, currentLocation!.longitude ?? 0.0);

    var destinationPosition =
        LatLng(destinationLatlng.latitude, destinationLatlng.longitude);

    _marker.add(
        Marker(markerId: MarkerId('sourcePosition'), position: sourceposition));

    _marker.add(Marker(
        markerId: MarkerId('destinationPosition'),
        position: destinationPosition));

    setPolylinesInMap();
  }

  //function to show polylines
  void setPolylinesInMap() async {
    //await added to avoid getting value in future
    var result = await polylinePoints.getRouteBetweenCoordinates(
        GoogleMapApi().url,
        PointLatLng(currentLocation!.latitude ?? 0.0,
            currentLocation!.longitude ?? 0.0),
        PointLatLng(destinationLatlng.latitude, destinationLatlng.longitude));

    //result.points will ive a list
    if (result.points.isNotEmpty) {
      result.points.forEach((pointLatLang) {
        polylineCoordinates
            .add(LatLng(pointLatLang.latitude, pointLatLang.longitude));
      });
    }

    setState(() {
      _polylines.add(Polyline(
          polylineId: PolylineId('polyline'),
          color: Colors.blueAccent,
          width: 5,
          points: polylineCoordinates));
    });
  }

  void updatePinsOnMap() async {
    CameraPosition cameraPosition = CameraPosition(
        target: LatLng(currentLocation!.latitude ?? 0.0,
            currentLocation!.longitude ?? 0.0),
        zoom: 20,
        tilt: 80,
        bearing: 30);

    //google map controller to move camera position
    final GoogleMapController controller = await _controller.future;

    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    var sourcePosition = LatLng(
        currentLocation!.latitude ?? 0.0, currentLocation!.longitude ?? 0.0);

    setState(() {
      //to see chnages in state
      //remove previous position marker
      _marker.removeWhere((marker) => marker.mapsId.value == 'sourcePosition');

      //add new location pins
      _marker.add(Marker(
          markerId: MarkerId('sourcePosition'), position: sourcePosition));
    });
  }

  @override
  Widget build(BuildContext context) {
    //it is initial camera position which will be shown in map
    CameraPosition initialCameraPosition = CameraPosition(
        //required parameter which takes latitude and longitude
        target: currentLocation != null
            ? LatLng(currentLocation!.latitude ?? 0.0,
                currentLocation!.longitude ?? 0.0)
            : LatLng(0.0, 0.0),

        //optional parameter
        zoom: 20,
        tilt: 80,
        bearing: 30);

    return currentLocation == null
        ? Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            alignment: Alignment.center,
            child: CircularProgressIndicator(),
          )
        : SafeArea(
            child: Scaffold(
            //GoogleMap widget got from that package
            body: GoogleMap(
              myLocationButtonEnabled: true,
              compassEnabled: true,
              markers: _marker,
              polylines: _polylines,
              mapType: MapType.normal,
              initialCameraPosition: initialCameraPosition,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
                showLocationPin();
              },
            ),
          ));
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }
}
