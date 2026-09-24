# street_beacon

A Flutter plugin and Dart package that translates raw GPS coordinates into human-readable **Indian postal addresses**, **spoken dispatcher scripts** (for 112 / 108 / towing calls), and **offline 2G SMS beacons** when phone data drops.

Powered natively by Android's `android.location.Geocoder` with zero external cloud API keys required.

---

## 🌟 Why `street_beacon`?

When someone faces an unexpected situation—such as a car breakdown on a highway, getting disoriented in a new city, an elder wandering, or a medical crisis:
1. **Raw coordinates (`12.9716, 77.5946`) are meaningless** over a voice phone call to an emergency dispatcher or roadside mechanic.
2. **Indian addresses have a unique hierarchy**: They rely on landmarks, colony/sector names, road names, and 6-digit PIN codes rather than simple house numbers.
3. **Mobile data (4G/5G) is not guaranteed**: Data connectivity frequently fluctuates or drops on highways, ghat roads, or during network congestion.

`street_beacon` solves all three:
- 🇮🇳 **Indian Address Hierarchy**: Parses Premise/Landmark, Road/Marg, Colony/Sector, City, District, State, and PIN code.
- 🗣️ **Spoken Dispatch Scripts**: Produces natural sentences designed to be read out loud over the phone to 112 / 108 operators.
- 📶 **Network Resilience & 2G Offline SMS**: If internet fails or times out, it computes an offline **Plus Code (Open Location Code)** and formats a 160-character SMS with a Google Maps coordinate link.

---

## 🚀 Getting Started

Add `street_beacon` to your `pubspec.yaml`:

```yaml
dependencies:
  street_beacon:
    path: C:/street_beacon # or from pub.dev
```

### Android Configuration

Ensure your `android/app/src/main/AndroidManifest.xml` includes internet and location permissions:

```xml
<manifest ...>
    <!-- Required by Android Geocoder for backend address lookup -->
    <uses-permission android:name="android.permission.INTERNET" />
    
    <!-- Optional: If fetching device coordinates via Geolocator or Location -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
</manifest>
```

---

## 📖 Usage Examples

### 1. Reverse-Geocoding Coordinates to Indian Address

```dart
import 'package:street_beacon/street_beacon.dart';

void locateUser() async {
  final BeaconResult result = await StreetBeacon.reverseGeocode(
    12.9716,
    77.5946,
    options: const BeaconOptions(
      locale: 'en_IN',
      timeout: Duration(seconds: 6),
      fallbackToOfflineOnFailure: true,
    ),
  );

  if (result.isOnlineResolved && result.address != null) {
    // 1. Standard Indian Postal Address
    print(result.address!.toIndianFormattedAddress());
    // Output: "Near Metro Pillar 84, MG Road, Indiranagar, Bengaluru, Karnataka - 560038"

    // 2. Address breakdown components
    print('Premise: ${result.address!.premise}');
    print('Road: ${result.address!.road}');
    print('Colony/Sector: ${result.address!.colony}');
    print('City: ${result.address!.city}');
    print('PIN Code: ${result.address!.pincode}');
  }
}
```

---

### 2. Spoken Dialogue for Emergency Calls (112 / 108 / Roadside Towing)

When on the phone with a dispatcher, simply read out `toSpokenDispatchSummary()`:

```dart
final String script = await StreetBeacon.getIndianDispatchSummary(12.9716, 77.5946);
print(script);
// Output:
// "I am currently near Metro Pillar 84, on MG Road, in Indiranagar, Bengaluru, PIN code 5 6 0 0 3 8."
```

If the device is offline, it automatically switches to reading exact coordinates and bearing digit-by-digit:
```
"Emergency assistance needed. My coordinates are Latitude 12 point 9 7 1 6 North, Longitude 77 point 5 9 4 6 East. Plus code is 7 J 4 V X R F X plus 7 P."
```

---

