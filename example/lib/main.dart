import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:street_beacon/street_beacon.dart';

void main() {
  runApp(const StreetBeaconExampleApp());
}

/// Example application demonstrating the `street_beacon` package for
/// Indian emergency assistance, roadside breakdowns, and unexpected situations.
class StreetBeaconExampleApp extends StatelessWidget {
  const StreetBeaconExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Street Beacon - Emergency & Assistance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE65100), // High-visibility amber/orange
          brightness: Brightness.light,
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 8),
        ),
      ),
      home: const BeaconHomePage(),
    );
  }
}

class BeaconHomePage extends StatefulWidget {
  const BeaconHomePage({super.key});

  @override
  State<BeaconHomePage> createState() => _BeaconHomePageState();
}

class _BeaconHomePageState extends State<BeaconHomePage> {
  // Coordinate input controllers
  final TextEditingController _latController = TextEditingController(text: '12.9716');
  final TextEditingController _lngController = TextEditingController(text: '77.5946');

  bool _isGeocoderAvailable = false;
  bool _isLoading = false;
  BeaconResult? _lastResult;
  String? _errorMessage;

  // Preset Indian locations for quick demonstration
  final List<Map<String, dynamic>> _presets = [
    {
      'name': 'Bengaluru (MG Rd / Indiranagar)',
      'lat': 12.9716,
      'lng': 77.5946,
      'scenario': 'City breakdown',
    },
    {
      'name': 'Delhi (Connaught Place)',
      'lat': 28.6315,
      'lng': 77.2167,
      'scenario': 'Disoriented tourist',
    },
    {
      'name': 'Mumbai (Marine Drive)',
      'lat': 18.9438,
      'lng': 72.8234,
      'scenario': 'Medical emergency',
    },
    {
      'name': 'NH 44 Highway (Remote / Weak Signal)',
      'lat': 14.6819,
      'lng': 77.6006,
      'scenario': 'Highway car trouble (Tests low-signal / offline fallback)',
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkGeocoder();
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  /// Verifies if the host Android device has an active Geocoder backend
  Future<void> _checkGeocoder() async {
    final available = await StreetBeacon.isGeocoderAvailable();
    if (mounted) {
      setState(() {
        _isGeocoderAvailable = available;
      });
    }
  }

  /// Performs reverse-geocoding using StreetBeacon
  Future<void> _resolveLocation() async {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());

    if (lat == null || lng == null) {
      setState(() {
        _errorMessage = 'Please enter valid numeric latitude and longitude.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Calls StreetBeacon.reverseGeocode with Indian locale and strict timeout
      // to avoid freezing when phone data is weak or dropping
      final result = await StreetBeacon.reverseGeocode(
        lat,
        lng,
        options: const BeaconOptions(
          locale: 'en_IN',
          timeout: Duration(seconds: 6),
          fallbackToOfflineOnFailure: true, // Automatically provides offline SMS & Plus Code
        ),
      );

      if (mounted) {
        setState(() {
          _lastResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error resolving location: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Copies text to clipboard and displays a confirmation SnackBar
  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1B5E20),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.fmd_good_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Street Beacon',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD84315),
        actions: [
          // Geocoder backend status chip
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Chip(
              avatar: Icon(
                _isGeocoderAvailable ? Icons.check_circle : Icons.warning_amber_rounded,
                size: 16,
                color: _isGeocoderAvailable ? Colors.green[800] : Colors.orange[800],
              ),
              label: Text(
                _isGeocoderAvailable ? 'Geocoder Ready' : 'Geocoder Offline',
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: Colors.white,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Informational intro banner
          _buildInfoBanner(),

          const SizedBox(height: 12),

          // Preset locations selector
          _buildPresetChips(),

          const SizedBox(height: 16),

          // Coordinate input section
          _buildCoordinateInputs(),

          const SizedBox(height: 16),

          // Action button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _resolveLocation,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.share_location_rounded),
              label: Text(
                _isLoading ? 'Resolving Street Address...' : 'Generate Street Beacon',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD84315),
                foregroundColor: Colors.white,
              ),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Results display
          if (_lastResult != null) ...[
            const SizedBox(height: 20),
            _buildResultView(_lastResult!),
          ],
        ],
      ),
    );
  }

  /// Informational header explaining the value of Street Beacon
  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFFE65100), size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Street Beacon transforms raw GPS coordinates into human-readable Indian postal addresses, '
              'read-aloud scripts for 112/108 calls, and offline SMS fallback when mobile data drops.',
              style: TextStyle(fontSize: 13, color: Color(0xFF4E342E)),
            ),
          ),
        ],
      ),
    );
  }

  /// Quick-select preset buttons
  Widget _buildPresetChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sample Indian Scenarios:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _presets.map((preset) {
            return ActionChip(
              avatar: const Icon(Icons.place, size: 16),
              label: Text(preset['name'] as String),
              onPressed: () {
                setState(() {
                  _latController.text = (preset['lat'] as double).toString();
                  _lngController.text = (preset['lng'] as double).toString();
                });
                _resolveLocation();
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Coordinate text input fields
  Widget _buildCoordinateInputs() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _latController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: const InputDecoration(
              labelText: 'Latitude',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.explore_outlined),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _lngController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: const InputDecoration(
              labelText: 'Longitude',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.explore_outlined),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the resolved result cards
  Widget _buildResultView(BeaconResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode badge (Online Geocoded vs Offline Fallback)
        Row(
          children: [
            Icon(
              result.isOnlineResolved ? Icons.cloud_done : Icons.cloud_off,
              color: result.isOnlineResolved ? Colors.green[700] : Colors.deepOrange,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              result.isOnlineResolved
                  ? 'Online Geocoded (Indian Postal Standard)'
                  : 'Offline Fallback (Low / No Network Mode)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: result.isOnlineResolved ? Colors.green[800] : Colors.deepOrange[800],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 1. Spoken Dispatch Script Card (Top priority for emergency calls)
        _buildSpokenScriptCard(result),

        const SizedBox(height: 8),

        // 2. Formatted Indian Address Card (or coordinates breakdown)
        _buildAddressDetailsCard(result),

        const SizedBox(height: 8),

        // 3. 2G Offline-Ready SMS Card
        _buildSmsCard(result),
      ],
    );
  }

  /// Card with spoken dialogue to read out loud over the phone
  Widget _buildSpokenScriptCard(BeaconResult result) {
    final spokenScript = result.toSpokenDispatchSummary();

    return Card(
      color: const Color(0xFFE8F5E9), // Light calming green
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.green.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.record_voice_over, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Read Out Loud to Dispatcher (112 / 108 / Towing):',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy spoken script',
                  icon: const Icon(Icons.copy, size: 18, color: Color(0xFF2E7D32)),
                  onPressed: () => _copyToClipboard(spokenScript, 'Spoken script'),
                ),
              ],
            ),
            const Divider(color: Colors.black12),
            Text(
              '"$spokenScript"',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B5E20),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card with detailed Indian address breakdown
  Widget _buildAddressDetailsCard(BeaconResult result) {
    if (result.isOnlineResolved && result.address != null) {
      final addr = result.address!;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.pin_drop, color: Color(0xFFD84315)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Indian Postal Address:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy address',
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () => _copyToClipboard(
                      addr.toIndianFormattedAddress(),
                      'Address',
                    ),
                  ),
                ],
              ),
              const Divider(),
              SelectableText(
                addr.toIndianFormattedAddress(),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (addr.premise != null) _buildTag('Premise', addr.premise!),
                  if (addr.road != null) _buildTag('Road', addr.road!),
                  if (addr.colony != null) _buildTag('Colony/Sector', addr.colony!),
                  if (addr.city != null) _buildTag('City', addr.city!),
                  if (addr.district != null) _buildTag('District', addr.district!),
                  if (addr.state != null) _buildTag('State', addr.state!),
                  if (addr.pincode != null) _buildTag('PIN Code', addr.pincode!, isHighlight: true),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      final offline = result.offlineBeacon!;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Offline Coordinate Coordinates:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const Divider(),
              Text('Latitude: ${offline.latitude}'),
              Text('Longitude: ${offline.longitude}'),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Text('Offline Plus Code: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Chip(
                    label: Text(
                      offline.plusCode,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    backgroundColor: const Color(0xFF0D47A1),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }

  /// Card with SMS message text formatted for sending over 2G networks
  Widget _buildSmsCard(BeaconResult result) {
    final smsText = result.toShareableSmsMessage();

    return Card(
      color: const Color(0xFFF3E5F5), // Light purple
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.purple.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sms, color: Color(0xFF6A1B9A)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Emergency SMS Text (Works with 2G & zero data):',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF4A148C),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy SMS message',
                  icon: const Icon(Icons.copy, size: 18, color: Color(0xFF6A1B9A)),
                  onPressed: () => _copyToClipboard(smsText, 'SMS text'),
                ),
              ],
            ),
            const Divider(color: Colors.black12),
            SelectableText(
              smsText,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: Color(0xFF311B92),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Small chip tag for breakdown components
  Widget _buildTag(String label, String value, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlight ? const Color(0xFFFFE082) : Colors.grey[200],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isHighlight ? const Color(0xFFFFB300) : Colors.grey[300]!,
        ),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 11,
          fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          color: Colors.black87,
        ),
      ),
    );
  }
}
