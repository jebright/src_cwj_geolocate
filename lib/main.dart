import 'dart:async';
import 'extensions.dart';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'history.dart';
import 'history_record.dart';
import 'location_service.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Maps Demo',
      home: MyMap(),
    );
  }
}

class MyMap extends StatefulWidget {
  @override
  State<MyMap> createState() => MyMapSampleState();
}

class MyMapSampleState extends State<MyMap> {
  final Map<String, Marker> _markers = new Map();
  final List<HistoryRecord> _history = new List<HistoryRecord>();
  Position _lastPosition;
  
  LocationService _locationService = new LocationService();
  Completer<GoogleMapController> _controller = Completer();

  @override
  void dispose() {
    _locationService.stopTracking();
    super.dispose();
  }

  void _zoomToCurrentLocation() async {
    var currentLocation = await _locationService.getCurrentPosition();
    var currentAddress = await _locationService.getAddress(currentLocation);
    print('got current location as ${currentLocation.latitude}, ${currentLocation.longitude}');

    await _moveToPosition(currentLocation);

    setState(() {
      _markers.clear();
      final marker = _createMarker("curr_loc", currentLocation, currentAddress, goHistory);
      _markers["Current Location"] = marker;
    });
  }

  Marker _createMarker(
      String id, Position position, String title, Function tap) {
    return Marker(
        markerId: MarkerId(id),
        position: LatLng(position.latitude, position.longitude),
        infoWindow: InfoWindow(title: title),
        onTap: tap);
  }

  // BitmapDescriptor _getMarkerIcon() {
  //   //
  //   Uint8List byteData;
  //   BitmapDescriptor bd = BitmapDescriptor.fromBytes(byteData);
  //   return bd;
  // }

  void goHistory() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => new HistoryPage(history: this._history)));
  }

  void _onLocationUpdate(Position position) async {
    double distance = 0;
    if(_lastPosition != null) {
      distance = await _locationService.distanceBetween(_lastPosition, position);
    }
    _lastPosition = position;

    String positionText =  position.description();
    String distanceText = 'Moved $distance meters.';
    String msg = '$distanceText $positionText';
    print(msg);

    String timestamp = position.timestamp.toLocalUsTime();
    var hr = new HistoryRecord();
    hr.title = timestamp;
    hr.description = msg;
    hr.position = position;
    _history.add(hr);
  }

  Future<void> _moveToPosition(Position pos) async {
    final GoogleMapController mapController = await _controller.future;
    if (mapController == null) return;
    print('moving to position ${pos.latitude}, ${pos.longitude}');
    mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(pos.latitude, pos.longitude),
      zoom: 15.0,
    )));
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _controller.complete(controller);
    });

    _locationService.startTracking(_onLocationUpdate);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: GoogleMap(
        mapType: MapType.normal,
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: LatLng(40.688841, -74.044015),
          zoom: 11,
        ),
        markers: _markers.values.toSet(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _zoomToCurrentLocation,
        tooltip: 'Get Location',
        child: Icon(Icons.flag),
      ),
    );
  }
}
