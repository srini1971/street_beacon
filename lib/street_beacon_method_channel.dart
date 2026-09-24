import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'street_beacon_platform_interface.dart';

/// An implementation of [StreetBeaconPlatform] that uses method channels.
class MethodChannelStreetBeacon extends StreetBeaconPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('street_beacon');

  @override
  Future<bool> isGeocoderAvailable() async {
    // Invokes native method 'isGeocoderAvailable'
    final available = await methodChannel.invokeMethod<bool>('isGeocoderAvailable');
    return available ?? false;
  }

  @override
  Future<Map<dynamic, dynamic>?> reverseGeocode({
    required double latitude,
    required double longitude,
    required String locale,
    required int maxResults,
    required int timeoutMs,
  }) async {
    // Passes coordinate arguments and configuration parameters to the native host
    final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
      'reverseGeocode',
      <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        'locale': locale,
        'maxResults': maxResults,
        'timeoutMs': timeoutMs,
      },
    );
    return result;
  }
}
