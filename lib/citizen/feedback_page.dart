import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController controller = TextEditingController();
  String selectedCategory = "General";
  bool loading = false;

  final List<Map<String, dynamic>> categories = [
    {'label': 'General', 'icon': Icons.chat_bubble_outline_rounded},
    {'label': 'Bug Report', 'icon': Icons.bug_report_outlined},
    {'label': 'Collector Issue', 'icon': Icons.local_shipping_outlined},
    {'label': 'Suggestion', 'icon': Icons.lightbulb_outline_rounded},
  ];

  Future<void> sendFeedback() async {
    if (controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write your feedback"), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => loading = true);

    await FirebaseFirestore.instance.collection("feedback").add({
      "userId": FirebaseAuth.instance.currentUser!.uid,
      "category": selectedCategory,
      "message": controller.text.trim(),
      "createdAt": Timestamp.now(),
    });

    controller.clear();
    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Thanks for your feedback!"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2D6A4F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
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
        title: const Text("Feedback", style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Illustration area
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.favorite_rounded, color: Color(0xFF2D6A4F), size: 40),
                  const SizedBox(height: 10),
                  const Text(
                    "We'd love to hear from you",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1B3A2D)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Your feedback helps us improve EcoPickup",
                    style: TextStyle(fontSize: 13, color: const Color(0xFF2D6A4F).withOpacity(0.75)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Category
            const Text("Category", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1B3A2D))),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final bool selected = selectedCategory == cat['label'];
                return GestureDetector(
                  onTap: () => setState(() => selectedCategory = cat['label'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF2D6A4F) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selected ? const Color(0xFF2D6A4F) : const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat['icon'] as IconData, size: 16, color: selected ? Colors.white : const Color(0xFF6B7280)),
                        const SizedBox(width: 6),
                        Text(
                          cat['label'] as String,
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

            const SizedBox(height: 20),

            // Message
            const Text("Your Message", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1B3A2D))),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: "Tell us what's on your mind...",
                hintStyle: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2D6A4F), width: 1.5)),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F)))
                  : ElevatedButton(
                      onPressed: sendFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D6A4F),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("Submit Feedback", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}