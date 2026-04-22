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
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ─── Header ────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A3A6C),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(greeting(), style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7))),
                            const SizedBox(height: 4),
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection("users").doc(uid).get(),
                              builder: (context, snap) {
                                String name = "Collector";
                                if (snap.hasData) {
                                  final d = snap.data!.data() as Map<String, dynamic>;
                                  name = (d["name"] ?? "Collector").toString().split(" ").first;
                                }
                                return Text("Hey, $name! 👋", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white));
                              },
                            ),
                          ],
                        ),
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Stats row
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('pickup_requests')
                          .where('collectorId', isEqualTo: uid)
                          .snapshots(),
                      builder: (context, snap) {
                        int completed = 0, active = 0;
                        if (snap.hasData) {
                          for (var doc in snap.data!.docs) {
                            final d = doc.data() as Map<String, dynamic>;
                            if (d["status"] == "Completed") completed++;
                            if (d["status"] == "Accepted" || d["status"] == "Arrived") active++;
                          }
                        }
                        return Row(
                          children: [
                            _StatBadge(label: "Active", value: active.toString(), icon: Icons.local_shipping_outlined),
                            const SizedBox(width: 10),
                            _StatBadge(label: "Done", value: completed.toString(), icon: Icons.check_circle_outline_rounded),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ─── Action Cards ───────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const Text("Actions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1B2C4E))),
                  const SizedBox(height: 12),

                  _ActionCard(
                    icon: Icons.inbox_rounded,
                    title: "Pickup Requests",
                    subtitle: "View and accept pending requests",
                    color: const Color(0xFF1A3A6C),
                    bgColor: const Color(0xFFE3EBF8),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectorRequestsPage())),
                  ),

                  const SizedBox(height: 12),

                  _ActionCard(
                    icon: Icons.check_circle_rounded,
                    title: "Completed Pickups",
                    subtitle: "Your pickup history",
                    color: const Color(0xFF2D6A4F),
                    bgColor: const Color(0xFFE8F5E9),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompletedPickupsPage())),
                  ),

                  const SizedBox(height: 12),

                  _ActionCard(
                    icon: Icons.map_rounded,
                    title: "Navigation Map",
                    subtitle: "Navigate to accepted request",
                    color: const Color(0xFF7B1FA2),
                    bgColor: const Color(0xFFF3E5F5),
                    onTap: () async {
                      try {
                        var snapshot = await FirebaseFirestore.instance
                            .collection('pickup_requests')
                            .where('collectorId', isEqualTo: uid)
                            .where('status', isEqualTo: "Accepted")
                            .limit(1)
                            .get();

                        if (snapshot.docs.isNotEmpty) {
                          var data = snapshot.docs.first.data();
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => NavigationMapPage(
                              lat: (data["lat"] as num).toDouble(),
                              lng: (data["lng"] as num).toDouble(),
                            ),
                          ));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("No active accepted request")),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                      }
                    },
                  ),
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatBadge({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1B2C4E))),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}