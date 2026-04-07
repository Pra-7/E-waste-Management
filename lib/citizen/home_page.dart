import 'package:flutter/material.dart';
import './request_pickup.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("E-Waste App"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            /// GREETING
            Text(
              greeting(),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              "Welcome Back",
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 30),

            /// REQUEST PICKUP
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),

              child: ListTile(
                leading: const Icon(Icons.recycling, color: Colors.green),
                title: const Text("Request Pickup"),
                trailing: const Icon(Icons.arrow_forward),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RequestPickupPage(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 15),

            /// E-WASTE TIPS
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),

              child: ListTile(
                leading: const Icon(Icons.lightbulb, color: Colors.orange),
                title: const Text("E-Waste Tips"),

                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("E-Waste Tips"),
                      content: const Text(
                        "• Do not throw electronics in trash\n"
                        "• Recycle properly\n"
                        "• Donate usable devices\n"
                        "• Avoid burning e-waste",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("OK"),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}