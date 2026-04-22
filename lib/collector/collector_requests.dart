import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../view_location.dart';

class CollectorRequestsPage extends StatelessWidget {
  const CollectorRequestsPage({super.key});

  Future<void> openGoogleMaps(double lat, double lng) async {
    final Uri url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    if (await launchUrl(url, mode: LaunchMode.externalApplication));
    else throw 'Could not launch Google Maps';
  }

  Future<void> acceptRequest(String docId, String userId) async {
    String collectorId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('pickup_requests').doc(docId).update({
      "status": "Accepted",
      "collectorId": collectorId,
      "collectorLat": 27.7172,
      "collectorLng": 85.3240,
    });
    await FirebaseFirestore.instance.collection('notifications').add({
      "userId": userId,
      "message": "Your pickup request has been accepted by a collector",
      "createdAt": Timestamp.now(),
    });
  }

  Future<void> markArrived(String docId, String userId) async {
    await FirebaseFirestore.instance.collection('pickup_requests').doc(docId).update({"status": "Arrived"});
    await FirebaseFirestore.instance.collection('notifications').add({
      "userId": userId,
      "message": "Your collector has arrived at your location",
      "createdAt": Timestamp.now(),
    });
  }

  Future<void> completePickup(String docId, String userId) async {
    await FirebaseFirestore.instance.collection('pickup_requests').doc(docId).update({"status": "Completed"});
    await FirebaseFirestore.instance.collection('notifications').add({
      "userId": userId,
      "message": "Your e-waste pickup has been completed. Thank you!",
      "createdAt": Timestamp.now(),
    });
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
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: const Text("Pickup Requests", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1B2C4E))),
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

                  var docs = snapshot.data!.docs;

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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      String docId = docs[index].id;
                      String status = data['status'] ?? 'Pending';

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
                              // Header row
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
                                        Text(data['device'] ?? 'Unknown', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1B2C4E))),
                                        const SizedBox(height: 2),
                                        _StatusBadge(status: status),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),
                              const Divider(height: 1, color: Color(0xFFF3F4F6)),
                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF9CA3AF)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(data['address'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)), overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              // Action row
                              Row(
                                children: [
                                  // View on map
                                  _IconBtn(
                                    icon: Icons.map_outlined,
                                    tooltip: "View Location",
                                    onTap: () {
                                      if (data["lat"] != null && data["lng"] != null) {
                                        Navigator.push(context, MaterialPageRoute(
                                          builder: (_) => ViewLocationPage(
                                            lat: (data["lat"] as num).toDouble(),
                                            lng: (data["lng"] as num).toDouble(),
                                          ),
                                        ));
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  // Directions
                                  _IconBtn(
                                    icon: Icons.directions_rounded,
                                    tooltip: "Get Directions",
                                    onTap: () {
                                      if (data["lat"] != null && data["lng"] != null) {
                                        openGoogleMaps((data["lat"] as num).toDouble(), (data["lng"] as num).toDouble());
                                      }
                                    },
                                  ),

                                  const Spacer(),

                                  // Action button
                                  if (status == "Pending")
                                    _ActionBtn(
                                      label: "Accept",
                                      color: const Color(0xFF1A3A6C),
                                      onTap: () => acceptRequest(docId, data["userId"]),
                                    ),
                                  if (status == "Accepted")
                                    _ActionBtn(
                                      label: "I've Arrived",
                                      color: const Color(0xFF7B1FA2),
                                      onTap: () => markArrived(docId, data["userId"]),
                                    ),
                                  if (status == "Arrived")
                                    _ActionBtn(
                                      label: "Complete",
                                      color: const Color(0xFF2D6A4F),
                                      onTap: () => completePickup(docId, data["userId"]),
                                    ),
                                  if (status == "Completed")
                                    const Text("Done", style: TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.w700)),
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
      case "Accepted":
        bg = const Color(0xFFE3EBF8); fg = const Color(0xFF1A3A6C); break;
      case "Completed":
        bg = const Color(0xFFE8F5E9); fg = const Color(0xFF2D6A4F); break;
      case "Arrived":
        bg = const Color(0xFFF3E5F5); fg = const Color(0xFF7B1FA2); break;
      default:
        bg = const Color(0xFFFFF3E0); fg = const Color(0xFFE65100);
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
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
    );
  }
}