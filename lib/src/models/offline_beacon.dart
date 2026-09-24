import '../offline/emergency_facilities.dart';
import '../offline/offline_cities.dart';
import '../offline/regional_language.dart';

/// Encapsulates location information when cellular data or the Android Geocoder
/// is unavailable (e.g., in rural areas, highways, tunnels, or during network failure).
///
/// Provides 100% offline utilities:
/// - Exact GPS coordinates formatting for emergency voice calls.
/// - Open Location Code (Plus Code) generation computed purely locally without internet.
/// - Standard 2G SMS emergency dispatch text with a direct Google Maps link.
class OfflineBeacon {
  /// The exact GPS latitude.
  final double latitude;

  /// The exact GPS longitude.
  final double longitude;

  /// The failure reason why online reverse geocoding could not complete.
  final String? failureReason;

  /// The device battery level percentage (0 to 100) at the moment the beacon was generated.
  /// Null if battery monitoring is not available or disabled.
  final int? batteryLevel;

  /// The exact timestamp when the beacon location was captured.
  final DateTime? timestamp;

  /// Creates an [OfflineBeacon].
  const OfflineBeacon({
    required this.latitude,
    required this.longitude,
    this.failureReason,
    this.batteryLevel,
    this.timestamp,
  });

  /// The timestamp when the beacon was captured, defaulting to now if not specified.
  DateTime get resolvedTimestamp => timestamp ?? DateTime.now();

  /// Whether the phone battery is dangerously low (<= 15%), signaling that
  /// responders or family must act urgently before the device powers off.
  bool get isLowBattery => batteryLevel != null && batteryLevel! <= 15;

  /// Computes a standard 10-character Open Location Code (Plus Code) completely offline.
  /// Plus Codes are short alphanumeric codes (like `7J4VXRFX+7P`) representing an area
  /// of about 14x14 meters. Responders in India can type this code directly into Google Maps
  /// or emergency consoles even without a named road.
  String get plusCode => _encodePlusCode(latitude, longitude);

  /// Finds the closest major Indian city/district center and direction completely offline.
  NearestCityResult get nearestCity => OfflineCityDatabase.findNearest(latitude, longitude);

  /// Automatically detects the regional language of the state in which the user is stranded.
  ///
  /// Examples:
  /// - Stranded in Bangalore / Mysuru -> [IndianLanguage.kannada]
  /// - Stranded in Chennai / Coimbatore -> [IndianLanguage.tamil]
  /// - Stranded in Mumbai / Pune -> [IndianLanguage.marathi]
  /// - Stranded in Hyderabad / Vijayawada -> [IndianLanguage.telugu]
  /// - Stranded in Delhi / Noida / Lucknow -> [IndianLanguage.hindi]
  IndianLanguage get regionalLanguage => nearestCity.city.regionalLanguage;

  /// Formats the [timestamp] into a human-readable Indian time string (e.g. "09:15 PM").
  String get formattedTime {
    final time = resolvedTimestamp;
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '${hour12.toString().padLeft(2, '0')}:$minute $ampm';
  }

  /// Generates an emergency SMS text optimized for 2G SMS networks with zero mobile data,
  /// formatted bilingually in the local state's regional language and English,
  /// including battery status and timestamp telemetry.
  ///
  /// Example when stranded near Bengaluru with low battery:
  /// `"ತುರ್ತು ಸಹಾಯ ಬೇಕಾಗಿದೆ (EMERGENCY ASSISTANCE): Location offline (approximately 18 km North-East of Bengaluru (Karnataka)). Coordinates: 12.97160, 77.59460. Plus Code: 7J4VXRFX+7P. Bat: 8% [CRITICAL]. Time: 09:15 PM. Map: https://maps.google.com/?q=12.97160,77.59460"`
  String toShareableSmsMessage({String? alertPrefix}) {
    final latStr = latitude.toStringAsFixed(5);
    final lngStr = longitude.toStringAsFixed(5);
    final mapsUrl = 'https://maps.google.com/?q=$latStr,$lngStr';
    final cityHint = 'Location offline (${nearestCity.toSpokenPhrase()})';
    final prefix = alertPrefix ?? RegionalTranslations.getAlertPrefix(regionalLanguage);

    final telemetryBuffer = StringBuffer();
    if (batteryLevel != null) {
      final batteryStatus = isLowBattery ? 'Bat: $batteryLevel% [CRITICAL]' : 'Bat: $batteryLevel%';
      telemetryBuffer.write(' $batteryStatus.');
    }
    telemetryBuffer.write(' Time: $formattedTime.');

    return '$prefix: $cityHint. Coordinates: $latStr, $lngStr. Plus Code: $plusCode.${telemetryBuffer.toString()} Map: $mapsUrl';
  }

