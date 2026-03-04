import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CitizenHomePage extends StatelessWidget {
  const CitizenHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Citizen Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          )
        ],
      ),
      body: const Center(
        child: Text(
          'Welcome, Citizen!\nRequest Pickup | Tips | Profile',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
