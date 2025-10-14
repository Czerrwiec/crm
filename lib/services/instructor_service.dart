import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';

class InstructorService {
  final _supabase = Supabase.instance.client;

  // Pobierz wszystkich instruktorów z liczbą kursantów
  Future<List<Map<String, dynamic>>> getInstructorsWithStudentCount() async {
    // Pobierz instruktorów
    final instructors = await _supabase
        .from('users')
        .select('*')
        .eq('role', 'instructor')
        .order('last_name');

    // Dla każdego instruktora policz aktywnych kursantów
    final instructorsWithCount = <Map<String, dynamic>>[];

    for (final instructor in instructors) {
      final students = await _supabase
          .from('students')
          .select('id')
          .eq('instructor_id', instructor['id'])
          .eq('active', true); // Tylko aktywni

      instructorsWithCount.add({
        ...instructor,
        'students': [
          {'count': (students as List).length},
        ],
      });
    }

    return instructorsWithCount;
  }

  // Pobierz wszystkich instruktorów (dla dropdown)
  Future<List<AppUser>> getInstructors() async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('role', 'instructor')
        .order('last_name');

    return (response as List).map((json) => AppUser.fromJson(json)).toList();
  }

  // Pobierz jednego instruktora
  Future<AppUser> getInstructor(String id) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('id', id)
        .single();

    return AppUser.fromJson(response);
  }

  // TODO: Przenieść na backend (Edge Function z Admin API)
  // Obecnie signUp() przełącza sesję na nowego użytkownika,
  // więc admin zostaje wylogowany po dodaniu instruktora.
  // Można skorzystać z Supabase Edge Function
  Future<String> addInstructor({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    // Zapisz aktualną sesję admina
    final adminSession = _supabase.auth.currentSession;

    if (adminSession?.refreshToken == null) {
      throw Exception('Brak aktywnej sesji - zaloguj się ponownie');
    }

    // Utwórz nowe konto (to przełącza sesję na nowego użytkownika!)
    final authResponse = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    if (authResponse.user == null) {
      throw Exception('Nie udało się utworzyć konta');
    }

    final userId = authResponse.user!.id;

    try {
      // Przywróć sesję admina
      await _supabase.auth.setSession(adminSession!.refreshToken!);

      // Teraz RPC wykona się jako admin
      await _supabase.rpc(
        'create_instructor',
        params: {
          'p_user_id': userId,
          'p_email': email,
          'p_first_name': firstName,
          'p_last_name': lastName,
          'p_phone': phone,
        },
      );

      return userId;
    } catch (e) {
      print('Błąd dodawania do users: $e');
      rethrow;
    }
  }

  // Aktualizuj instruktora
  Future<void> updateInstructor(String id, Map<String, dynamic> data) async {
    await _supabase.from('users').update(data).eq('id', id);
  }

  // Usuń instruktora (przez funkcję server-side)
  Future<void> deleteInstructor(String id) async {
    try {
      await _supabase.rpc('delete_instructor', params: {'p_user_id': id});
    } catch (e) {
      if (e.toString().contains('active students')) {
        throw Exception(
          'Nie można usunąć instruktora, który ma przypisanych aktywnych kursantów',
        );
      }
      rethrow;
    }
  }
}
