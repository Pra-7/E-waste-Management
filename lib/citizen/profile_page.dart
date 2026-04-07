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

      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection("users").doc(uid).get(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var user = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(

            child: Column(

              children: [

                /// PROFILE HEADER
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF4CAF50),
                        Color(0xFF2E7D32)
                      ],
                    ),
                  ),

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [

                      const SizedBox(height: 30),

                      CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white,
                        child: const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        user["name"] ?? "Citizen",
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        user["email"] ?? "",
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// ACCOUNT SETTINGS
                _menuItem(
                  context,
                  Icons.person,
                  "My Profile",
                  const MyProfilePage(),
                ),

                _menuItem(
                  context,
                  Icons.history,
                  "Pickup History",
                  const MyRequestsPage(),
                ),

                _menuItem(
                  context,
                  Icons.feedback,
                  "Feedback / Report Problem",
                  const FeedbackPage(),
                ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),

                  child: SizedBox(
                    width: double.infinity,

                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout),

                      label: const Text("Logout"),

                      onPressed: () async {

                        await FirebaseAuth.instance.signOut();

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 40)
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String title, Widget page) {

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),

      child: Card(

        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: const Icon(Icons.arrow_forward_ios, size: 18),

          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            );
          },
        ),
      ),
    );
  }
}