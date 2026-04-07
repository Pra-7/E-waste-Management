import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompletedPickupsPage extends StatelessWidget {
  const CompletedPickupsPage({super.key});

  /// MARK COMPLETED + SEND NOTIFICATION
  Future<void> markCompleted(String docId, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection("pickup_requests")
          .doc(docId)
          .update({
        "status": "Completed",
      });

      /// ADD NOTIFICATION
      await FirebaseFirestore.instance.collection("notifications").add({
        "userId": userId,
        "message": "Your pickup has been completed",
        "createdAt": Timestamp.now(),
      });

    } catch (e) {
      print("Error completing pickup: $e");
    }
  }

  @override
  Widget build(BuildContext context) {

    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Completed Pickups"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("pickup_requests")
            .orderBy("createdAt", descending: true)
            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No requests found"));
          }

          var requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {

              var data = requests[index].data() as Map<String, dynamic>;
              String docId = requests[index].id;

              bool isAcceptedByMe =
                  data.containsKey("acceptedBy") &&
                  data["acceptedBy"] == currentUserId;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),

                child: ListTile(
                  title: Text(
                    data["device"] ?? "Unknown Device",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),

                      Text("📍 Address: ${data["address"] ?? ""}"),
                      Text("📝 Description: ${data["description"] ?? ""}"),
                      Text("📌 Status: ${data["status"] ?? ""}"),
                    ],
                  ),

                  /// 🔥 MAIN LOGIC HERE
                  trailing: data["status"] == "Accepted"
                      ? isAcceptedByMe
                          ? ElevatedButton(
                              onPressed: () {
                                markCompleted(docId, data["userId"]);
                              },
                              child: const Text("Complete"),
                            )
                          : const Text(
                              "Assigned to other",
                              style: TextStyle(color: Colors.grey),
                            )

                      : data["status"] == "Completed"
                          ? const Text(
                              "Completed",
                              style: TextStyle(color: Colors.green),
                            )

                      : const Text(
                          "Pending",
                          style: TextStyle(color: Colors.orange),
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