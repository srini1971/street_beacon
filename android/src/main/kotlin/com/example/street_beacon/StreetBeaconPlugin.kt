package com.example.street_beacon

import android.content.Context
import android.location.Address
import android.location.Geocoder
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.IOException
import java.util.Locale
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/**
 * StreetBeaconPlugin
 *
 * A Flutter plugin that leverages Android's native [android.location.Geocoder]
 * to reverse-geocode GPS coordinates into detailed street addresses and landmarks.
 *
 * Key Architecture Highlights:
 * 1. Threading: Geocoding queries involve network I/O with Google Play Services / OEM servers.
 *    To prevent freezing the Flutter UI thread (Application Not Responding / ANR), all lookups
 *    are dispatched on a background thread pool.
 * 2. Main-thread Dispatch: Flutter's [Result] callback must always be returned on the
 *    Android Main UI thread, handled via [mainHandler].
 * 3. Modern Android 13+ (API 33) Support: Supports the asynchronous [Geocoder.GeocodeListener]
 *    API while gracefully maintaining backward compatibility with older Android versions.
 * 4. Network Resilience: Tailored for fluctuating network connections (such as 2G/3G/4G in India).
 *    Network drops or [IOException] are captured and reported cleanly so Flutter can switch
 *    to offline SMS fallback without crashing.
 */
class StreetBeaconPlugin : FlutterPlugin, MethodCallHandler {

    // Communication channel between Flutter (Dart) and Android (Kotlin)
    private lateinit var channel: MethodChannel

    // Android application context required to instantiate Android's Geocoder
    private lateinit var context: Context

    // Handler to safely post results back to the Android Main/UI thread for Flutter
    private val mainHandler = Handler(Looper.getMainLooper())

    // Background thread pool for performing blocking geocoder network calls
    private val backgroundExecutor = Executors.newCachedThreadPool()

