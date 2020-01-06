import 'dart:core';
import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

extension DoubleExtensions on double {
  double toPrecision(int fractionDigits) {
    double mod = pow(10, fractionDigits.toDouble());
    return ((this * mod).round().toDouble() / mod);
  }
}

extension PositionExtensions on Position {
  String description() {
    return this == null ? 'Unknown position' : 'Current Position: $this';
  }
}

extension DateTimeExtensions on DateTime {
  String toLocalUsTime() {
    return new DateFormat.yMMMMd("en_US")
      .add_jms()
      .format(this.toLocal());
  }
}