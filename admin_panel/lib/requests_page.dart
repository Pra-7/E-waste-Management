import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestsPage extends StatelessWidget {
  const RequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Pickup Requests",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("pickup_requests")
                  .snapshots(),

              builder: (context, snapshot) {

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No requests found"));
                }

                var docs = snapshot.data!.docs;

                return SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 40,
                      columns: const [
                        DataColumn(label: Text("Device")),
                        DataColumn(label: Text("Address")),
                        DataColumn(label: Text("User")),
                        DataColumn(label: Text("Status")),
                        DataColumn(label: Text("Action")),
                      ],
                      rows: docs.map((doc) {

                        var data = doc.data() as Map<String, dynamic>;

                        return DataRow(cells: [

                          DataCell(Text(data["device"] ?? "")),
                          DataCell(Text(data["address"] ?? "")),
                          DataCell(Text(data["userId"] ?? "")),

                          DataCell(
                            Text(
                              data["status"] ?? "",
                              style: TextStyle(
                                color: _statusColor(data["status"]),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection("pickup_requests")
                                    .doc(doc.id)
                                    .delete();
                              },
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case "Pending":
        return Colors.orange;
      case "Accepted":
        return Colors.blue;
      case "Completed":
        return Colors.green;
      case "Arrived":
        return Colors.purple;
      default:
        return Colors.black;
    }
  }
}