  /// Generates a bilingual emergency SMS text explicitly composed with the regional script
  /// and English coordinate/map details.
  String toBilingualSmsMessage({IndianLanguage? overrideLanguage}) {
    final lang = overrideLanguage ?? regionalLanguage;
    final prefix = RegionalTranslations.getAlertPrefix(lang);
    return toShareableSmsMessage(alertPrefix: prefix);
  }

  /// Generates a standard `sms:` URI with pre-filled recipient and bilingual message body.
  ///
  /// Enables one-tap launching into the native SMS app (via url_launcher or native intent)
  /// for instantaneous 2G cellular SMS dispatch without requiring mobile data.
  ///
  /// Example:
  /// `sms:112?body=...`
  Uri toSmsUri({
    String recipient = '112',
    String? alertPrefix,
    IndianLanguage? overrideLanguage,
  }) {
    final lang = overrideLanguage ?? regionalLanguage;
    final prefix = alertPrefix ?? RegionalTranslations.getAlertPrefix(lang);
    final message = toShareableSmsMessage(alertPrefix: prefix);
    return Uri(
      scheme: 'sms',
      path: recipient,
      queryParameters: <String, String>{'body': message},
    );
  }

  /// Generates a group SMS URI to broadcast the emergency location and live map link
  /// directly to the user's emergency contacts list (family members, friends, or trusted guardians).
  ///
  /// Allows family and friends to receive the exact pinpoint GPS link and rush to help,
  /// completely over standard 2G SMS without requiring mobile internet.
  ///
  /// Multiple phone numbers are formatted with comma separation (compatible with Android and iOS group SMS).
  ///
  /// Example:
  /// ```dart
  /// final uri = beacon.toEmergencyContactsSmsUri(
  ///   recipients: ['+919876543210', '+919123456789', '112'],
  /// );
  /// ```
  Uri toEmergencyContactsSmsUri({
    required List<String> recipients,
    String? alertPrefix,
    IndianLanguage? overrideLanguage,
  }) {
    if (recipients.isEmpty) {
      throw ArgumentError('Recipients list must not be empty');
    }
    // Clean and join recipient numbers
    final sanitized = recipients.map((r) => r.trim()).where((r) => r.isNotEmpty).join(',');
    final lang = overrideLanguage ?? regionalLanguage;
    final prefix = alertPrefix ?? RegionalTranslations.getAlertPrefix(lang);
    final message = toShareableSmsMessage(alertPrefix: prefix);

    return Uri(
      scheme: 'sms',
      path: sanitized,
      queryParameters: <String, String>{'body': message},
    );
  }

  /// Generates a natural human script for speaking to emergency dispatchers (112 / 108).
  ///
  /// Designed to sound like what an actual person would say under stress, prioritizing
  /// the regional landmark and indicating that exact coordinates have been sent via SMS.
  ///
  /// Example:
  /// *"Emergency! I need assistance. I am located approximately 18 km North-East of Bengaluru (Karnataka). I have also sent my exact live map location to your control room by SMS."*
  String toSpokenDispatchSummary({bool mentionSmsSent = true}) {
    final locationPhrase = nearestCity.toSpokenPhrase();
    final batteryWarning = isLowBattery ? ' My phone battery is down to $batteryLevel% and may switch off soon.' : '';

    if (mentionSmsSent) {
      return 'Emergency! I need assistance. I am located $locationPhrase.$batteryWarning '
          'I have also sent my exact live map location to your control room by SMS.';
    } else {
      return 'Emergency! I need assistance. I am located $locationPhrase.$batteryWarning';
    }
  }

  /// Generates a localized spoken script in the regional language of the state
  /// where the user is stranded, enabling local police or 108 operators to understand instantly.
  ///
  /// Example for Karnataka:
  /// `"ತುರ್ತು ಸಹಾಯ ಬೇಕಾಗಿದೆ! ನಾನು Bengaluru ನಗರದಿಂದ ಸುಮಾರು 18 ಕಿ.ಮೀ North-East ಭಾಗದಲ್ಲಿದ್ದೇನೆ. ನಾನು SMS ಮೂಲಕ ಲೈವ್ ಮ್ಯಾಪ್ ಲೊಕೇಶನ್ ಕಳುಹಿಸಿದ್ದೇನೆ."`
  String toRegionalSpokenSummary({
    IndianLanguage? overrideLanguage,
    bool mentionSmsSent = true,
  }) {
    final lang = overrideLanguage ?? regionalLanguage;
    return RegionalTranslations.getSpokenPrompt(
      language: lang,
      cityName: nearestCity.city.name,
      distanceKm: nearestCity.distanceKm.round(),
      compassDirection: nearestCity.compassDirection,
      mentionSms: mentionSmsSent,
    );
  }

