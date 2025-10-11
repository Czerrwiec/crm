import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ustawienia')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.person),
            title: Text('Profil'),
            subtitle: Text('Zarządzaj swoim profilem'),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.school),
            title: Text('Dane szkoły jazdy'),
            subtitle: Text('Nazwa, adres, NIP'),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Powiadomienia'),
            subtitle: Text('Ustawienia powiadomień'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Wyloguj się',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              await AuthService().signOut();

              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false, // usuwa historię nawigacji
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
