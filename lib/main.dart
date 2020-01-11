import 'dart:async';
import 'package:flutter/material.dart';

import 'extensions.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:poly/poly.dart' as poly;

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
  int _selectedIndex = 0;
  bool _addingPolygon = false;
  List<LatLng> _points = <LatLng>[];
  final Map<String, Marker> _markers = new Map();
  final List<Polygon> _polygons = new List<Polygon>();
  final List<HistoryRecord> _history = new List<HistoryRecord>();
  Position _lastPosition;
  bool _withinBoundary = false;

  LocationService _locationService = new LocationService();
  Completer<GoogleMapController> _controller = Completer();

  @override
  void dispose() {
    _locationService.stopTracking();
    super.dispose();
  }

  //Build the main user interface
  List<Widget> _buildWidgetStack() {
    List<Widget> list = new List<Widget>();
    list.add(_buildMap());
    if (_addingPolygon) {
      list.add(_buildFinishPolygonButton());
    }
    list.add(_buildBoundaryIndicator());
    return list;
  }

  //Build a Google Map
  GoogleMap _buildMap() {
    return GoogleMap(
      mapType: MapType.normal,
      onMapCreated: _onMapCreated,
      onTap: _onMapTap,
      polygons: Set<Polygon>.of(_polygons),
      initialCameraPosition: CameraPosition(
        target: LatLng(40.688841, -74.044015),
        zoom: 11,
      ),
      markers: _markers.values.toSet(),
    );
  }

  //Build our bottom nav bar
  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          title: Text('Home'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_location),
          title: Text('Update'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          title: Text('History'),
        ),
      ],
      currentIndex: 0, //_selectedIndex,
      selectedItemColor: Colors.amber[800],
      onTap: _onNavBarTapped,
    );
  }

  //The finish button built here is put on the screen when adding a polygon.
  //Clicking it finishes the polygon.
  Widget _buildFinishPolygonButton() {
    return Positioned(
        right: 30,
        top: 40,
        child: RaisedButton(
          onPressed: _finishPolygon,
          color: Colors.amber[800],
          child: const Text(
            'Finish',
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
        ));
  }

  //And indicator that tells us if we are in the boundary of a polygon or not.
  Widget _buildBoundaryIndicator() {
    return Positioned(
        left: 10,
        bottom: 40,
        child: _withinBoundary ? 
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 30.0,
          ) : 
          Icon(
            Icons.warning,
            color: Colors.red,
            size: 30.0,
          ),
        );
    
  }

  //When the user taps on the navbar, this is called to determine what action to take.
  void _onNavBarTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (_selectedIndex == 1) {
      showModalBottomSheet(
          context: context,
          builder: (context) {
            return Container(height: 180, child: _buildUpdateMenu());
          });
    }
    else if(_selectedIndex == 2) {
      _goHistory();
    }
  }

  //When the 'Update' nav bar button is clicked, this is the menu invoked
  Column _buildUpdateMenu() {
    return Column(
      children: <Widget>[
        ListTile(
          leading: Icon(Icons.my_location),
          title: Text('My Location'),
          onTap: _zoomToCurrentLocation,
        ),
        ListTile(
            leading: Icon(Icons.crop_square),
            title: Text('Add boundary'),
            onTap: _startPolygon),
        ListTile(
            leading: Icon(Icons.clear_all),
            title: Text('Clear'),
            onTap: _clear),
      ],
    );
  }

  //Puts us in the state of adding a polygon to the map
  void _startPolygon() {
    setState(() {
      _addingPolygon = true;
    });
    Navigator.of(context).pop();
  }

  //Takes us out of the state of adding a polygon to the map
  void _finishPolygon() async {
    setState(() {
      _addingPolygon = false;
      _points.clear();
    });
  }

  //Clear polygons and markers from the map
  void _clear() {
    setState(() {
      _polygons.clear();
      _markers.clear();
    });
  }

  //Zooms the camera to the current location on the map
  void _zoomToCurrentLocation() async {
    var position = await _locationService.getCurrentPosition();
    var currentAddress = await _locationService.getAddress(position);
    print(
        'got current location as ${position.latitude}, ${position.longitude}');

    await _moveToPosition(position);

    setState(() {
      _markers.clear();
      final marker =
          _createMarker("curr_loc", LatLng(position.latitude, position.longitude), currentAddress);
      _markers["Current Location"] = marker;
    });
  }

  //Create a map marker at the predefined location.
  Marker _createMarker(
      String id, LatLng position, String title) {
    return Marker(
        markerId: MarkerId(id),
        position: position,
        infoWindow: InfoWindow(title: title)
    );
  }

  //Called when you tap on the history button. Shows location history
  void _goHistory() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => new HistoryPage(history: this._history)));
  }

  //As the location changes, listen for the change and add to history
  void _onLocationUpdate(Position position) async {
    double distance = 0;
    if (_lastPosition != null) {
      distance =
          await _locationService.distanceBetween(_lastPosition, position);
    }
    _lastPosition = position;

    String positionText = position.description();
    String distanceText = 'Moved $distance meters.';
    String msg = '$distanceText $positionText';
    //print(msg);

    String timestamp = position.timestamp.toLocalUsTime();
    var hr = new HistoryRecord();
    hr.title = timestamp;
    hr.description = msg;
    hr.position = position;
    _history.add(hr);

    if((_polygons.length > 0) && (_polygons[0].points.length >=3) && (!_addingPolygon)) {
      var boundary = poly.Polygon(_polygons[0].points.map((f) => poly.Point(f.latitude, f.longitude)).toList());
      
      setState(() {
        _withinBoundary = boundary.isPointInside(poly.Point(_lastPosition.latitude, _lastPosition.longitude));  
      });
      
      print('Location within boundary? $_withinBoundary');
    }    

  }

  //Moves the map to a specific position.
  Future<void> _moveToPosition(Position pos) async {
    final GoogleMapController mapController = await _controller.future;
    if (mapController == null) return;
    print('moving to position ${pos.latitude}, ${pos.longitude}');
    mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(pos.latitude, pos.longitude),
      zoom: 15.0,
    )));
  }

  //Called when the google map is first created
  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _controller.complete(controller);
    });

    _locationService.startTracking(_onLocationUpdate);
  }

  //Handle taps on the map.  This is where we create polygons.
  void _onMapTap(LatLng l) {
    print(l);
    if (_addingPolygon) {
      _points.add(l);

      final Polygon polygon = Polygon(
          polygonId: PolygonId('boundary'),
          consumeTapEvents: true,
          strokeColor: Colors.orange,
          strokeWidth: 5,
          fillColor: Color(0xFFFFFF),
          points: List.from(_points));

      setState(() {
        _polygons.clear();
        _polygons.add(polygon);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: Stack(children: _buildWidgetStack()),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}
