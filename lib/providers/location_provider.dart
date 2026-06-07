import 'package:flutter_riverpod/flutter_riverpod.dart';

// Stubbed location provider: returns null (location disabled) to avoid
// including the geolocator plugin on emulators/dev builds as requested.
final locationProvider = FutureProvider<dynamic>((ref) async {
  return null;
});
