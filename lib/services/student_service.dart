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

  // Aktualizuj status course_paid i ZWRÓĆ zaktualizowanego studenta
  Future<Student> updateCoursePaidStatus(String studentId) async {
    // Pobierz kursanta
    final studentData = await _supabase
        .from('students')
        .select()
        .eq('id', studentId)
        .single();

    final coursePrice = (studentData['course_price'] as num?)?.toDouble() ?? 0;

    // Pobierz sumę płatności za kurs
    final paymentsData = await _supabase
        .from('payments')
        .select('amount')
        .eq('student_id', studentId)
        .eq('type', 'course');

    final totalPaid = (paymentsData as List).fold<double>(
      0.0,
      (sum, payment) => sum + (payment['amount'] as num).toDouble(),
    );

    final newCoursePaidStatus = totalPaid >= coursePrice;

    // Aktualizuj course_paid
    await _supabase
        .from('students')
        .update({'course_paid': newCoursePaidStatus})
        .eq('id', studentId);

    // Zwróć zaktualizowanego studenta
    studentData['course_paid'] = newCoursePaidStatus;
    return Student.fromJson(studentData);
  }

  // Zaktualizuj dane kursanta
  Future<void> updateStudent(
    String studentId,
    Map<String, dynamic> data,
  ) async {
    await _supabase.from('students').update(data).eq('id', studentId);
  }
}
