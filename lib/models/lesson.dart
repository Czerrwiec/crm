class Lesson {
  final String id;
  final List<String> studentIds; //Array
  final String instructorId;
  final DateTime date;
  final String startTime; // "09:00"
  final String endTime; // "11:00"
  final int duration;
  final String? notes;
  final String status; // 'scheduled', 'completed', 'cancelled'
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Lesson({
    required this.id,
    required this.studentIds,
    required this.instructorId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.duration,
    this.notes,
    this.status = 'scheduled',
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'],
      studentIds: List<String>.from(json['student_ids'] ?? []), 
      instructorId: json['instructor_id'],
      date: DateTime.parse(json['date']),
      startTime: json['start_time'],
      endTime: json['end_time'],
      duration: json['duration'],
      notes: json['notes'],
      status: json['status'] ?? 'scheduled',
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'student_ids': studentIds, // Array
      'instructor_id': instructorId,
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD
      'start_time': startTime,
      'end_time': endTime,
      'duration': duration,
      'notes': notes,
      'status': status,
      // created_by ustawiane przez trigger
    };
  }

  String get statusLabel {
    switch (status) {
      case 'scheduled':
        return 'Zaplanowana';
      case 'completed':
        return 'Ukończona';
      case 'cancelled':
        return 'Anulowana';
      default:
        return status;
    }
  }
}
