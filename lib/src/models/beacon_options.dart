/// Configuration options for the [StreetBeacon] reverse-geocoding service.
class BeaconOptions {
  /// The preferred locale code for geocoding responses.
  /// Defaults to `en_IN` for Indian English address formatting.
  /// Can also be set to `hi_IN` (Hindi) or regional locales.
  final String locale;

  /// The maximum number of address candidates to request from the Geocoder.
  /// Defaults to 1 for immediate primary match.
  final int maxResults;

  /// Maximum duration to wait before timing out.
  ///
  /// In emergency or assistance scenarios, network data in India can often stall
  /// indefinitely. A strict timeout ensures the user gets fast feedback or drops
  /// into offline SMS fallback instead of spinning forever.
  /// Defaults to 8 seconds.
  final Duration timeout;

  /// Whether to automatically create an [OfflineBeacon] with coordinates,
  /// Plus Code, and SMS dispatch text if network or Geocoder fails.
  /// Defaults to `true`.
  final bool fallbackToOfflineOnFailure;

  /// Creates a [BeaconOptions] configuration.
  const BeaconOptions({
    this.locale = 'en_IN',
    this.maxResults = 1,
    this.timeout = const Duration(seconds: 8),
    this.fallbackToOfflineOnFailure = true,
  });

  /// Serializes options into a map for platform channel transfer.
  Map<String, dynamic> toMap() {
    return {
      'locale': locale,
      'maxResults': maxResults,
      'timeoutMs': timeout.inMilliseconds,
    };
  }
}
