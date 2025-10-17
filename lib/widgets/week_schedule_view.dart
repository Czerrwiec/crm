import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/lesson.dart';

class WeekScheduleView extends StatelessWidget {
  final DateTime selectedDay;
  final List<Lesson> lessons;
  final Function(Lesson) onLessonTap;
  final double width; 

  const WeekScheduleView({
    super.key,
    required this.selectedDay,
    required this.lessons,
    required this.onLessonTap,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    // Tydzień od poniedziałku do niedzieli
    final weekStart = _getWeekStart(selectedDay);
    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return Column(
      children: [
        // Header z dniami tygodnia
        _buildWeekHeader(weekDays),

        // Siatka godzin + lekcje
        Expanded(child: _buildScheduleGrid(weekDays)),
      ],
    );
  }

  DateTime _getWeekStart(DateTime date) {
    // Pierwszy dzień tygodnia (poniedziałek)
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  Widget _buildWeekHeader(List<DateTime> weekDays) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          // Kolumna godzin (pusta)
          SizedBox(
            width: 60,
            child: Center(
              child: Text(
                'Godz.',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ),
          ),

          // Dni tygodnia
          ...weekDays.map((day) {
            final isToday =
                day.day == DateTime.now().day &&
                day.month == DateTime.now().month &&
                day.year == DateTime.now().year;

            return Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: Colors.grey.shade300)),
                  color: isToday ? Colors.blue.shade50 : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat.E('pl_PL').format(day),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isToday ? Colors.blue.shade700 : null,
                      ),
                    ),
                    Text(
                      day.day.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isToday ? Colors.blue.shade700 : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildScheduleGrid(List<DateTime> weekDays) {
    const startHour = 7;
    const endHour = 20;
    const hourHeight = 80.0;

    return SingleChildScrollView(
      child: SizedBox(
        height: (endHour - startHour) * hourHeight,
        child: Stack(
          children: [
            // Siatka godzin (tło)
            Row(
              children: [
                // Kolumna godzin
                SizedBox(
                  width: 60,
                  child: Column(
                    children: List.generate(endHour - startHour, (i) {
                      final hour = startHour + i;
                      return Container(
                        height: hourHeight,
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          '${hour.toString().padLeft(2, '0')}:00',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // Kolumny dni (linie)
                ...weekDays.map((day) {
                  return Expanded(
                    child: Column(
                      children: List.generate(endHour - startHour, (i) {
                        return Container(
                          height: hourHeight,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade300),
                              left: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ],
            ),

            // Kafelki lekcji (nad siatką)
            ..._buildLessonTiles(weekDays, startHour, hourHeight, width),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLessonTiles(
    List<DateTime> weekDays,
    int startHour,
    double hourHeight,
    double width,
  ) {
    final tiles = <Widget>[];

    for (var i = 0; i < weekDays.length; i++) {
      final day = weekDays[i];
      final dayLessons = lessons.where((lesson) {
        return lesson.date.year == day.year &&
            lesson.date.month == day.month &&
            lesson.date.day == day.day;
      }).toList();

      for (final lesson in dayLessons) {
        final tile = _buildLessonTile(
          lesson,
          i,
          startHour,
          hourHeight,
          weekDays.length,
          width,
        );
        if (tile != null) tiles.add(tile);
      }
    }

    return tiles;
  }

  Widget? _buildLessonTile(
    Lesson lesson,
    int dayIndex,
    int startHour,
    double hourHeight,
    int totalDays,
    double screenWidth,
  ) {
    // Parse start/end time
    final startParts = lesson.startTime.split(':');
    final endParts = lesson.endTime.split(':');

    final startMinutes =
        int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    final startOffsetMinutes = startMinutes - (startHour * 60);
    final durationMinutes = endMinutes - startMinutes;

    if (startOffsetMinutes < 0) return null; // Przed zakresem

    // Pozycja i rozmiar
    final top = (startOffsetMinutes / 60) * hourHeight;
    final height = (durationMinutes / 60) * hourHeight - 4;

    // Szerokość kolumny
    final columnWidth = (screenWidth - 60) / totalDays;

    return Positioned(
      left: 60 + (dayIndex * columnWidth) + 4,
      top: top + 2,
      width: columnWidth - 8,
      height: height,
      child: GestureDetector(
        onTap: () => onLessonTap(lesson),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _getStatusColor(lesson.status),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _getStatusColor(lesson.status).withOpacity(0.8),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${lesson.startTime} - ${lesson.endTime}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${lesson.duration}h jazdy',
                style: const TextStyle(color: Colors.white, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.orange.shade600;
      case 'completed':
        return Colors.green.shade600;
      case 'cancelled':
        return Colors.grey.shade600;
      default:
        return Colors.blue.shade600;
    }
  }
}
