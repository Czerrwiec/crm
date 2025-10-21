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
    // Zapisz z lokalnym czasem jako UTC
    final paymentData = payment.toJson();
    paymentData['created_at'] = DateTime.now().toUtc().toIso8601String();

    await _supabase.from('payments').insert(paymentData);

    if (onSuccess != null) {
      onSuccess();
    }
  }

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

  // Sprawdź czy użytkownik może edytować płatność
  Future<bool> canEditPayment(String paymentId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return false;

    try {
      // Pobierz płatność
      final payment = await _supabase
          .from('payments')
          .select('created_by')
          .eq('id', paymentId)
          .single();

      // Sprawdź rolę użytkownika
      final user = await _supabase
          .from('users')
          .select('role')
          .eq('id', currentUserId)
          .single();

      // Admin może wszystko, instruktor tylko swoje
      if (user['role'] == 'admin') {
        return true;
      }

      return payment['created_by'] == currentUserId;
    } catch (e) {
      return false;
    }
  }

  Future<void> updatePayment(Payment payment) async {
    // Sprawdź uprawnienia
    if (payment.id != null) {
      final canEdit = await canEditPayment(payment.id!);
      if (!canEdit) {
        throw Exception('Tylko admin może edytować tę płatność');
      }
    }

    await _supabase
        .from('payments')
        .update({
          'amount': payment.amount,
          'type': payment.type,
          'method': payment.method,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', payment.id!);
  }

  Future<void> deletePayment(String paymentId) async {
    // Sprawdź uprawnienia
    final canEdit = await canEditPayment(paymentId);
    if (!canEdit) {
      throw Exception('Tylko admin może usunąć tę płatność');
    }

    await _supabase.from('payments').delete().eq('id', paymentId);
  }
}
