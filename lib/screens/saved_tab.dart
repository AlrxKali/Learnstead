import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_client.dart';
import '../services/business_service.dart';
import '../utils/category_image.dart';
import '../widgets/business_card.dart';
import '../widgets/business_detail_sheet.dart';

class SavedTab extends StatefulWidget {
  const SavedTab({super.key});

  @override
  State<SavedTab> createState() => _SavedTabState();
}

class _SavedTabState extends State<SavedTab> {
  static const Color brand = Color(0xFF5D7048);

  final _service = BusinessService();

  List<Business> _saved = [];
  bool _isLoading = true;
  String? _error;

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
      final saved = await _service.listSaved();
      if (!mounted) return;
      setState(() {
        _saved = saved;
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

  Future<void> _unsave(Business b) async {
    // Optimistic remove.
    final idx = _saved.indexWhere((x) => x.id == b.id);
    if (idx == -1) return;
    setState(() => _saved.removeAt(idx));
    try {
      await _service.unsaveBusiness(b.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saved.insert(idx, b));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFB23A48)),
      );
    }
  }

  Future<void> _resave(Business b) async {
    setState(() => _saved.add(b));
    try {
      await _service.saveBusiness(b.id);
      if (!mounted) return;
      // Re-fetch to get correct ordering (saved_at desc).
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saved.removeWhere((x) => x.id == b.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFB23A48)),
      );
    }
  }

  void _showDetail(Business b) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, controller) => StatefulBuilder(
          builder: (_, setSheetState) {
            final isSaved = _saved.any((x) => x.id == b.id);
            return BusinessDetailSheet(
              business: b,
              scrollController: controller,
              isSaved: isSaved,
              onToggleSave: () async {
                if (isSaved) {
                  await _unsave(b);
                } else {
                  await _resave(b);
                }
                setSheetState(() {});
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Saved',
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF333333),
            ),
          ),
          if (_saved.isNotEmpty)
            Text(
              '${_saved.length}',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF999999),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _errorView();
    }
    if (_saved.isEmpty) {
      return _emptyView();
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
        itemCount: _saved.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final b = _saved[i];
          final image =
              b.category != null ? imageForCategory(b.category!) : null;
          return BusinessCard(
            business: b,
            imageAsset: image,
            isSaved: true,
            onToggleSave: () => _unsave(b),
            onTap: () => _showDetail(b),
          );
        },
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
                fontWeight: FontWeight.w600,
                color: const Color(0xFF555555),
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
            const Icon(Icons.favorite_border,
                color: Color(0xFFC5D1C9), size: 56),
            const SizedBox(height: 10),
            Text(
              'No saved providers yet',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap the heart on any provider to save it here for later.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: const Color(0xFF999999),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
