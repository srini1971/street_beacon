## 0.0.1 - Initial Release

* 🇮🇳 **Indian Address Hierarchy**: Complete support for Indian postal structure parsing (Premise, Landmark, Road/Marg, Colony/Sector, City, District, State, and PIN code).
* 🗣️ **Natural Spoken Dispatch Scripts**: Generates human-friendly spoken dialogues for emergency voice calls with 112 / 108 dispatchers.
* 📍 **100% Offline Location Intelligence**:
  * Embedded database of ~80 major Indian cities and district centers.
  * Real-time **Haversine distance** and **8-point compass bearing** calculation completely offline.
  * Pure local generation of 10-character **Open Location Codes (Plus Codes)** with zero network traffic.
* 🌐 **Automatic Regional State Language Detection**:
  * Automatically detects the official language of the state (Kannada in Karnataka, Tamil in Tamil Nadu, Telugu in AP/Telangana, Marathi in Maharashtra, Hindi in North India, Bengali, Gujarati, Punjabi, Odia, Assamese, Malayalam).
  * Generates bilingual emergency SMS dispatches (Regional Script + English).
  * Includes English phonetic pronunciation guides for out-of-state travelers.
* 🔋 **Battery Level & Timestamp Telemetry**:
  * Real-time device battery tracking with critical low battery warnings (`Bat: 8% [CRITICAL]`).
  * Formatted Indian timestamp (`Time: 09:15 PM`).
* 👨‍👩‍👧‍👦 **Family & Friends Emergency Contacts Broadcast**:
  * One-tap group SMS URI generation (`toEmergencyContactsSmsUri`) to broadcast coordinates and live Google Maps links to trusted contacts over 2G cellular SMS.
* 🛠️ **Nearby Facility Search & Mechanic Assistance**:
  * Direct map deep-linking for nearby mechanics, puncture shops, hospitals, fuel/EV stations, and police stations with zero paid API keys.
  * Specialized vehicle breakdown SMS formatter for local towing services.
* 📞 **Official Indian Emergency Helplines**:
  * 1-tap offline dialers for **NHAI Highway Assistance (1033)**, **Unified Emergency (112)**, and **Medical Ambulance (108)**.
