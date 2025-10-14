import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

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
              // Pokaż dialog potwierdzenia
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Wyloguj się'),
                  content: const Text('Czy na pewno chcesz się wylogować?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Anuluj'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Wyloguj'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await AuthService().signOut();
                // Zamknij ekran ustawień
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}
