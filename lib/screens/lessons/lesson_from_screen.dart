import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/lesson.dart';
import '../../models/student.dart';
import '../../services/lesson_service.dart';
import '../../services/student_service.dart';

class LessonFormScreen extends StatefulWidget {
  final String instructorId;
  final Lesson? lesson; // null = dodawanie, nie-null = edycja
  final DateTime? preselectedDate;
  final VoidCallback? onLessonSaved;

  const LessonFormScreen({
    super.key,
    required this.instructorId,
    this.lesson,
    this.preselectedDate,
    this.onLessonSaved,
  });

  @override
  State<LessonFormScreen> createState() => _LessonFormScreenState();
}

class _LessonFormScreenState extends State<LessonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lessonService = LessonService();
  final _studentService = StudentService();

  List<Student> _availableStudents = [];
  List<String> _selectedStudentIds = [];
  bool _isLoadingStudents = true;
  bool _isSaving = false;

  late DateTime _selectedDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 0);
  String _status = 'scheduled';
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Inicjalizuj dane z istniejącej lekcji lub domyślne
    if (widget.lesson != null) {
      _selectedDate = widget.lesson!.date;
      _parseTime(widget.lesson!.startTime, widget.lesson!.endTime);
      _selectedStudentIds = List.from(widget.lesson!.studentIds);
      _status = widget.lesson!.status;
      _notesController.text = widget.lesson!.notes ?? '';
    } else {
      _selectedDate = widget.preselectedDate ?? DateTime.now();
    }

    _loadStudents();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _parseTime(String startTimeStr, String endTimeStr) {
    final startParts = startTimeStr.split(':');
    final endParts = endTimeStr.split(':');

    _startTime = TimeOfDay(
      hour: int.parse(startParts[0]),
      minute: int.parse(startParts[1]),
    );

    _endTime = TimeOfDay(
      hour: int.parse(endParts[0]),
      minute: int.parse(endParts[1]),
    );
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoadingStudents = true);
    try {
      // Pobierz aktywnych kursantów przypisanych do tego instruktora
      final students = await _studentService.getStudents(activeOnly: true);

      final instructorStudents = students
          .where((s) => s.instructorId == widget.instructorId)
          .toList();

      setState(() {
        _availableStudents = instructorStudents;
      });
      if (widget.lesson == null) {
        _checkCurrentTimeConflict();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd ładowania kursantów: $e')));
      }
    } finally {
      setState(() => _isLoadingStudents = false);
    }
  }

  Future<void> _checkCurrentTimeConflict() async {
    final hasConflict = await _lessonService.hasConflict(
      instructorId: widget.instructorId,
      date: _selectedDate,
      startTime:
          '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
      endTime:
          '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
    );

    if (hasConflict && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Uwaga: w tym czasie instruktor ma już zaplanowaną lekcję',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('pl', 'PL'),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _pickTime(bool isStartTime) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: const Locale('pl', 'PL'),
          child: child,
        );
      },
    );

    if (time != null) {
      setState(() {
        if (isStartTime) {
          _startTime = time;
          // Auto-ustaw koniec na +2h jeśli jeszcze nie wybrano
          if (_endTime.hour <= _startTime.hour) {
            _endTime = TimeOfDay(
              hour: (_startTime.hour + 2) % 24,
              minute: _startTime.minute,
            );
          }
        } else {
          _endTime = time;
        }
      });
    }
  }

  int _calculateDuration() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    return ((endMinutes - startMinutes) / 60).round();
  }

  Future<void> _saveLesson() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wybierz co najmniej jednego kursanta')),
      );
      return;
    }

    final duration = _calculateDuration();

    if (duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Godzina zakończenia musi być późniejsza niż rozpoczęcia',
          ),
        ),
      );
      return;
    }

    final hasConflict = await _lessonService.hasConflict(
      instructorId: widget.instructorId,
      date: _selectedDate,
      startTime:
          '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
      endTime:
          '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
      excludeLessonId: widget.lesson?.id, // Przy edycji ignoruj obecną lekcję
    );

    if (hasConflict) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'W tym czasie instruktor ma już zaplanowaną lekcję',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final lesson = Lesson(
        id: widget.lesson?.id ?? '',
        studentIds: _selectedStudentIds,
        instructorId: widget.instructorId,
        date: _selectedDate,
        startTime:
            '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
        endTime:
            '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
        duration: duration,
        status: _status,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: widget.lesson?.createdAt ?? DateTime.now(),
        updatedAt: widget.lesson != null ? DateTime.now() : null,
      );

      if (widget.lesson == null) {
        // Dodawanie
        await _lessonService.addLesson(lesson);
      } else {
        // Edycja
        await _lessonService.updateLesson(lesson);
      }

      widget.onLessonSaved?.call();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.lesson == null ? 'Lekcja dodana' : 'Lekcja zaktualizowana',
            ),
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
      appBar: AppBar(
        title: Text(widget.lesson == null ? 'Dodaj lekcję' : 'Edytuj lekcję'),
      ),
      body: _isLoadingStudents
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Data
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Data'),
                      subtitle: Text(
                        DateFormat(
                          'dd.MM.yyyy (EEEE)',
                          'pl_PL',
                        ).format(_selectedDate),
                      ),
                      trailing: const Icon(Icons.edit),
                      onTap: _pickDate,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Godziny
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            leading: const Icon(Icons.access_time),
                            title: const Text('Od'),
                            subtitle: Text(_startTime.format(context)),
                            trailing: const Icon(Icons.edit),
                            onTap: () => _pickTime(true),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            leading: const Icon(Icons.access_time),
                            title: const Text('Do'),
                            subtitle: Text(_endTime.format(context)),
                            trailing: const Icon(Icons.edit),
                            onTap: () => _pickTime(false),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Czas trwania: ${_calculateDuration()}h',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Status
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'scheduled',
                          child: Text('Zaplanowana'),
                        ),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Text('Ukończona'),
                        ),
                        DropdownMenuItem(
                          value: 'cancelled',
                          child: Text('Anulowana'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _status = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Kursanci (multi-select)
                    Text(
                      'Kursanci (${_selectedStudentIds.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _availableStudents.length,
                        itemBuilder: (context, index) {
                          final student = _availableStudents[index];
                          final isSelected = _selectedStudentIds.contains(
                            student.id,
                          );

                          return CheckboxListTile(
                            title: Text(student.fullName),
                            subtitle: Text(student.phone ?? ''),
                            value: isSelected,
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedStudentIds.add(student.id);
                                } else {
                                  _selectedStudentIds.remove(student.id);
                                }
                              });
                            },
                          );
                        },
                      ),
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
                      onPressed: _isSaving ? null : _saveLesson,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _isSaving
                            ? 'Zapisywanie...'
                            : (widget.lesson == null
                                  ? 'Dodaj lekcję'
                                  : 'Zapisz zmiany'),
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
