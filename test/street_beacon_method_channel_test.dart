import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:street_beacon/street_beacon_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final MethodChannelStreetBeacon platform = MethodChannelStreetBeacon();
  const MethodChannel channel = MethodChannel('street_beacon');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'isGeocoderAvailable') {
          return true;
        } else if (methodCall.method == 'reverseGeocode') {
          return {
            'latitude': methodCall.arguments['latitude'],
            'longitude': methodCall.arguments['longitude'],
            'featureName': 'Metro Pillar 84',
            'thoroughfare': 'MG Road',
            'subLocality': 'Indiranagar',
            'locality': 'Bengaluru',
            'postalCode': '560038',
            'countryName': 'India',
          };
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('isGeocoderAvailable invokes method channel', () async {
    final available = await platform.isGeocoderAvailable();
    expect(available, isTrue);
  });

  test('reverseGeocode passes arguments and receives address map', () async {
    final result = await platform.reverseGeocode(
      latitude: 12.9716,
      longitude: 77.5946,
      locale: 'en_IN',
      maxResults: 1,
      timeoutMs: 5000,
    );

    expect(result, isNotNull);
    expect(result!['locality'], 'Bengaluru');
    expect(result['postalCode'], '560038');
  });
}
