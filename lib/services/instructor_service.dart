import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';

class InstructorService {
  final _supabase = Supabase.instance.client;

  // Pobierz wszystkich instruktorów
  Future<List<AppUser>> getInstructors() async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('role', 'instructor')
        .order('last_name');

    return (response as List).map((json) => AppUser.fromJson(json)).toList();
  }
}
