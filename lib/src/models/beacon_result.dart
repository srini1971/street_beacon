import '../offline/emergency_facilities.dart';
import '../offline/regional_language.dart';
import 'beacon_address.dart';
import 'offline_beacon.dart';

/// The result of a [StreetBeacon.reverseGeocode] operation.
///
/// Handles both successful online geocoding ([address] is non-null)
/// and graceful offline fallback ([offlineBeacon] is non-null) when
/// mobile data is interrupted or unavailable.
class BeaconResult {
  /// The reverse-geocoded address when online geocoding succeeds.
  final BeaconAddress? address;

  /// The offline beacon containing raw coordinates and Plus Code
  /// when online geocoding is unavailable or times out.
  final OfflineBeacon? offlineBeacon;

  /// Whether the location was successfully resolved via the Geocoder service.
  final bool isOnlineResolved;

  /// Error message or warning if online geocoding could not complete.
  final String? errorMessage;

  /// Creates a successful online [BeaconResult].
  const BeaconResult.online(BeaconAddress this.address)
      : offlineBeacon = null,
        isOnlineResolved = true,
        errorMessage = null;

  /// Creates an offline fallback [BeaconResult].
  const BeaconResult.offline(
    OfflineBeacon this.offlineBeacon, {
    this.errorMessage,
  })  : address = null,
        isOnlineResolved = false;

  /// Returns a spoken-word script suitable for reading aloud to an emergency
  /// dispatcher or helper over a phone call.
  /// Returns a spoken-word script suitable for reading aloud to an emergency
  /// dispatcher or helper over a phone call.
  ///
  /// Automatically uses the Indian street address if online, or falls back to
  /// natural regional landmark description and SMS confirmation if offline.
  String toSpokenDispatchSummary({bool mentionSmsSent = true}) {
    if (isOnlineResolved && address != null) {
      return address!.toIndianDispatchSummary();
    } else if (offlineBeacon != null) {
      return offlineBeacon!.toSpokenDispatchSummary(mentionSmsSent: mentionSmsSent);
    }
    return 'Location unavailable.';
  }

  /// Device battery percentage (0 to 100) if provided, or null if unmonitored.
  int? get batteryLevel => address?.batteryLevel ?? offlineBeacon?.batteryLevel;

  /// Timestamp when this beacon result was created.
  DateTime get timestamp => address?.timestamp ?? offlineBeacon?.timestamp ?? DateTime.now();

  /// Whether the device battery is critically low (<= 15%).
  bool get isLowBattery => batteryLevel != null && batteryLevel! <= 15;

  /// Returns technical spoken coordinates if offline (or coordinate string if online),
  /// for situations where a dispatcher explicitly requests raw numerical coordinates.
  String toTechnicalSpokenCoordinates() {
    if (offlineBeacon != null) {
      return offlineBeacon!.toTechnicalSpokenCoordinates();
    } else if (address != null) {
      return 'Coordinates: Latitude ${address!.latitude.toStringAsFixed(4)}, Longitude ${address!.longitude.toStringAsFixed(4)}.';
    }
    return 'Coordinates unavailable.';
  }

  /// The primary regional language of the location (detected from address state when online,
  /// or from nearest city state when offline).
  IndianLanguage get regionalLanguage {
    if (isOnlineResolved && address != null) {
      return address!.regionalLanguage;
    } else if (offlineBeacon != null) {
      return offlineBeacon!.regionalLanguage;
    }
    return IndianLanguage.english;
  }

  /// Generates a localized spoken script in the regional language of the state
  /// where the user is stranded, enabling local police or 108 operators to understand instantly.
  String toRegionalSpokenSummary({
    IndianLanguage? overrideLanguage,
    bool mentionSmsSent = true,
  }) {
    if (offlineBeacon != null) {
      return offlineBeacon!.toRegionalSpokenSummary(
        overrideLanguage: overrideLanguage,
        mentionSmsSent: mentionSmsSent,
      );
    } else if (address != null) {
      // In online mode, the Indian formatted address already contains the local terms
      return address!.toIndianDispatchSummary();
    }
    return 'Location unavailable.';
  }

  /// Provides an English phonetic pronunciation guide of the regional language script,
  /// designed for travelers from other states who cannot read the native regional script.
  String toRegionalPronunciationGuide({IndianLanguage? overrideLanguage}) {
    if (offlineBeacon != null) {
      return offlineBeacon!.toRegionalPronunciationGuide(overrideLanguage: overrideLanguage);
    }
    return '';
  }

