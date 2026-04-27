import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../view_location.dart';

class MyRequestsPage extends StatelessWidget {
  const MyRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F0),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: const Text(
                "My Requests",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1B3A2D)),
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("pickup_requests")
                    .where("userId", isEqualTo: userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F)));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Something went wrong", style: TextStyle(color: Colors.red.shade400)));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text("No pickup requests yet", style: TextStyle(fontSize: 16, color: Color(0xFF9CA3AF))),
                          const SizedBox(height: 4),
                          const Text("Tap Request Pickup to get started", style: TextStyle(fontSize: 13, color: Color(0xFFD1D5DB))),
                        ],
                      ),
                    );
                  }

                  var requests = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      var data = requests[index].data() as Map<String, dynamic>;
                      String docId = requests[index].id; // ← needed for live tracking
                      String status = data["status"] ?? "Pending";
                      final statusConfig = _statusConfig(status);

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
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: statusConfig['bg'] as Color,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(statusConfig['icon'] as IconData, color: statusConfig['color'] as Color, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data["device"] ?? "Unknown Device",
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1B3A2D)),
                                        ),
                                        const SizedBox(height: 3),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: statusConfig['bg'] as Color,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusConfig['color'] as Color),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),
                              const Divider(height: 1, color: Color(0xFFF3F4F6)),
                              const SizedBox(height: 10),

                              // Address (real name now)
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF9CA3AF)),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      data["address"] ?? "",
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                              if ((data["description"] ?? "").isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(Icons.notes_rounded, size: 14, color: Color(0xFF9CA3AF)),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(data["description"], style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)), overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              ],

                              // "Almost there" banner when status is Arrived
                              if (status == "Arrived") ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3E5F5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.local_shipping_rounded, size: 14, color: Color(0xFF7B1FA2)),
                                      SizedBox(width: 6),
                                      Text("Collector is almost at your location!", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF7B1FA2))),
                                    ],
                                  ),
                                ),
                              ],

                              // Track button (Accepted or Arrived)
                              if (status == "Accepted" || status == "Arrived") ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      if (data["lat"] == null || data["lng"] == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Location not available yet")),
                                        );
                                        return;
                                      }
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ViewLocationPage(
                                            lat: (data["lat"] as num).toDouble(),
                                            lng: (data["lng"] as num).toDouble(),
                                            docId: docId, // ← passes docId for live stream
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.my_location_rounded, size: 16),
                                    label: const Text("Track Collector Live"),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF2D6A4F),
                                      side: const BorderSide(color: Color(0xFF2D6A4F)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ],
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

  Map<String, dynamic> _statusConfig(String status) {
    switch (status) {
      case "Accepted":
        return {'icon': Icons.local_shipping_rounded, 'color': const Color(0xFF1565C0), 'bg': const Color(0xFFE3F2FD)};
      case "Completed":
        return {'icon': Icons.check_circle_rounded, 'color': const Color(0xFF2D6A4F), 'bg': const Color(0xFFE8F5E9)};
      case "Arrived":
        return {'icon': Icons.location_on_rounded, 'color': const Color(0xFF7B1FA2), 'bg': const Color(0xFFF3E5F5)};
      default:
        return {'icon': Icons.hourglass_bottom_rounded, 'color': const Color(0xFFE65100), 'bg': const Color(0xFFFFF3E0)};
    }
  }
}