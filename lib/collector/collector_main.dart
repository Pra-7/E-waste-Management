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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_rounded, label: "Home", index: 0, currentIndex: currentIndex, color: const Color(0xFF1A3A6C), onTap: (i) => setState(() => currentIndex = i)),
                _NavItem(icon: Icons.inbox_rounded, label: "Requests", index: 1, currentIndex: currentIndex, color: const Color(0xFF1A3A6C), onTap: (i) => setState(() => currentIndex = i)),
                _NavItem(icon: Icons.check_circle_rounded, label: "Completed", index: 2, currentIndex: currentIndex, color: const Color(0xFF1A3A6C), onTap: (i) => setState(() => currentIndex = i)),
                _NavItem(icon: Icons.person_rounded, label: "Profile", index: 3, currentIndex: currentIndex, color: const Color(0xFF1A3A6C), onTap: (i) => setState(() => currentIndex = i)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final Color color;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool selected = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: selected ? color : const Color(0xFF9CA3AF)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? color : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}