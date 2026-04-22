import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'requests_page.dart';
import 'citizens_page.dart';
import 'collectors_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {

  int selectedIndex = 0;

  final pages = const [
    DashboardPage(),
    RequestsPage(),
    CitizensPage(),
    CollectorsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [

          /// 🔥 SIDEBAR
          Container(
            width: 220,
            color: Colors.green[700],
            child: Column(
              children: [

                const SizedBox(height: 40),

                const Text(
                  "ADMIN PANEL",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                _menuItem("Dashboard", 0, Icons.dashboard),
                _menuItem("Pickup Requests", 1, Icons.list),
                _menuItem("Citizens", 2, Icons.people),
                _menuItem("Collectors", 3, Icons.local_shipping),
              ],
            ),
          ),

          /// 🔥 RIGHT SIDE CONTENT
          Expanded(
            child: pages[selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _menuItem(String title, int index, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),

      selected: selectedIndex == index,

      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
    );
  }
}