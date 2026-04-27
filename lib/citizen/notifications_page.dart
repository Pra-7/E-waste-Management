import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F0),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: const Text(
                "Notifications",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1B3A2D)),
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // FIX: removed orderBy — using only .where() avoids the
                // composite index requirement that causes infinite loading.
                // Sorting is done client-side below.
                stream: FirebaseFirestore.instance
                    .collection("notifications")
                    .where("userId", isEqualTo: user.uid)
                    .snapshots(),

                builder: (context, snapshot) {
                  // Show error details instead of spinning forever
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 40),
                          const SizedBox(height: 10),
                          Text(
                            "Error: ${snapshot.error}",
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F)));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text("No notifications yet", style: TextStyle(fontSize: 16, color: Color(0xFF9CA3AF))),
                          const SizedBox(height: 4),
                          const Text("You'll be notified when your request is updated", style: TextStyle(fontSize: 13, color: Color(0xFFD1D5DB))),
                        ],
                      ),
                    );
                  }

                  // Sort client-side by createdAt descending
                  var notifications = snapshot.data!.docs.toList();
                  notifications.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aTs = aData['createdAt'] as Timestamp?;
                    final bTs = bData['createdAt'] as Timestamp?;
                    if (aTs == null && bTs == null) return 0;
                    if (aTs == null) return 1;
                    if (bTs == null) return -1;
                    return bTs.compareTo(aTs); // newest first
                  });

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final data = notifications[index].data() as Map<String, dynamic>;
                      final String message = data["message"] ?? "";
                      final Timestamp? ts = data["createdAt"];
                      final DateTime? date = ts?.toDate();

                      // Pick icon based on message content
                      IconData notifIcon = Icons.eco_rounded;
                      Color notifColor = const Color(0xFF2D6A4F);
                      Color notifBg = const Color(0xFFE8F5E9);

                      if (message.contains("accepted") || message.contains("on their way")) {
                        notifIcon = Icons.local_shipping_rounded;
                        notifColor = const Color(0xFF1A3A6C);
                        notifBg = const Color(0xFFE3EBF8);
                      } else if (message.contains("almost") || message.contains("500m") || message.contains("arrived")) {
                        notifIcon = Icons.location_on_rounded;
                        notifColor = const Color(0xFF7B1FA2);
                        notifBg = const Color(0xFFF3E5F5);
                      } else if (message.contains("completed")) {
                        notifIcon = Icons.check_circle_rounded;
                        notifColor = const Color(0xFF2D6A4F);
                        notifBg = const Color(0xFFE8F5E9);
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: notifBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(notifIcon, color: notifColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1B3A2D),
                                    ),
                                  ),
                                  if (date != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('MMM d, h:mm a').format(date),
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
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