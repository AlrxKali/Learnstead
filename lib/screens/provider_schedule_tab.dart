import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProviderScheduleTab extends StatefulWidget {
  const ProviderScheduleTab({super.key});

  @override
  State<ProviderScheduleTab> createState() => _ProviderScheduleTabState();
}

class _ProviderScheduleTabState extends State<ProviderScheduleTab> {
  late DateTime _selectedDate;
  late DateTime _weekStart;

  // Mock events keyed by day-of-month
  final Map<int, List<_Event>> _events = {
    17: [
      const _Event(
        title: 'Creative Arts Workshop',
        time: '10:00 AM – 12:00 PM',
        attendees: 8,
        status: 'Confirmed',
        type: _EventType.session,
      ),
      const _Event(
        title: 'Parent Consultation',
        time: '1:00 PM – 1:30 PM',
        attendees: 1,
        status: 'Pending',
        type: _EventType.consultation,
      ),
    ],
    18: [
      const _Event(
        title: 'STEM Exploration',
        time: '2:00 PM – 4:00 PM',
        attendees: 10,
        status: 'Confirmed',
        type: _EventType.session,
      ),
    ],
    19: [
      const _Event(
        title: 'Nature Walk & Journaling',
        time: '9:00 AM – 11:00 AM',
        attendees: 6,
        status: 'Confirmed',
        type: _EventType.session,
      ),
      const _Event(
        title: 'New Family Tour',
        time: '3:00 PM – 3:45 PM',
        attendees: 2,
        status: 'Confirmed',
        type: _EventType.consultation,
      ),
    ],
    20: [
      const _Event(
        title: 'Small Group Reading',
        time: '10:00 AM – 11:30 AM',
        attendees: 4,
        status: 'Confirmed',
        type: _EventType.session,
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _weekStart = _getWeekStart(_selectedDate);
  }

  DateTime _getWeekStart(DateTime date) {
    final diff = date.weekday % 7; // Sunday = 0
    return DateTime(date.year, date.month, date.day - diff);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildMonthHeader(),
        const SizedBox(height: 16),
        _buildWeekStrip(),
        const SizedBox(height: 16),
        _buildSelectedDateHeader(),
        const SizedBox(height: 8),
        Expanded(
          child: _buildEventList(),
        ),
      ],
    );
  }

  Widget _buildMonthHeader() {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month - 1,
                      _selectedDate.day,
                    );
                    _weekStart = _getWeekStart(_selectedDate);
                  });
                },
                child: const Icon(
                  Icons.chevron_left,
                  color: Color(0xFF555555),
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${months[_selectedDate.month - 1]} ${_selectedDate.year}',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month + 1,
                      _selectedDate.day,
                    );
                    _weekStart = _getWeekStart(_selectedDate);
                  });
                },
                child: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF555555),
                  size: 24,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = DateTime.now();
                _weekStart = _getWeekStart(_selectedDate);
              });
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9F8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0E7E3)),
              ),
              child: Text(
                'Today',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5D7048),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekStrip() {
    final dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final day = _weekStart.add(Duration(days: i));
          final isSelected = day.day == _selectedDate.day &&
              day.month == _selectedDate.month &&
              day.year == _selectedDate.year;
          final isToday = day.day == DateTime.now().day &&
              day.month == DateTime.now().month &&
              day.year == DateTime.now().year;
          final hasEvents = _events.containsKey(day.day) &&
              day.month == _selectedDate.month;

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = day),
            child: Container(
              width: 42,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF5D7048)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    dayLabels[i],
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white.withAlpha(180)
                          : const Color(0xFF999999),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? Colors.white
                          : isToday
                              ? const Color(0xFF5D7048)
                              : const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: hasEvents
                          ? (isSelected
                              ? Colors.white
                              : const Color(0xFF6F9A84))
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSelectedDateHeader() {
    final weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final label =
        '${weekdays[_selectedDate.weekday - 1]}, ${months[_selectedDate.month - 1]} ${_selectedDate.day}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF555555),
            ),
          ),
          GestureDetector(
            onTap: () {
              // TODO: Add event flow
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF5D7048),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'Add Event',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    final dayEvents = _events[_selectedDate.day];

    if (dayEvents == null || dayEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 48,
              color: const Color(0xFFC5D1C9).withAlpha(150),
            ),
            const SizedBox(height: 12),
            Text(
              'No events scheduled',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF999999),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + Add Event to create one',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFC5D1C9),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: dayEvents.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final event = dayEvents[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(_Event event) {
    final barColor = event.type == _EventType.session
        ? const Color(0xFF5D7048)
        : const Color(0xFFCC6B2E);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Colored bar
          Container(
            width: 4,
            height: 80,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF333333),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: event.status == 'Confirmed'
                              ? const Color(0xFF5D7048).withAlpha(20)
                              : const Color(0xFFCC6B2E).withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          event.status,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: event.status == 'Confirmed'
                                ? const Color(0xFF5D7048)
                                : const Color(0xFFCC6B2E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time_outlined,
                          size: 14, color: Color(0xFF999999)),
                      const SizedBox(width: 4),
                      Text(
                        event.time,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF999999),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.people_outline,
                          size: 14, color: Color(0xFF999999)),
                      const SizedBox(width: 4),
                      Text(
                        '${event.attendees} attendee${event.attendees == 1 ? '' : 's'}',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _EventType { session, consultation }

class _Event {
  final String title;
  final String time;
  final int attendees;
  final String status;
  final _EventType type;

  const _Event({
    required this.title,
    required this.time,
    required this.attendees,
    required this.status,
    required this.type,
  });
}
