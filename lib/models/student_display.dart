import 'student.dart';

// Rozszerzenie Student o dane instruktora
class StudentDisplay {
  final Student student;
  final String? instructorName;

  StudentDisplay({
    required this.student,
    this.instructorName,
  });

  factory StudentDisplay.fromJson(Map<String, dynamic> json) {
    final student = Student.fromJson(json);
    
    String? instructorName;
    if (json['instructor'] != null) {
      final instructor = json['instructor'];
      instructorName = '${instructor['first_name']} ${instructor['last_name']}';
    }

    return StudentDisplay(
      student: student,
      instructorName: instructorName,
    );
  }
}