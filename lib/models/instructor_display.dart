import 'app_user.dart';

class InstructorDisplay {
  final AppUser instructor;
  final int studentCount;

  InstructorDisplay({required this.instructor, required this.studentCount});

  factory InstructorDisplay.fromJson(Map<String, dynamic> json) {
    final instructor = AppUser.fromJson(json);

    // Pobierz liczbę kursantów z zagnieżdżonego count
    int studentCount = 0;
    if (json['students'] != null && json['students'] is List) {
      final students = json['students'] as List;
      if (students.isNotEmpty && students[0]['count'] != null) {
        studentCount = students[0]['count'] as int;
      }
    }

    return InstructorDisplay(
      instructor: instructor,
      studentCount: studentCount,
    );
  }
}
