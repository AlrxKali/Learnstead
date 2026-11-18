import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_client.dart';
import '../services/event_service.dart';
import '../utils/datetime_format.dart';
import '../widgets/event_form_sheet.dart';

class ProviderScheduleTab extends StatefulWidget {
  const ProviderScheduleTab({super.key});

  @override
  State<ProviderScheduleTab> createState() => _ProviderScheduleTabState();
}

class _ProviderScheduleTabState extends State<ProviderScheduleTab> {
  final _eventService = EventService();

  late DateTime _selectedDate;
  late DateTime _weekStart;

  /// Events whose start falls in the visible week.
  List<BusinessEvent> _events = [];
  bool _isLoading = true;
  String? _loadError;
  bool _noBusiness = false;
  int _loadSeq = 0;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _weekStart = _getWeekStart(_selectedDate);
    _loadWeek();
  }

  /// Select [date]; refetch only if that moves to a different week.
  void _select(DateTime date) {
    final newWeek = _getWeekStart(date);
    final weekChanged = !isSameDay(newWeek, _weekStart);
    setState(() {
      _selectedDate = date;
      _weekStart = newWeek;
    });
    if (weekChanged) _loadWeek();
  }

  Future<void> _loadWeek() async {
    final seq = ++_loadSeq;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final events = await _eventService.listMyEvents(
        from: _weekStart,
        to: _weekStart.add(const Duration(days: 7)),
      );
      if (!mounted || seq != _loadSeq) return;
      setState(() {
        _events = events;
        _isLoading = false;
        _noBusiness = false;
      });
    } on ApiException catch (e) {
      if (!mounted || seq != _loadSeq) return;
      setState(() {
        _events = [];
        _isLoading = false;
        _noBusiness = e.statusCode == 404;
        _loadError = e.statusCode == 404 ? null : e.message;
      });
    }
  }

  List<BusinessEvent> _eventsOn(DateTime day) =>
      _events.where((e) => isSameDay(e.startsAt, day)).toList();

  Future<void> _openForm({BusinessEvent? existing}) async {
    if (_noBusiness) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Set up your business first (My Business tab).'),
        ),
      );
      return;
    }
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventFormSheet(
        initialDay: _selectedDate,
        existing: existing,
      ),
    );
    if (changed == true && mounted) _loadWeek();
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _select(
                  _selectedDate.subtract(const Duration(days: 7)),
                ),
                child: const Icon(
                  Icons.chevron_left,
                  color: Color(0xFF555555),
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${monthNames[_selectedDate.month - 1]} ${_selectedDate.year}',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _select(
                  _selectedDate.add(const Duration(days: 7)),
                ),
                child: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF555555),
                  size: 24,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => _select(DateTime.now()),
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
          // Calendar arithmetic (not Duration) so DST shifts can't skip a day.
          final day = DateTime(
              _weekStart.year, _weekStart.month, _weekStart.day + i);
          final isSelected = isSameDay(day, _selectedDate);
          final isToday = isSameDay(day, DateTime.now());
          final hasEvents = _eventsOn(day).isNotEmpty;

          return GestureDetector(
            onTap: () => _select(day),
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
    final label = formatLongDate(_selectedDate);

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
            onTap: () => _openForm(),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return _centerMessage(
        icon: Icons.error_outline,
        iconColor: const Color(0xFFB23A48),
        title: _loadError!,
        action: TextButton(
          onPressed: _loadWeek,
          child: Text(
            'Retry',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF5D7048),
            ),
          ),
        ),
      );
    }
    if (_noBusiness) {
      return _centerMessage(
        icon: Icons.storefront_outlined,
        title: 'Set up your business first',
        subtitle: 'Your schedule lives on your business listing.',
      );
    }

    final dayEvents = _eventsOn(_selectedDate);
    if (dayEvents.isEmpty) {
      return _centerMessage(
        icon: Icons.event_available_outlined,
        title: 'No events scheduled',
        subtitle: 'Tap + Add Event to create one',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWeek,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: dayEvents.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _buildEventCard(dayEvents[index]),
      ),
    );
  }

  Widget _centerMessage({
    required IconData icon,
    Color? iconColor,
    required String title,
    String? subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: iconColor ?? const Color(0xFFC5D1C9).withAlpha(150),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF999999),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFC5D1C9),
                ),
              ),
            ],
            ?action,
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(BusinessEvent event) {
    final cancelled = event.status == EventStatus.cancelled;
    final barColor = cancelled
        ? const Color(0xFFBBBBBB)
        : event.type == EventType.session
            ? const Color(0xFF5D7048)
            : const Color(0xFFCC6B2E);
    final statusColor = switch (event.status) {
      EventStatus.confirmed => const Color(0xFF5D7048),
      EventStatus.pending => const Color(0xFFCC6B2E),
      EventStatus.cancelled => const Color(0xFF999999),
    };

    return GestureDetector(
      onTap: () => _openForm(existing: event),
      child: Container(
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
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
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
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: cancelled
                                    ? const Color(0xFF999999)
                                    : const Color(0xFF333333),
                                decoration: cancelled
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              event.status.label,
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          _meta(Icons.access_time_outlined,
                              formatTimeRange(event.startsAt, event.endsAt)),
                          _meta(
                            event.type == EventType.session
                                ? Icons.groups_outlined
                                : Icons.forum_outlined,
                            event.type.label,
                          ),
                          if (event.capacity != null)
                            _meta(
                              Icons.people_outline,
                              '${event.capacity} spot${event.capacity == 1 ? '' : 's'}',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF999999)),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF999999),
          ),
        ),
      ],
    );
  }
}
