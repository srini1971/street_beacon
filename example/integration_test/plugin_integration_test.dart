import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:street_beacon/street_beacon.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('isGeocoderAvailable test', (WidgetTester tester) async {
    // Tests that native Geocoder backend status can be queried without throwing
    final bool available = await StreetBeacon.isGeocoderAvailable();
    // Verify it returns a valid boolean value
    expect(available, isA<bool>());
  });
}
