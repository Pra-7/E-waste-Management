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
      appBar: AppBar(
        title: const Text("My Requests"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("pickup_requests")
            .where("userId", isEqualTo: userId)
            .snapshots(),

        builder: (context, snapshot) {

          /// LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          /// ERROR
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          /// NO DATA
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No requests yet"));
          }

          var requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {

              var data = requests[index].data() as Map<String, dynamic>;

              String status = data["status"] ?? "Pending";

              Color statusColor;
              IconData statusIcon;

              switch (status) {
                case "Accepted":
                  statusColor = Colors.blue;
                  statusIcon = Icons.local_shipping;
                  break;
                case "Completed":
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle;
                  break;
                case "Arrived":
                  statusColor = Colors.purple;
                  statusIcon = Icons.location_on;
                  break;
                default:
                  statusColor = Colors.orange;
                  statusIcon = Icons.hourglass_bottom;
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),

                child: ListTile(
                  leading: Icon(statusIcon, color: statusColor),

                  title: Text(
                    data["device"] ?? "Unknown Device",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text("📍 ${data["address"] ?? ""}"),
                      Text("📝 ${data["description"] ?? ""}"),
                    ],
                  ),

                  /// ✅ FIXED TRAILING (NO OVERFLOW + SAFE)
                  trailing: SizedBox(
                    width: 90,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        /// STATUS
                        Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 5),

                        /// TRACK BUTTON
                        if (status == "Accepted" || status == "Arrived")
                          GestureDetector(
                            onTap: () {

                              /// 🔥 SAFE CHECK (NO CRASH)
                              if (data["lat"] == null ||
                                  data["lng"] == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Location not available")),
                                );
                                return;
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ViewLocationPage(

                                    /// USER LOCATION
                                    lat: (data["lat"] as num).toDouble(),
                                    lng: (data["lng"] as num).toDouble(),

                                    /// COLLECTOR LOCATION (SAFE)
                                    collectorLat:
                                        data["collectorLat"] != null
                                            ? (data["collectorLat"] as num)
                                                .toDouble()
                                            : null,

                                    collectorLng:
                                        data["collectorLng"] != null
                                            ? (data["collectorLng"] as num)
                                                .toDouble()
                                            : null,
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              "Track",
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
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