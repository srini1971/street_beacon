import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'street_beacon_method_channel.dart';

abstract class StreetBeaconPlatform extends PlatformInterface {
  /// Constructs a StreetBeaconPlatform.
  StreetBeaconPlatform() : super(token: _token);

  static final Object _token = Object();

  static StreetBeaconPlatform _instance = MethodChannelStreetBeacon();

  /// The default instance of [StreetBeaconPlatform] to use.
  ///
  /// Defaults to [MethodChannelStreetBeacon].
  static StreetBeaconPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [StreetBeaconPlatform] when
  /// they register themselves.
  static set instance(StreetBeaconPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Checks if the native platform has an active Geocoder service backend installed.
  ///
  /// On Android, this calls [android.location.Geocoder.isPresent].
  Future<bool> isGeocoderAvailable() {
    throw UnimplementedError('isGeocoderAvailable() has not been implemented.');
  }

  /// Sends coordinates to the native Android Geocoder for reverse-geocoding.
  ///
  /// Returns a Map of address fields or throws a [PlatformException].
  Future<Map<dynamic, dynamic>?> reverseGeocode({
    required double latitude,
    required double longitude,
    required String locale,
    required int maxResults,
    required int timeoutMs,
  }) {
    throw UnimplementedError('reverseGeocode() has not been implemented.');
  }
}
