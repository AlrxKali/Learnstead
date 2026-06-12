import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/api_client.dart';
import '../services/planner_service.dart';
import 'plans_screen.dart';

class PlannerTab extends StatefulWidget {
  const PlannerTab({super.key});

  @override
  State<PlannerTab> createState() => _PlannerTabState();
}

class _PlannerTabState extends State<PlannerTab> {
  static const Color brand = Color(0xFF5D7048);
  static const Color brandLight = Color(0xFF6F9A84);

  final _planner = PlannerService();

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = _dateOnly(DateTime.now());

  List<Plan> _plans = [];
  Map<DateTime, List<PlanSession>> _sessionsByDay = {};
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        _planner.listPlans(),
        _planner.listSessions(),
      ]);
      if (!mounted) return;
      setState(() {
        _plans = results[0] as List<Plan>;
        _sessionsByDay = _bucketByDay(results[1] as List<PlanSession>);
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.message;
      });
    }
  }

  Map<DateTime, List<PlanSession>> _bucketByDay(List<PlanSession> sessions) {
    final m = <DateTime, List<PlanSession>>{};
    for (final s in sessions) {
      final key = _dateOnly(s.startsAt);
      (m[key] ??= []).add(s);
    }
    for (final list in m.values) {
      list.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    }
    return m;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Plan? _planFor(PlanSession s) {
    for (final p in _plans) {
      if (p.id == s.planId) return p;
    }
    return null;
  }

  List<PlanSession> _sessionsFor(DateTime day) =>
      _sessionsByDay[_dateOnly(day)] ?? const [];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return _ErrorState(message: _loadError!, onRetry: _loadAll);
    }
    return Stack(
      children: [
        Column(
          children: [
            _buildHeader(),
            _buildCalendar(),
            const Divider(height: 1, color: Color(0xFFE0E7E3)),
            Expanded(child: _buildDayList()),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            backgroundColor: brand,
            foregroundColor: Colors.white,
            onPressed: _openNewSessionSheet,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Planner',
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF333333),
            ),
          ),
          TextButton.icon(
            onPressed: _openPlansScreen,
            icon: const Icon(Icons.format_list_bulleted, size: 18),
            label: Text(
              'Plans',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: brand,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar<PlanSession>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2035, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
      onDaySelected: (selected, focused) {
        setState(() {
          _selectedDay = _dateOnly(selected);
          _focusedDay = focused;
        });
      },
      onPageChanged: (focused) => _focusedDay = focused,
      eventLoader: _sessionsFor,
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF333333),
        ),
        leftChevronIcon: const Icon(Icons.chevron_left, color: brandLight),
        rightChevronIcon: const Icon(Icons.chevron_right, color: brandLight),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF999999),
        ),
        weekendStyle: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF999999),
        ),
      ),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        todayDecoration: BoxDecoration(
          color: brandLight.withAlpha(60),
          shape: BoxShape.circle,
        ),
        selectedDecoration: const BoxDecoration(
          color: brand,
          shape: BoxShape.circle,
        ),
        markersAlignment: Alignment.bottomCenter,
      ),
      calendarBuilders: CalendarBuilders<PlanSession>(
        markerBuilder: (context, date, events) {
          if (events.isEmpty) return const SizedBox.shrink();
          // Show up to 3 colored dots based on each session's plan color.
          final colors = events
              .take(3)
              .map((s) => _hexToColor(_planFor(s)?.color ?? '#6F9A84'))
              .toList();
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: colors.map((c) {
                return Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayList() {
    final sessions = _sessionsFor(_selectedDay);
    final dayLabel = _humanDate(_selectedDay);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dayLabel,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: sessions.isEmpty
                ? _emptyDay()
                : ListView.separated(
                    itemCount: sessions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final s = sessions[i];
                      final plan = _planFor(s);
                      return _SessionCard(
                        session: s,
                        plan: plan,
                        onTap: () => _openSessionDetail(s, plan),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyDay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_note_outlined,
              size: 48, color: Color(0xFFC5D1C9)),
          const SizedBox(height: 10),
          Text(
            'No sessions on this day',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to add one.',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFAAAAAA),
            ),
          ),
        ],
      ),
    );
  }

  // -------- actions --------

  Future<void> _openPlansScreen() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PlansScreen()),
    );
    if (changed == true) _loadAll();
  }

  Future<void> _openNewSessionSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewSessionSheet(
        plans: _plans,
        initialDay: _selectedDay,
      ),
    );
    if (created == true) _loadAll();
  }

  Future<void> _openSessionDetail(PlanSession s, Plan? plan) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SessionDetailSheet(session: s, plan: plan),
    );
    if (changed == true) _loadAll();
  }
}

