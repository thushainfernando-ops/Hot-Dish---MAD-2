import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Stub accelerometer provider that yields zeros periodically. This avoids
// requiring the sensors_plus plugin on emulators/devices where it's not
// needed for the app use-case (restaurant app).
final accelerometerProvider = StreamProvider.autoDispose<double>((ref) {
  // emits 0.0 every second as a placeholder
  return Stream<double>.periodic(const Duration(seconds: 1), (_) => 0.0);
});
