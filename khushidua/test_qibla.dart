import 'dart:math' as console;

import 'package:prayers_times/prayers_times.dart';

void main() {
  var coords = Coordinates(31.5497, 74.3436);
  console.log(Qibla.qibla(coords));
}