  /// Returns an SMS-ready message with a Google Maps coordinate link.
  ///
  /// Defaults to a bilingual alert in the local regional language + English.
  String toShareableSmsMessage({String? alertPrefix}) {
    if (isOnlineResolved && address != null) {
      return address!.toShareableSmsMessage(alertPrefix: alertPrefix);
    } else if (offlineBeacon != null) {
      return offlineBeacon!.toShareableSmsMessage(alertPrefix: alertPrefix);
    }
    return '${alertPrefix ?? 'EMERGENCY'}: Coordinates unavailable.';
  }

  /// Generates a bilingual emergency SMS text explicitly composed with the regional script
  /// and English coordinate/map details.
  String toBilingualSmsMessage({IndianLanguage? overrideLanguage}) {
    final lang = overrideLanguage ?? regionalLanguage;
    final prefix = RegionalTranslations.getAlertPrefix(lang);
    return toShareableSmsMessage(alertPrefix: prefix);
  }

  /// Generates a standard `sms:` URI for native one-tap SMS launching.
  ///
  /// Pre-fills the recipient (defaulting to 112) and the message body with
  /// bilingual alert, coordinates, nearest landmark/city, and a Google Maps link.
  Uri toSmsUri({
    String recipient = '112',
    String? alertPrefix,
    IndianLanguage? overrideLanguage,
  }) {
    if (isOnlineResolved && address != null) {
      return address!.toSmsUri(
        recipient: recipient,
        alertPrefix: alertPrefix,
        overrideLanguage: overrideLanguage,
      );
    } else if (offlineBeacon != null) {
      return offlineBeacon!.toSmsUri(
        recipient: recipient,
        alertPrefix: alertPrefix,
        overrideLanguage: overrideLanguage,
      );
    }
    return Uri(
      scheme: 'sms',
      path: recipient,
      queryParameters: <String, String>{'body': 'EMERGENCY: Coordinates unavailable.'},
    );
  }

  /// Generates a group SMS URI to broadcast the emergency location and live map link
  /// directly to the user's emergency contacts list (family members, friends, or trusted guardians).
  Uri toEmergencyContactsSmsUri({
    required List<String> recipients,
    String? alertPrefix,
    IndianLanguage? overrideLanguage,
  }) {
    if (isOnlineResolved && address != null) {
      return address!.toEmergencyContactsSmsUri(
        recipients: recipients,
        alertPrefix: alertPrefix,
        overrideLanguage: overrideLanguage,
      );
    } else if (offlineBeacon != null) {
      return offlineBeacon!.toEmergencyContactsSmsUri(
        recipients: recipients,
        alertPrefix: alertPrefix,
        overrideLanguage: overrideLanguage,
      );
    }
    final sanitized = recipients.join(',');
    return Uri(
      scheme: 'sms',
      path: sanitized,
      queryParameters: <String, String>{'body': 'EMERGENCY: Coordinates unavailable.'},
    );
  }

  /// Generates a universal Google Maps search URI to find nearby facilities
  /// (mechanics, puncture shops, hospitals, fuel/EV stations, or police stations).
  Uri? toFacilitySearchUri(EmergencyFacility facility) {
    if (isOnlineResolved && address != null) {
      return address!.toFacilitySearchUri(facility);
    } else if (offlineBeacon != null) {
      return offlineBeacon!.toFacilitySearchUri(facility);
    }
    return null;
  }

  /// Generates an emergency SMS customized specifically for a mechanic or roadside towing service.
  String toMechanicSmsMessage({String vehicleModel = ''}) {
    if (isOnlineResolved && address != null) {
      return address!.toMechanicSmsMessage(vehicleModel: vehicleModel);
    } else if (offlineBeacon != null) {
      return offlineBeacon!.toMechanicSmsMessage(vehicleModel: vehicleModel);
    }
    return 'VEHICLE BREAKDOWN: Need assistance. Location unavailable.';
  }

  /// Returns the human-readable physical address, or coordinate text if offline.
  String toReadableText() {
    if (isOnlineResolved && address != null) {
      return address!.toIndianFormattedAddress();
    } else if (offlineBeacon != null) {
      return 'GPS: ${offlineBeacon!.latitude.toStringAsFixed(5)}, ${offlineBeacon!.longitude.toStringAsFixed(5)} (Plus Code: ${offlineBeacon!.plusCode})';
    }
    return 'Unknown location';
  }

  @override
  String toString() {
    if (isOnlineResolved) {
      return 'BeaconResult.online($address)';
    } else {
      return 'BeaconResult.offline($offlineBeacon, error: $errorMessage)';
    }
  }
}
