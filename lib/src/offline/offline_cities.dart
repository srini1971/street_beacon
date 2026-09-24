import 'dart:math' as math;
import 'regional_language.dart';

/// Represents a prominent Indian city, district headquarters, or regional hub
/// embedded directly into the binary for 100% offline proximity calculations.
class OfflineCity {
  /// Name of the city or district headquarters (e.g., 'Bengaluru', 'Chennai').
  final String name;

  /// State or Union Territory name (e.g., 'Karnataka', 'Tamil Nadu').
  final String state;

  /// Latitude coordinate.
  final double latitude;

  /// Longitude coordinate.
  final double longitude;

  /// Creates an [OfflineCity] constant.
  const OfflineCity({
    required this.name,
    required this.state,
    required this.latitude,
    required this.longitude,
  });

  /// The primary regional language spoken in this city's state.
  ///
  /// Examples:
  /// - Bengaluru -> [IndianLanguage.kannada]
  /// - Chennai -> [IndianLanguage.tamil]
  /// - Mumbai -> [IndianLanguage.marathi]
  /// - Kolkata -> [IndianLanguage.bengali]
  IndianLanguage get regionalLanguage => IndianLanguage.fromState(state);
}

/// Result of a nearest-city proximity calculation.
class NearestCityResult {
  /// The nearest [OfflineCity].
  final OfflineCity city;

  /// Approximate distance in kilometers from the query coordinates.
  final double distanceKm;

  /// Compass direction from the city toward the coordinates (e.g., "North-East", "South").
  final String compassDirection;

  /// Creates a [NearestCityResult].
  const NearestCityResult({
    required this.city,
    required this.distanceKm,
    required this.compassDirection,
  });

  /// Natural English phrasing for human dispatchers.
  /// Example: "approximately 18 km North-East of Bengaluru (Karnataka)" or "within Bengaluru (Karnataka)"
  String toSpokenPhrase() {
    if (distanceKm < 5.0) {
      return 'in or near ${city.name} (${city.state})';
    }
    final rounded = distanceKm.round();
    return 'approximately $rounded km $compassDirection of ${city.name} (${city.state})';
  }

  @override
  String toString() => '${city.name}, ${city.state} (~${distanceKm.round()} km $compassDirection)';
}

