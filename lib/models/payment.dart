class Payment {
  final String? id;
  final String studentId;
  final double amount;
  final String type; // 'course' lub 'extra_lessons'
  final String method; // 'cash', 'card', 'transfer'
  final DateTime createdAt;

  Payment({
    this.id,
    required this.studentId,
    required this.amount,
    required this.type,
    required this.method,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      studentId: json['student_id'],
      amount: (json['amount'] as num).toDouble(),
      type: json['type'],
      method: json['method'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'student_id': studentId,
      'amount': amount,
      'type': type,
      'method': method,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get typeLabel {
    switch (type) {
      case 'course':
        return 'Kurs';
      case 'extra_lessons':
        return 'Dodatkowe godziny';
      default:
        return type;
    }
  }

  String get methodLabel {
    switch (method) {
      case 'cash':
        return 'Gotówka';
      case 'card':
        return 'Karta';
      case 'transfer':
        return 'Przelew';
      default:
        return method;
    }
  }
}
