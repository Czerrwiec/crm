import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class InstructorHomeScreen extends StatelessWidget {
  const InstructorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Instruktora'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Widok Instruktora - wkrótce twoi kursanci',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}