/// Offline proximity resolver for India.
class OfflineCityDatabase {
  /// Curated list of ~80 major Indian cities, state capitals, and strategic highway/corridor hubs.
  static const List<OfflineCity> cities = [
    // --- North ---
    OfflineCity(name: 'New Delhi', state: 'Delhi', latitude: 28.6139, longitude: 77.2090),
    OfflineCity(name: 'Noida', state: 'Uttar Pradesh', latitude: 28.5355, longitude: 77.3910),
    OfflineCity(name: 'Gurugram', state: 'Haryana', latitude: 28.4595, longitude: 77.0266),
    OfflineCity(name: 'Faridabad', state: 'Haryana', latitude: 28.4089, longitude: 77.3178),
    OfflineCity(name: 'Ghaziabad', state: 'Uttar Pradesh', latitude: 28.6692, longitude: 77.4538),
    OfflineCity(name: 'Meerut', state: 'Uttar Pradesh', latitude: 28.9845, longitude: 77.7064),
    OfflineCity(name: 'Agra', state: 'Uttar Pradesh', latitude: 27.1767, longitude: 78.0081),
    OfflineCity(name: 'Mathura', state: 'Uttar Pradesh', latitude: 27.4924, longitude: 77.6737),
    OfflineCity(name: 'Aligarh', state: 'Uttar Pradesh', latitude: 27.8974, longitude: 78.0880),
    OfflineCity(name: 'Lucknow', state: 'Uttar Pradesh', latitude: 26.8467, longitude: 80.9462),
    OfflineCity(name: 'Kanpur', state: 'Uttar Pradesh', latitude: 26.4499, longitude: 80.3319),
    OfflineCity(name: 'Varanasi', state: 'Uttar Pradesh', latitude: 25.3176, longitude: 82.9739),
    OfflineCity(name: 'Prayagraj', state: 'Uttar Pradesh', latitude: 25.4358, longitude: 81.8463),
    OfflineCity(name: 'Bareilly', state: 'Uttar Pradesh', latitude: 28.3670, longitude: 79.4304),
    OfflineCity(name: 'Moradabad', state: 'Uttar Pradesh', latitude: 28.8386, longitude: 78.7733),
    OfflineCity(name: 'Gorakhpur', state: 'Uttar Pradesh', latitude: 26.7606, longitude: 83.3732),
    OfflineCity(name: 'Jhansi', state: 'Uttar Pradesh', latitude: 25.4484, longitude: 78.5685),
    OfflineCity(name: 'Dehradun', state: 'Uttarakhand', latitude: 30.3165, longitude: 78.0322),
    OfflineCity(name: 'Haridwar', state: 'Uttarakhand', latitude: 29.9457, longitude: 78.1642),
    OfflineCity(name: 'Haldwani', state: 'Uttarakhand', latitude: 29.2183, longitude: 79.5130),
    OfflineCity(name: 'Chandigarh', state: 'Chandigarh', latitude: 30.7333, longitude: 76.7794),
    OfflineCity(name: 'Amritsar', state: 'Punjab', latitude: 31.6340, longitude: 74.8723),
    OfflineCity(name: 'Ludhiana', state: 'Punjab', latitude: 30.9010, longitude: 75.8573),
    OfflineCity(name: 'Jalandhar', state: 'Punjab', latitude: 31.3260, longitude: 75.5762),
    OfflineCity(name: 'Patiala', state: 'Punjab', latitude: 30.3398, longitude: 76.3869),
    OfflineCity(name: 'Shimla', state: 'Himachal Pradesh', latitude: 31.1048, longitude: 77.1734),
    OfflineCity(name: 'Mandi', state: 'Himachal Pradesh', latitude: 31.5892, longitude: 76.9182),
    OfflineCity(name: 'Dharamshala', state: 'Himachal Pradesh', latitude: 32.2190, longitude: 76.3234),
    OfflineCity(name: 'Srinagar', state: 'Jammu & Kashmir', latitude: 34.0837, longitude: 74.7973),
    OfflineCity(name: 'Jammu', state: 'Jammu & Kashmir', latitude: 32.7266, longitude: 74.8570),
    OfflineCity(name: 'Leh', state: 'Ladakh', latitude: 34.1526, longitude: 77.5771),

    // --- West ---
    OfflineCity(name: 'Mumbai', state: 'Maharashtra', latitude: 19.0760, longitude: 72.8777),
    OfflineCity(name: 'Pune', state: 'Maharashtra', latitude: 18.5204, longitude: 73.8567),
    OfflineCity(name: 'Nagpur', state: 'Maharashtra', latitude: 21.1458, longitude: 79.0882),
    OfflineCity(name: 'Nashik', state: 'Maharashtra', latitude: 19.9975, longitude: 73.7898),
    OfflineCity(name: 'Chhatrapati Sambhajinagar', state: 'Maharashtra', latitude: 19.8762, longitude: 75.3433),
    OfflineCity(name: 'Solapur', state: 'Maharashtra', latitude: 17.6599, longitude: 75.9064),
    OfflineCity(name: 'Kolhapur', state: 'Maharashtra', latitude: 16.7050, longitude: 74.2433),
    OfflineCity(name: 'Amravati', state: 'Maharashtra', latitude: 20.9374, longitude: 77.7796),
    OfflineCity(name: 'Ahmedabad', state: 'Gujarat', latitude: 23.0225, longitude: 72.5714),
    OfflineCity(name: 'Surat', state: 'Gujarat', latitude: 21.1702, longitude: 72.8311),
    OfflineCity(name: 'Vadodara', state: 'Gujarat', latitude: 22.3072, longitude: 73.1812),
    OfflineCity(name: 'Rajkot', state: 'Gujarat', latitude: 22.3039, longitude: 70.8022),
    OfflineCity(name: 'Bhavnagar', state: 'Gujarat', latitude: 21.7645, longitude: 72.1519),
    OfflineCity(name: 'Jamnagar', state: 'Gujarat', latitude: 22.4707, longitude: 70.0577),
    OfflineCity(name: 'Jaipur', state: 'Rajasthan', latitude: 26.9124, longitude: 75.7873),
    OfflineCity(name: 'Jodhpur', state: 'Rajasthan', latitude: 26.2389, longitude: 73.0243),
    OfflineCity(name: 'Udaipur', state: 'Rajasthan', latitude: 24.5854, longitude: 73.7125),
    OfflineCity(name: 'Kota', state: 'Rajasthan', latitude: 25.2138, longitude: 75.8648),
    OfflineCity(name: 'Bikaner', state: 'Rajasthan', latitude: 28.0229, longitude: 73.3119),
    OfflineCity(name: 'Ajmer', state: 'Rajasthan', latitude: 26.4499, longitude: 74.6399),
    OfflineCity(name: 'Panaji', state: 'Goa', latitude: 15.4909, longitude: 73.8278),
    OfflineCity(name: 'Margao', state: 'Goa', latitude: 15.2832, longitude: 73.9862),

    // --- South ---
    OfflineCity(name: 'Bengaluru', state: 'Karnataka', latitude: 12.9716, longitude: 77.5946),
    OfflineCity(name: 'Mysuru', state: 'Karnataka', latitude: 12.2958, longitude: 76.6394),
    OfflineCity(name: 'Hubballi-Dharwad', state: 'Karnataka', latitude: 15.3647, longitude: 75.1240),
    OfflineCity(name: 'Mangaluru', state: 'Karnataka', latitude: 12.9141, longitude: 74.8560),
    OfflineCity(name: 'Belagavi', state: 'Karnataka', latitude: 15.8497, longitude: 74.4977),
    OfflineCity(name: 'Kalaburagi', state: 'Karnataka', latitude: 17.3297, longitude: 76.8343),
    OfflineCity(name: 'Shivamogga', state: 'Karnataka', latitude: 13.9299, longitude: 75.5681),
    OfflineCity(name: 'Ballari', state: 'Karnataka', latitude: 15.1394, longitude: 76.9214),
    OfflineCity(name: 'Hyderabad', state: 'Telangana', latitude: 17.3850, longitude: 78.4867),
    OfflineCity(name: 'Warangal', state: 'Telangana', latitude: 17.9689, longitude: 79.5941),
    OfflineCity(name: 'Nizamabad', state: 'Telangana', latitude: 18.6725, longitude: 78.0941),
    OfflineCity(name: 'Karimnagar', state: 'Telangana', latitude: 18.4386, longitude: 79.1288),
    OfflineCity(name: 'Chennai', state: 'Tamil Nadu', latitude: 13.0827, longitude: 80.2707),
    OfflineCity(name: 'Coimbatore', state: 'Tamil Nadu', latitude: 11.0168, longitude: 76.9558),
    OfflineCity(name: 'Madurai', state: 'Tamil Nadu', latitude: 9.9252, longitude: 78.1198),
    OfflineCity(name: 'Tiruchirappalli', state: 'Tamil Nadu', latitude: 10.7905, longitude: 78.7047),
    OfflineCity(name: 'Salem', state: 'Tamil Nadu', latitude: 11.6643, longitude: 78.1460),
    OfflineCity(name: 'Tirunelveli', state: 'Tamil Nadu', latitude: 8.7139, longitude: 77.7567),
    OfflineCity(name: 'Vellore', state: 'Tamil Nadu', latitude: 12.9165, longitude: 79.1325),
    OfflineCity(name: 'Kochi', state: 'Kerala', latitude: 9.9312, longitude: 76.2673),
    OfflineCity(name: 'Thiruvananthapuram', state: 'Kerala', latitude: 8.5241, longitude: 76.9366),
    OfflineCity(name: 'Kozhikode', state: 'Kerala', latitude: 11.2588, longitude: 75.7804),
    OfflineCity(name: 'Thrissur', state: 'Kerala', latitude: 10.5276, longitude: 76.2144),
    OfflineCity(name: 'Kollam', state: 'Kerala', latitude: 8.8932, longitude: 76.6141),
    OfflineCity(name: 'Visakhapatnam', state: 'Andhra Pradesh', latitude: 17.6868, longitude: 83.2185),
    OfflineCity(name: 'Vijayawada', state: 'Andhra Pradesh', latitude: 16.5062, longitude: 80.6480),
    OfflineCity(name: 'Guntur', state: 'Andhra Pradesh', latitude: 16.3067, longitude: 80.4365),
    OfflineCity(name: 'Tirupati', state: 'Andhra Pradesh', latitude: 13.6288, longitude: 79.4192),
    OfflineCity(name: 'Kurnool', state: 'Andhra Pradesh', latitude: 15.8281, longitude: 78.0373),

    // --- East & North East ---
    OfflineCity(name: 'Kolkata', state: 'West Bengal', latitude: 22.5726, longitude: 88.3639),
    OfflineCity(name: 'Howrah', state: 'West Bengal', latitude: 22.5958, longitude: 88.2636),
    OfflineCity(name: 'Asansol', state: 'West Bengal', latitude: 23.6739, longitude: 86.9524),
    OfflineCity(name: 'Siliguri', state: 'West Bengal', latitude: 26.7271, longitude: 88.3953),
    OfflineCity(name: 'Durgapur', state: 'West Bengal', latitude: 23.5204, longitude: 87.3119),
    OfflineCity(name: 'Patna', state: 'Bihar', latitude: 25.5941, longitude: 85.1376),
    OfflineCity(name: 'Gaya', state: 'Bihar', latitude: 24.7914, longitude: 85.0002),
    OfflineCity(name: 'Muzaffarpur', state: 'Bihar', latitude: 26.1209, longitude: 85.3647),
    OfflineCity(name: 'Bhagalpur', state: 'Bihar', latitude: 25.2425, longitude: 86.9842),
    OfflineCity(name: 'Ranchi', state: 'Jharkhand', latitude: 23.3441, longitude: 85.3096),
    OfflineCity(name: 'Jamshedpur', state: 'Jharkhand', latitude: 22.8046, longitude: 86.2029),
    OfflineCity(name: 'Dhanbad', state: 'Jharkhand', latitude: 23.7957, longitude: 86.4304),
    OfflineCity(name: 'Bhubaneswar', state: 'Odisha', latitude: 20.2961, longitude: 85.8245),
    OfflineCity(name: 'Cuttack', state: 'Odisha', latitude: 20.4625, longitude: 85.8828),
    OfflineCity(name: 'Rourkela', state: 'Odisha', latitude: 22.2604, longitude: 84.8536),
    OfflineCity(name: 'Guwahati', state: 'Assam', latitude: 26.1445, longitude: 91.7362),
    OfflineCity(name: 'Dibrugarh', state: 'Assam', latitude: 27.4728, longitude: 94.9120),
    OfflineCity(name: 'Silchar', state: 'Assam', latitude: 24.8333, longitude: 92.7789),
    OfflineCity(name: 'Shillong', state: 'Meghalaya', latitude: 25.5788, longitude: 91.8933),
    OfflineCity(name: 'Imphal', state: 'Manipur', latitude: 24.8170, longitude: 93.9368),
    OfflineCity(name: 'Aizawl', state: 'Mizoram', latitude: 23.7271, longitude: 92.7176),
    OfflineCity(name: 'Agartala', state: 'Tripura', latitude: 23.8315, longitude: 91.2868),
    OfflineCity(name: 'Kohima', state: 'Nagaland', latitude: 25.6751, longitude: 94.1086),
    OfflineCity(name: 'Itanagar', state: 'Arunachal Pradesh', latitude: 27.0844, longitude: 93.6053),
    OfflineCity(name: 'Gangtok', state: 'Sikkim', latitude: 27.3389, longitude: 88.6065),

    // --- Central ---
    OfflineCity(name: 'Bhopal', state: 'Madhya Pradesh', latitude: 23.2599, longitude: 77.4126),
    OfflineCity(name: 'Indore', state: 'Madhya Pradesh', latitude: 22.7196, longitude: 75.8577),
    OfflineCity(name: 'Gwalior', state: 'Madhya Pradesh', latitude: 26.2183, longitude: 78.1828),
    OfflineCity(name: 'Jabalpur', state: 'Madhya Pradesh', latitude: 23.1815, longitude: 79.9864),
    OfflineCity(name: 'Ujjain', state: 'Madhya Pradesh', latitude: 23.1765, longitude: 75.7885),
    OfflineCity(name: 'Raipur', state: 'Chhattisgarh', latitude: 21.2514, longitude: 81.6296),
    OfflineCity(name: 'Bhilai', state: 'Chhattisgarh', latitude: 21.1938, longitude: 81.3509),
    OfflineCity(name: 'Bilaspur', state: 'Chhattisgarh', latitude: 22.0797, longitude: 82.1409),
  ];

