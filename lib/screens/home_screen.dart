import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/business_service.dart';
import '../utils/age.dart';
import '../utils/phone.dart';
import 'planner_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color activeColor = Color(0xFF5D7048);
  static const Color inactiveColor = Color(0xFFC5D1C9);

  int _selectedIndex = 0;

  final _authService = AuthService();
  final _businessService = BusinessService();
  final _searchController = TextEditingController();
  final _zipController = TextEditingController();

  List<BusinessCategory> _categories = [];
  List<Business> _results = [];
  String? _selectedCategoryId;
  bool _isLoading = true;
  bool _isSavingZip = false;
  String? _loadError;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _zipController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _businessService.listCategories();
      if (!mounted) return;
      setState(() => _categories = cats);
    } on ApiException {
      // Non-fatal — the chip row just stays empty.
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final results = await _businessService.discover(
        q: _searchController.text,
        categoryId: _selectedCategoryId,
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
        _loadError = e.message;
      });
    }
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _refresh);
  }

  Future<void> _saveZipCode() async {
    final raw = _zipController.text.trim();
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 5 && digits.length != 9) {
      _showError('Please enter a 5-digit US zip code.');
      return;
    }
    setState(() => _isSavingZip = true);
    try {
      await _authService.updateMyProfile(homeZipCode: raw);
      if (!mounted) return;
      setState(() => _isSavingZip = false);
      _refresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSavingZip = false);
      _showError(e.message);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFB23A48),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _selectedIndex == 0
            ? _buildDiscoverTab()
            : _selectedIndex == 3
                ? const PlannerTab()
                : _buildComingSoonTab(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: activeColor,
        unselectedItemColor: inactiveColor,
        selectedLabelStyle: const TextStyle(fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Saved'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Planner'),
        ],
      ),
    );
  }

  Widget _buildComingSoonTab() {
    return Center(
      child: Text(
        'Coming soon',
        style: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF999999),
        ),
      ),
    );
  }

  Widget _buildDiscoverTab() {
    final hasZip = (Session.current?.profile.homeZipCode ?? '').isNotEmpty;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _buildHero(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!hasZip) ...[
                  _buildZipPrompt(),
                  const SizedBox(height: 16),
                ],
                if (_categories.isNotEmpty) ...[
                  _buildCategoryChips(),
                  const SizedBox(height: 16),
                ],
                _buildResults(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Image.asset(
          'static/home.png',
          width: double.infinity,
          fit: BoxFit.contain,
        ),
        Positioned(
          bottom: 16,
          left: 30,
          right: 30,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: const Color(0xFF333333),
              ),
              decoration: InputDecoration(
                hintText: 'Search by name or keyword…',
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
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZipPrompt() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCC8A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.place_outlined,
                  color: Color(0xFFCC6B2E), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Set your zip code to see local programs',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF7A4A1E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "We'll use it to surface in-person and hybrid providers near you. Online programs always show up.",
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: const Color(0xFF7A4A1E),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _zipController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.nunito(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. 97201',
                    hintStyle: GoogleFonts.nunito(
                        fontSize: 14, color: const Color(0xFFAAAAAA)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFFFCC8A)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFFFCC8A)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSavingZip ? null : _saveZipCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCC6B2E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSavingZip
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Save',
                        style: GoogleFonts.nunito(
                            fontSize: 13, fontWeight: FontWeight.w700),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Explicit category → image mappings. Anything not listed here gets a
  // deterministic random image from _fallbackImages so the same category
  // always shows the same picture across renders.
  static const Map<String, String> _categoryImageMap = {
    'Enrichment Program': 'static/activity cards/Art and Music.png',
    'Co-op': 'static/activity cards/Co-ops.png',
    'Tutoring': 'static/activity cards/Therapies.png',
  };

  static const List<String> _fallbackImages = [
    'static/activity cards/Art and Music.png',
    'static/activity cards/Co-ops.png',
    'static/activity cards/Therapies.png',
  ];

  String _imageFor(BusinessCategory c) {
    final explicit = _categoryImageMap[c.name];
    if (explicit != null) return explicit;
    final idx = c.name.hashCode.abs() % _fallbackImages.length;
    return _fallbackImages[idx];
  }

  Widget _buildCategoryChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Browse by activity',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF333333),
              ),
            ),
            if (_selectedCategoryId != null)
              GestureDetector(
                onTap: () {
                  setState(() => _selectedCategoryId = null);
                  _refresh();
                },
                child: Row(
                  children: [
                    const Icon(Icons.close, size: 14, color: activeColor),
                    const SizedBox(width: 4),
                    Text(
                      'Clear',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: activeColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _categoryCard(_categories[i]),
          ),
        ),
      ],
    );
  }

  Widget _categoryCard(BusinessCategory c) {
    final selected = _selectedCategoryId == c.id;
    final image = _imageFor(c);
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryId = selected ? null : c.id;
        });
        _refresh();
      },
      child: SizedBox(
        width: 110,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    image,
                    width: 110,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                ),
                if (selected)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: activeColor.withAlpha(80),
                        border: Border.all(color: activeColor, width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              c.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? activeColor : const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const Icon(Icons.error_outline,
                color: Color(0xFFB23A48), size: 48),
            const SizedBox(height: 10),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _refresh,
              child: Text(
                'Retry',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: activeColor,
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (_results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.search_off,
                  color: Color(0xFFC5D1C9), size: 48),
              const SizedBox(height: 10),
              Text(
                'No matches yet',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF555555),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Try a different search or category.',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF999999),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: _results
          .map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildBusinessCard(b),
              ))
          .toList(),
    );
  }

  Widget _buildBusinessCard(Business business) {
    final initial =
        business.name.isNotEmpty ? business.name[0].toUpperCase() : '?';
    final category = business.category?.name;
    final ages = formatAgeRange(business.minAge, business.maxAge);
    final location = business.deliveryMode == DeliveryMode.online
        ? null
        : [
            if (business.city != null && business.city!.isNotEmpty)
              business.city!,
            if (business.state != null && business.state!.isNotEmpty)
              business.state!,
          ].join(', ');

    return GestureDetector(
      onTap: () => _showBusinessDetail(business),
      child: Container(
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF6F9A84).withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: activeColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    business.name,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (category != null) _metaPill(category, true),
                      _metaPill(business.deliveryMode.label, false),
                      if (ages != null) _metaPill(ages, false),
                    ],
                  ),
                  if (location != null && location.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined,
                            size: 13, color: Color(0xFF999999)),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: const Color(0xFF999999),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (business.description != null &&
                      business.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      business.description!,
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
          ],
        ),
      ),
    );
  }

  Widget _metaPill(String text, bool primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: primary
            ? const Color(0xFF6F9A84).withAlpha(30)
            : const Color(0xFFF0F2F0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: primary ? activeColor : const Color(0xFF777777),
        ),
      ),
    );
  }

  void _showBusinessDetail(Business b) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (ctx, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
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
              Text(
                b.name,
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (b.category != null) _metaPill(b.category!.name, true),
                  _metaPill(b.deliveryMode.label, false),
                  if (formatAgeRange(b.minAge, b.maxAge) != null)
                    _metaPill(formatAgeRange(b.minAge, b.maxAge)!, false),
                ],
              ),
              if (b.description != null && b.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  b.description!,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: const Color(0xFF555555),
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (b.subcategories.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Services',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: b.subcategories
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6F9A84).withAlpha(20),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              s.name,
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: activeColor,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),
              _detailRow(Icons.phone_outlined, formatPhone(b.phone)),
              _detailRow(Icons.email_outlined, b.email),
              _detailRow(Icons.language_outlined, b.website),
              if (b.deliveryMode != DeliveryMode.online)
                _detailRow(Icons.place_outlined, b.formattedAddress),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6F9A84)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: const Color(0xFF333333),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
