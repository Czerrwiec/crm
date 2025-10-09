import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment.dart';

class PaymentService {
  final _supabase = Supabase.instance.client;

  Future<List<Payment>> getPaymentsByStudent(String studentId) async {
    final response = await _supabase
        .from('payments')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Payment.fromJson(json)).toList();
  }

  Future<void> addPayment(Payment payment, {Function? onSuccess}) async {
    await _supabase.from('payments').insert(payment.toJson());

    // Jeśli callback przekazany, wywołaj
    if (onSuccess != null) {
      onSuccess();
    }
  }
}
