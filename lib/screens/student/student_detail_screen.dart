import 'package:flutter/material.dart';
import '../../models/student.dart';
import '../../models/payment.dart';
import '../../services/payment_service.dart';
import '../../services/student_service.dart';

class StudentDetailScreen extends StatefulWidget {
  final Student student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final _paymentService = PaymentService();
  List<Payment> _payments = [];
  bool _isLoadingPayments = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoadingPayments = true);
    try {
      final payments = await _paymentService.getPaymentsByStudent(
        widget.student.id,
      );
      setState(() => _payments = payments);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd ładowania płatności: $e')));
      }
    } finally {
      setState(() => _isLoadingPayments = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.student.fullName),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Dane personalne'),
              Tab(text: 'Kalendarz'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildPersonalDataTab(), _buildCalendarTab()],
        ),
      ),
    );
  }

  // Zakładka 1: Dane personalne
  Widget _buildPersonalDataTab() {
    // Oblicz sumy płatności
    final coursePaid = _payments
        .where((p) => p.type == 'course')
        .fold(0.0, (sum, p) => sum + p.amount);
    final extraPaid = _payments
        .where((p) => p.type == 'extra_lessons')
        .fold(0.0, (sum, p) => sum + p.amount);
    final outstanding = widget.student.coursePrice - coursePaid;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Podstawowe dane (placeholder - następny krok)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Imię: ${widget.student.firstName}'),
                  Text('Nazwisko: ${widget.student.lastName}'),
                  Text('Telefon: ${widget.student.phone ?? "brak"}'),
                  Text('Email: ${widget.student.email ?? "brak"}'),
                  Text('PKK: ${widget.student.pkkNumber ?? "brak"}'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Sekcja płatności
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Płatności', style: Theme.of(context).textTheme.titleLarge),
              // Podsumowanie finansowe
              Card(
                color: outstanding > 0
                    ? Colors.orange.shade50
                    : Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Cena kursu: ${widget.student.coursePrice.toStringAsFixed(2)} zł',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Wpłacono: ${coursePaid.toStringAsFixed(2)} zł',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (outstanding > 0)
                        Text(
                          'Do zapłaty: ${outstanding.toStringAsFixed(2)} zł',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        )
                      else
                        Text(
                          '✅ Opłacone',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      if (extraPaid > 0)
                        Text(
                          'Extra: ${extraPaid.toStringAsFixed(2)} zł',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          _isLoadingPayments
              ? const Center(child: CircularProgressIndicator())
              : _payments.isEmpty
              ? const Text('Brak płatności')
              : Card(
                  child: Column(
                    children: [
                      // Nagłówek tabeli
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.grey.shade200,
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Data',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Kwota',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Typ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Metoda',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Wiersze płatności
                      ...(_payments.map(
                        (payment) => _buildPaymentRow(payment),
                      )),
                    ],
                  ),
                ),

          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showAddPaymentDialog,
            icon: const Icon(Icons.add),
            label: const Text('Dodaj płatność'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(Payment payment) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '${payment.createdAt.day.toString().padLeft(2, '0')}.${payment.createdAt.month.toString().padLeft(2, '0')}.${payment.createdAt.year}',
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('${payment.amount.toStringAsFixed(2)} zł'),
          ),
          Expanded(flex: 2, child: Text(payment.typeLabel)),
          Expanded(flex: 2, child: Text(payment.methodLabel)),
        ],
      ),
    );
  }

  // Zakładka 2: Kalendarz (placeholder)
  Widget _buildCalendarTab() {
    return const Center(child: Text('Kalendarz jazd - wkrótce'));
  }

  // Dialog dodawania płatności
  Future<void> _showAddPaymentDialog() async {
    final amountController = TextEditingController();
    String selectedType = 'course';
    String selectedMethod = 'cash';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Dodaj płatność'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Kwota (zł)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Typ płatności',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'course', child: Text('Kurs')),
                  DropdownMenuItem(
                    value: 'extra_lessons',
                    child: Text('Dodatkowe godziny'),
                  ),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedMethod,
                decoration: const InputDecoration(
                  labelText: 'Metoda płatności',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Gotówka')),
                  DropdownMenuItem(value: 'card', child: Text('Karta')),
                  DropdownMenuItem(value: 'transfer', child: Text('Przelew')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedMethod = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text.trim());
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Wprowadź poprawną kwotę')),
                  );
                  return;
                }

                try {
                  // Dodaj płatność
                  final payment = Payment(
                    studentId: widget.student.id,
                    amount: amount,
                    type: selectedType,
                    method: selectedMethod,
                  );

                  await _paymentService.addPayment(payment);

                  // Aktualizuj status course_paid
                  await StudentService().updateCoursePaidStatus(
                    widget.student.id,
                  );

                  if (context.mounted) {
                    // Zamknij dialog płatności
                    Navigator.pop(context, true);

                    // Zamknij ekran szczegółów (wraca do listy)
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Błąd: $e')));
                  }
                }
              },
              child: const Text('Dodaj'),
            ),
          ],
        ),
      ),
    );

    // Jeśli dodano płatność, odśwież listę
    if (result == true) {
      _loadPayments();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Płatność dodana')));
      }
    }
  }
}
