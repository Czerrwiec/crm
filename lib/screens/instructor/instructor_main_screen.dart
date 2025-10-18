import 'package:flutter/material.dart';
import 'instructor_students_screen.dart';
import 'instructor_home_screen.dart';

class InstructorMainScreen extends StatefulWidget {
  const InstructorMainScreen({super.key});

  @override
  State<InstructorMainScreen> createState() => _InstructorMainScreenState();
}

class _InstructorMainScreenState extends State<InstructorMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const InstructorStudentsScreen(),
    const InstructorHomeScreen(),
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Kursanci'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Kalendarz',
          ),
        ],
      ),
    );
  }
}
