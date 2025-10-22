import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../services/lesson_service.dart';
import '../../services/instructor_service.dart';
import '../../services/student_service.dart';
import '../../models/lesson.dart';
import '../../models/app_user.dart';
import '../../widgets/week_schedule_view.dart';
import '../lessons/lesson_from_screen.dart';
import 'settings_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _lessonService = LessonService();
  final _instructorService = InstructorService();
  final _studentService = StudentService();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Lesson> _lessons = [];
  List<AppUser> _instructors = [];
  Map<String, String> _studentNames = {};

  bool _isLoading = true;
  bool _isLoadingInstructors = true;
  bool _showWeekView = false;

  String? _selectedInstructorId; // null = wszyscy instruktorzy

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadInstructors();
  }

  Future<void> _loadInstructors() async {
    setState(() => _isLoadingInstructors = true);
    try {
      final instructors = await _instructorService.getInstructors();
      setState(() {
        _instructors = instructors;
        // Domyślnie: pierwszy instruktor
        if (instructors.isNotEmpty) {
          _selectedInstructorId = instructors.first.id;
        }
      });
      await _loadLessons();
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

  Future<void> _loadLessons() async {
    if (_selectedInstructorId == null) return;

    setState(() => _isLoading = true);
    try {
      final lessons = await _lessonService.getLessonsByInstructor(
        _selectedInstructorId!,
        _focusedDay,
      );

      // Pobierz nazwiska kursantów
      final studentIds = lessons
          .expand((lesson) => lesson.studentIds)
          .toSet()
          .toList();

      final students = await _studentService.getStudents();
      final namesMap = {
        for (var student in students) student.id: student.fullName,
      };

      setState(() {
        _lessons = lessons;
        _studentNames = namesMap;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Lesson> _getLessonsForDay(DateTime day) {
    return _lessons.where((lesson) {
      return lesson.date.year == day.year &&
          lesson.date.month == day.month &&
          lesson.date.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalendarz'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: 'Ustawienia',
          ),
        ],
      ),
      body: _isLoadingInstructors
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Dropdown wyboru instruktora
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedInstructorId,
                          decoration: const InputDecoration(
                            labelText: 'Instruktor',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
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
                              _loadLessons();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Kalendarz miesięczny
                if (_isLoading)
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
                Expanded(
                  child: _showWeekView ? _buildWeekView() : _buildDayList(),
                ),
              ],
            ),
      floatingActionButton: _selectedInstructorId != null
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LessonFormScreen(
                      instructorId: _selectedInstructorId!,
                      preselectedDate: _selectedDay ?? DateTime.now(),
                      onLessonSaved: _loadLessons,
                    ),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  // Widok listy lekcji (jak u instruktora)
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
              '${lesson.startTimeFormatted} - ${lesson.endTimeFormatted}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lesson.studentIds.isNotEmpty)
                  Text(
                    lesson.studentIds
                        .map((id) => _studentNames[id] ?? 'Nieznany')
                        .join(', '),
                  ),
                Text('${lesson.durationFormatted} jazdy'),
                Text(
                  lesson.statusLabel,
                  style: TextStyle(
                    color: _getStatusColor(lesson.status),
                    fontWeight: FontWeight.w500,
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

  // Dialog szczegółów
  void _showLessonDetails(Lesson lesson) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Lekcja ${lesson.startTimeFormatted} - ${lesson.endTimeFormatted}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data: ${DateFormat('dd.MM.yyyy').format(lesson.date)}'),
            Text('Czas trwania: ${lesson.durationFormatted}'),
            Text('Status: ${lesson.statusLabel}'),
            if (lesson.studentIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Kursanci: ${lesson.studentIds.map((id) => _studentNames[id] ?? "Nieznany").join(", ")}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
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
          if (lesson.status != 'completed')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showDeleteLessonDialog(lesson);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Usuń'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LessonFormScreen(
                    instructorId: _selectedInstructorId!,
                    lesson: lesson,
                    onLessonSaved: _loadLessons,
                  ),
                ),
              );
            },
            child: const Text('Edytuj'),
          ),
        ],
      ),
    );
  }

  // Dialog usuwania
  Future<void> _showDeleteLessonDialog(Lesson lesson) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń lekcję'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Czy na pewno chcesz usunąć tę lekcję?'),
            const SizedBox(height: 12),
            Text(
              'Data: ${DateFormat('dd.MM.yyyy').format(lesson.date)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              'Godzina: ${lesson.startTimeFormatted} - ${lesson.endTimeFormatted}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
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
        await _lessonService.deleteLesson(lesson.id);
        await _loadLessons();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lekcja usunięta'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Błąd: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
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
}
