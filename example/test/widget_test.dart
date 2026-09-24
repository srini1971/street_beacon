import 'package:flutter_test/flutter_test.dart';
import 'package:street_beacon_example/main.dart';

void main() {
  testWidgets('Renders StreetBeaconExampleApp with title and inputs', (WidgetTester tester) async {
    // Build the example app and pump a frame
    await tester.pumpWidget(const StreetBeaconExampleApp());

    // Verify that the title and action button are rendered
    expect(find.text('Street Beacon'), findsOneWidget);
    expect(find.text('Generate Street Beacon'), findsOneWidget);
    expect(find.text('Sample Indian Scenarios:'), findsOneWidget);
  });
}
