import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../view_location.dart';

class CollectorRequestsPage extends StatelessWidget {
  const CollectorRequestsPage({super.key});

  /// GOOGLE MAP ROUTE
  Future<void> openGoogleMaps(double lat, double lng) async {
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );

    if (await launchUrl(
      googleMapsUrl,
      mode: LaunchMode.externalApplication,
      ));
    else {
      throw 'Could not launch Google Maps';
    }
  }

  /// ACCEPT REQUEST
  Future<void> acceptRequest(String docId, String userId) async {
    String collectorId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('pickup_requests')
        .doc(docId)
        .update({
      "status": "Accepted",
      "collectorId": collectorId,
      "collectorLat": 27.7172,
      "collectorLng": 85.3240,
    });

    await FirebaseFirestore.instance.collection('notifications').add({
      "userId": userId,
      "message": "Your pickup request has been accepted",
      "createdAt": Timestamp.now(),
    });
  }

  /// MARK ARRIVED
  Future<void> markArrived(String docId, String userId) async {
    await FirebaseFirestore.instance
        .collection('pickup_requests')
        .doc(docId)
        .update({
      "status": "Arrived",
    });

    await FirebaseFirestore.instance.collection('notifications').add({
      "userId": userId,
      "message": "🚚 Collector has arrived at your location",
      "createdAt": Timestamp.now(),
    });
  }

  /// COMPLETE
  Future<void> completePickup(String docId, String userId) async {
    await FirebaseFirestore.instance
        .collection('pickup_requests')
        .doc(docId)
        .update({
      "status": "Completed",
    });

    await FirebaseFirestore.instance.collection('notifications').add({
      "userId": userId,
      "message": "Your pickup has been completed",
      "createdAt": Timestamp.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pickup Requests")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pickup_requests')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No requests"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String docId = docs[index].id;

              return Card(
                margin: const EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Device: ${data['device'] ?? ''}",
                          style: const TextStyle(fontSize: 16)),
                      Text("📍 ${data['address'] ?? ''}"),
                      Text("Status: ${data['status'] ?? ''}"),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          /// MAP
                          IconButton(
                            icon: const Icon(Icons.map),
                            onPressed: () {
                              if (data["lat"] != null &&
                                  data["lng"] != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ViewLocationPage(
                                      lat: (data["lat"] as num).toDouble(),
                                      lng: (data["lng"] as num).toDouble(),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),

                          /// ROUTE
                          IconButton(
                            icon: const Icon(Icons.directions),
                            onPressed: () {
                              if (data["lat"] != null &&
                                  data["lng"] != null) {
                                double lat =
                                    (data["lat"] as num).toDouble();
                                double lng =
                                    (data["lng"] as num).toDouble();

                                openGoogleMaps(lat, lng);
                              }
                            },
                          ),

                          const Spacer(),

                          /// BUTTONS
                          if (data["status"] == "Pending")
                            ElevatedButton(
                              onPressed: () {
                                acceptRequest(docId, data["userId"]);
                              },
                              child: const Text("Accept"),
                            ),

                          if (data["status"] == "Accepted")
                            ElevatedButton(
                              onPressed: () {
                                markArrived(docId, data["userId"]); // ✅ FIX
                              },
                              child: const Text("Arrived"),
                            ),

                          if (data["status"] == "Arrived")
                            ElevatedButton(
                              onPressed: () {
                                completePickup(docId, data["userId"]);
                              },
                              child: const Text("Complete"),
                            ),
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
    );
  }
}