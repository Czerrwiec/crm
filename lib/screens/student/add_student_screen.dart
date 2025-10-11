import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../services/instructor_service.dart';
import '../../services/student_service.dart';

class AddStudentScreen extends StatefulWidget {
  final VoidCallback? onStudentAdded;

  const AddStudentScreen({super.key, this.onStudentAdded});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _instructorService = InstructorService();
  final _studentService = StudentService();

  List<AppUser> _instructors = [];
  bool _isLoadingInstructors = true;
  bool _isSaving = false;

  // Kontrolery
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _pkkController = TextEditingController();
  final _cityController = TextEditingController();
  final _coursePriceController = TextEditingController(text: '3200.00');
  final _courseStartDateController = TextEditingController();
  final _totalHoursDrivenController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  // Checkboxy
  bool _theoryPassed = false;
  bool _internalExamPassed = false;
  bool _isSupplementaryCourse = false;
  bool _car = false;
  bool _active = true;

  String? _selectedInstructorId;

  @override
  void initState() {
    super.initState();
    _loadInstructors();
    // Ustaw dzisiejszą datę jako domyślną
    final now = DateTime.now();
    _courseStartDateController.text =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _pkkController.dispose();
    _cityController.dispose();
    _coursePriceController.dispose();
    _courseStartDateController.dispose();
    _totalHoursDrivenController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInstructors() async {
    setState(() => _isLoadingInstructors = true);
    try {
      final instructors = await _instructorService.getInstructors();
      setState(() {
        _instructors = instructors;
        // Wybierz pierwszego instruktora domyślnie
        if (instructors.isNotEmpty) {
          _selectedInstructorId = instructors.first.id;
        }
      });
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

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Parse daty
      DateTime? courseStartDate;
      if (_courseStartDateController.text.trim().isNotEmpty) {
        final parts = _courseStartDateController.text.split('.');
        if (parts.length == 3) {
          courseStartDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }

      // Parse ceny i godzin
      final coursePrice = double.parse(_coursePriceController.text.trim());
      final totalHoursDriven = int.parse(
        _totalHoursDrivenController.text.trim(),
      );

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
        'active': _active,
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'course_start_date': courseStartDate?.toIso8601String(),
        'total_hours_driven': totalHoursDriven,
      };

      await _studentService.addStudent(data);

      // Wywołaj callback
      widget.onStudentAdded?.call();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kursant dodany'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dodaj kursanta')),
      body: _isLoadingInstructors
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Imię i Nazwisko
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'Imię *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Imię jest wymagane';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Nazwisko *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nazwisko jest wymagane';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Telefon i Email
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Telefon',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // PKK i Miasto
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _pkkController,
                            decoration: const InputDecoration(
                              labelText: 'Numer PKK',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: 'Miasto zdawania',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_city),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Cena kursu
                    TextFormField(
                      controller: _coursePriceController,
                      decoration: const InputDecoration(
                        labelText: 'Cena kursu (zł) *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Cena jest wymagana';
                        }
                        final price = double.tryParse(value.trim());
                        if (price == null || price <= 0) {
                          return 'Wprowadź poprawną cenę';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Instruktor
                    DropdownButtonFormField<String>(
                      value: _selectedInstructorId,
                      decoration: const InputDecoration(
                        labelText: 'Instruktor *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: _instructors.map((instructor) {
                        return DropdownMenuItem(
                          value: instructor.id,
                          child: Text(instructor.fullName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedInstructorId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Wybierz instruktora';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Data rozpoczęcia i Godziny
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _courseStartDateController,
                            decoration: InputDecoration(
                              labelText: 'Data rozpoczęcia kursu',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.calendar_today),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.edit_calendar),
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
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
                              ),
                            ),
                            readOnly: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _totalHoursDrivenController,
                            decoration: const InputDecoration(
                              labelText: 'Godziny wyjeżdżone',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.access_time),
                              suffixText: 'h',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Checkboxy
                    CheckboxListTile(
                      title: const Text('Teoria zdana'),
                      value: _theoryPassed,
                      onChanged: (value) =>
                          setState(() => _theoryPassed = value ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text('Egzamin wewnętrzny zdany'),
                      value: _internalExamPassed,
                      onChanged: (value) =>
                          setState(() => _internalExamPassed = value ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text('Kurs uzupełniający'),
                      value: _isSupplementaryCourse,
                      onChanged: (value) => setState(
                        () => _isSupplementaryCourse = value ?? false,
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text('Auto na egzamin'),
                      value: _car,
                      onChanged: (value) =>
                          setState(() => _car = value ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text('Kursant aktywny'),
                      value: _active,
                      onChanged: (value) =>
                          setState(() => _active = value ?? true),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),

                    // Notatki
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notatki',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Przycisk Zapisz
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveStudent,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _isSaving ? 'Zapisywanie...' : 'Dodaj kursanta',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