### 3. Automatic Regional State Language & Bilingual 2G SMS

Automatically identifies the state (Karnataka -> Kannada, Tamil Nadu -> Tamil, Maharashtra -> Marathi, Delhi/UP -> Hindi, etc.) and formats a bilingual SMS:

```dart
final uri = await StreetBeacon.getEmergencySmsUri(
  12.9716,
  77.5946,
  batteryLevel: 8, // Optional: Device battery telemetry
);
// Launches native SMS app with pre-filled message:
// "ತುರ್ತು ಸಹಾಯ ಬೇಕಾಗಿದೆ (EMERGENCY ASSISTANCE): Location offline (in or near Bengaluru (Karnataka)). Coordinates: 12.97160, 77.59460. Plus Code: 7J4VXRFX+7P. Bat: 8% [CRITICAL]. Time: 09:15 PM. Map: https://maps.google.com/?q=12.97160,77.59460"
```

---

### 4. Family & Friends Emergency Contacts Broadcast

Broadcasts the exact GPS pin and map link to multiple family members or emergency contacts in 1 tap:

```dart
final groupSmsUri = await StreetBeacon.getEmergencyContactsSmsUri(
  12.9716,
  77.5946,
  recipients: ['+919876543210', '+919123456789', '112'],
  batteryLevel: 12,
);
// Launches native SMS app with all recipients pre-filled!
```

---

### 5. Nearby Emergency Facilities & Mechanic Search

Launches Google Maps filtered by nearest open facilities around the user's coordinates with zero paid API keys:

```dart
// 1. Search nearest mechanics, puncture shops, and towing cranes:
final mechanicSearchUri = await StreetBeacon.getNearbyFacilitySearchUri(
  12.9716, 
  77.5946, 
  EmergencyFacility.mechanic,
);

// 2. Search nearest hospitals, petrol pumps, or police stations:
final hospitalSearchUri = await StreetBeacon.getNearbyFacilitySearchUri(
  12.9716, 
  77.5946, 
  EmergencyFacility.hospital,
);

// 3. Generate ready-made breakdown text for mechanics:
final mechanicSms = await StreetBeacon.getMechanicSmsMessage(
  12.9716, 
  77.5946, 
  vehicleModel: 'Hyundai Creta',
);
```

---

### 6. Official Nationwide Indian Emergency Helplines (100% Offline)

Instant 1-tap phone dialer URIs for 24x7 government roadside assistance and emergency response:

```dart
// NHAI 24x7 Highway Roadside, Towing & Crane Assistance (National Highways)
final nhaiUri = StreetBeacon.getHelplineDialerUri(EmergencyHelpline.nhaiHighwayAssistance); // tel:1033

// Police & Unified Emergency Response
final policeUri = StreetBeacon.getHelplineDialerUri(EmergencyHelpline.unifiedEmergency); // tel:112

// Ambulance & Medical Emergency
final ambulanceUri = StreetBeacon.getHelplineDialerUri(EmergencyHelpline.ambulance); // tel:108
```

---

## 🏗️ Architecture & Android Native Layer

Under the hood, `street_beacon` interacts with Android's native `android.location.Geocoder`:
- **Thread Safety**: All network I/O is offloaded to a background thread pool, preventing ANR (Application Not Responding) UI freezes.
- **Main Thread Dispatch**: Results are returned on the Android Main UI thread via `Handler(Looper.getMainLooper())`.
- **Modern Android 13+ (API 33)**: Implements `Geocoder.GeocodeListener` for asynchronous non-blocking queries on modern Android versions, with seamless fallback for older devices.
- **Offline Math**: Plus Codes and Haversine distance calculations are computed via pure Dart algorithms locally on the device with zero internet traffic.

---

## 🧪 Testing

Run automated tests:

```bash
flutter test
```

Run linter:

```bash
flutter analyze
```

---

## 📄 License

MIT License.
