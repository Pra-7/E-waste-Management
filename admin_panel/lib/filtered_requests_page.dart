import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FilteredRequestsPage extends StatelessWidget {
  final String status;

  const FilteredRequestsPage({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$status Requests")),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("pickup_requests")
            .where("status", isEqualTo: status)
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {

              var data = docs[index].data() as Map<String, dynamic>;

              return ListTile(
                title: Text(data["device"] ?? ""),
                subtitle: Text(data["address"] ?? ""),
              );
            },
          );
        },
      ),
    );
  }
}