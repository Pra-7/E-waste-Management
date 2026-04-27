import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Citizens use this page to track their collector in real time.
/// It listens to Firestore changes so the collector marker moves live.
class ViewLocationPage extends StatelessWidget {
  final double lat;
  final double lng;
  final String? docId; // Firestore document ID for live updates

  // These are kept for backward compat if called without docId
  final double? collectorLat;
  final double? collectorLng;

  const ViewLocationPage({
    super.key,
    required this.lat,
    required this.lng,
    this.docId,
    this.collectorLat,
    this.collectorLng,
  });

  @override
  Widget build(BuildContext context) {
    // If we have a docId, stream live data from Firestore
    if (docId != null) {
      return _LiveTrackingView(lat: lat, lng: lng, docId: docId!);
    }

    // Fallback: static view
    return _StaticView(lat: lat, lng: lng, collectorLat: collectorLat, collectorLng: collectorLng);
  }
}

// ─── Live streaming version ──────────────────────────────────────────────────

class _LiveTrackingView extends StatelessWidget {
  final double lat;
  final double lng;
  final String docId;

  const _LiveTrackingView({required this.lat, required this.lng, required this.docId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text("Track Collector", style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pickup_requests')
            .doc(docId)
            .snapshots(),
        builder: (context, snapshot) {
          double? cLat, cLng;
          String status = "Pending";

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            status = data['status'] ?? 'Pending';
            if (data['collectorLat'] != null) cLat = (data['collectorLat'] as num).toDouble();
            if (data['collectorLng'] != null) cLng = (data['collectorLng'] as num).toDouble();
          }

          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(lat, lng),
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName: 'com.example.e_waste_collector',
                  ),
                  MarkerLayer(
                    markers: [
                      // Pickup location (citizen)
                      Marker(
                        point: LatLng(lat, lng),
                        width: 50,
                        height: 50,
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D6A4F),
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: const Color(0xFF2D6A4F).withOpacity(0.4), blurRadius: 8)],
                              ),
                              padding: const EdgeInsets.all(7),
                              child: const Icon(Icons.home_rounded, color: Colors.white, size: 18),
                            ),
                          ],
                        ),
                      ),

                      // Collector (live position)
                      if (cLat != null && cLng != null)
                        Marker(
                          point: LatLng(cLat, cLng),
                          width: 50,
                          height: 50,
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A3A6C),
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: const Color(0xFF1A3A6C).withOpacity(0.4), blurRadius: 8)],
                                ),
                                padding: const EdgeInsets.all(7),
                                child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 18),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  // Line from collector to pickup
                  if (cLat != null && cLng != null)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [LatLng(cLat, cLng), LatLng(lat, lng)],
                          strokeWidth: 3,
                          color: const Color(0xFF1A3A6C),
                          isDotted: true,
                        ),
                      ],
                    ),
                ],
              ),

              // ─── Status card ─────────────────────────────
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF22C55E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Live tracking",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF22C55E)),
                          ),
                          const Spacer(),
                          _StatusPill(status: status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _LegendDot(color: const Color(0xFF2D6A4F), label: "Pickup location"),
                          const SizedBox(width: 16),
                          if (cLat != null)
                            _LegendDot(color: const Color(0xFF1A3A6C), label: "Collector"),
                        ],
                      ),
                      if (cLat == null) ...[
                        const SizedBox(height: 8),
                        const Text(
                          "Waiting for collector's location...",
                          style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Static fallback version (no docId) ─────────────────────────────────────

class _StaticView extends StatelessWidget {
  final double lat;
  final double lng;
  final double? collectorLat;
  final double? collectorLng;

  const _StaticView({required this.lat, required this.lng, this.collectorLat, this.collectorLng});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text("Track Collector", style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: FlutterMap(
        options: MapOptions(initialCenter: LatLng(lat, lng), initialZoom: 15),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.e_waste_collector',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(lat, lng),
                width: 40,
                height: 40,
                child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
              ),
              if (collectorLat != null && collectorLng != null)
                Marker(
                  point: LatLng(collectorLat!, collectorLng!),
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.local_shipping, color: Colors.blue, size: 40),
                ),
            ],
          ),
          if (collectorLat != null && collectorLng != null)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: [LatLng(collectorLat!, collectorLng!), LatLng(lat, lng)],
                  strokeWidth: 4,
                  color: Colors.blue,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Small helper widgets ────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (status) {
      case "Accepted":  bg = const Color(0xFFE3EBF8); fg = const Color(0xFF1A3A6C); break;
      case "Arrived":   bg = const Color(0xFFF3E5F5); fg = const Color(0xFF7B1FA2); break;
      case "Completed": bg = const Color(0xFFE8F5E9); fg = const Color(0xFF2D6A4F); break;
      default:          bg = const Color(0xFFFFF3E0); fg = const Color(0xFFE65100);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
      ],
    );
  }
}