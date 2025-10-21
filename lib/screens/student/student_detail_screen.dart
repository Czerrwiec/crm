import 'package:flutter/material.dart';
import '../../models/student.dart';
import '../../models/payment.dart';
import '../../services/payment_service.dart';
import '../../services/student_service.dart';
import '../../services/instructor_service.dart';
import '../../models/app_user.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../services/lesson_service.dart';
import '../../models/lesson.dart';
import '../../widgets/week_schedule_view.dart';
import '../../services/auth_service.dart';

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

  final _lessonService = LessonService();
  List<Lesson> _lessons = [];
  bool _isLoadingLessons = false;
  bool _showWeekView = false;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<String, String> _studentNames = {};

  final _instructorService = InstructorService();
  List<AppUser> _instructors = [];
  bool _isLoadingInstructors = true;
  bool _isEditing = false;
  String? _currentUserRole;

  // Kontrolery formularza
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _pkkController;
  late TextEditingController _coursePriceController;
  late TextEditingController _notesController;
  late TextEditingController _cityController;
  late TextEditingController _courseStartDateController;
  late TextEditingController _totalHoursDrivenController;

  // Stan checkboxów
  late bool _theoryPassed;
  late bool _internalExamPassed;
  late bool _active;
  late bool _isSupplementaryCourse;
  late bool _car;

  // Wybrany instruktor
  String? _selectedInstructorId;

  @override
  void initState() {
    super.initState();

    // Inicjalizuj kontrolery z danymi kursanta
    _firstNameController = TextEditingController(
      text: widget.student.firstName,
    );
    _lastNameController = TextEditingController(text: widget.student.lastName);
    _phoneController = TextEditingController(text: widget.student.phone ?? '');
    _emailController = TextEditingController(text: widget.student.email ?? '');
    _pkkController = TextEditingController(
      text: widget.student.pkkNumber ?? '',
    );
    _coursePriceController = TextEditingController(
      text: widget.student.coursePrice.toStringAsFixed(2),
    );
    _notesController = TextEditingController(text: widget.student.notes ?? '');
    _cityController = TextEditingController(text: widget.student.city ?? '');
    _isSupplementaryCourse = widget.student.isSupplementaryCourse;

    // Inicjalizuj checkboxy
    _theoryPassed = widget.student.theoryPassed;
    _internalExamPassed = widget.student.internalExamPassed;
    _active = widget.student.active;
    _car = widget.student.car;

    // Wybrany instruktor
    _selectedInstructorId = widget.student.instructorId;

    _courseStartDateController = TextEditingController(
      text: widget.student.courseStartDate != null
          ? '${widget.student.courseStartDate!.day.toString().padLeft(2, '0')}.${widget.student.courseStartDate!.month.toString().padLeft(2, '0')}.${widget.student.courseStartDate!.year}'
          : '',
    );
    _totalHoursDrivenController = TextEditingController(
      text: widget.student.totalHoursDriven.toString(),
    );
    _selectedDay = _focusedDay;
    _studentNames = {widget.student.id: widget.student.fullName};

    _loadPayments();
    _loadLessons();
    _loadInstructors();
    _loadUserRole();
  }

  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _pkkController.dispose();
    _coursePriceController.dispose();
    _notesController.dispose();
    _cityController.dispose();
    _courseStartDateController.dispose();
    _totalHoursDrivenController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    try {
      final role = await AuthService().getUserRole();
      setState(() {
        _currentUserRole = role;
      });
    } catch (e) {
      print('Błąd pobierania roli: $e');
    }
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

  Future<void> _loadLessons() async {
    setState(() => _isLoadingLessons = true);
    try {
      // Pobierz wszystkie lekcje instruktora w danym miesiącu
      if (widget.student.instructorId == null) {
        setState(() => _lessons = []);
        return;
      }

      final allLessons = await _lessonService.getLessonsByInstructor(
        widget.student.instructorId!,
        _focusedDay,
      );

      // Filtruj tylko lekcje z tym kursantem
      final studentLessons = allLessons.where((lesson) {
        return lesson.studentIds.contains(widget.student.id);
      }).toList();

      setState(() => _lessons = studentLessons);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd ładowania lekcji: $e')));
      }
    } finally {
      setState(() => _isLoadingLessons = false);
    }
  }

  List<Lesson> _getLessonsForDay(DateTime day) {
    return _lessons.where((lesson) {
      return lesson.date.year == day.year &&
          lesson.date.month == day.month &&
          lesson.date.day == day.day;
    }).toList();
  }

  Future<void> _loadInstructors() async {
    setState(() => _isLoadingInstructors = true);
    try {
      final instructors = await _instructorService.getInstructors();
      setState(() => _instructors = instructors);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd ładowania instruktorów: $e')),
        );
      }
    } finally {
      setState(() => _isLoadingInstructors = false);
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
          // Formularz edycji danych
          // Formularz/widok danych
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dane personalne',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      // ✅ POKAŻ PRZYCISK TYLKO DLA ADMINA
                      if (!_isEditing && _currentUserRole == 'admin')
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edytuj'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Imię i Nazwisko
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            labelText: 'Imię *',
                            border: const OutlineInputBorder(),
                          ),
                          enabled: _isEditing,
                          style: TextStyle(
                            color: _isEditing ? Colors.black : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            labelText: 'Nazwisko *',
                            border: OutlineInputBorder(),
                          ),
                          enabled: _isEditing,
                          style: TextStyle(
                            color: _isEditing ? Colors.black : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Telefon i Email
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Telefon',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          enabled: _isEditing,
                          style: TextStyle(
                            color: _isEditing ? Colors.black : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          enabled: _isEditing,
                          style: TextStyle(
                            color: _isEditing ? Colors.black : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // PKK i Miasto
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _pkkController,
                          decoration: const InputDecoration(
                            labelText: 'Numer PKK',
                            border: OutlineInputBorder(),
                          ),
                          enabled: _isEditing,
                          style: TextStyle(
                            color: _isEditing ? Colors.black : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'Miasto zdawania',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_city),
                          ),
                          enabled: _isEditing,
                          style: TextStyle(
                            color: _isEditing ? Colors.black : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Cena kursu
                  TextField(
                    controller: _coursePriceController,
                    decoration: const InputDecoration(
                      labelText: 'Cena kursu (zł) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    enabled: _isEditing,
                    style: TextStyle(
                      color: _isEditing ? Colors.black : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dropdown instruktora
                  _isLoadingInstructors
                      ? const CircularProgressIndicator()
                      : DropdownButtonFormField<String>(
                          value: _selectedInstructorId,
                          decoration: const InputDecoration(
                            labelText: 'Instruktor *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          style: TextStyle(
                            color: _isEditing ? Colors.black : Colors.black87,
                          ),
                          items: _instructors.map((instructor) {
                            return DropdownMenuItem(
                              value: instructor.id,
                              child: Text(instructor.fullName),
                            );
                          }).toList(),
                          onChanged: _isEditing
                              ? (value) {
                                  setState(() {
                                    _selectedInstructorId = value;
                                  });
                                }
                              : null,
                        ),
                  const SizedBox(height: 16),

                  // Checkboxy
                  CheckboxListTile(
                    title: const Text('Teoria zdana'),
                    value: _theoryPassed,
                    onChanged: _isEditing
                        ? (value) {
                            setState(() {
                              _theoryPassed = value ?? false;
                            });
                          }
                        : null,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text('Egzamin wewnętrzny zdany'),
                    value: _internalExamPassed,
                    onChanged: _isEditing
                        ? (value) {
                            setState(() {
                              _internalExamPassed = value ?? false;
                            });
                          }
                        : null,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text('Kurs uzupełniający'),
                    value: _isSupplementaryCourse,
                    onChanged: _isEditing
                        ? (value) {
                            setState(() {
                              _isSupplementaryCourse = value ?? false;
                            });
                          }
                        : null,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text('Auto na egzamin'),
                    value: _car,
                    onChanged: _isEditing
                        ? (value) {
                            setState(() {
                              _car = value ?? false;
                            });
                          }
                        : null,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text('Kursant aktywny'),
                    value: _active,
                    onChanged: _isEditing
                        ? (value) {
                            setState(() {
                              _active = value ?? true;
                            });
                          }
                        : null,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _courseStartDateController,
                          decoration: InputDecoration(
                            labelText: 'Data rozpoczęcia kursu',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.calendar_today),
                            suffixIcon: _isEditing
                                ? IconButton(
                                    icon: const Icon(Icons.edit_calendar),
                                    onPressed: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate:
                                            widget.student.courseStartDate ??
                                            DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now(),
                                      );
                                      if (date != null) {
                                        setState(() {
                                          _courseStartDateController.text =
                                              '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
                                        });
                                      }
                                    },
                                  )
                                : null,
                          ),
                          readOnly: true,
                          style: TextStyle(
                            color: _isEditing ? Colors.black : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _totalHoursDrivenController,
                          decoration: const InputDecoration(
                            labelText: 'Godziny wyjeżdżone',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.access_time),
                            suffixText: 'h',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter
                                .digitsOnly, // Przyjmuje tylko cyfry
                          ],
                          enabled: _isEditing,
                          style: TextStyle(
                            color: _isEditing ? Colors.black : Colors.black87,
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              int? parsedValue = int.tryParse(value);
                              if (parsedValue == null) {
                                _totalHoursDrivenController
                                    .clear(); // Czyści, jeśli nie jest int
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Notatki
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notatki',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    enabled: _isEditing,
                    style: TextStyle(
                      color: _isEditing ? Colors.black : Colors.black87,
                    ),
                  ),

                  // Przyciski Zapisz/Anuluj (tylko w trybie edycji)
                  if (_isEditing) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _cancelEditing,
                            icon: const Icon(Icons.close),
                            label: const Text('Anuluj'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _saveChanges,
                            icon: const Icon(Icons.save),
                            label: const Text('Zapisz'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
    final displayDate = (wasEdited ? payment.updatedAt! : payment.createdAt)
        .toLocal();
    final authorId = wasEdited ? payment.updatedBy : payment.createdBy;
    final authorLabel = wasEdited ? 'Edytowane przez' : 'Dodane przez';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          // Kolumna z datą i autorem
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
                // ✅ Info o autorze (zostaje tutaj)
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
          // Kwota
          Expanded(
            flex: 2,
            child: Text(
              '${payment.amount.toStringAsFixed(2)} zł',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          // Typ
          Expanded(flex: 2, child: Text(payment.typeLabel)),
          // Metoda
          Expanded(flex: 2, child: Text(payment.methodLabel)),
          // ✅ Akcje (edycja/usuwanie) - z kontrolą uprawnień
          FutureBuilder<bool>(
            future: _paymentService.canEditPayment(payment.id!),
            builder: (context, snapshot) {
              // Podczas ładowania pokaż szare ikony
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onPressed: null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.delete, size: 18, color: Colors.grey),
                      onPressed: null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                );
              }

              final canEdit = snapshot.data ?? false;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Przycisk edycji
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      size: 18,
                      color: canEdit ? null : Colors.grey,
                    ),
                    onPressed: canEdit
                        ? () => _showEditPaymentDialog(payment)
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Tylko admin może edytować tę płatność',
                                ),
                                backgroundColor: Colors.orange,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                    tooltip: canEdit ? 'Edytuj' : 'Tylko admin może edytować',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  // Przycisk usuwania
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      size: 18,
                      color: canEdit ? Colors.red.shade400 : Colors.grey,
                    ),
                    onPressed: canEdit
                        ? () => _showDeletePaymentDialog(payment)
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Tylko admin może usunąć tę płatność',
                                ),
                                backgroundColor: Colors.orange,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                    tooltip: canEdit ? 'Usuń' : 'Tylko admin może usunąć',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Zakładka 2: Kalendarz
  Widget _buildCalendarTab() {
    if (widget.student.instructorId == null) {
      return const Center(child: Text('Brak przypisanego instruktora'));
    }

    return Column(
      children: [
        // Kalendarz miesięczny
        if (_isLoadingLessons)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            locale: 'pl_PL',
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            daysOfWeekHeight: 40,
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) {
                final text = DateFormat.E('pl_PL').format(day);
                return Center(
                  child: Text(
                    text,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _loadLessons();
            },
            eventLoader: _getLessonsForDay,
            calendarStyle: CalendarStyle(
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: Colors.blue.shade700,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.blue.shade200,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue.shade700,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
              titleTextFormatter: (date, locale) =>
                  DateFormat.yMMMM('pl_PL').format(date),
            ),
            availableCalendarFormats: const {
              CalendarFormat.month: 'Miesiąc',
              CalendarFormat.twoWeeks: '2 tygodnie',
              CalendarFormat.week: 'Tydzień',
            },
          ),

        // Toggle widoku tygodniowego
        const Divider(height: 1),
        SwitchListTile(
          title: const Text('Widok tygodniowy z godzinami'),
          subtitle: const Text('Pokaż szczegółowy rozkład godzin'),
          value: _showWeekView,
          onChanged: (value) {
            setState(() {
              _showWeekView = value;
            });
          },
        ),
        const Divider(height: 1),

        // Widok poniżej
        Expanded(child: _showWeekView ? _buildWeekView() : _buildDayList()),
      ],
    );
  }

  // Widok listy lekcji
  Widget _buildDayList() {
    if (_selectedDay == null) {
      return const Center(child: Text('Wybierz dzień'));
    }

    final dayLessons = _getLessonsForDay(_selectedDay!);

    if (dayLessons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Brak lekcji tego dnia',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dayLessons.length,
      itemBuilder: (context, index) {
        final lesson = dayLessons[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(lesson.status),
              child: const Icon(Icons.drive_eta, color: Colors.white),
            ),
            title: Text(
              '${lesson.startTime} - ${lesson.endTime}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${lesson.duration}h jazdy'),
                Text(
                  lesson.statusLabel,
                  style: TextStyle(
                    color: _getStatusColor(lesson.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (lesson.notes != null && lesson.notes!.isNotEmpty)
                  Text(
                    lesson.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            onTap: () {
              _showLessonDetails(lesson);
            },
          ),
        );
      },
    );
  }

  // Widok tygodniowy
  Widget _buildWeekView() {
    if (_selectedDay == null) {
      return const Center(child: Text('Wybierz dzień'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return WeekScheduleView(
          selectedDay: _selectedDay!,
          lessons: _lessons,
          onLessonTap: (lesson) {
            _showLessonDetails(lesson);
          },
          width: constraints.maxWidth,
          studentNames: _studentNames,
        );
      },
    );
  }

  // Dialog szczegółów lekcji
  void _showLessonDetails(Lesson lesson) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Lekcja ${lesson.startTime} - ${lesson.endTime}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data: ${DateFormat('dd.MM.yyyy').format(lesson.date)}'),
            Text('Czas trwania: ${lesson.duration}h'),
            Text('Status: ${lesson.statusLabel}'),
            if (lesson.notes != null && lesson.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Notatki: ${lesson.notes}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
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

  // Anuluj edycję - przywróć oryginalne wartości
  void _cancelEditing() {
    setState(() {
      _firstNameController.text = widget.student.firstName;
      _lastNameController.text = widget.student.lastName;
      _phoneController.text = widget.student.phone ?? '';
      _emailController.text = widget.student.email ?? '';
      _pkkController.text = widget.student.pkkNumber ?? '';
      _cityController.text = widget.student.city ?? '';
      _coursePriceController.text = widget.student.coursePrice.toStringAsFixed(
        2,
      );
      _notesController.text = widget.student.notes ?? '';

      _theoryPassed = widget.student.theoryPassed;
      _internalExamPassed = widget.student.internalExamPassed;
      _isSupplementaryCourse = widget.student.isSupplementaryCourse;
      _car = widget.student.car;
      _active = widget.student.active;
      _selectedInstructorId = widget.student.instructorId;
      _courseStartDateController.text = widget.student.courseStartDate != null
          ? '${widget.student.courseStartDate!.day.toString().padLeft(2, '0')}.${widget.student.courseStartDate!.month.toString().padLeft(2, '0')}.${widget.student.courseStartDate!.year}'
          : '';
      _totalHoursDrivenController.text = widget.student.totalHoursDriven
          .toString();

      _isEditing = false;
    });
  }

  // Zapisz zmiany
  Future<void> _saveChanges() async {
    // Walidacja
    if (_firstNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Imię jest wymagane')));
      return;
    }

    if (_lastNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nazwisko jest wymagane')));
      return;
    }

    if (_selectedInstructorId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Wybierz instruktora')));
      return;
    }

    final coursePrice = double.tryParse(_coursePriceController.text.trim());
    if (coursePrice == null || coursePrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wprowadź poprawną cenę kursu')),
      );
      return;
    }

    DateTime? courseStartDate;
    if (_courseStartDateController.text.trim().isNotEmpty) {
      final parts = _courseStartDateController.text.split('.');
      if (parts.length == 3) {
        courseStartDate = DateTime(
          int.parse(parts[2]), // rok
          int.parse(parts[1]), // miesiąc
          int.parse(parts[0]), // dzień
        );
      }
    }

    final totalHoursDriven =
        int.tryParse(_totalHoursDrivenController.text.trim()) ?? 0;

    try {
      final data = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'email': _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        'pkk_number': _pkkController.text.trim().isEmpty
            ? null
            : _pkkController.text.trim(),
        'city': _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        'instructor_id': _selectedInstructorId,
        'course_price': coursePrice,
        'theory_passed': _theoryPassed,
        'internal_exam_passed': _internalExamPassed,
        'is_supplementary_course': _isSupplementaryCourse,
        'car': _car,
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'course_start_date': courseStartDate?.toIso8601String(),
        'total_hours_driven': totalHoursDriven,
        'active': _active,
      };

      await StudentService().updateStudent(widget.student.id, data);

      // Wywołaj callback żeby odświeżyć listę
      widget.onStudentUpdated?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zmiany zapisane'),
            backgroundColor: Colors.green,
          ),
        );
      }
      setState(() {
        _isEditing = false; // ✅ Wyłącz tryb edycji
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    }
  }
}
