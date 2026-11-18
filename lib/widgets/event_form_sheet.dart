import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_client.dart';
import '../services/event_service.dart';
import '../utils/datetime_format.dart';

/// Bottom sheet for creating or editing a schedule event.
///
/// Pops with `true` when something was saved or deleted.
class EventFormSheet extends StatefulWidget {
  final DateTime initialDay;
  final BusinessEvent? existing;

  const EventFormSheet({super.key, required this.initialDay, this.existing});

  @override
  State<EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends State<EventFormSheet> {
  static const Color _brand = Color(0xFF5D7048);

  final _service = EventService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController();

  late DateTime _date;
  TimeOfDay _start = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 11, minute: 0);
  EventType _type = EventType.session;
  EventStatus _status = EventStatus.confirmed;
  bool _isSubmitting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e == null) {
      _date = widget.initialDay;
    } else {
      _date = e.startsAt;
      _start = TimeOfDay.fromDateTime(e.startsAt);
      _end = TimeOfDay.fromDateTime(e.endsAt);
      _type = e.type;
      _status = e.status;
      _titleController.text = e.title;
      _descriptionController.text = e.description ?? '';
      _capacityController.text = e.capacity?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  DateTime _combine(TimeOfDay t) =>
      DateTime(_date.year, _date.month, _date.day, t.hour, t.minute);

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
    if (t == null) return;
    setState(() {
      _start = t;
      // Keep the end after the start, capped at the end of the day.
      if (!_combine(_end).isAfter(_combine(_start))) {
        final bumped = _combine(_start).add(const Duration(hours: 1));
        _end = isSameDay(bumped, _date)
            ? TimeOfDay.fromDateTime(bumped)
            : const TimeOfDay(hour: 23, minute: 59);
      }
    });
  }

  Future<void> _pickEnd() async {
    final t = await showTimePicker(context: context, initialTime: _end);
    if (t != null) setState(() => _end = t);
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError('Please enter a title.');
      return;
    }
    final starts = _combine(_start);
    final ends = _combine(_end);
    if (!ends.isAfter(starts)) {
      _showError('End time must be after start time.');
      return;
    }
    final capacityText = _capacityController.text.trim();
    final capacity = capacityText.isEmpty ? null : int.tryParse(capacityText);
    if (capacityText.isNotEmpty && (capacity == null || capacity < 1)) {
      _showError('Spots must be a number greater than zero.');
      return;
    }
    final description = _descriptionController.text.trim();

    setState(() => _isSubmitting = true);
    try {
      if (_isEdit) {
        await _service.updateEvent(
          widget.existing!.id,
          title: title,
          description: description.isEmpty ? null : description,
          type: _type,
          startsAt: starts,
          endsAt: ends,
          capacity: capacity,
          status: _status,
        );
      } else {
        await _service.createEvent(
          title: title,
          description: description.isEmpty ? null : description,
          type: _type,
          startsAt: starts,
          endsAt: ends,
          capacity: capacity,
          status: _status,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Delete this event?',
            style:
                GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800)),
        content: Text(
          'This removes it from your schedule and your public listing.',
          style: GoogleFonts.nunito(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFB23A48))),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isSubmitting = true);
    try {
      await _service.deleteEvent(widget.existing!.id);
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
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEdit ? 'Edit event' : 'New event',
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF333333),
                      ),
                    ),
                  ),
                  if (_isEdit)
                    IconButton(
                      tooltip: 'Delete event',
                      onPressed: _isSubmitting ? null : _delete,
                      icon: const Icon(Icons.delete_outline,
                          color: Color(0xFFB23A48)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _label('Title *'),
              TextField(
                controller: _titleController,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.nunito(fontSize: 14),
                decoration: _decoration(hint: 'e.g. Creative Arts Workshop'),
              ),
              const SizedBox(height: 14),
              _label('Type'),
              Row(
                children: EventType.values.map((t) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _choice(
                      label: t.label,
                      selected: _type == t,
                      onTap: () => setState(() => _type = t),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              _label('Date'),
              _pickerRow(
                onTap: _pickDate,
                icon: Icons.calendar_today_outlined,
                text: formatLongDate(_date),
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
              const SizedBox(height: 14),
              _label('Spots available (optional)'),
              TextField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.nunito(fontSize: 14),
                decoration: _decoration(hint: 'e.g. 8'),
              ),
              const SizedBox(height: 14),
              _label('Status'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in EventStatus.values)
                    // Cancelling only makes sense for an event that exists.
                    if (_isEdit || s != EventStatus.cancelled)
                      _choice(
                        label: s.label,
                        selected: _status == s,
                        onTap: () => setState(() => _status = s),
                      ),
                ],
              ),
              const SizedBox(height: 14),
              _label('Details (optional)'),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.nunito(fontSize: 14),
                decoration:
                    _decoration(hint: 'What families should know or bring'),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 46,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brand,
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
                          _isEdit ? 'Save changes' : 'Add event',
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

  Widget _choice({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _brand : const Color(0xFFF7F9F8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _brand : const Color(0xFFE0E7E3),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF555555),
          ),
        ),
      ),
    );
  }

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
          borderSide: const BorderSide(color: Color(0xFF6F9A84), width: 1.5),
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
            Icon(icon, size: 16, color: const Color(0xFF6F9A84)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
