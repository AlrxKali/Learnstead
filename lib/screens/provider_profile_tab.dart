import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_client.dart';
import '../services/business_service.dart';
import 'create_business_screen.dart';

class ProviderProfileTab extends StatefulWidget {
  const ProviderProfileTab({super.key});

  @override
  State<ProviderProfileTab> createState() => _ProviderProfileTabState();
}

class _ProviderProfileTabState extends State<ProviderProfileTab> {
  final _businessService = BusinessService();
  final _aboutController = TextEditingController();

  Business? _business;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  bool _notFound = false;
  String? _loadError;

  // Placeholder data — needs its own backend tables to wire up.
  final _services = [
    'Creative Arts',
    'STEM',
    'Nature-Based Learning',
    'Small Group Sessions',
    'After-School Programs',
    'Weekend Workshops',
  ];

  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }

  Future<void> _loadBusiness() async {
    setState(() {
      _isLoading = true;
      _notFound = false;
      _loadError = null;
    });
    try {
      final business = await _businessService.getMyBusiness();
      if (!mounted) return;
      setState(() {
        _business = business;
        _aboutController.text = business.description ?? '';
        _isLoading = false;
      });
    } on BusinessNotFoundException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _notFound = true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.message;
      });
    }
  }

  Future<void> _toggleEditOrSave() async {
    if (!_isEditing) {
      setState(() => _isEditing = true);
      return;
    }

    final newDescription = _aboutController.text.trim();
    if (newDescription == (_business?.description ?? '')) {
      setState(() => _isEditing = false);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updated = await _businessService.updateMyBusiness(
        description: newDescription,
      );
      if (!mounted) return;
      setState(() {
        _business = updated;
        _aboutController.text = updated.description ?? '';
        _isEditing = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save: ${e.message}'),
          backgroundColor: const Color(0xFFB23A48),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _aboutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_notFound) {
      return _buildNoBusinessState();
    }
    if (_loadError != null) {
      return _buildErrorState(_loadError!);
    }

    final business = _business!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCoverAndLogo(business),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 50),
                _buildNameAndEditButton(business),
                const SizedBox(height: 16),
                _buildListingStatus(),
                const SizedBox(height: 24),
                _buildAboutSection(),
                const SizedBox(height: 24),
                _buildServicesSection(),
                const SizedBox(height: 24),
                _buildDetailsSection(business),
                const SizedBox(height: 24),
                _buildReviewsSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoBusinessState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.storefront_outlined,
              size: 64,
              color: Color(0xFFC5D1C9),
            ),
            const SizedBox(height: 16),
            Text(
              'No business yet',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Set up your business profile so families can find you.",
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: const Color(0xFF999999),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateBusinessScreen(),
                  ),
                );
                if (!mounted) return;
                _loadBusiness();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D7048),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Set up business',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Color(0xFFB23A48)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: const Color(0xFF555555),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadBusiness,
              child: Text(
                'Retry',
                style: GoogleFonts.nunito(
                  fontSize: 14,
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

  Widget _buildCoverAndLogo(Business business) {
    final initial = business.name.isNotEmpty ? business.name[0].toUpperCase() : '?';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          child: Image.asset(
            'static/landscapes/lake.png',
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          bottom: -36,
          left: 20,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF6F9A84).withAlpha(40),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: GoogleFonts.nunito(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF5D7048),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameAndEditButton(Business business) {
    final categoryName = business.category?.name ?? 'Uncategorized';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                business.name,
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                categoryName,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF999999),
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _isSaving ? null : _toggleEditOrSave,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _isEditing
                  ? const Color(0xFF5D7048)
                  : const Color(0xFFF7F9F8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isEditing
                    ? const Color(0xFF5D7048)
                    : const Color(0xFFE0E7E3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isSaving)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(
                    _isEditing ? Icons.check : Icons.edit_outlined,
                    size: 16,
                    color: _isEditing
                        ? Colors.white
                        : const Color(0xFF555555),
                  ),
                const SizedBox(width: 6),
                Text(
                  _isEditing ? 'Save' : 'Edit',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _isEditing
                        ? Colors.white
                        : const Color(0xFF555555),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListingStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF5D7048).withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: Color(0xFF5D7048)),
          const SizedBox(width: 8),
          Text(
            'Your listing is live',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF5D7048),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    final hasDescription = (_business?.description ?? '').trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        if (_isEditing)
          TextField(
            controller: _aboutController,
            maxLines: 5,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: const Color(0xFF333333),
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: 'Tell families about your business…',
              hintStyle: GoogleFonts.nunito(
                fontSize: 14,
                color: const Color(0xFFAAAAAA),
              ),
              filled: true,
              fillColor: const Color(0xFFF7F9F8),
              contentPadding: const EdgeInsets.all(14),
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
            ),
          )
        else
          Text(
            hasDescription
                ? _business!.description!
                : 'No description yet. Tap Edit to add one.',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: hasDescription
                  ? const Color(0xFF555555)
                  : const Color(0xFFAAAAAA),
              height: 1.5,
            ),
          ),
      ],
    );
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Services',
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _services.map((service) {
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6F9A84).withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                service,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5D7048),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(Business business) {
    final details = <_DetailRow>[
      if (business.formattedAddress != null)
        _DetailRow(
          Icons.location_on_outlined,
          'Address',
          business.formattedAddress!,
        ),
      if (business.phone != null && business.phone!.isNotEmpty)
        _DetailRow(Icons.phone_outlined, 'Phone', business.phone!),
      if (business.email != null && business.email!.isNotEmpty)
        _DetailRow(Icons.email_outlined, 'Email', business.email!),
      if (business.website != null && business.website!.isNotEmpty)
        _DetailRow(Icons.language_outlined, 'Website', business.website!),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details',
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 10),
        if (details.isEmpty)
          Text(
            'No contact details yet.',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFAAAAAA),
            ),
          )
        else
          ...details.map((detail) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(detail.icon, size: 18, color: const Color(0xFF6F9A84)),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 60,
                    child: Text(
                      detail.label,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF999999),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      detail.value,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF333333),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reviews',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF333333),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E7E3)),
          ),
          child: Text(
            'No reviews yet.',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFAAAAAA),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(this.icon, this.label, this.value);
}