    /**
     * Called when the Flutter engine attaches to the Android host.
     * Sets up the method channel and stores the application context.
     */
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "street_beacon")
        channel.setMethodCallHandler(this)
    }

    /**
     * Entry point for method calls invoked from Dart over the [MethodChannel].
     */
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isGeocoderAvailable" -> {
                handleIsGeocoderAvailable(result)
            }
            "reverseGeocode" -> {
                handleReverseGeocode(call, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * Checks whether an Android Geocoder backend service is installed on this device.
     *
     * In Android, Geocoder relies on a backend service (usually provided by Google Play Services
     * or an OEM implementation). Calling [Geocoder.isPresent] returns true if a backend exists.
     */
    private fun handleIsGeocoderAvailable(result: Result) {
        try {
            val isAvailable = Geocoder.isPresent()
            result.success(isAvailable)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    /**
     * Handles reverse-geocoding coordinate parameters sent from Dart.
     *
     * Expected arguments in [call]:
     * - "latitude": Double (e.g. 12.9716)
     * - "longitude": Double (e.g. 77.5946)
     * - "locale": String (e.g. "en_IN" for Indian English formatting)
     * - "maxResults": Int (default 1)
     */
    private fun handleReverseGeocode(call: MethodCall, result: Result) {
        val latitude = call.argument<Double>("latitude")
        val longitude = call.argument<Double>("longitude")
        val localeString = call.argument<String>("locale") ?: "en_IN"
        val maxResults = call.argument<Int>("maxResults") ?: 1

        // Validate coordinate existence
        if (latitude == null || longitude == null) {
            result.error(
                "INVALID_ARGUMENTS",
                "Latitude and longitude must not be null.",
                null
            )
            return
        }

        // Validate geographic coordinate boundaries
        if (latitude < -90.0 || latitude > 90.0 || longitude < -180.0 || longitude > 180.0) {
            result.error(
                "INVALID_COORDINATES",
                "Coordinates out of bounds: lat=$latitude, lng=$longitude",
                null
            )
            return
        }

        // Check if Geocoder backend is present on device
        if (!Geocoder.isPresent()) {
            result.error(
                "GEOCODER_NOT_AVAILABLE",
                "No geocoder backend service available on this device.",
                null
            )
            return
        }

        // Parse target locale (e.g., "en_IN" -> Language: "en", Country: "IN")
        val localeObj = parseLocale(localeString)

        // Atomic flag to ensure the Flutter Result callback is only called once
        val isResultSent = AtomicBoolean(false)

        // Execute geocoding in a background worker thread
        backgroundExecutor.execute {
            try {
                val geocoder = Geocoder(context, localeObj)

                // Android 13 (Tiramisu, API 33) introduced an asynchronous GeocodeListener
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    geocoder.getFromLocation(
                        latitude,
                        longitude,
                        maxResults,
                        object : Geocoder.GeocodeListener {
                            override fun onGeocode(addresses: MutableList<Address>) {
                                if (isResultSent.compareAndSet(false, true)) {
                                    postSuccessResult(addresses.firstOrNull(), result)
                                }
                            }

                            override fun onError(errorMessage: String?) {
                                if (isResultSent.compareAndSet(false, true)) {
                                    postErrorResult(
                                        "NETWORK_ERROR",
                                        errorMessage ?: "Geocoding service error",
                                        result
                                    )
                                }
                            }
                        }
                    )
                } else {
                    // Backwards-compatible synchronous method for Android 12 (API 32) and below.
                    // This is safe because we are already on a background thread.
                    @Suppress("DEPRECATION")
                    val addresses = geocoder.getFromLocation(latitude, longitude, maxResults)
                    if (isResultSent.compareAndSet(false, true)) {
                        postSuccessResult(addresses?.firstOrNull(), result)
                    }
                }
            } catch (ioException: IOException) {
                // Network failure or timeout (frequent in poor 2G/3G connectivity areas)
                if (isResultSent.compareAndSet(false, true)) {
                    postErrorResult(
                        "NETWORK_ERROR",
                        "Network failure during reverse geocoding: ${ioException.localizedMessage}",
                        result
                    )
                }
            } catch (e: Exception) {
                // Unexpected general error
                if (isResultSent.compareAndSet(false, true)) {
                    postErrorResult(
                        "GEOCODER_ERROR",
                        e.localizedMessage ?: "Unexpected error during geocoding",
                        result
                    )
                }
            }
        }
    }

    /**
     * Converts an Android native [Address] object into a Flutter-friendly [Map].
     *
     * Maps Android Address fields to Indian address conventions:
     * - [Address.getFeatureName] -> Specific building, house number, or landmark
     * - [Address.getThoroughfare] -> Road / Street / Marg name
     * - [Address.getSubLocality] -> Colony / Sector / Nagar / Village
     * - [Address.getLocality] -> City / Town / Taluk
     * - [Address.getSubAdminArea] -> District
     * - [Address.getAdminArea] -> State / Union Territory
     * - [Address.getPostalCode] -> 6-digit PIN Code
     */
    private fun addressToMap(address: Address): Map<String, Any?> {
        val addressMap = HashMap<String, Any?>()

        addressMap["latitude"] = address.latitude
        addressMap["longitude"] = address.longitude

        // Line 0 is the full formatted string returned by Android/Google
        val formatted = if (address.maxAddressLineIndex >= 0) {
            address.getAddressLine(0)
        } else {
            null
        }
        addressMap["formattedAddress"] = formatted

        // Landmark / Premise / Building name (e.g., "Opposite Metro Pillar 120")
        addressMap["featureName"] = address.featureName

        // Road / Street name (e.g., "MG Road", "100 Feet Road")
        addressMap["thoroughfare"] = address.thoroughfare

        // Building / House / Door number if provided
        addressMap["subThoroughfare"] = address.subThoroughfare

        // Colony, Sector, Mohalla, Nagar, or Layout (e.g., "Indiranagar", "Sector 62")
        addressMap["subLocality"] = address.subLocality

        // City or Town (e.g., "Bengaluru", "Noida")
        addressMap["locality"] = address.locality

        // District (e.g., "Bengaluru Urban", "Gautam Buddha Nagar")
        addressMap["subAdminArea"] = address.subAdminArea

        // State or Union Territory (e.g., "Karnataka", "Uttar Pradesh", "Delhi")
        addressMap["adminArea"] = address.adminArea

        // Indian 6-digit PIN Code (e.g., "560038")
        addressMap["postalCode"] = address.postalCode

        // Country details
        addressMap["countryName"] = address.countryName
        addressMap["countryCode"] = address.countryCode

        return addressMap
    }

    /**
     * Dispatches successful address data back to Flutter on the Main/UI thread.
     */
    private fun postSuccessResult(address: Address?, result: Result) {
        mainHandler.post {
            if (address != null) {
                result.success(addressToMap(address))
            } else {
                result.success(null)
            }
        }
    }

    /**
     * Dispatches error information back to Flutter on the Main/UI thread.
     */
    private fun postErrorResult(errorCode: String, errorMessage: String, result: Result) {
        mainHandler.post {
            result.error(errorCode, errorMessage, null)
        }
    }

    /**
     * Parses a locale string such as "en_IN" into a Java [Locale] instance.
     */
    private fun parseLocale(localeString: String): Locale {
        return if (localeString.contains("_")) {
            val parts = localeString.split("_")
            Locale(parts[0], parts[1])
        } else if (localeString.contains("-")) {
            val parts = localeString.split("-")
            Locale(parts[0], parts[1])
        } else {
            Locale(localeString)
        }
    }

    /**
     * Called when the plugin is detached from the Flutter engine.
     * Cleans up the method channel and background executor.
     */
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        backgroundExecutor.shutdown()
    }
}
