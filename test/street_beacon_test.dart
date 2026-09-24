import 'package:flutter_test/flutter_test.dart';
import 'package:street_beacon/street_beacon.dart';
import 'package:street_beacon/street_beacon_platform_interface.dart';
import 'package:street_beacon/street_beacon_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockStreetBeaconPlatform
    with MockPlatformInterfaceMixin
    implements StreetBeaconPlatform {
  bool mockIsAvailable = true;
  Map<dynamic, dynamic>? mockAddressData;
  Exception? errorToThrow;

  @override
  Future<bool> isGeocoderAvailable() {
    if (errorToThrow != null) throw errorToThrow!;
    return Future.value(mockIsAvailable);
  }

  @override
  Future<Map<dynamic, dynamic>?> reverseGeocode({
    required double latitude,
    required double longitude,
    required String locale,
    required int maxResults,
    required int timeoutMs,
  }) {
    if (errorToThrow != null) throw errorToThrow!;
    return Future.value(mockAddressData);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final StreetBeaconPlatform initialPlatform = StreetBeaconPlatform.instance;

  test('Default platform instance is MethodChannelStreetBeacon', () {
    expect(initialPlatform, isInstanceOf<MethodChannelStreetBeacon>());
  });

  group('BeaconAddress - Indian Postal Address Formatting', () {
    test('Formats full Indian address correctly with hierarchy', () {
      const address = BeaconAddress(
        latitude: 12.9716,
        longitude: 77.5946,
        premise: 'Near Metro Pillar 84',
        road: 'MG Road',
        colony: 'Indiranagar',
        city: 'Bengaluru',
        district: 'Bengaluru Urban',
        state: 'Karnataka',
        pincode: '560038',
        country: 'India',
        countryCode: 'IN',
      );

      final formatted = address.toIndianFormattedAddress();
      expect(
        formatted,
        'Near Metro Pillar 84, MG Road, Indiranagar, Bengaluru, Karnataka - 560038',
      );
    });

    test('Omits missing components without dangling punctuation', () {
      const address = BeaconAddress(
        latitude: 28.6139,
        longitude: 77.2090,
        road: 'Barakhamba Road',
        colony: 'Connaught Place',
        city: 'New Delhi',
        state: 'Delhi',
        pincode: '110001',
      );

      final formatted = address.toIndianFormattedAddress();
      expect(formatted, 'Barakhamba Road, Connaught Place, New Delhi, Delhi - 110001');
    });

    test('Generates spoken dialogue for emergency phone calls (112/108)', () {
      const address = BeaconAddress(
        latitude: 12.9716,
        longitude: 77.5946,
        premise: 'Metro Pillar 84',
        road: 'MG Road',
        colony: 'Indiranagar',
        city: 'Bengaluru',
        pincode: '560038',
      );

      final spoken = address.toIndianDispatchSummary();
      expect(
        spoken,
        'I am currently near Metro Pillar 84, on MG Road, in Indiranagar, Bengaluru, PIN code 5 6 0 0 3 8.',
      );
    });

    test('Generates compact SMS text with Google Maps link', () {
      const address = BeaconAddress(
        latitude: 12.9716,
        longitude: 77.5946,
        road: 'MG Road',
        colony: 'Indiranagar',
        city: 'Bengaluru',
        state: 'Karnataka',
        pincode: '560038',
      );

      final sms = address.toShareableSmsMessage();
      expect(sms, contains('ತುರ್ತು ಸಹಾಯ ಬೇಕಾಗಿದೆ (EMERGENCY ASSISTANCE)'));
      expect(sms, contains('MG Road, Indiranagar, Bengaluru'));
      expect(sms, contains('https://maps.google.com/?q=12.97160,77.59460'));

      // With custom alertPrefix
      final customSms = address.toShareableSmsMessage(alertPrefix: 'CUSTOM ALERT');
      expect(customSms, contains('CUSTOM ALERT: MG Road, Indiranagar, Bengaluru'));
    });
  });

  group('OfflineBeacon - 100% Offline Resilience for Low Network Areas', () {
    test('Computes Open Location Code (Plus Code) offline without internet', () {
      // Coordinates for Bangalore MG Road area
      const offline = OfflineBeacon(latitude: 12.9716, longitude: 77.5946);
      final code = offline.plusCode;

      // Plus Code should be 10 alphanumeric chars with '+' at position 8
      expect(code.length, 11);
      expect(code.contains('+'), isTrue);
      expect(code[8], '+');
    });

    test('Finds nearest major city and cardinal direction offline', () {
      // Coordinates approx 20 km North-East of Bengaluru center
      const offline = OfflineBeacon(latitude: 13.1000, longitude: 77.7000);
      final nearest = offline.nearestCity;

      expect(nearest.city.name, 'Bengaluru');
      expect(nearest.city.state, 'Karnataka');
      expect(nearest.distanceKm, greaterThan(10));
      expect(nearest.compassDirection, 'North-East');
    });

    test('Generates natural human spoken summary for emergency calls', () {
      const offline = OfflineBeacon(latitude: 12.9716, longitude: 77.5946);
      final spoken = offline.toSpokenDispatchSummary();

      expect(spoken, contains('Emergency! I need assistance'));
      expect(spoken, contains('Bengaluru'));
      expect(spoken, contains('Karnataka'));
      expect(spoken, contains('sent my exact live map location to your control room by SMS'));

      // When SMS mention is disabled
      final withoutSms = offline.toSpokenDispatchSummary(mentionSmsSent: false);
      expect(withoutSms, isNot(contains('SMS')));
      expect(withoutSms, contains('Bengaluru'));
    });

    test('Generates technical spoken coordinates when explicitly requested', () {
      const offline = OfflineBeacon(latitude: 12.9716, longitude: 77.5946);
      final tech = offline.toTechnicalSpokenCoordinates();

      expect(tech, contains('Coordinates: Latitude 12.9716 North, Longitude 77.5946 East'));
      expect(tech, contains('Plus code:'));
    });

    test('Automatically identifies regional state language from coordinates', () {
      // Bangalore -> Karnataka -> Kannada
      const blr = OfflineBeacon(latitude: 12.9716, longitude: 77.5946);
      expect(blr.regionalLanguage, IndianLanguage.kannada);

      // Chennai -> Tamil Nadu -> Tamil
      const chennai = OfflineBeacon(latitude: 13.0827, longitude: 80.2707);
      expect(chennai.regionalLanguage, IndianLanguage.tamil);

      // Mumbai -> Maharashtra -> Marathi
      const mumbai = OfflineBeacon(latitude: 19.0760, longitude: 72.8777);
      expect(mumbai.regionalLanguage, IndianLanguage.marathi);

      // Delhi -> Delhi -> Hindi
      const delhi = OfflineBeacon(latitude: 28.6139, longitude: 77.2090);
      expect(delhi.regionalLanguage, IndianLanguage.hindi);
    });

    test('Generates localized regional spoken summary and English pronunciation guide', () {
      // In Bangalore: should output Kannada text and English phonetic guide
      const offline = OfflineBeacon(latitude: 12.9716, longitude: 77.5946);
      final regionalPrompt = offline.toRegionalSpokenSummary();

      expect(regionalPrompt, contains('ತುರ್ತು ಸಹಾಯ ಬೇಕಾಗಿದೆ'));
      expect(regionalPrompt, contains('Bengaluru'));

      final pronunciationGuide = offline.toRegionalPronunciationGuide();
      expect(pronunciationGuide, contains('Thurtu sahaya bekagide'));
      expect(pronunciationGuide, contains('Bengaluru'));
    });

    test('Generates bilingual regional SMS text and clickable SMS URI for 2G network', () {
      const offline = OfflineBeacon(latitude: 12.9716, longitude: 77.5946);
      final sms = offline.toShareableSmsMessage();

      // Automatically contains Kannada prefix + English text
      expect(sms, contains('ತುರ್ತು ಸಹಾಯ ಬೇಕಾಗಿದೆ (EMERGENCY ASSISTANCE)'));
      expect(sms, contains('Location offline'));
      expect(sms, contains('Bengaluru'));
      expect(sms, contains('Coordinates: 12.97160, 77.59460'));
      expect(sms, contains('Plus Code:'));

      final uri = offline.toSmsUri(recipient: '112');
      expect(uri.scheme, 'sms');
      expect(uri.path, '112');
      expect(uri.queryParameters['body'], contains('ತುರ್ತು ಸಹಾಯ ಬೇಕಾಗಿದೆ'));
    });

    test('Generates group SMS URI for emergency contacts list (family & friends broadcast)', () {
      const offline = OfflineBeacon(latitude: 12.9716, longitude: 77.5946);
      final emergencyContacts = ['+919876543210', '+919123456789', '+919845012345'];

      final groupSmsUri = offline.toEmergencyContactsSmsUri(recipients: emergencyContacts);

      expect(groupSmsUri.scheme, 'sms');
      expect(groupSmsUri.path, '+919876543210,+919123456789,+919845012345');
      expect(groupSmsUri.queryParameters['body'], contains('ತುರ್ತು ಸಹಾಯ ಬೇಕಾಗಿದೆ'));
      expect(groupSmsUri.queryParameters['body'], contains('https://maps.google.com/?q=12.97160,77.59460'));
    });

    test('Embeds Battery Level & Timestamp telemetry in SMS and spoken scripts', () {
      final fixedTime = DateTime(2026, 9, 23, 21, 15); // 09:15 PM
      final offlineLowBat = OfflineBeacon(
        latitude: 12.9716,
        longitude: 77.5946,
        batteryLevel: 8,
        timestamp: fixedTime,
      );

      expect(offlineLowBat.isLowBattery, isTrue);
      expect(offlineLowBat.formattedTime, '09:15 PM');

      final sms = offlineLowBat.toShareableSmsMessage();
      expect(sms, contains('Bat: 8% [CRITICAL]'));
      expect(sms, contains('Time: 09:15 PM'));

      final spoken = offlineLowBat.toSpokenDispatchSummary();
      expect(spoken, contains('battery is down to 8%'));

      // Regular battery level (not low)
      final offlineNormalBat = OfflineBeacon(
        latitude: 12.9716,
        longitude: 77.5946,
        batteryLevel: 65,
        timestamp: fixedTime,
      );
      expect(offlineNormalBat.isLowBattery, isFalse);
      expect(offlineNormalBat.toShareableSmsMessage(), contains('Bat: 65%. Time: 09:15 PM.'));
    });

    test('Generates nearby facility search URIs and mechanic breakdown SMS', () {
      const offline = OfflineBeacon(latitude: 12.9716, longitude: 77.5946);

      // Mechanic search URI
      final mechanicUri = offline.toFacilitySearchUri(EmergencyFacility.mechanic);
      expect(mechanicUri.scheme, 'https');
      expect(mechanicUri.host, 'www.google.com');
      expect(mechanicUri.path, contains('maps/search'));
      expect(mechanicUri.path, contains('mechanic'));

      // Hospital search URI
      final hospitalUri = offline.toFacilitySearchUri(EmergencyFacility.hospital);
      expect(hospitalUri.path, contains('hospital'));

      // Customized breakdown SMS for mechanic
      final mechanicSms = offline.toMechanicSmsMessage(vehicleModel: 'Hyundai Creta (KA03XX1234)');
      expect(mechanicSms, contains('VEHICLE BREAKDOWN: Need towing/mechanic assistance for Hyundai Creta'));
      expect(mechanicSms, contains('https://maps.google.com/?q=12.97160,77.59460'));

      // Official Indian helpline dialers
      final nhaiUri = EmergencyHelpline.nhaiHighwayAssistance.toDialerUri();
      expect(nhaiUri.toString(), 'tel:1033');

      final emergencyUri = EmergencyHelpline.unifiedEmergency.toDialerUri();
      expect(emergencyUri.toString(), 'tel:112');
    });
  });

  group('StreetBeacon API with MockPlatform', () {
    late MockStreetBeaconPlatform fakePlatform;

    setUp(() {
      fakePlatform = MockStreetBeaconPlatform();
      StreetBeaconPlatform.instance = fakePlatform;
    });

    test('isGeocoderAvailable returns platform value', () async {
      fakePlatform.mockIsAvailable = true;
      expect(await StreetBeacon.isGeocoderAvailable(), isTrue);

      fakePlatform.mockIsAvailable = false;
      expect(await StreetBeacon.isGeocoderAvailable(), isFalse);
    });

    test('reverseGeocode returns online BeaconResult when successful', () async {
      fakePlatform.mockAddressData = {
        'latitude': 12.9716,
        'longitude': 77.5946,
        'formattedAddress': 'MG Road, Bengaluru',
        'featureName': 'Opp Metro',
        'thoroughfare': 'MG Road',
        'subLocality': 'Shivaji Nagar',
        'locality': 'Bengaluru',
        'adminArea': 'Karnataka',
        'postalCode': '560001',
        'countryName': 'India',
        'countryCode': 'IN',
      };

      final result = await StreetBeacon.reverseGeocode(12.9716, 77.5946);

      expect(result.isOnlineResolved, isTrue);
      expect(result.address, isNotNull);
      expect(result.address!.city, 'Bengaluru');
      expect(result.address!.pincode, '560001');
      expect(result.toSpokenDispatchSummary(), contains('Opp Metro'));
    });

    test('reverseGeocode falls back to OfflineBeacon when platform fails', () async {
      fakePlatform.errorToThrow = Exception('Network connection failed');

      final result = await StreetBeacon.reverseGeocode(
        12.9716,
        77.5946,
        options: const BeaconOptions(fallbackToOfflineOnFailure: true),
      );

      expect(result.isOnlineResolved, isFalse);
      expect(result.offlineBeacon, isNotNull);
      expect(result.offlineBeacon!.latitude, 12.9716);
      expect(result.offlineBeacon!.plusCode, isNotEmpty);
      expect(result.toShareableSmsMessage(), contains('https://maps.google.com/?q=12.97160,77.59460'));
    });

    test('Validates coordinate range and throws ArgumentError', () {
      expect(
        () => StreetBeacon.reverseGeocode(95.0, 77.0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => StreetBeacon.reverseGeocode(12.0, 190.0),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