// ============================================================
//  Session card (in the day list)
// ============================================================

class _SessionCard extends StatelessWidget {
  final PlanSession session;
  final Plan? plan;
  final VoidCallback onTap;

  const _SessionCard({
    required this.session,
    required this.plan,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _hexToColor(plan?.color ?? '#6F9A84');
    final cancelled = session.status == SessionStatus.cancelled;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 5,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan?.title ?? '(deleted plan)',
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: cancelled
                                ? const Color(0xFFAAAAAA)
                                : const Color(0xFF333333),
                            decoration:
                                cancelled ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      if (cancelled)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E7E3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Cancelled',
                            style: GoogleFonts.nunito(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF777777),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeRange(session),
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF555555),
                    ),
                  ),
                  if (plan?.business != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      plan!.business!.name,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF999999),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFC5D1C9)),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  New-session bottom sheet
// ============================================================

class _NewSessionSheet extends StatefulWidget {
  final List<Plan> plans;
  final DateTime initialDay;

  const _NewSessionSheet({required this.plans, required this.initialDay});

  @override
  State<_NewSessionSheet> createState() => _NewSessionSheetState();
}

class _NewSessionSheetState extends State<_NewSessionSheet> {
  final _planner = PlannerService();
  final _notesController = TextEditingController();
  final _newPlanTitleController = TextEditingController();

  static const _newPlanSentinel = '__NEW__';

  String? _selectedPlanId;
  DateTime _date = DateTime.now();
  TimeOfDay _start = const TimeOfDay(hour: 16, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 17, minute: 0);
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDay;
    if (widget.plans.isNotEmpty) {
      _selectedPlanId = widget.plans.first.id;
    } else {
      _selectedPlanId = _newPlanSentinel;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _newPlanTitleController.dispose();
    super.dispose();
  }

  DateTime _combine(DateTime d, TimeOfDay t) =>
      DateTime(d.year, d.month, d.day, t.hour, t.minute);

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickStart() async {
    final t = await showTimePicker(context: context, initialTime: _start);
    if (t != null) {
      setState(() {
        _start = t;
        // Auto-bump end if it's now <= start.
        final s = _combine(_date, _start);
        final e = _combine(_date, _end);
        if (!e.isAfter(s)) {
          final bumped = s.add(const Duration(hours: 1));
          _end = TimeOfDay(hour: bumped.hour, minute: bumped.minute);
        }
      });
    }
  }

  Future<void> _pickEnd() async {
    final t = await showTimePicker(context: context, initialTime: _end);
    if (t != null) setState(() => _end = t);
  }

  Future<void> _submit() async {
    final isNewPlan = _selectedPlanId == _newPlanSentinel;
    if (isNewPlan && _newPlanTitleController.text.trim().isEmpty) {
      _showError('Please enter a plan title.');
      return;
    }
    final starts = _combine(_date, _start);
    final ends = _combine(_date, _end);
    if (!ends.isAfter(starts)) {
      _showError('End time must be after start time.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      String planId;
      if (isNewPlan) {
        final created = await _planner.createPlan(
          title: _newPlanTitleController.text.trim(),
        );
        planId = created.id;
      } else {
        planId = _selectedPlanId!;
      }
      await _planner.createSession(
        planId: planId,
        startsAt: starts,
        endsAt: ends,
        notes: _notesController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: const Color(0xFFB23A48)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final isNewPlan = _selectedPlanId == _newPlanSentinel;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E7E3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'New session',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 16),
              _label('Plan'),
              DropdownButtonFormField<String>(
                initialValue: _selectedPlanId,
                onChanged: (v) => setState(() => _selectedPlanId = v),
                decoration: _decoration(hint: 'Choose a plan'),
                items: [
                  ...widget.plans.map(
                    (p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.title,
                          style: GoogleFonts.nunito(fontSize: 14)),
                    ),
                  ),
                  DropdownMenuItem(
                    value: _newPlanSentinel,
                    child: Text('+ New plan…',
                        style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF5D7048))),
                  ),
                ],
              ),
              if (isNewPlan) ...[
                const SizedBox(height: 12),
                _label('Plan title *'),
                TextField(
                  controller: _newPlanTitleController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration(hint: 'e.g. Math Tutoring'),
                ),
              ],
              const SizedBox(height: 16),
              _label('Date'),
              _pickerRow(
                onTap: _pickDate,
                icon: Icons.calendar_today_outlined,
                text: _formatDate(_date),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Start'),
                        _pickerRow(
                          onTap: _pickStart,
                          icon: Icons.schedule_outlined,
                          text: _start.format(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('End'),
                        _pickerRow(
                          onTap: _pickEnd,
                          icon: Icons.schedule_outlined,
                          text: _end.format(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _label('Notes (optional)'),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: _decoration(hint: 'Anything to remember'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _PlannerTabState.brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Add session',
                          style: GoogleFonts.nunito(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          t,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF555555),
          ),
        ),
      );

  InputDecoration _decoration({required String hint}) => InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.nunito(fontSize: 14, color: const Color(0xFFAAAAAA)),
        filled: true,
        fillColor: const Color(0xFFF7F9F8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E7E3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E7E3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF6F9A84), width: 1.5),
        ),
      );

