import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CollectorHomePage extends StatelessWidget {
  const CollectorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collector Dashboard'),
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
          'Welcome, Collector!\nView Requests | Update Status',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
