import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/business_service.dart';
import '../utils/category_image.dart';
import '../widgets/business_card.dart';
import '../widgets/business_detail_sheet.dart';

enum LocationScope { nearMe, anywhere }

extension on LocationScope {
  String get label =>
      this == LocationScope.nearMe ? 'Near me' : 'Anywhere';
}

class SearchFilters {
  String? categoryId;
  Set<String> subcategoryIds;
  Set<DeliveryMode> deliveryModes;
  int? age;
  LocationScope location;

  SearchFilters({
    this.categoryId,
    Set<String>? subcategoryIds,
    Set<DeliveryMode>? deliveryModes,
    this.age,
    this.location = LocationScope.anywhere,
  })  : subcategoryIds = subcategoryIds ?? <String>{},
        deliveryModes = deliveryModes ?? <DeliveryMode>{};

  int get count {
    int c = 0;
    if (categoryId != null) c++;
    c += subcategoryIds.length;
    c += deliveryModes.length;
    if (age != null) c++;
    if (location == LocationScope.nearMe) c++;
    return c;
  }

  SearchFilters copy() => SearchFilters(
        categoryId: categoryId,
        subcategoryIds: {...subcategoryIds},
        deliveryModes: {...deliveryModes},
        age: age,
        location: location,
      );
}

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  static const Color brand = Color(0xFF5D7048);

  final _service = BusinessService();
  final _searchController = TextEditingController();
  Timer? _debounce;

  SearchFilters _filters = SearchFilters();

  List<BusinessCategory> _categories = [];
  List<BusinessCategory> _subcategories = [];

  List<Business> _results = [];
  Set<String> _savedIds = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadSavedIds();
    _refresh();
  }

  Future<void> _loadSavedIds() async {
    try {
      final ids = await _service.listSavedIds();
      if (!mounted) return;
      setState(() => _savedIds = ids);
    } on ApiException {
      // Non-fatal; hearts just show as unfilled.
    }
  }

  Future<void> _toggleSave(Business b) async {
    final wasSaved = _savedIds.contains(b.id);
    // Optimistic toggle.
    setState(() {
      if (wasSaved) {
        _savedIds.remove(b.id);
      } else {
        _savedIds.add(b.id);
      }
    });
    try {
      if (wasSaved) {
        await _service.unsaveBusiness(b.id);
      } else {
        await _service.saveBusiness(b.id);
      }
    } on ApiException catch (e) {
      // Revert.
      if (!mounted) return;
      setState(() {
        if (wasSaved) {
          _savedIds.add(b.id);
        } else {
          _savedIds.remove(b.id);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFB23A48)),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _service.listCategories();
      final subs = await _service.listSubcategories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _subcategories = subs;
      });
    } on ApiException {
      // Non-fatal; filter sheet just shows fewer options.
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      String? zipPrefix;
      if (_filters.location == LocationScope.nearMe) {
        final z = Session.current?.profile.homeZipCode;
        if (z != null && z.length >= 3) zipPrefix = z.substring(0, 3);
      }
      final results = await _service.search(
        q: _searchController.text,
        categoryId: _filters.categoryId,
        subcategoryIds: _filters.subcategoryIds.isEmpty
            ? null
            : _filters.subcategoryIds.toList(),
        deliveryModes: _filters.deliveryModes.isEmpty
            ? null
            : _filters.deliveryModes.toList(),
        age: _filters.age,
        zipPrefix: zipPrefix,
      );
      if (!mounted) return;
      setState(() {
        _results = results;
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

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _refresh);
  }

  Future<void> _openFilters() async {
    final updated = await showModalBottomSheet<SearchFilters?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        initial: _filters.copy(),
        categories: _categories,
        subcategories: _subcategories,
        hasHomeZip:
            (Session.current?.profile.homeZipCode ?? '').isNotEmpty,
      ),
    );
    if (updated != null) {
      setState(() => _filters = updated);
      _refresh();
    }
  }

  void _clearOneFilter({
    String? subcategoryId,
    DeliveryMode? mode,
    bool clearCategory = false,
    bool clearAge = false,
    bool clearLocation = false,
  }) {
    setState(() {
      if (subcategoryId != null) _filters.subcategoryIds.remove(subcategoryId);
      if (mode != null) _filters.deliveryModes.remove(mode);
      if (clearCategory) _filters.categoryId = null;
      if (clearAge) _filters.age = null;
      if (clearLocation) _filters.location = LocationScope.anywhere;
    });
    _refresh();
  }

  void _clearAll() {
    _searchController.clear();
    setState(() => _filters = SearchFilters());
    _refresh();
  }

  // ============= build =============

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        if (_filters.count > 0) _buildActiveFilterStrip(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search',
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSearchBox()),
              const SizedBox(width: 10),
              _buildFilterButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E7E3)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: GoogleFonts.nunito(
          fontSize: 14,
          color: const Color(0xFF333333),
        ),
        decoration: InputDecoration(
          hintText: 'Search programs, names, keywords…',
          hintStyle: GoogleFonts.nunito(
            fontSize: 14,
            color: const Color(0xFFAAAAAA),
          ),
          prefixIcon:
              const Icon(Icons.search, color: Color(0xFFC5D1C9), size: 20),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _refresh();
                  },
                ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    final hasFilters = _filters.count > 0;
    return GestureDetector(
      onTap: _openFilters,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: hasFilters ? brand : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasFilters ? brand : const Color(0xFFE0E7E3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune,
              size: 18,
              color: hasFilters ? Colors.white : const Color(0xFF555555),
            ),
            if (hasFilters) ...[
              const SizedBox(width: 6),
              Text(
                '${_filters.count}',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterStrip() {
    final chips = <Widget>[];

    if (_filters.categoryId != null) {
      final cat = _categories.firstWhere(
        (c) => c.id == _filters.categoryId,
        orElse: () => BusinessCategory(id: '?', name: 'Category'),
      );
      chips.add(_filterChip(cat.name, () => _clearOneFilter(clearCategory: true)));
    }
    for (final subId in _filters.subcategoryIds) {
      final sub = _subcategories.firstWhere(
        (s) => s.id == subId,
        orElse: () => BusinessCategory(id: subId, name: 'Service'),
      );
      chips.add(
        _filterChip(sub.name, () => _clearOneFilter(subcategoryId: subId)),
      );
    }
    for (final m in _filters.deliveryModes) {
      chips.add(_filterChip(m.label, () => _clearOneFilter(mode: m)));
    }
    if (_filters.age != null) {
      chips.add(_filterChip('Age ${_filters.age}', () => _clearOneFilter(clearAge: true)));
    }
    if (_filters.location == LocationScope.nearMe) {
      chips.add(_filterChip('Near me', () => _clearOneFilter(clearLocation: true)));
    }
    chips.add(
      GestureDetector(
        onTap: _clearAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            'Clear all',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: brand,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );

    return Container(
      width: double.infinity,
      color: const Color(0xFFF7F9F8),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: chips
              .map((c) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: c,
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _filterChip(String text, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E7E3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF555555),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close,
                size: 14, color: Color(0xFF999999)),
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
      return _errorState();
    }
    if (_results.isEmpty) {
      return _emptyState();
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
        itemCount: _results.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final b = _results[i];
          final image = b.category != null
              ? imageForCategory(b.category!)
              : null;
          return BusinessCard(
            business: b,
            imageAsset: image,
            isSaved: _savedIds.contains(b.id),
            onToggleSave: () => _toggleSave(b),
            onTap: () => _showBusinessDetail(b),
          );
        },
      ),
    );
  }

  Widget _errorState() {
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
            TextButton(onPressed: _refresh, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, color: Color(0xFFC5D1C9), size: 56),
            const SizedBox(height: 10),
            Text(
              'No matches',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _filters.count > 0
                  ? 'Try removing a filter or changing your search.'
                  : 'Try a different search term.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF999999),
              ),
            ),
            if (_filters.count > 0) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _clearAll,
                child: Text(
                  'Clear filters',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: brand,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showBusinessDetail(Business b) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, controller) => StatefulBuilder(
          // Lets the heart inside the sheet reflect toggle state without
          // closing/reopening it.
          builder: (_, setSheetState) => BusinessDetailSheet(
            business: b,
            scrollController: controller,
            isSaved: _savedIds.contains(b.id),
            onToggleSave: () async {
              await _toggleSave(b);
              setSheetState(() {});
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  Filter sheet
// ============================================================

class _FilterSheet extends StatefulWidget {
  final SearchFilters initial;
  final List<BusinessCategory> categories;
  final List<BusinessCategory> subcategories;
  final bool hasHomeZip;

  const _FilterSheet({
    required this.initial,
    required this.categories,
    required this.subcategories,
    required this.hasHomeZip,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  static const Color brand = Color(0xFF5D7048);

  late SearchFilters _filters;
  late TextEditingController _ageController;

  @override
  void initState() {
    super.initState();
    _filters = widget.initial;
    _ageController = TextEditingController(
      text: _filters.age?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  void _applyAge() {
    final t = _ageController.text.trim();
    if (t.isEmpty) {
      _filters.age = null;
      return;
    }
    final n = int.tryParse(t);
    if (n == null || n < 0 || n > 99) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Age must be 0–99'),
          backgroundColor: const Color(0xFFB23A48),
        ),
      );
      throw const FormatException('bad age');
    }
    _filters.age = n;
  }

  void _onApply() {
    try {
      _applyAge();
    } on FormatException {
      return;
    }
    Navigator.pop(context, _filters);
  }

  void _onReset() {
    setState(() {
      _filters = SearchFilters();
      _ageController.text = '';
    });
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
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E7E3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  GestureDetector(
                    onTap: _onReset,
                    child: Text(
                      'Reset',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: brand,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ageSection(),
                    const SizedBox(height: 22),
                    _categorySection(),
                    const SizedBox(height: 22),
                    _subcategorySection(),
                    const SizedBox(height: 22),
                    _deliverySection(),
                    const SizedBox(height: 22),
                    _locationSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                height: 46,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Apply',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF333333),
        ),
      );

  Widget _ageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Child's age"),
        const SizedBox(height: 8),
        Text(
          'Programs that serve this age (open-ended ranges included).',
          style: GoogleFonts.nunito(
            fontSize: 12,
            color: const Color(0xFF999999),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 100,
          child: TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'e.g. 7',
              hintStyle: GoogleFonts.nunito(
                fontSize: 14,
                color: const Color(0xFFAAAAAA),
              ),
              filled: true,
              fillColor: const Color(0xFFF7F9F8),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
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
                borderSide: const BorderSide(
                  color: Color(0xFF6F9A84),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _categorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Activity type'),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final c = widget.categories[i];
              final selected = _filters.categoryId == c.id;
              return GestureDetector(
                onTap: () => setState(() {
                  _filters.categoryId = selected ? null : c.id;
                }),
                child: SizedBox(
                  width: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              imageForCategory(c),
                              width: 100,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (selected)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: brand.withAlpha(80),
                                  border: Border.all(color: brand, width: 2),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: selected ? brand : const Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _subcategorySection() {
    if (widget.subcategories.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Services'),
        const SizedBox(height: 4),
        Text(
          'Tap any that should be offered.',
          style: GoogleFonts.nunito(
            fontSize: 12,
            color: const Color(0xFF999999),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.subcategories.map((s) {
            final selected = _filters.subcategoryIds.contains(s.id);
            return GestureDetector(
              onTap: () => setState(() {
                if (selected) {
                  _filters.subcategoryIds.remove(s.id);
                } else {
                  _filters.subcategoryIds.add(s.id);
                }
              }),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? brand : const Color(0xFF6F9A84).withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  s.name,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : brand,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _deliverySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('How is it offered?'),
        const SizedBox(height: 10),
        Row(
          children: DeliveryMode.values.map((mode) {
            final selected = _filters.deliveryModes.contains(mode);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: mode == DeliveryMode.hybrid ? 0 : 8,
                ),
                child: GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _filters.deliveryModes.remove(mode);
                    } else {
                      _filters.deliveryModes.add(mode);
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: selected ? brand : const Color(0xFFF7F9F8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? brand : const Color(0xFFE0E7E3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        mode.label,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF555555),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _locationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Location'),
        const SizedBox(height: 8),
        if (!widget.hasHomeZip)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              "Set your home zip to enable 'Near me'.",
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: const Color(0xFF999999),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Row(
          children: LocationScope.values.map((s) {
            final selected = _filters.location == s;
            final disabled = s == LocationScope.nearMe && !widget.hasHomeZip;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: s == LocationScope.values.last ? 0 : 8,
                ),
                child: GestureDetector(
                  onTap: disabled
                      ? null
                      : () => setState(() => _filters.location = s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: selected ? brand : const Color(0xFFF7F9F8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? brand : const Color(0xFFE0E7E3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        s.label,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: disabled
                              ? const Color(0xFFAAAAAA)
                              : selected
                                  ? Colors.white
                                  : const Color(0xFF555555),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
