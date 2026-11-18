class AppConstants {
  static const String appName = 'Tropical Gyros Staff';
  static const String appSubtitle = 'Delivery & Cashier Portal';
  static const String currency = 'BSD ';

  // Centralized Official Restaurant Configuration
  // Tropical Gyros Flagship: Rosetta Street & Mackey Street, Palmdale, Nassau, Bahamas
  static const String restaurantName = 'Tropical Gyros Flagship';
  static const String restaurantAddress =
      'Rosetta Street & Mackey Street, Palmdale, Nassau, Bahamas';
  static const String restaurantPhone = '+1 (242) 462-6299';
  static const String restaurantPhoneDialable = '+12424626299';
  static const String restaurantPhoneSecondary = '+1 (242) 603-5752';

  // Provisional & Verified Coordinates
  static const double restaurantLatitude = 25.0675;
  static const double restaurantLongitude = -77.3245;

  // Delivery Geofencing
  static const double deliveryRadiusMiles = 3.0;
  static const double metersPerMile = 1609.34;
  static const double deliveryRadiusMeters = deliveryRadiusMiles * metersPerMile; // 4828.02m

  // Drop-off Proximity Restriction: Couriers must be within this distance (meters) of drop location to deliver
  static const double dropLocationProximityMeters = 200.0; // 200 meters doorstep geofence

  // Backend API Base URL (Live Public Cloudflare Endpoint)
  static const String backendBaseUrl =
      'https://jennifer-manchester-robust-pleasant.trycloudflare.com';

  // Demo Notice Strings
  static const String demoNotice =
      'DEMO UI PROTOTYPE • Local State Only (No Real Backend / APIs)';
}
