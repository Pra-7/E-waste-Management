import 'package:flutter/material.dart';
import 'home_page.dart';
import 'my_requests.dart';
import 'notifications_page.dart';
import 'profile_page.dart';

class CitizenMainPage extends StatefulWidget {
  const CitizenMainPage({super.key});

  @override
  State<CitizenMainPage> createState() => _CitizenMainPageState();
}

class _CitizenMainPageState extends State<CitizenMainPage> {

  int currentIndex = 0;

  final pages = const [
    HomePage(),
    MyRequestsPage(),
    NotificationsPage(),
    ProfilePage(),
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
            icon: Icon(Icons.notifications),
            label: "Notifications",
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