import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_client.dart';
import '../services/planner_service.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  static const Color brand = Color(0xFF5D7048);

  final _planner = PlannerService();
  List<Plan> _plans = [];
  bool _isLoading = true;
  String? _error;
  bool _changedAnything = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final plans = await _planner.listPlans();
      if (!mounted) return;
      setState(() {
        _plans = plans;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _openEditor({Plan? existing}) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlanEditor(existing: existing),
    );
    if (changed == true) {
      _changedAnything = true;
      _load();
    }
  }

  Future<void> _confirmDelete(Plan p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete plan?'),
        content: Text(
          'This will permanently delete "${p.title}" and every session inside it.',
        ),
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
    if (ok != true) return;
    try {
      await _planner.deletePlan(p.id);
      _changedAnything = true;
      if (!mounted) return;
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFB23A48),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        // No-op; parent reads `_changedAnything` via Navigator.pop result.
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF333333),
          elevation: 0,
          title: Text(
            'My plans',
            style: GoogleFonts.nunito(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _changedAnything),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          onPressed: () => _openEditor(),
          child: const Icon(Icons.add),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _errorView()
                : _plans.isEmpty
                    ? _emptyView()
                    : _planList(),
      ),
    );
  }

  Widget _errorView() {
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
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: const Color(0xFF555555),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _emptyView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_note_outlined,
                color: Color(0xFFC5D1C9), size: 56),
            const SizedBox(height: 10),
            Text(
              'No plans yet',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'A plan groups related sessions (e.g., "Math Tutoring").',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: const Color(0xFF999999),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Create your first plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: _plans.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final p = _plans[i];
        return _PlanCard(
          plan: p,
          onEdit: () => _openEditor(existing: p),
          onDelete: () => _confirmDelete(p),
        );
      },
    );
  }
}

// ============================================================
//  Plan list card
// ============================================================

class _PlanCard extends StatelessWidget {
  final Plan plan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PlanCard({
    required this.plan,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: _hexToColor(plan.color),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.title,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF333333),
                  ),
                ),
                if (plan.business != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    plan.business!.name,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: const Color(0xFF999999),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (plan.notes != null && plan.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    plan.notes!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: const Color(0xFF555555),
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined,
                color: Color(0xFF555555), size: 20),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline,
                color: Color(0xFFB23A48), size: 20),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  Plan editor bottom sheet (create + edit)
// ============================================================

class _PlanEditor extends StatefulWidget {
  final Plan? existing;
  const _PlanEditor({this.existing});

  @override
  State<_PlanEditor> createState() => _PlanEditorState();
}

class _PlanEditorState extends State<_PlanEditor> {
  static const List<String> _swatch = [
    '#6F9A84', '#5D7048', '#CC6B2E', '#B23A48',
    '#3A6EA5', '#7A5AA5', '#777777',
  ];

  final _planner = PlannerService();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedColor = '#6F9A84';
  bool _busy = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _titleController.text = widget.existing!.title;
      _notesController.text = widget.existing!.notes ?? '';
      _selectedColor = widget.existing!.color;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError('Please enter a title.');
      return;
    }
    setState(() => _busy = true);
    try {
      if (_isEdit) {
        await _planner.updatePlan(
          widget.existing!.id,
          title: title,
          notes: _notesController.text.trim(),
          color: _selectedColor,
        );
      } else {
        await _planner.createPlan(
          title: title,
          notes: _notesController.text.trim(),
          color: _selectedColor,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
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
            const SizedBox(height: 16),
            Text(
              _isEdit ? 'Edit plan' : 'New plan',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 16),
            _label('Title *'),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.words,
              decoration: _decoration(hint: 'e.g. Math Tutoring'),
            ),
            const SizedBox(height: 12),
            _label('Notes (optional)'),
            TextField(
              controller: _notesController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoration(hint: 'Anything to remember'),
            ),
            const SizedBox(height: 14),
            _label('Color'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _swatch.map((hex) {
                final selected = _selectedColor == hex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _hexToColor(hex),
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: Colors.black, width: 2)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: _busy ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _PlansScreenState.brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _busy
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
                        _isEdit ? 'Save' : 'Create plan',
                        style: GoogleFonts.nunito(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
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
}

Color _hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  final value = int.tryParse(cleaned, radix: 16) ?? 0x6F9A84;
  return Color(0xFF000000 | value);
}
