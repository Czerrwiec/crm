import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // Sprawdź czy użytkownik jest zalogowany
  User? get currentUser => _supabase.auth.currentUser;

  // Stream zmian stanu autoryzacji
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Logowanie
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Wylogowanie
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Pobierz rolę użytkownika
  Future<String?> getUserRole() async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('users')
        .select('role')
        .eq('id', userId)
        .single();

    return response['role'] as String?;
  }
}