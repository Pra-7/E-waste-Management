import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'login.dart';
import 'citizen/citizen_home.dart';
import 'collector/collector_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-Waste Management',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // 🔹 Firebase still checking login state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 🔹 No user logged in
        if (!snapshot.hasData) {
          return const LoginPage();
        }

        final user = snapshot.data!;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, roleSnapshot) {

            // 🔹 Firestore loading
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // 🔹 If Firestore user data does not exist
            if (!roleSnapshot.hasData || !roleSnapshot.data!.exists) {

              // Logout invalid user
              FirebaseAuth.instance.signOut();

              return const LoginPage();
            }

            final data =
                roleSnapshot.data!.data() as Map<String, dynamic>;

            final role = data['role'];

            // 🔹 Navigate based on role
            if (role == 'Collector') {
              return const CollectorHomePage();
            } else {
              return const CitizenHomePage();
            }
          },
        );
      },
    );
  }
}