  /// Provides an English phonetic pronunciation guide of the regional language script,
  /// designed for travelers from other states who cannot read the native regional script.
  ///
  /// Example for a traveler in Karnataka:
  /// `"Thurtu sahaya bekagide! Naanu Bengaluru inda sumaaru 18 km North-East nalliddene."`
  String toRegionalPronunciationGuide({IndianLanguage? overrideLanguage}) {
    final lang = overrideLanguage ?? regionalLanguage;
    return RegionalTranslations.getPronunciationGuide(
      language: lang,
      cityName: nearestCity.city.name,
      distanceKm: nearestCity.distanceKm.round(),
      compassDirection: nearestCity.compassDirection,
    );
  }

  /// Generates a technical spoken-word script of exact GPS coordinates and Plus Code,
  /// formatted for when a dispatcher explicitly requests raw numerical coordinates.
  ///
  /// Example:
  /// *"Coordinates: Latitude 12.9716 North, Longitude 77.5946 East. Plus code: 7J4VXRFX+7P."*
  String toTechnicalSpokenCoordinates() {
    final latDir = latitude >= 0 ? 'North' : 'South';
    final lngDir = longitude >= 0 ? 'East' : 'West';
    final latStr = latitude.abs().toStringAsFixed(4);
    final lngStr = longitude.abs().toStringAsFixed(4);

    return 'Coordinates: Latitude $latStr $latDir, Longitude $lngStr $lngDir. '
        'Plus code: $plusCode.';
  }

  /// Generates a standard geo URI compatible with Android native map intents.
  Uri toGeoUri({String label = 'Offline Location'}) {
    final encodedLabel = Uri.encodeComponent(label);
    return Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude($encodedLabel)');
  }

  /// Generates a universal Google Maps search URI to find nearby facilities
  /// (e.g. mechanics, puncture shops, hospitals, fuel/EV stations, or police stations).
  ///
  /// Example:
  /// ```dart
  /// final uri = beacon.toFacilitySearchUri(EmergencyFacility.mechanic);
  /// ```
  Uri toFacilitySearchUri(EmergencyFacility facility) {
    return FacilitySearchHelper.buildGoogleMapsSearchUri(
      latitude: latitude,
      longitude: longitude,
      facility: facility,
    );
  }

  /// Generates an emergency SMS customized specifically for a mechanic or roadside towing service.
  ///
  /// Example:
  /// `"VEHICLE BREAKDOWN: Need towing/mechanic assistance. Location: Approximately 18 km North-East of Bengaluru (Karnataka). Coordinates: 12.97160, 77.59460. Map: https://maps.google.com/?q=12.97160,77.59460"`
  String toMechanicSmsMessage({String vehicleModel = ''}) {
    final latStr = latitude.toStringAsFixed(5);
    final lngStr = longitude.toStringAsFixed(5);
    final mapsUrl = 'https://maps.google.com/?q=$latStr,$lngStr';
    final vehicleDetails = vehicleModel.trim().isNotEmpty ? ' for $vehicleModel' : '';
    final locPhrase = nearestCity.toSpokenPhrase();

    return 'VEHICLE BREAKDOWN: Need towing/mechanic assistance$vehicleDetails. '
        'Location: $locPhrase. Coordinates: $latStr, $lngStr. Map: $mapsUrl';
  }

  // --- Offline Open Location Code (Plus Code) implementation ---
  // Standard Open Location Code base-20 alphabet (excluding easily confused chars like 1, l, 0, o)
  static const String _alphabet = '23456789CFGHJMPQRVWX';

  static String _encodePlusCode(double lat, double lng) {
    // Clamp latitude between -90 and 90
    var latitude = lat.clamp(-90.0, 90.0);
    // Normalize longitude between -180 and 180
    var longitude = lng;
    while (longitude < -180.0) {
      longitude += 360.0;
    }
    while (longitude >= 180.0) {
      longitude -= 360.0;
    }

    // Latitude 90 is handled by nudging slightly below
    if (latitude == 90.0) {
      latitude = 89.999999;
    }

    // Convert to positive coordinates (from 0 to 180 and 0 to 360)
    var latVal = latitude + 90.0;
    var lngVal = longitude + 180.0;

    final buffer = StringBuffer();

    // 5 pairs of coordinates for standard 10-digit code (resolution ~14 meters)
    double latGrid = 20.0;
    double lngGrid = 20.0;

    for (int i = 0; i < 5; i++) {
      if (i == 4) {
        buffer.write('+');
      }

      final latDigit = (latVal / latGrid).floor();
      final lngDigit = (lngVal / lngGrid).floor();

      buffer.write(_alphabet[latDigit.clamp(0, 19)]);
      buffer.write(_alphabet[lngDigit.clamp(0, 19)]);

      latVal -= latDigit * latGrid;
      lngVal -= lngDigit * lngGrid;

      latGrid /= 20.0;
      lngGrid /= 20.0;
    }

    return buffer.toString();
  }

  @override
  String toString() => 'OfflineBeacon($latitude, $longitude, plusCode: $plusCode)';
}