  Widget _pickerRow({
    required VoidCallback onTap,
    required IconData icon,
    required String text,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9F8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E7E3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFC5D1C9), size: 18),
            const SizedBox(width: 10),
            Text(
              text,
              style: GoogleFonts.nunito(
                  fontSize: 14, color: const Color(0xFF333333)),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  Session detail bottom sheet
// ============================================================

class _SessionDetailSheet extends StatefulWidget {
  final PlanSession session;
  final Plan? plan;
  const _SessionDetailSheet({required this.session, required this.plan});

  @override
  State<_SessionDetailSheet> createState() => _SessionDetailSheetState();
}

class _SessionDetailSheetState extends State<_SessionDetailSheet> {
  final _planner = PlannerService();
  bool _busy = false;
  late PlanSession _session;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
  }

  Future<void> _toggleCancel() async {
    setState(() => _busy = true);
    try {
      final updated = _session.status == SessionStatus.planned
          ? await _planner.cancelSession(_session.id)
          : await _planner.reactivateSession(_session.id);
      if (!mounted) return;
      setState(() {
        _session = updated;
        _busy = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showError(e.message);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete session?'),
        content: const Text('This will permanently remove this session.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await _planner.deleteSession(_session.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showError(e.message);
    }
  }

  void _showError(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: const Color(0xFFB23A48)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final cancelled = _session.status == SessionStatus.cancelled;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E7E3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _hexToColor(plan?.color ?? '#6F9A84'),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  plan?.title ?? '(deleted plan)',
                  style: GoogleFonts.nunito(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF333333),
                  ),
                ),
              ),
              if (cancelled)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E7E3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Cancelled',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF777777),
                    ),
                  ),
                ),
            ],
          ),
          if (plan?.business != null) ...[
            const SizedBox(height: 6),
            Text(
              plan!.business!.name,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: const Color(0xFF999999),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 16, color: Color(0xFF6F9A84)),
              const SizedBox(width: 8),
              Text(
                _humanDate(_session.startsAt),
                style: GoogleFonts.nunito(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.schedule_outlined,
                  size: 16, color: Color(0xFF6F9A84)),
              const SizedBox(width: 8),
              Text(
                _timeRange(_session),
                style: GoogleFonts.nunito(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (_session.notes != null && _session.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _session.notes!,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: const Color(0xFF555555),
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _toggleCancel,
                  icon: Icon(cancelled ? Icons.undo : Icons.cancel_outlined),
                  label: Text(cancelled ? 'Reactivate' : 'Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF555555),
                    side: const BorderSide(color: Color(0xFFE0E7E3)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB23A48),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  Error state
// ============================================================

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: Color(0xFFB23A48), size: 48),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5D7048),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  Formatting helpers
// ============================================================

String _humanDate(DateTime d) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  const weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];
  return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
}

String _formatDate(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

String _timeRange(PlanSession s) {
  String fmt(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour12:$m $period';
  }

  return '${fmt(s.startsAt)} – ${fmt(s.endsAt)}';
}

Color _hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  final value = int.tryParse(cleaned, radix: 16) ?? 0x6F9A84;
  return Color(0xFF000000 | value);
}
