import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lesson.dart';

class LessonService {
  final _supabase = Supabase.instance.client;

  // Pobierz lekcje dla instruktora w danym miesiącu
  Future<List<Lesson>> getLessonsByInstructor(
    String instructorId,
    DateTime month,
  ) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);

    final response = await _supabase
        .from('lessons')
        .select()
        .eq('instructor_id', instructorId)
        .gte('date', startOfMonth.toIso8601String().split('T')[0])
        .lte('date', endOfMonth.toIso8601String().split('T')[0])
        .order('date')
        .order('start_time');

    return (response as List).map((json) => Lesson.fromJson(json)).toList();
  }

  // Dodaj lekcję
  Future<void> addLesson(Lesson lesson) async {
    await _supabase.from('lessons').insert(lesson.toJson());
  }

  // Aktualizuj lekcję
  Future<void> updateLesson(Lesson lesson) async {
    await _supabase.from('lessons').update(lesson.toJson()).eq('id', lesson.id);
  }

  // Usuń lekcję
  Future<void> deleteLesson(String lessonId) async {
    await _supabase.from('lessons').delete().eq('id', lessonId);
  }
}
