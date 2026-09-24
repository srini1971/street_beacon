import 'dart:async';
import 'package:flutter/services.dart';

import 'src/models/beacon_address.dart';
import 'src/models/beacon_options.dart';
import 'src/models/beacon_result.dart';
import 'src/models/offline_beacon.dart';
import 'src/offline/emergency_facilities.dart';
import 'src/offline/regional_language.dart';
import 'street_beacon_platform_interface.dart';

export 'src/models/beacon_address.dart';
export 'src/models/beacon_options.dart';
export 'src/models/beacon_result.dart';
export 'src/models/offline_beacon.dart';
export 'src/offline/emergency_facilities.dart';
export 'src/offline/offline_cities.dart';
export 'src/offline/regional_language.dart';

/// The primary interface for the `street_beacon` plugin.
///
/// Converts raw GPS coordinates into human-readable Indian postal addresses,
/// spoken dispatcher summaries for 112/108 calls, and offline SMS emergency beacons
/// when mobile networks are down.
class StreetBeacon {
  // Private constructor to prevent direct instantiation
  StreetBeacon._();

  /// Checks if the native host device has a functional Geocoder backend service installed.
  ///
  /// On Android, this wraps [android.location.Geocoder.isPresent].
  /// Returns `true` if geocoding services (like Google Play Services or OEM providers)
  /// are present on the device.
  static Future<bool> isGeocoderAvailable() async {
    try {
      return await StreetBeaconPlatform.instance.isGeocoderAvailable();
    } catch (e) {
      // If the platform interface fails or throws, treat as unavailable
      return false;
    }
  }

  /// Reverse-geocodes the given [latitude] and [longitude] into a structured [BeaconResult].
  ///
  /// Features:
  /// - Supports Indian address hierarchy (Premise, Road, Colony/Sector, City, State, PIN).
  /// - Respects [options.timeout] so poor 2G/3G/4G connections do not hang your UI.
  /// - Automatically falls back to an [OfflineBeacon] with coordinates, offline Plus Code,
  ///   and 2G SMS dispatch text if cellular data fails or times out.
  ///
  /// Example:
  /// ```dart
  /// final result = await StreetBeacon.reverseGeocode(12.9716, 77.5946);
  /// if (result.isOnlineResolved) {
  ///   print('Address: ${result.address!.toIndianFormattedAddress()}');
  ///   print('Spoken: ${result.toSpokenDispatchSummary()}');
  /// } else {
  ///   print('Offline SMS: ${result.toShareableSmsMessage()}');
  /// }
  /// ```
  static Future<BeaconResult> reverseGeocode(
    double latitude,
    double longitude, {
    int? batteryLevel,
    DateTime? timestamp,
    BeaconOptions options = const BeaconOptions(),
  }) async {
    // Validate latitude (-90 to +90) and longitude (-180 to +180)
    if (latitude < -90.0 || latitude > 90.0) {
      throw ArgumentError('Latitude must be between -90 and 90. Received: $latitude');
    }
    if (longitude < -180.0 || longitude > 180.0) {
      throw ArgumentError('Longitude must be between -180 and 180. Received: $longitude');
    }

    final capturedTime = timestamp ?? DateTime.now();

    try {
      // Invoke native platform channel with timeout protection
      final rawData = await StreetBeaconPlatform.instance
          .reverseGeocode(
            latitude: latitude,
            longitude: longitude,
            locale: options.locale,
            maxResults: options.maxResults,
            timeoutMs: options.timeout.inMilliseconds,
          )
          .timeout(options.timeout);

      if (rawData != null && rawData.isNotEmpty) {
        final address = BeaconAddress.fromMap(
          rawData,
          batteryLevel: batteryLevel,
          timestamp: capturedTime,
        );
        return BeaconResult.online(address);
      } else {
        // Empty response from Geocoder
        if (options.fallbackToOfflineOnFailure) {
          return BeaconResult.offline(
            OfflineBeacon(
              latitude: latitude,
              longitude: longitude,
              failureReason: 'Geocoder returned no matching address',
              batteryLevel: batteryLevel,
              timestamp: capturedTime,
            ),
            errorMessage: 'No address matches found for coordinates.',
          );
        } else {
          throw const FormatException('No address could be found for the given coordinates.');
        }
      }
    } on TimeoutException catch (e) {
      // Network stalled or timed out (common in Indian transit areas)
      if (options.fallbackToOfflineOnFailure) {
        return BeaconResult.offline(
          OfflineBeacon(
            latitude: latitude,
            longitude: longitude,
            failureReason: 'Network request timed out after ${options.timeout.inSeconds}s',
            batteryLevel: batteryLevel,
            timestamp: capturedTime,
          ),
          errorMessage: 'Geocoding request timed out: ${e.message}',
        );
      }
      rethrow;
    } on PlatformException catch (e) {
      // Platform-specific error (e.g. NETWORK_ERROR, GEOCODER_NOT_AVAILABLE, IO_ERROR)
      if (options.fallbackToOfflineOnFailure) {
        return BeaconResult.offline(
          OfflineBeacon(
            latitude: latitude,
            longitude: longitude,
            failureReason: e.message ?? e.code,
            batteryLevel: batteryLevel,
            timestamp: capturedTime,
          ),
          errorMessage: e.message ?? e.code,
        );
      }
      rethrow;
    } catch (e) {
      // General unexpected errors
      if (options.fallbackToOfflineOnFailure) {
        return BeaconResult.offline(
          OfflineBeacon(
            latitude: latitude,
            longitude: longitude,
            failureReason: e.toString(),
            batteryLevel: batteryLevel,
            timestamp: capturedTime,
          ),
          errorMessage: e.toString(),
        );
      }
      rethrow;
    }
  }

