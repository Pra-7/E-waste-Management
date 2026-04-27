import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../view_location.dart';
import 'collector_location_service.dart';

class CollectorRequestsPage extends StatefulWidget {
  const CollectorRequestsPage({super.key});

  @override
  State<CollectorRequestsPage> createState() => _CollectorRequestsPageState();
}

class _CollectorRequestsPageState extends State<CollectorRequestsPage> {

  Future<void> openGoogleMaps(double lat, double lng) async {
    final Uri url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  /// Accept request + start live GPS tracking toward pickup point
  Future<void> acceptRequest(
    String docId,
    String userId,
    double pickupLat,
    double pickupLng,
  ) async {
    final collectorId = FirebaseAuth.instance.currentUser!.uid;

    // 1. Update Firestore status
    await FirebaseFirestore.instance
        .collection('pickup_requests')
        .doc(docId)
        .update({
      "status": "Accepted",
      "collectorId": collectorId,
    });

    // 2. Notify citizen
    await FirebaseFirestore.instance.collection('notifications').add({
      "userId": userId,
      "message": "✅ Your pickup request has been accepted! The collector is on their way.",
      "createdAt": Timestamp.now(),
    });

    // 3. Start live location tracking — auto-triggers "Arrived" within 500m
    await CollectorLocationService.startTracking(
      docId: docId,
      userId: userId,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      thresholdMeters: 500,
      onError: (msg) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
          );
        }
      },
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Request accepted. Live tracking started — you'll auto-arrive within 500m."),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> completePickup(String docId, String userId) async {
    await FirebaseFirestore.instance
        .collection('pickup_requests')
        .doc(docId)
        .update({"status": "Completed"});

    await FirebaseFirestore.instance.collection('notifications').add({
      "userId": userId,
      "message": "✅ Your e-waste pickup has been completed. Thank you for recycling!",
      "createdAt": Timestamp.now(),
    });

    // Stop tracking (in case still running)
    await CollectorLocationService.stopTracking();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: const Text(
                "Pickup Requests",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1B2C4E)),
              ),
            ),

            // Live tracking indicator
            if (CollectorLocationService.isTracking)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.my_location_rounded, color: Color(0xFF2D6A4F), size: 16),
                    SizedBox(width: 8),
                    Text(
                      "Live tracking active — will auto-notify when near pickup",
                      style: TextStyle(fontSize: 12, color: Color(0xFF2D6A4F), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('pickup_requests')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF1A3A6C)));
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text("No requests yet", style: TextStyle(fontSize: 16, color: Color(0xFF9CA3AF))),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final docId = docs[index].id;
                      final status = data['status'] ?? 'Pending';
                      final lat = data['lat'] != null ? (data['lat'] as num).toDouble() : null;
                      final lng = data['lng'] != null ? (data['lng'] as num).toDouble() : null;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ─── Header ─────────────────
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE3EBF8),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.devices_rounded, color: Color(0xFF1A3A6C), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['device'] ?? 'Unknown Device',
                                          style: const TextStyle(
                                              fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1B2C4E)),
                                        ),
                                        const SizedBox(height: 3),
                                        _StatusBadge(status: status),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),
                              const Divider(height: 1, color: Color(0xFFF3F4F6)),
                              const SizedBox(height: 10),

                              // ─── Address ────────────────
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF9CA3AF)),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      data['address'] ?? '',
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                              if ((data['description'] ?? '').isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.notes_rounded, size: 14, color: Color(0xFF9CA3AF)),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        data['description'],
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              // Auto-proximity notice for accepted requests
                              if (status == "Accepted") ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F9FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFBAE6FD)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF0284C7)),
                                      SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          "Citizen will be auto-notified when you're within 500m",
                                          style: TextStyle(fontSize: 11, color: Color(0xFF0284C7)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 14),

                              // ─── Action Row ──────────────
                              Row(
                                children: [
                                  if (lat != null && lng != null) ...[
                                    _IconBtn(
                                      icon: Icons.map_outlined,
                                      tooltip: "View on map",
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ViewLocationPage(lat: lat, lng: lng),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _IconBtn(
                                      icon: Icons.directions_rounded,
                                      tooltip: "Open in Google Maps",
                                      onTap: () => openGoogleMaps(lat, lng),
                                    ),
                                  ],
                                  const Spacer(),

                                  // Action button — no "Arrived" (auto-handled by proximity)
                                  if (status == "Pending" && lat != null && lng != null)
                                    _ActionBtn(
                                      label: "Accept",
                                      color: const Color(0xFF1A3A6C),
                                      onTap: () => acceptRequest(docId, data["userId"], lat, lng),
                                    ),

                                  if (status == "Arrived")
                                    _ActionBtn(
                                      label: "Complete",
                                      color: const Color(0xFF2D6A4F),
                                      onTap: () => completePickup(docId, data["userId"]),
                                    ),

                                  if (status == "Completed")
                                    const Text("Done ✓",
                                        style: TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (status) {
      case "Accepted":  bg = const Color(0xFFE3EBF8); fg = const Color(0xFF1A3A6C); break;
      case "Completed": bg = const Color(0xFFE8F5E9); fg = const Color(0xFF2D6A4F); break;
      case "Arrived":   bg = const Color(0xFFF3E5F5); fg = const Color(0xFF7B1FA2); break;
      default:          bg = const Color(0xFFFFF3E0); fg = const Color(0xFFE65100);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: const Color(0xFF6B7280)),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
    );
  }
}