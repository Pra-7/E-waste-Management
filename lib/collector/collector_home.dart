import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'collector_requests.dart';
import 'completed_pickups.dart';
import 'navigation_map.dart';

class CollectorHomePage extends StatelessWidget {
  const CollectorHomePage({super.key});

  String greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Collector Dashboard"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            /// Greeting
            Text(
              greeting(),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Welcome Collector",
              style: TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 30),

            /// 🔵 View Pickup Requests
            Card(
              child: ListTile(
                leading: const Icon(Icons.list),
                title: const Text("View Pickup Requests"),
                trailing: const Icon(Icons.arrow_forward),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CollectorRequestsPage(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            /// 🟢 Completed Pickups
            Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text("Completed Pickups"),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CompletedPickupsPage(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            /// 🗺️ Navigation Map (UPDATED)
            Card(
              child: ListTile(
                leading: const Icon(Icons.map),
                title: const Text("Navigation Map"),
                trailing: const Icon(Icons.arrow_forward),

                onTap: () async {
                  try {

                    var snapshot = await FirebaseFirestore.instance
                        .collection('pickup_requests')
                        .where('collectorId',
                            isEqualTo:
                                FirebaseAuth.instance.currentUser!.uid)
                        .where('status', isEqualTo: "Accepted")
                        .limit(1)
                        .get();

                    if (snapshot.docs.isNotEmpty) {
                      var data = snapshot.docs.first.data();

                      double lat =
                          (data["lat"] as num).toDouble();
                      double lng =
                          (data["lng"] as num).toDouble();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NavigationMapPage(
                            lat: lat,
                            lng: lng,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("No active accepted request"),
                        ),
                      );
                    }

                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: $e")),
                    );
                  }
                },
              ),
            ),

          ],
        ),
      ),
    );
  }
}