  /// Convenience shortcut to immediately obtain a spoken dispatch summary
  /// for emergency phone calls (112, 108, roadside towing).
  ///
  /// Handles both online and offline cases seamlessly.
  static Future<String> getIndianDispatchSummary(
    double latitude,
    double longitude, {
    bool mentionSmsSent = true,
    BeaconOptions options = const BeaconOptions(),
  }) async {
    final result = await reverseGeocode(latitude, longitude, options: options);
    return result.toSpokenDispatchSummary(mentionSmsSent: mentionSmsSent);
  }

  /// Convenience shortcut to obtain technical spoken coordinates for situations
  /// where an emergency dispatcher specifically requests raw numbers.
  static Future<String> getTechnicalSpokenCoordinates(
    double latitude,
    double longitude, {
    BeaconOptions options = const BeaconOptions(),
  }) async {
    final result = await reverseGeocode(latitude, longitude, options: options);
    return result.toTechnicalSpokenCoordinates();
  }

  /// Convenience shortcut to immediately obtain a localized spoken prompt
  /// in the primary official regional language of the state (Kannada, Tamil, Marathi, etc.)
  /// where the user is stranded.
  static Future<String> getRegionalSpokenSummary(
    double latitude,
    double longitude, {
    IndianLanguage? overrideLanguage,
    bool mentionSmsSent = true,
    BeaconOptions options = const BeaconOptions(),
  }) async {
    final result = await reverseGeocode(latitude, longitude, options: options);
    return result.toRegionalSpokenSummary(
      overrideLanguage: overrideLanguage,
      mentionSmsSent: mentionSmsSent,
    );
  }

  /// Convenience shortcut to obtain an English pronunciation guide of the local language script
  /// so out-of-state travelers can easily read the prompt aloud over phone calls.
  static Future<String> getRegionalPronunciationGuide(
    double latitude,
    double longitude, {
    IndianLanguage? overrideLanguage,
    BeaconOptions options = const BeaconOptions(),
  }) async {
    final result = await reverseGeocode(latitude, longitude, options: options);
    return result.toRegionalPronunciationGuide(overrideLanguage: overrideLanguage);
  }

  /// Convenience shortcut to generate an offline-ready emergency SMS text message
  /// with a Google Maps coordinate link for 2G SMS dispatch.
  static Future<String> getEmergencySmsMessage(
    double latitude,
    double longitude, {
    String? alertPrefix,
    IndianLanguage? overrideLanguage,
    int? batteryLevel,
    DateTime? timestamp,
    BeaconOptions options = const BeaconOptions(),
  }) async {
    final result = await reverseGeocode(
      latitude,
      longitude,
      batteryLevel: batteryLevel,
      timestamp: timestamp,
      options: options,
    );
    return result.toShareableSmsMessage(alertPrefix: alertPrefix);
  }

  /// Convenience shortcut to generate a standard `sms:` URI for one-tap SMS launching
  /// with pre-filled bilingual alert, coordinates, and Google Maps link.
  static Future<Uri> getEmergencySmsUri(
    double latitude,
    double longitude, {
    String recipient = '112',
    String? alertPrefix,
    IndianLanguage? overrideLanguage,
    int? batteryLevel,
    DateTime? timestamp,
    BeaconOptions options = const BeaconOptions(),
  }) async {
    final result = await reverseGeocode(
      latitude,
      longitude,
      batteryLevel: batteryLevel,
      timestamp: timestamp,
      options: options,
    );
    return result.toSmsUri(
      recipient: recipient,
      alertPrefix: alertPrefix,
      overrideLanguage: overrideLanguage,
    );
  }

  /// Convenience shortcut to generate a group SMS URI for broadcasting the emergency alert
  /// and live Google Maps link to the user's family members, friends, or trusted contacts.
  static Future<Uri> getEmergencyContactsSmsUri(
    double latitude,
    double longitude, {
    required List<String> recipients,
    String? alertPrefix,
    IndianLanguage? overrideLanguage,
    int? batteryLevel,
    DateTime? timestamp,
    BeaconOptions options = const BeaconOptions(),
  }) async {
    final result = await reverseGeocode(
      latitude,
      longitude,
      batteryLevel: batteryLevel,
      timestamp: timestamp,
      options: options,
    );
    return result.toEmergencyContactsSmsUri(
      recipients: recipients,
      alertPrefix: alertPrefix,
      overrideLanguage: overrideLanguage,
    );
  }

  /// Convenience shortcut to search nearby emergency facilities (mechanics, hospitals, fuel, police)
  /// centered around the user's coordinates in Google Maps.
  static Future<Uri?> getNearbyFacilitySearchUri(
    double latitude,
    double longitude,
    EmergencyFacility facility, {
    BeaconOptions options = const BeaconOptions(),
  }) async {
    final result = await reverseGeocode(latitude, longitude, options: options);
    return result.toFacilitySearchUri(facility);
  }

  /// Convenience shortcut to generate a breakdown assistance SMS for a local mechanic or towing service.
  static Future<String> getMechanicSmsMessage(
    double latitude,
    double longitude, {
    String vehicleModel = '',
    BeaconOptions options = const BeaconOptions(),
  }) async {
    final result = await reverseGeocode(latitude, longitude, options: options);
    return result.toMechanicSmsMessage(vehicleModel: vehicleModel);
  }

  /// Returns a one-tap dialer URI for official nationwide Indian emergency & roadside helplines
  /// (e.g. NHAI 1033 for highway towing/cranes, 112 for police, 108 for ambulance).
  static Uri getHelplineDialerUri(EmergencyHelpline helpline) {
    return helpline.toDialerUri();
  }
}
