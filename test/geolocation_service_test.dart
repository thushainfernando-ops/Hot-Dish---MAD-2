import 'package:flutter_test/flutter_test.dart';
import 'package:hot_dish_mobile_app/services/geolocation_service.dart';

void main() {
  test('calculateDistance returns zero for identical coordinates', () {
    final lat = GeolocationService.restaurantLat;
    final lon = GeolocationService.restaurantLon;
    final d = GeolocationService.calculateDistance(lat, lon, lat, lon);
    expect(d, closeTo(0.0, 0.0001));
  });

  test('estimateDeliveryTime returns at least preparation time', () {
    final minutes = GeolocationService.estimateDeliveryTime(0.0);
    expect(minutes, greaterThanOrEqualTo(10));
  });

  test('formatDistance formats meters and kilometers', () {
    final m = GeolocationService.formatDistance(0.2);
    expect(m.contains('m') || m.contains('km'), isTrue);
    final k = GeolocationService.formatDistance(2.5);
    expect(k.contains('km'), isTrue);
  });
}
