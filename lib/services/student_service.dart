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
    final studentData = await _supabase
        .from('students')
        .select()
        .eq('id', studentId)
        .single();

    final coursePrice = (studentData['course_price'] as num?)?.toDouble() ?? 0;

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

    await _supabase
        .from('students')
        .update({'course_paid': newCoursePaidStatus})
        .eq('id', studentId);

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

  // Dodaj nowego kursanta
  Future<String> addStudent(Map<String, dynamic> data) async {
    final response = await _supabase
        .from('students')
        .insert(data)
        .select('id')
        .single();

    return response['id'] as String;
  }

  // Pobierz kursantów z filtrowaniem
  Future<List<Student>> getStudents({bool? activeOnly}) async {
    var query = _supabase.from('students').select();

    if (activeOnly == true) {
      query = query.eq('active', true);
    }

    final response = await query.order('last_name');
    return (response as List).map((json) => Student.fromJson(json)).toList();
  }

  // ✅ ZMIENIONE - Zaktualizuj godziny wyjeżdżone dla wielu studentów (double)
  Future<void> updateStudentsHours(
    List<String> studentIds,
    double hoursToAdd,
  ) async {
    if (studentIds.isEmpty || hoursToAdd == 0) return;

    // Dla każdego studenta dodaj godziny
    for (final studentId in studentIds) {
      try {
        // Pobierz aktualne godziny
        final studentData = await _supabase
            .from('students')
            .select('total_hours_driven')
            .eq('id', studentId)
            .single();

        final currentHours =
            (studentData['total_hours_driven'] as num?)?.toDouble() ?? 0.0;
        final newHours = currentHours + hoursToAdd;

        // Nie pozwól na ujemne godziny
        if (newHours < 0) {
          print(
            '⚠️ Ostrzeżenie: Próba ustawienia ujemnych godzin dla $studentId',
          );
          continue;
        }

        // Zaktualizuj
        await _supabase
            .from('students')
            .update({'total_hours_driven': newHours})
            .eq('id', studentId);

        print(
          '✅ Zaktualizowano godziny dla $studentId: $currentHours → $newHours',
        );
      } catch (e) {
        print('❌ Błąd aktualizacji godzin dla $studentId: $e');
        // Nie przerywamy pętli - próbujemy zaktualizować pozostałych
      }
    }
  }

  // ✅ ZMIENIONE - Przelicz wszystkie godziny studenta na podstawie lekcji (double)
  Future<void> recalculateStudentHours(String studentId) async {
    try {
      // Pobierz wszystkie ukończone lekcje studenta
      final lessonsData = await _supabase
          .from('lessons')
          .select('duration, student_ids')
          .eq('status', 'completed')
          .contains('student_ids', [studentId]);

      double totalHours = 0.0;

      for (final lesson in lessonsData as List) {
        final studentIds = List<String>.from(lesson['student_ids'] ?? []);
        if (studentIds.contains(studentId)) {
          totalHours += (lesson['duration'] as num?)?.toDouble() ?? 0.0;
        }
      }

      // Zaktualizuj studenta
      await _supabase
          .from('students')
          .update({'total_hours_driven': totalHours})
          .eq('id', studentId);

      print('✅ Przeliczono godziny dla $studentId: $totalHours');
    } catch (e) {
      print('❌ Błąd przeliczania godzin dla $studentId: $e');
      rethrow;
    }
  }
}
