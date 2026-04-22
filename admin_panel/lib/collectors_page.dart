import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CollectorsPage extends StatefulWidget {
  const CollectorsPage({super.key});

  @override
  State<CollectorsPage> createState() => _CollectorsPageState();
}

class _CollectorsPageState extends State<CollectorsPage> {

  bool isLatestFirst = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// 🔥 TITLE + FILTER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              const Text(
                "Collectors",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              DropdownButton<String>(
                value: isLatestFirst ? "Latest" : "Oldest",
                items: const [
                  DropdownMenuItem(value: "Latest", child: Text("Latest")),
                  DropdownMenuItem(value: "Oldest", child: Text("Oldest")),
                ],
                onChanged: (value) {
                  setState(() {
                    isLatestFirst = value == "Latest";
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          /// 🔥 DATA TABLE
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .snapshots(),

              builder: (context, snapshot) {

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}"),
                  );
                }

                var allUsers = snapshot.data!.docs;

                /// ✅ FILTER COLLECTORS
                var collectors = allUsers.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return (data["role"] ?? "")
                      .toString()
                      .toLowerCase() == "collector";
                }).toList();

                /// 🔥 SORT
                collectors.sort((a, b) {
                  var aTime = a["createdAt"] ?? Timestamp.now();
                  var bTime = b["createdAt"] ?? Timestamp.now();

                  return isLatestFirst
                      ? bTime.compareTo(aTime)
                      : aTime.compareTo(bTime);
                });

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// TOTAL COUNT
                    Text(
                      "Total Collectors: ${collectors.length}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),

                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,

                          child: DataTable(
                            columnSpacing: 40,

                            columns: const [
                              DataColumn(label: Text("Email")),
                              DataColumn(label: Text("Role")),
                              DataColumn(label: Text("Pickups")),
                              DataColumn(label: Text("Action")),
                            ],

                            rows: collectors.map((doc) {

                              var data = doc.data() as Map<String, dynamic>;

                              return DataRow(cells: [

                                /// EMAIL
                                DataCell(Text(data["email"] ?? "")),

                                /// ROLE
                                const DataCell(Text("Collector")),

                                /// TOTAL PICKUPS (COMPLETED)
                                DataCell(
                                  FutureBuilder<QuerySnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection("pickup_requests")
                                        .where("collectorId", isEqualTo: doc.id)
                                        .where("status", isEqualTo: "Completed")
                                        .get(),
                                    builder: (context, snap) {

                                      if (!snap.hasData) {
                                        return const Text("...");
                                      }

                                      return Text(
                                        snap.data!.docs.length.toString(),
                                      );
                                    },
                                  ),
                                ),

                                /// DELETE BUTTON
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection("users")
                                          .doc(doc.id)
                                          .delete();

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Collector deleted"),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}