  /// Finds the closest [OfflineCity] from the database for the given latitude and longitude.
  static NearestCityResult findNearest(double latitude, double longitude) {
    if (cities.isEmpty) {
      throw StateError('OfflineCityDatabase is empty');
    }

    OfflineCity? closestCity;
    double minDistance = double.infinity;

    for (final city in cities) {
      final dist = haversineDistanceKm(latitude, longitude, city.latitude, city.longitude);
      if (dist < minDistance) {
        minDistance = dist;
        closestCity = city;
      }
    }

    final nearest = closestCity!;
    final direction = calculateBearingDirection(nearest.latitude, nearest.longitude, latitude, longitude);

    return NearestCityResult(
      city: nearest,
      distanceKm: minDistance,
      compassDirection: direction,
    );
  }

  /// Calculates the great-circle distance between two points on the Earth in kilometers
  /// using the Haversine formula.
  static double haversineDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final rLat1 = _degreesToRadians(lat1);
    final rLat2 = _degreesToRadians(lat2);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) * math.sin(dLon / 2) * math.cos(rLat1) * math.cos(rLat2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  /// Calculates the 8-point compass bearing from origin (city) to destination (user coordinates).
  static String calculateBearingDirection(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final rLat1 = _degreesToRadians(lat1);
    final rLat2 = _degreesToRadians(lat2);
    final dLon = _degreesToRadians(lon2 - lon1);

    final y = math.sin(dLon) * math.cos(rLat2);
    final x = math.cos(rLat1) * math.sin(rLat2) -
        math.sin(rLat1) * math.cos(rLat2) * math.cos(dLon);

    final initialBearingRad = math.atan2(y, x);
    final bearingDeg = (_radiansToDegrees(initialBearingRad) + 360.0) % 360.0;

    if (bearingDeg >= 337.5 || bearingDeg < 22.5) {
      return 'North';
    } else if (bearingDeg >= 22.5 && bearingDeg < 67.5) {
      return 'North-East';
    } else if (bearingDeg >= 67.5 && bearingDeg < 112.5) {
      return 'East';
    } else if (bearingDeg >= 112.5 && bearingDeg < 157.5) {
      return 'South-East';
    } else if (bearingDeg >= 157.5 && bearingDeg < 202.5) {
      return 'South';
    } else if (bearingDeg >= 202.5 && bearingDeg < 247.5) {
      return 'South-West';
    } else if (bearingDeg >= 247.5 && bearingDeg < 292.5) {
      return 'West';
    } else {
      return 'North-West';
    }
  }

  static double _degreesToRadians(double degrees) => degrees * (math.pi / 180.0);
  static double _radiansToDegrees(double radians) => radians * (180.0 / math.pi);
}
