import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'map_picker.dart';

class RequestPickupPage extends StatefulWidget {
  const RequestPickupPage({super.key});

  @override
  State<RequestPickupPage> createState() => _RequestPickupPageState();
}

class _RequestPickupPageState extends State<RequestPickupPage> {

  final TextEditingController deviceController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  bool loading = false;

  double? selectedLat;
  double? selectedLng;

  /// SUBMIT REQUEST
  Future<void> submitRequest() async {

    if (selectedLat == null || selectedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select location from map")),
      );
      return;
    }

    try {
      setState(() {
        loading = true;
      });

      String uid = auth.currentUser!.uid;

      await firestore.collection("pickup_requests").add({
        "userId": uid,
        "device": deviceController.text,
        "address": addressController.text,
        "description": descriptionController.text,
        "status": "Pending",
        "createdAt": Timestamp.now(),

        /// MAP DATA
        "lat": selectedLat,
        "lng": selectedLng,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pickup request submitted")),
      );

      deviceController.clear();
      addressController.clear();
      descriptionController.clear();

      selectedLat = null;
      selectedLng = null;

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Pickup"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            /// DEVICE TYPE
            TextField(
              controller: deviceController,
              decoration: const InputDecoration(
                labelText: "Device Type (Laptop, Phone etc)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            /// ADDRESS (MAP PICKER)
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MapPickerPage(),
                  ),
                );

                if (result != null) {
                  setState(() {
                    selectedLat = result['lat'];
                    selectedLng = result['lng'];

                    addressController.text =
                        "${selectedLat!.toStringAsFixed(4)}, ${selectedLng!.toStringAsFixed(4)}";
                  });
                }
              },
              child: AbsorbPointer(
                child: TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: "Pickup Address (Tap to select on map)",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// DESCRIPTION
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            /// LOCATION STATUS
            if (selectedLat != null)
              const Text(
                "Location Selected ✔",
                style: TextStyle(color: Colors.green),
              ),

            const SizedBox(height: 20),

            /// SUBMIT BUTTON
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: submitRequest,
                    child: const Text("Submit Request"),
                  )
          ],
        ),
      ),
    );
  }
}