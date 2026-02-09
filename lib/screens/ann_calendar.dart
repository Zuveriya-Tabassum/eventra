import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'ann_models.dart';

class AnnouncementCalendarPage extends StatefulWidget {
  final List<Announcement> announcements;

  const AnnouncementCalendarPage({
    super.key,
    required this.announcements,
  });

  @override
  State<AnnouncementCalendarPage> createState() =>
      _AnnouncementCalendarPageState();
}

class _AnnouncementCalendarPageState extends State<AnnouncementCalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  List<Announcement> _eventsForDay(DateTime day) {
    return widget.announcements.where((a) {
      return isSameDay(a.date, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final events = _eventsForDay(_selectedDay);

    return Column(
      children: [
        TableCalendar<Announcement>(
          firstDay: DateTime(2020),
          lastDay: DateTime(2030),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarFormat: CalendarFormat.month,
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            });
          },
          eventLoader: _eventsForDay,
          calendarStyle: CalendarStyle(
            markerDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: events.isEmpty
              ? const Center(child: Text('No announcements on this day'))
              : ListView.builder(
            itemCount: events.length,
            itemBuilder: (_, i) {
              final ann = events[i];
              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: ann.isImportant
                      ? const Icon(Icons.priority_high,
                      color: Colors.red)
                      : const Icon(Icons.event),
                  title: Text(ann.title),
                  subtitle: Text(ann.category.name.toUpperCase()),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
