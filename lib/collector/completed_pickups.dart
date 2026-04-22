// ─────────────────────────────────────────────────────────
//  completed_pickups.dart
// ─────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompletedPickupsPage extends StatelessWidget {
  const CompletedPickupsPage({super.key});

  Future<void> markCompleted(String docId, String userId) async {
    try {
      await FirebaseFirestore.instance.collection("pickup_requests").doc(docId).update({"status": "Completed"});
      await FirebaseFirestore.instance.collection("notifications").add({
        "userId": userId,
        "message": "Your pickup has been completed. Thank you for recycling!",
        "createdAt": Timestamp.now(),
      });
    } catch (e) {
      debugPrint("Error completing pickup: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: const Text("Completed Pickups", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1B2C4E))),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("pickup_requests")
                    .orderBy("createdAt", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF1A3A6C)));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text("No requests found", style: TextStyle(fontSize: 16, color: Color(0xFF9CA3AF))),
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
                      String docId = requests[index].id;
                      String status = data["status"] ?? "Pending";

                      bool isAcceptedByMe = data.containsKey("acceptedBy") && data["acceptedBy"] == currentUserId;

                      Color statusColor;
                      switch (status) {
                        case "Completed": statusColor = const Color(0xFF2D6A4F); break;
                        case "Accepted": statusColor = const Color(0xFF1A3A6C); break;
                        default: statusColor = const Color(0xFFE65100);
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    status == "Completed" ? Icons.check_circle_rounded : Icons.local_shipping_rounded,
                                    color: statusColor,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(data["device"] ?? "Unknown Device", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1B2C4E))),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text("📍 ${data["address"] ?? ""}", style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                            if ((data["description"] ?? "").isNotEmpty)
                              Text("📝 ${data["description"]}", style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                            if (status == "Accepted") ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: isAcceptedByMe
                                    ? ElevatedButton(
                                        onPressed: () => markCompleted(docId, data["userId"]),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2D6A4F),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        child: const Text("Mark Complete"),
                                      )
                                    : Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
                                        child: const Text("Assigned to other collector", style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                                      ),
                              ),
                            ],
                          ],
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