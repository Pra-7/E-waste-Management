import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../login.dart';
import 'my_profile_page.dart';
import 'my_requests.dart';
import 'feedback_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F0),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection("users").doc(uid).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F)));
          }

          var user = snapshot.data!.data() as Map<String, dynamic>;
          final String name = user["name"] ?? "Citizen";
          final String email = user["email"] ?? "";
          final String initials = name.trim().isNotEmpty
              ? name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
              : "C";

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ─── Profile Header ─────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2D6A4F),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2D6A4F),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(email, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75))),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text("Citizen", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── Menu Items ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Account", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF), letterSpacing: 0.8)),
                        const SizedBox(height: 8),
                        _menuCard(context, [
                          _MenuItem(Icons.person_outline_rounded, "My Profile", const Color(0xFF2D6A4F), const MyProfilePage()),
                          _MenuItem(Icons.history_rounded, "Pickup History", const Color(0xFF1565C0), const MyRequestsPage()),
                          _MenuItem(Icons.chat_bubble_outline_rounded, "Feedback & Reports", const Color(0xFFE65100), const FeedbackPage()),
                        ]),

                        const SizedBox(height: 28),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.logout_rounded, size: 20),
                            label: const Text("Sign Out", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginPage()),
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFEE2E2),
                              foregroundColor: const Color(0xFFDC2626),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _menuCard(BuildContext context, List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                title: Text(item.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1B3A2D))),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF9CA3AF)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => item.page)),
              ),
              if (i < items.length - 1)
                const Divider(height: 1, indent: 66, endIndent: 16, color: Color(0xFFF3F4F6)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final Color color;
  final Widget page;
  const _MenuItem(this.icon, this.title, this.color, this.page);
}