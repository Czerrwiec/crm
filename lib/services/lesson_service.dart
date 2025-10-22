import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lesson.dart';
import 'student_service.dart';

class LessonService {
  final _supabase = Supabase.instance.client;
  final _studentService = StudentService();

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

    // Jeśli lekcja od razu jest completed, zaktualizuj godziny
    if (lesson.status == 'completed') {
      await _studentService.updateStudentsHours(
        lesson.studentIds,
        lesson.duration,
      );
    }
  }

  // Aktualizuj lekcję
  Future<void> updateLesson(Lesson lesson) async {
    // Pobierz starą wersję lekcji żeby porównać status
    final oldLessonData = await _supabase
        .from('lessons')
        .select()
        .eq('id', lesson.id)
        .single();

    final oldLesson = Lesson.fromJson(oldLessonData);
    final oldStatus = oldLesson.status;
    final newStatus = lesson.status;

    // Zapisz zaktualizowaną lekcję
    await _supabase.from('lessons').update(lesson.toJson()).eq('id', lesson.id);

    // Logika aktualizacji godzin
    if (oldStatus != newStatus) {
      if (newStatus == 'completed' && oldStatus != 'completed') {
        // Zmiana na completed - DODAJ godziny
        print(
          '📚 Dodaję ${lesson.durationFormatted}h dla studentów: ${lesson.studentIds}',
        );
        await _studentService.updateStudentsHours(
          lesson.studentIds,
          lesson.duration,
        );
      } else if (oldStatus == 'completed' && newStatus != 'completed') {
        // Zmiana z completed na inny - ODEJMIJ godziny
        print(
          '📚 Odejmuję ${lesson.durationFormatted}h dla studentów: ${lesson.studentIds}',
        );
        await _studentService.updateStudentsHours(
          lesson.studentIds,
          -lesson.duration,
        );
      }
    }

    // Jeśli zmienili się studenci przy lekcji completed
    if (newStatus == 'completed') {
      final oldStudentIds = oldLesson.studentIds.toSet();
      final newStudentIds = lesson.studentIds.toSet();

      // Studenci usunięci z lekcji - odejmij im godziny
      final removedStudents = oldStudentIds.difference(newStudentIds).toList();
      if (removedStudents.isNotEmpty) {
        print(
          '📚 Odejmuję ${lesson.durationFormatted}h dla usuniętych: $removedStudents',
        );
        await _studentService.updateStudentsHours(
          removedStudents,
          -lesson.duration,
        );
      }

      // Studenci dodani do lekcji - dodaj im godziny
      final addedStudents = newStudentIds.difference(oldStudentIds).toList();
      if (addedStudents.isNotEmpty) {
        print('📚 Dodaję ${lesson.durationFormatted}h dla dodanych: $addedStudents');
        await _studentService.updateStudentsHours(
          addedStudents,
          lesson.duration,
        );
      }
    }

    // Jeśli zmienił się czas trwania przy completed
    if (newStatus == 'completed' && lesson.duration != oldLesson.duration) {
      final hoursDifference = lesson.duration - oldLesson.duration;
      print('📚 Korekta czasu: ${hoursDifference}h dla ${lesson.studentIds}');
      await _studentService.updateStudentsHours(
        lesson.studentIds,
        hoursDifference,
      );
    }
  }

  // Usuń lekcję
  Future<void> deleteLesson(String lessonId) async {
    // Pobierz lekcję przed usunięciem
    final lessonData = await _supabase
        .from('lessons')
        .select()
        .eq('id', lessonId)
        .single();

    final lesson = Lesson.fromJson(lessonData);

    // Usuń lekcję
    await _supabase.from('lessons').delete().eq('id', lessonId);

    // Jeśli była completed, odejmij godziny
    if (lesson.status == 'completed') {
      print(
        '📚 Usuwam lekcję - odejmuję ${lesson.durationFormatted}h dla ${lesson.studentIds}',
      );
      await _studentService.updateStudentsHours(
        lesson.studentIds,
        -lesson.duration,
      );
    }
  }

  // Sprawdź czy instruktor ma już lekcję w tym czasie
  Future<bool> hasConflict({
    required String instructorId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? excludeLessonId,
  }) async {
    var query = _supabase
        .from('lessons')
        .select()
        .eq('instructor_id', instructorId)
        .eq('date', date.toIso8601String().split('T')[0])
        .neq('status', 'cancelled');

    if (excludeLessonId != null) {
      query = query.neq('id', excludeLessonId);
    }

    final response = await query;
    final lessons = (response as List)
        .map((json) => Lesson.fromJson(json))
        .toList();

    for (final lesson in lessons) {
      if (_timeRangesOverlap(
        startTime,
        endTime,
        lesson.startTime,
        lesson.endTime,
      )) {
        return true;
      }
    }

    return false;
  }

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

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
