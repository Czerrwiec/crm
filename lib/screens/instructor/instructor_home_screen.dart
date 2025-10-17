import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/lesson_service.dart';
import '../../models/lesson.dart';
import '../../widgets/week_schedule_view.dart';
import '../lessons/lesson_from_screen.dart';

class InstructorHomeScreen extends StatefulWidget {
  const InstructorHomeScreen({super.key});

  @override
  State<InstructorHomeScreen> createState() => _InstructorHomeScreenState();
}

class _InstructorHomeScreenState extends State<InstructorHomeScreen> {
  final _lessonService = LessonService();
  final _authService = AuthService();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Lesson> _lessons = [];
  bool _isLoading = true;
  String? _instructorId;

  // Toggle widoku tygodniowego
  bool _showWeekView = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _initInstructor();
  }

  Future<void> _initInstructor() async {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        _instructorId = user.id;
      });
      await _loadLessons();
    }
  }

  Future<void> _loadLessons() async {
    if (_instructorId == null) return;

    setState(() => _isLoading = true);
    try {
      final lessons = await _lessonService.getLessonsByInstructor(
        _instructorId!,
        _focusedDay,
      );
      setState(() {
        _lessons = lessons;
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
        title: const Text('Moje lekcje'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Kalendarz miesięczny
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

                // Divider + Toggle widoku tygodniowego
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

                // Widok poniżej (lista lub tydzień)
                Expanded(
                  child: _showWeekView ? _buildWeekView() : _buildDayList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LessonFormScreen(
                instructorId: _instructorId!,
                preselectedDate: _selectedDay ?? DateTime.now(),
                onLessonSaved: _loadLessons,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Widok listy lekcji wybranego dnia (jak było)
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
              // TODO: Szczegóły lekcji
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Szczegóły lekcji - wkrótce')),
              );
            },
          ),
        );
      },
    );
  }

  // Custom widok tygodniowy z godzinami
  // Custom widok tygodniowy z godzinami
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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LessonFormScreen(
                    instructorId: _instructorId!,
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
