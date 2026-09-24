/// Represents common critical facilities needed during vehicle breakdowns or emergencies.
enum EmergencyFacility {
  /// Mechanics, puncture shops, towing cranes, and vehicle service centers.
  mechanic('mechanic car repair puncture towing service'),

  /// Hospitals, trauma care centers, and emergency clinics.
  hospital('hospital trauma center emergency clinic'),

  /// Petrol pumps, diesel fuel stations, and EV charging points.
  fuel('petrol pump fuel station EV charging point'),

  /// Police stations, highway patrol outposts, and police chowkis.
  police('police station highway patrol chowki'),

  /// 24-hour pharmacies and medical chemists.
  pharmacy('medical store 24 hour pharmacy chemist');

  /// The search query keywords sent to map providers.
  final String queryKeywords;

  const EmergencyFacility(this.queryKeywords);
}

/// Official 24x7 nationwide Indian emergency and roadside assistance helplines
/// that can be dialed completely offline over standard cellular voice networks.
enum EmergencyHelpline {
  /// National Highways Authority of India (NHAI) 24x7 Roadside Helpline.
  /// Provides towing, crane rescue, mechanical assistance, and ambulance on all Indian National Highways.
  nhaiHighwayAssistance('1033', 'NHAI Highway Roadside & Towing Helpline'),

  /// Unified National Emergency Helpline across all Indian States & UTs.
  /// Connects to Police, Fire, and Emergency Response Support System (ERSS).
  unifiedEmergency('112', 'National Emergency Helpline (Police/Fire/Disaster)'),

  /// National Medical Ambulance and Emergency Health Service.
  ambulance('108', 'Emergency Medical Ambulance Service'),

  /// Women's Safety Helpline for rapid police dispatch and assistance.
  womenHelpline('1090', 'Women Helpline (Police Dispatch)'),

  /// Railway Protection Force (RPF) and train travel security helpline.
  railwaySecurity('139', 'Indian Railways Security & Assistance');

  /// The official phone number to dial.
  final String number;

  /// Human-readable title and description of the service.
  final String description;

  const EmergencyHelpline(this.number, this.description);

  /// Generates a standard `tel:` URI for one-tap native phone dialer launching.
  ///
  /// Example:
  /// `tel:1033`
  Uri toDialerUri() => Uri(scheme: 'tel', path: number);
}

/// Helper utilities to construct native facility search URIs.
class FacilitySearchHelper {
  /// Builds a universal Google Maps search URI centered around [latitude] and [longitude]
  /// for the specified [facility].
  ///
  /// When tapped by the user, this natively launches Google Maps (or browser)
  /// directly filtered by nearby open facilities with phone numbers, reviews, and turn-by-turn navigation.
  ///
  /// Example:
  /// `https://www.google.com/maps/search/mechanic+car+repair+puncture+towing+service/@12.97160,77.59460,14z`
  static Uri buildGoogleMapsSearchUri({
    required double latitude,
    required double longitude,
    required EmergencyFacility facility,
    int zoom = 14,
  }) {
    final encodedQuery = Uri.encodeComponent(facility.queryKeywords);
    final latStr = latitude.toStringAsFixed(5);
    final lngStr = longitude.toStringAsFixed(5);
    return Uri.parse('https://www.google.com/maps/search/$encodedQuery/@$latStr,$lngStr,${zoom}z');
  }

  /// Builds a native Android `geo:` intent URI for searching nearby facilities.
  ///
  /// Example:
  /// `geo:12.97160,77.59460?q=mechanic+car+repair+puncture`
  static Uri buildGeoSearchUri({
    required double latitude,
    required double longitude,
    required EmergencyFacility facility,
  }) {
    final latStr = latitude.toStringAsFixed(5);
    final lngStr = longitude.toStringAsFixed(5);
    final encodedQuery = Uri.encodeComponent(facility.queryKeywords);
    return Uri.parse('geo:$latStr,$lngStr?q=$encodedQuery');
  }
}
