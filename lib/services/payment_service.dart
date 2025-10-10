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

  // Pobierz informacje o autorze płatności
  Future<String?> getCreatedByName(String? createdById) async {
    if (createdById == null) return null;

    try {
      final response = await _supabase
          .from('users')
          .select('first_name, last_name')
          .eq('id', createdById)
          .single();

      return '${response['first_name']} ${response['last_name']}';
    } catch (e) {
      return null;
    }
  }

  // Edytuj płatność
  Future<void> updatePayment(Payment payment) async {
    await _supabase
        .from('payments')
        .update({
          'amount': payment.amount,
          'type': payment.type,
          'method': payment.method,
        })
        .eq('id', payment.id!);
  }

  // Usuń płatność
  Future<void> deletePayment(String paymentId) async {
    await _supabase.from('payments').delete().eq('id', paymentId);
  }
}
