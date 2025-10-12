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

  // Dodaj instruktora (najpierw auth, potem users)
  Future<String> addInstructor({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    // Utwórz konto w auth
    final authResponse = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    if (authResponse.user == null) {
      throw Exception('Nie udało się utworzyć konta');
    }

    final userId = authResponse.user!.id;

    // Dodaj do tabeli users
    await _supabase.from('users').insert({
      'id': userId,
      'email': email,
      'role': 'instructor',
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
    });

    return userId;
  }

  // Aktualizuj instruktora
  Future<void> updateInstructor(String id, Map<String, dynamic> data) async {
    await _supabase.from('users').update(data).eq('id', id);
  }

  // Usuń instruktora
  Future<void> deleteInstructor(String id) async {
    // Sprawdź czy ma kursantów
    final studentsCount = await _supabase
        .from('students')
        .select('id')
        .eq('instructor_id', id)
        .count();

    if (studentsCount.count > 0) {
      throw Exception(
        'Nie można usunąć instruktora, który ma przypisanych kursantów',
      );
    }

    // Usuń z users (auth.users zostanie przez CASCADE)
    await _supabase.from('users').delete().eq('id', id);
  }
}
