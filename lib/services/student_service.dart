import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student.dart';

class StudentService {
  final _supabase = Supabase.instance.client;

  // Pobierz kursantów z JOIN do instruktorów
  Future<List<Map<String, dynamic>>> getStudentsWithInstructors() async {
    final response = await _supabase
        .from('students')
        .select('''
          *,
          instructor:instructor_id (
            first_name,
            last_name
          )
        ''')
        .order('last_name');

    return List<Map<String, dynamic>>.from(response as List);
  }
}