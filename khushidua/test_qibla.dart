import 'package:prayers_times/prayers_times.dart';
import 'dart:developer';

void main() {
  var coords = Coordinates(31.5497, 74.3436);
  log(Qibla.qibla(coords).toString());
}
