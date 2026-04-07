import 'package:flutter/material.dart';
import 'collector_home.dart';
import 'collector_requests.dart';
import 'completed_pickups.dart';
import 'collector_profile.dart';

class CollectorMainPage extends StatefulWidget {
  const CollectorMainPage({super.key});

  @override
  State<CollectorMainPage> createState() => _CollectorMainPageState();
}

class _CollectorMainPageState extends State<CollectorMainPage> {

  int currentIndex = 0;

  final pages = const [
    CollectorHomePage(),
    CollectorRequestsPage(),
    CompletedPickupsPage(),
    CollectorProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: pages[currentIndex],

      bottomNavigationBar: BottomNavigationBar(

        currentIndex: currentIndex,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        type: BottomNavigationBarType.fixed,

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: "Requests",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: "Completed",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),

        ],
      ),
    );
  }
}