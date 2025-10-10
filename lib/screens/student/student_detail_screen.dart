import 'package:flutter/material.dart';
import '../../models/student.dart';
import '../../models/payment.dart';
import '../../services/payment_service.dart';
import '../../services/student_service.dart';

class StudentDetailScreen extends StatefulWidget {
  final Student student;
  final VoidCallback? onStudentUpdated;

  const StudentDetailScreen({
    super.key,
    required this.student,
    this.onStudentUpdated,
  });

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
    // Sprawdź czy płatność była edytowana
    final wasEdited = payment.updatedAt != null && payment.updatedBy != null;
    final displayDate = wasEdited ? payment.updatedAt! : payment.createdAt;
    final authorId = wasEdited ? payment.updatedBy : payment.createdBy;
    final authorLabel = wasEdited ? 'Edytowane przez' : 'Dodane przez';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${displayDate.day.toString().padLeft(2, '0')}.${displayDate.month.toString().padLeft(2, '0')}.${displayDate.year}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${displayDate.hour.toString().padLeft(2, '0')}:${displayDate.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                // Info o autorze
                FutureBuilder<String?>(
                  future: _paymentService.getCreatedByName(authorId),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return Text(
                        '$authorLabel: ${snapshot.data}',
                        style: TextStyle(
                          fontSize: 10,
                          color: wasEdited
                              ? Colors.orange.shade700
                              : Colors.grey.shade500,
                          fontStyle: wasEdited
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${payment.amount.toStringAsFixed(2)} zł',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(flex: 2, child: Text(payment.typeLabel)),
          Expanded(flex: 2, child: Text(payment.methodLabel)),
          // Akcje (edycja/usuwanie)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () => _showEditPaymentDialog(payment),
                tooltip: 'Edytuj',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.delete, size: 18, color: Colors.red.shade400),
                onPressed: () => _showDeletePaymentDialog(payment),
                tooltip: 'Usuń',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
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

                  // Wywołaj callback żeby odświeżyć listę w tle
                  widget.onStudentUpdated?.call();

                  if (context.mounted) {
                    Navigator.pop(context, true); // Zamknij dialog
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

  // Dialog edycji płatności
  Future<void> _showEditPaymentDialog(Payment payment) async {
    final amountController = TextEditingController(
      text: payment.amount.toStringAsFixed(2),
    );
    String selectedType = payment.type;
    String selectedMethod = payment.method;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edytuj płatność'),
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
                  final updatedPayment = Payment(
                    id: payment.id,
                    studentId: payment.studentId,
                    amount: amount,
                    type: selectedType,
                    method: selectedMethod,
                    createdAt: payment.createdAt,
                    createdBy: payment.createdBy,
                  );

                  await _paymentService.updatePayment(updatedPayment);
                  await StudentService().updateCoursePaidStatus(
                    widget.student.id,
                  );

                  widget.onStudentUpdated?.call();

                  if (context.mounted) {
                    Navigator.pop(context, true);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Błąd: $e')));
                  }
                }
              },
              child: const Text('Zapisz'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      _loadPayments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Płatność zaktualizowana')),
        );
      }
    }
  }

  // Dialog usuwania płatności
  Future<void> _showDeletePaymentDialog(Payment payment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń płatność'),
        content: Text(
          'Czy na pewno chcesz usunąć płatność ${payment.amount.toStringAsFixed(2)} zł (${payment.typeLabel})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _paymentService.deletePayment(payment.id!);
        await StudentService().updateCoursePaidStatus(widget.student.id);

        widget.onStudentUpdated?.call();
        _loadPayments();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Płatność usunięta')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Błąd: $e')));
        }
      }
    }
  }
}
