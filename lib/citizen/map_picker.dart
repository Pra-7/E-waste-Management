import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'geocoding_service.dart';

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  LatLng selectedLocation = LatLng(27.7172, 85.3240);
  String selectedAddress = "Kathmandu, Nepal";
  bool loadingAddress = false;

  /// Called when user taps on the map — reverse geocode immediately
  Future<void> onMapTap(LatLng point) async {
    setState(() {
      selectedLocation = point;
      loadingAddress = true;
      selectedAddress = "Getting address...";
    });

    final address = await GeocodingService.getAddressFromLatLng(
      point.latitude,
      point.longitude,
    );

    if (mounted) {
      setState(() {
        selectedAddress = address;
        loadingAddress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Select Pickup Location",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),

      body: Stack(
        children: [
          // ─── Map ───────────────────────────────────────────
          FlutterMap(
            options: MapOptions(
              initialCenter: selectedLocation,
              initialZoom: 14,
              onTap: (tapPosition, point) => onMapTap(point),
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.e_waste_collector',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: selectedLocation,
                    width: 50,
                    height: 50,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D6A4F),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2D6A4F).withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(Icons.location_pin, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ─── Address preview card at bottom ───────────────
          Positioned(
            left: 16,
            right: 16,
            bottom: 100,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on_rounded, color: Color(0xFF2D6A4F), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Selected location",
                          style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        loadingAddress
                            ? const SizedBox(
                                height: 14,
                                width: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2D6A4F)),
                              )
                            : Text(
                                selectedAddress,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1B3A2D),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Tip label ────────────────────────────────────
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Tap on the map to set your pickup point",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),

      // ─── Confirm FAB ──────────────────────────────────────
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FloatingActionButton.extended(
            onPressed: loadingAddress
                ? null
                : () {
                    Navigator.pop(context, {
                      "lat": selectedLocation.latitude,
                      "lng": selectedLocation.longitude,
                      "address": selectedAddress,
                    });
                  },
            backgroundColor: const Color(0xFF2D6A4F),
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text(
              "Confirm Location",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}