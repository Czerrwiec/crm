import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/auth/login_screen.dart';
import 'screens/instructor/instructor_home_screen.dart';
import 'services/auth_service.dart';
import 'screens/admin/admin_main_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('pl_PL', null);

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRM',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const AuthGate(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pl', 'PL'), // język polski
        Locale('en', 'US'), // fallback
      ],
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<AuthState>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Sprawdź czy użytkownik jest zalogowany
        if (snapshot.hasData && snapshot.data?.session != null) {
          return FutureBuilder<String?>(
            future: authService.getUserRole(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final role = roleSnapshot.data;

              if (role == 'admin') {
                return const AdminMainScreen();
              } else if (role == 'instructor') {
                return const InstructorHomeScreen();
              }

              // Jeśli rola nieznana
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Nieznana rola użytkownika',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),

                      ElevatedButton.icon(
                        onPressed: () async {
                          await AuthService().signOut();
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Wyloguj się'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
        // Nie zalogowany - pokaż ekran logowania
        return const LoginScreen();
      },
    );
  }
}
