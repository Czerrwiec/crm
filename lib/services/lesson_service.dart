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

  // Sprawdź czy instruktor ma już lekcję w tym czasie
  Future<bool> hasConflict({
    required String instructorId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? excludeLessonId, // Przy edycji - ignoruj obecną lekcję
  }) async {
    var query = _supabase
        .from('lessons')
        .select()
        .eq('instructor_id', instructorId)
        .eq('date', date.toIso8601String().split('T')[0])
        .neq('status', 'cancelled'); // Anulowane nie blokują

    // Przy edycji - ignoruj obecną lekcję
    if (excludeLessonId != null) {
      query = query.neq('id', excludeLessonId);
    }

    final response = await query;
    final lessons = (response as List)
        .map((json) => Lesson.fromJson(json))
        .toList();

    // Sprawdź nakładanie się godzin
    for (final lesson in lessons) {
      if (_timeRangesOverlap(
        startTime,
        endTime,
        lesson.startTime,
        lesson.endTime,
      )) {
        return true; // Jest konflikt
      }
    }

    return false; // Brak konfliktu
  }

  // Pomocnicza: sprawdź czy zakresy czasu się nakładają
  bool _timeRangesOverlap(
    String start1,
    String end1,
    String start2,
    String end2,
  ) {
    final start1Minutes = _timeToMinutes(start1);
    final end1Minutes = _timeToMinutes(end1);
    final start2Minutes = _timeToMinutes(start2);
    final end2Minutes = _timeToMinutes(end2);

    return start1Minutes < end2Minutes && end1Minutes > start2Minutes;
  }

  // Pomocnicza: konwertuj "HH:mm" na minuty
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
