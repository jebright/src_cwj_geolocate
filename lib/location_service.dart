import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'extensions.dart';

class LocationService {

  Geolocator _geolocator;
  StreamSubscription<Position> positionStream;
  
  LocationService() {
    _geolocator = Geolocator();
  }

  Future<Position> getCurrentPosition() async {
    var p = await _geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    return p;
  }

  Future<double> distanceBetween(Position start, Position end) async {
    double distance = await _geolocator.distanceBetween(start.latitude, start.longitude, end.latitude, end.longitude);
    return distance.toPrecision(2);
  }

  Future<String> getAddress(Position pos) async {
    try {
      List<Placemark> placemarks = await _geolocator
          .placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks != null && placemarks.isNotEmpty) {
        final Placemark pos = placemarks[0];
        return pos.thoroughfare + ', ' + pos.locality;
      }
      return "";
    } catch (ex) {
      return "";
    }
  }

  void startTracking(void onLocationUpdate(Position event)) {
    var locationOptions =
        LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 0);

    positionStream = _geolocator
        .getPositionStream(locationOptions)
        .listen((Position pos) {
          onLocationUpdate(pos);
        });
  }

  void stopTracking() {
    if(positionStream != null) {
      positionStream.cancel();
    }
  }
  
}