import 'package:geolocator/geolocator.dart';
import 'dart:math';

class GeolocationService {
  GeolocationService._();

  // Restaurant coordinates (Hot Dish location in Balapitiya, Sri Lanka)
  static const double restaurantLat = 6.3520;
  static const double restaurantLon = 80.3425;

  /// Get current user location
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null; // Location services disabled
      }

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null; // Permission denied
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null; // Permission permanently denied
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Calculate distance between two coordinates in km using Haversine formula
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) *
            cos(lat2 * p) *
            (1 - cos((lon2 - lon1) * p)) /
            2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  /// Estimate delivery time in minutes based on distance
  /// Assumes average delivery speed of 30 km/h in urban area + 10 min preparation
  static int estimateDeliveryTime(double distanceKm) {
    const averageSpeedKmPerHour = 30;
    const preparationTimeMinutes = 10;

    // Calculate travel time
    final travelTimeMinutes =
        (distanceKm / averageSpeedKmPerHour * 60).ceil();

    // Total time = preparation + travel
    return preparationTimeMinutes + travelTimeMinutes;
  }

  /// Get address string from coordinates (reverse geocoding)
  /// For simplicity, returns formatted coordinate string
  /// In production, you'd use a reverse geocoding API
  static String formatCoordinates(double lat, double lon) {
    return '$lat, $lon';
  }

  /// Format distance for display
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  /// Get distance from user location to restaurant
  static Future<Map<String, dynamic>?> getDeliveryInfo() async {
    try {
      final position = await getCurrentLocation();
      if (position == null) return null;

      final distance = calculateDistance(
        position.latitude,
        position.longitude,
        restaurantLat,
        restaurantLon,
      );

      final estimatedTime = estimateDeliveryTime(distance);

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'distance_km': distance,
        'distance_formatted': formatDistance(distance),
        'estimated_minutes': estimatedTime,
        'restaurant_lat': restaurantLat,
        'restaurant_lon': restaurantLon,
      };
    } catch (e) {
      print('Error getting delivery info: $e');
      return null;
    }
  }
}
