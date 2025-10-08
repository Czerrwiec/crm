class Student {
  final String id;
  final String? userId;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String? instructorId;
  final String? pkkNumber;
  final bool theoryPassed;
  final bool internalExamPassed;
  final bool coursePaid;
  final int extraHours;
  final int totalHoursDriven;
  final DateTime? courseStartDate;
  final bool active;
  final String? notes;
  final String? phone;
  final String? email;

  Student({
    required this.id,
    this.userId,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.instructorId,
    this.pkkNumber,
    this.theoryPassed = false,
    this.internalExamPassed = false,
    this.coursePaid = false,
    this.extraHours = 0,
    this.totalHoursDriven = 0,
    this.courseStartDate,
    this.active = true,
    this.notes,
    this.phone,
    this.email,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      userId: json['user_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      instructorId: json['instructor_id'],
      pkkNumber: json['pkk_number'],
      theoryPassed: json['theory_passed'] ?? false,
      internalExamPassed: json['internal_exam_passed'] ?? false,
      coursePaid: json['course_paid'] ?? false,
      extraHours: json['extra_hours'] ?? 0,
      totalHoursDriven: json['total_hours_driven'] ?? 0,
      courseStartDate: json['course_start_date'] != null
          ? DateTime.parse(json['course_start_date'])
          : null,
      active: json['active'] ?? true,
      notes: json['notes'],
      phone: json['phone'],
      email: json['email'],
    );
  }

  String get fullName => '$firstName $lastName';

  // Oblicz dni od rozpoczęcia kursu
  int? get courseDurationDays {
    if (courseStartDate == null) return null;
    return DateTime.now().difference(courseStartDate!).inDays;
  }
}