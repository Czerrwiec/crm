import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'admin_home_screen.dart';
import 'instructors_screen.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 1; // Domyślnie "Kursanci"

  final List<Widget> _screens = [
    const DashboardScreen(),
    const AdminHomeScreen(),
    const InstructorsScreen(),
    const CalendarScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Kursanci'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Instruktorzy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Kalendarz',
          ),
        ],
      ),
    );
  }
}
