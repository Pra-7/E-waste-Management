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
  final deviceController = TextEditingController();
  final addressController = TextEditingController();
  final descriptionController = TextEditingController();

  bool loading = false;
  double? selectedLat;
  double? selectedLng;

  // Device type selection
  String? selectedDevice;
  final List<Map<String, dynamic>> deviceTypes = [
    {'label': 'Laptop', 'icon': Icons.laptop_rounded},
    {'label': 'Phone', 'icon': Icons.smartphone_rounded},
    {'label': 'TV', 'icon': Icons.tv_rounded},
    {'label': 'Tablet', 'icon': Icons.tablet_rounded},
    {'label': 'Other', 'icon': Icons.devices_other_rounded},
  ];

  Future<void> submitRequest() async {
    if (selectedLat == null || selectedLng == null) {
      _snack("Please select a pickup location on the map");
      return;
    }
    if ((selectedDevice ?? deviceController.text).isEmpty) {
      _snack("Please specify the device type");
      return;
    }

    try {
      setState(() => loading = true);
      String uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection("pickup_requests").add({
        "userId": uid,
        "device": selectedDevice ?? deviceController.text,
        "address": addressController.text,
        "description": descriptionController.text,
        "status": "Pending",
        "createdAt": Timestamp.now(),
        "lat": selectedLat,
        "lng": selectedLng,
      });

      _snack("Pickup request submitted successfully!");
      deviceController.clear();
      addressController.clear();
      descriptionController.clear();
      setState(() {
        selectedLat = null;
        selectedLng = null;
        selectedDevice = null;
      });
    } catch (e) {
      _snack("Error: $e");
    }
    setState(() => loading = false);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text("Request Pickup", style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ─── Device Type Chips ──────────────────────────
            const Text("What are you recycling?", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1B3A2D))),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: deviceTypes.map((d) {
                final bool selected = selectedDevice == d['label'];
                return GestureDetector(
                  onTap: () => setState(() {
                    selectedDevice = d['label'] as String;
                    deviceController.text = d['label'] as String;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF2D6A4F) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? const Color(0xFF2D6A4F) : const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(d['icon'] as IconData, size: 18, color: selected ? Colors.white : const Color(0xFF6B7280)),
                        const SizedBox(width: 6),
                        Text(
                          d['label'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : const Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            // Custom device input if "Other"
            if (selectedDevice == "Other") ...[
              const SizedBox(height: 12),
              _inputField(
                controller: deviceController,
                hint: "Describe the device...",
                icon: Icons.device_unknown_outlined,
              ),
            ],

            const SizedBox(height: 24),

            // ─── Location Picker ────────────────────────────
            const Text("Pickup Location", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1B3A2D))),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const MapPickerPage()));
                if (result != null) {
                  setState(() {
                    selectedLat = result['lat'];
                    selectedLng = result['lng'];
                    addressController.text = "${selectedLat!.toStringAsFixed(5)}, ${selectedLng!.toStringAsFixed(5)}";
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selectedLat != null ? const Color(0xFF2D6A4F) : const Color(0xFFE5E7EB),
                    width: selectedLat != null ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selectedLat != null ? const Color(0xFFE8F5E9) : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: selectedLat != null ? const Color(0xFF2D6A4F) : const Color(0xFF9CA3AF),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedLat != null ? "Location selected" : "Tap to select on map",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: selectedLat != null ? const Color(0xFF2D6A4F) : const Color(0xFF6B7280),
                            ),
                          ),
                          if (selectedLat != null)
                            Text(addressController.text, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                        ],
                      ),
                    ),
                    Icon(
                      selectedLat != null ? Icons.check_circle_rounded : Icons.map_outlined,
                      color: selectedLat != null ? const Color(0xFF2D6A4F) : const Color(0xFF9CA3AF),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ─── Description ────────────────────────────────
            const Text("Additional Notes", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1B3A2D))),
            const SizedBox(height: 12),
            _inputField(
              controller: descriptionController,
              hint: "Any special instructions, condition of device...",
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            // ─── Submit ──────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F)))
                  : ElevatedButton(
                      onPressed: submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D6A4F),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.recycling_rounded, size: 20),
                          SizedBox(width: 8),
                          Text("Submit Request", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2D6A4F), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      ),
    );
  }
}