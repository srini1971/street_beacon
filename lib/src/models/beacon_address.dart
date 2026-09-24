import '../offline/emergency_facilities.dart';
import '../offline/regional_language.dart';

/// Model representing a structured geographic address, specially designed
/// with first-class support for Indian postal addresses and emergency dispatch needs.
class BeaconAddress {
  /// The latitude of the location.
  final double latitude;

  /// The longitude of the location.
  final double longitude;

  /// The full, unparsed address line as provided by the underlying Geocoder.
  /// Example: "Shop 14, 100 Feet Rd, Indiranagar, Bengaluru, Karnataka 560038"
  final String? formattedAddress;

  /// Specific landmark, premise name, shop, or building number.
  /// In Indian addresses, this corresponds to building names, house numbers,
  /// or prominent landmarks (e.g., "Opposite Metro Pillar 120", "Apollo Hospital").
  final String? premise;

  /// The road, street, marg, or thoroughfare name.
  /// In India, examples include "MG Road", "Ring Road", "100 Feet Road", "5th Main".
  final String? road;

  /// Building or door number if explicitly segmented by the Geocoder.
  final String? subThoroughfare;

  /// The locality sub-division: Colony, Sector, Mohalla, Nagar, Layout, or Village.
  /// In India, this is a critical address tier (e.g., "Indiranagar", "Sector 62", "Bandra West").
  final String? colony;

  /// The city, town, or taluk (e.g., "Bengaluru", "Noida", "Mumbai", "Pune").
  final String? city;

  /// The district or administrative sub-division (e.g., "Bengaluru Urban", "Thane").
  final String? district;

  /// The State or Union Territory (e.g., "Karnataka", "Maharashtra", "Delhi").
  final String? state;

  /// The 6-digit Indian Postal Index Number (PIN Code). Example: "560038".
  final String? pincode;

  /// The country name (e.g., "India").
  final String? country;

  /// The two-letter ISO country code (e.g., "IN").
  final String? countryCode;

  /// The device battery level percentage (0 to 100) at the time the address was resolved.
  final int? batteryLevel;

  /// The timestamp when this address was resolved.
  final DateTime? timestamp;

  /// Creates a new [BeaconAddress] instance.
  const BeaconAddress({
    required this.latitude,
    required this.longitude,
    this.formattedAddress,
    this.premise,
    this.road,
    this.subThoroughfare,
    this.colony,
    this.city,
    this.district,
    this.state,
    this.pincode,
    this.country,
    this.countryCode,
    this.batteryLevel,
    this.timestamp,
  });

  /// The timestamp when the address was captured, defaulting to now if not specified.
  DateTime get resolvedTimestamp => timestamp ?? DateTime.now();

  /// Whether the phone battery is critically low (<= 15%).
  bool get isLowBattery => batteryLevel != null && batteryLevel! <= 15;

  /// Formats the [timestamp] into a human-readable Indian time string (e.g. "09:15 PM").
  String get formattedTime {
    final time = resolvedTimestamp;
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '${hour12.toString().padLeft(2, '0')}:$minute $ampm';
  }

  /// Creates a [BeaconAddress] from a raw Map returned by the native platform channel.
  factory BeaconAddress.fromMap(
    Map<dynamic, dynamic> map, {
    int? batteryLevel,
    DateTime? timestamp,
  }) {
    return BeaconAddress(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      formattedAddress: map['formattedAddress'] as String?,
      premise: map['featureName'] as String?,
      road: map['thoroughfare'] as String?,
      subThoroughfare: map['subThoroughfare'] as String?,
      colony: map['subLocality'] as String?,
      city: map['locality'] as String?,
      district: map['subAdminArea'] as String?,
      state: map['adminArea'] as String?,
      pincode: map['postalCode'] as String?,
      country: map['countryName'] as String?,
      countryCode: map['countryCode'] as String?,
      batteryLevel: batteryLevel,
      timestamp: timestamp,
    );
  }

