import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/auth_service.dart';
import '../../services/lesson_service.dart';
import '../../models/lesson.dart';
import 'package:intl/intl.dart';

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
                // Kalendarz
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
                    titleTextFormatter:
                        (date, locale) => // ✅ DODAJ formatter nagłówka
                            DateFormat.yMMMM('pl_PL').format(date),
                  ),
                  // ✅ Polskie nazwy przycisków formatu
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Miesiąc',
                    CalendarFormat.twoWeeks: '2 tygodnie',
                    CalendarFormat.week: 'Tydzień',
                  },
                ),
                const SizedBox(height: 8),
                // Lista lekcji wybranego dnia
                Expanded(child: _buildLessonsList()),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Dodaj lekcję
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dodawanie lekcji - wkrótce')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLessonsList() {
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