  /// Converts this address into a Map representation.
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'formattedAddress': formattedAddress,
      'premise': premise,
      'road': road,
      'subThoroughfare': subThoroughfare,
      'colony': colony,
      'city': city,
      'district': district,
      'state': state,
      'pincode': pincode,
      'country': country,
      'countryCode': countryCode,
    };
  }

  /// Formats this location according to the standard **Indian Postal Address** hierarchy:
  ///
  /// `[Premise/Building], [Road/Marg], [Colony/Sector/Nagar], [City/District], [State] - [PIN Code]`
  ///
  /// Example:
  /// `"Near Metro Pillar 84, MG Road, Indiranagar, Bengaluru, Karnataka - 560038"`
  String toIndianFormattedAddress() {
    // Collect unique, non-empty components in logical hierarchy
    final List<String> parts = [];

    // 1. Building / Door / Premise / Landmark
    if (premise != null && premise!.trim().isNotEmpty) {
      parts.add(premise!.trim());
    }

    // 2. Road / Street
    if (road != null && road!.trim().isNotEmpty && road != premise) {
      parts.add(road!.trim());
    }

    // 3. Colony / Sector / Nagar / Village
    if (colony != null && colony!.trim().isNotEmpty && !parts.contains(colony)) {
      parts.add(colony!.trim());
    }

    // 4. City / Taluk
    if (city != null && city!.trim().isNotEmpty && !parts.contains(city)) {
      parts.add(city!.trim());
    } else if (district != null && district!.trim().isNotEmpty && !parts.contains(district)) {
      parts.add(district!.trim());
    }

    // 5. State with PIN Code (Standard Indian format: State - PIN)
    final statePart = StringBuffer();
    if (state != null && state!.trim().isNotEmpty) {
      statePart.write(state!.trim());
    }

    if (pincode != null && pincode!.trim().isNotEmpty) {
      if (statePart.isNotEmpty) {
        statePart.write(' - ');
      }
      statePart.write(pincode!.trim());
    }

    if (statePart.isNotEmpty) {
      parts.add(statePart.toString());
    }

    // If components were missing or empty, fall back to native formattedAddress
    if (parts.isEmpty && formattedAddress != null && formattedAddress!.isNotEmpty) {
      return formattedAddress!;
    }

    return parts.join(', ');
  }

  /// Generates an intuitive, spoken-word script specifically designed for reading
  /// aloud over a voice phone call to emergency dispatchers (112 / 108 / 100),
  /// roadside mechanics, or friends coming to assist.
  ///
  /// Example output:
  /// *"I am currently near Metro Pillar 84, on MG Road, in Indiranagar, Bengaluru, PIN code 5 6 0 0 3 8."*
  String toIndianDispatchSummary() {
    final buffer = StringBuffer('I am currently ');

    final hasPremise = premise != null && premise!.trim().isNotEmpty;
    final hasRoad = road != null && road!.trim().isNotEmpty && road != premise;
    final hasColony = colony != null && colony!.trim().isNotEmpty;
    final hasCity = city != null && city!.trim().isNotEmpty;

    if (hasPremise) {
      buffer.write('near $premise');
    }

    if (hasRoad) {
      if (hasPremise) buffer.write(', ');
      buffer.write('on $road');
    }

    if (hasColony) {
      if (hasPremise || hasRoad) buffer.write(', ');
      buffer.write('in $colony');
    }

    if (hasCity) {
      if (hasPremise || hasRoad || hasColony) buffer.write(', ');
      buffer.write(city);
    }

    // Spell out pincode with spaces so it is read clearly digit-by-digit
    if (pincode != null && pincode!.trim().isNotEmpty) {
      final spacedPin = pincode!.trim().split('').join(' ');
      buffer.write(', PIN code $spacedPin');
    }

    buffer.write('.');
    return buffer.toString();
  }

  /// The primary regional language detected from the resolved [state] name.
  IndianLanguage get regionalLanguage => IndianLanguage.fromState(state);

  /// Generates a compact, plain-text SMS message with an embedded Google Maps
  /// coordinates link.
  ///
  /// This is essential in Indian conditions where 4G/5G mobile internet drops,
  /// allowing the message to be dispatched instantly via standard 2G SMS.
  ///
  /// Example:
  /// `"NEED ASSISTANCE: Near Metro Pillar 84, MG Road, Indiranagar, Bengaluru - 560038. Map: https://maps.google.com/?q=12.9716,77.5946"`
  String toShareableSmsMessage({String? alertPrefix}) {
    final addressText = toIndianFormattedAddress();
    final mapsLink = 'https://maps.google.com/?q=${latitude.toStringAsFixed(5)},${longitude.toStringAsFixed(5)}';
    final prefix = alertPrefix ?? RegionalTranslations.getAlertPrefix(regionalLanguage);

    final telemetryBuffer = StringBuffer();
    if (batteryLevel != null) {
      final batteryStatus = isLowBattery ? 'Bat: $batteryLevel% [CRITICAL]' : 'Bat: $batteryLevel%';
      telemetryBuffer.write(' $batteryStatus.');
    }
    telemetryBuffer.write(' Time: $formattedTime.');

    return '$prefix: $addressText.${telemetryBuffer.toString()} Map: $mapsLink';
  }

  /// Generates a bilingual emergency SMS text explicitly composed with the regional script
  /// and English coordinate/map details.
  String toBilingualSmsMessage({IndianLanguage? overrideLanguage}) {
    final lang = overrideLanguage ?? regionalLanguage;
    final prefix = RegionalTranslations.getAlertPrefix(lang);
    return toShareableSmsMessage(alertPrefix: prefix);
  }

  /// Generates a standard `sms:` URI with pre-filled recipient and message body.
  ///
  /// Enables one-tap launching into the native SMS app for instant 2G dispatch.
  /// Example:
  /// `sms:112?body=NEED%20ASSISTANCE%3A...`
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
  Uri toEmergencyContactsSmsUri({
    required List<String> recipients,
    String? alertPrefix,
    IndianLanguage? overrideLanguage,
  }) {
    if (recipients.isEmpty) {
      throw ArgumentError('Recipients list must not be empty');
    }
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

  /// Generates a standard geo URI compatible with Android native map intents.
  /// Example: `geo:12.9716,77.5946?q=12.9716,77.5946(Current+Location)`
  Uri toGeoUri({String label = 'Current Location'}) {
    final encodedLabel = Uri.encodeComponent(label);
    return Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude($encodedLabel)');
  }

  /// Generates a universal Google Maps search URI to find nearby facilities
  /// (e.g. mechanics, puncture shops, hospitals, fuel/EV stations, or police stations).
  Uri toFacilitySearchUri(EmergencyFacility facility) {
    return FacilitySearchHelper.buildGoogleMapsSearchUri(
      latitude: latitude,
      longitude: longitude,
      facility: facility,
    );
  }

  /// Generates an emergency SMS customized specifically for a mechanic or roadside towing service.
  String toMechanicSmsMessage({String vehicleModel = ''}) {
    final mapsLink = 'https://maps.google.com/?q=${latitude.toStringAsFixed(5)},${longitude.toStringAsFixed(5)}';
    final vehicleDetails = vehicleModel.trim().isNotEmpty ? ' for $vehicleModel' : '';
    final addressText = toIndianFormattedAddress();

    return 'VEHICLE BREAKDOWN: Need towing/mechanic assistance$vehicleDetails. '
        'Location: $addressText. Map: $mapsLink';
  }

  @override
  String toString() => 'BeaconAddress(${toIndianFormattedAddress()})';
}
