import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProviderProfileTab extends StatefulWidget {
  const ProviderProfileTab({super.key});

  @override
  State<ProviderProfileTab> createState() => _ProviderProfileTabState();
}

class _ProviderProfileTabState extends State<ProviderProfileTab> {
  bool _isEditing = false;

  // Mock data controllers
  final _aboutController = TextEditingController(
    text:
        "Sarah's Learning Studio offers creative, hands-on learning experiences "
        'for children ages 4–12. We specialize in nature-based education, STEM '
        'exploration, and creative arts in a nurturing, small-group environment. '
        'Every child learns differently — we celebrate that.',
  );

  final _services = [
    'Creative Arts',
    'STEM',
    'Nature-Based Learning',
    'Small Group Sessions',
    'After-School Programs',
    'Weekend Workshops',
  ];

  @override
  void dispose() {
    _aboutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCoverAndLogo(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 50),
                _buildNameAndEditButton(),
                const SizedBox(height: 16),
                _buildListingStatus(),
                const SizedBox(height: 24),
                _buildAboutSection(),
                const SizedBox(height: 24),
                _buildServicesSection(),
                const SizedBox(height: 24),
                _buildDetailsSection(),
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

  Widget _buildCoverAndLogo() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover image
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
        // Business logo
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
                'S',
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

  Widget _buildNameAndEditButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Sarah's Learning Studio",
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Enrichment Program',
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
          onTap: () => setState(() => _isEditing = !_isEditing),
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
            _aboutController.text,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF555555),
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

  Widget _buildDetailsSection() {
    final details = [
      _DetailRow(Icons.child_care_outlined, 'Ages', '4 – 12 years'),
      _DetailRow(Icons.location_on_outlined, 'Address',
          '1234 Oak Lane, Portland, OR 97201'),
      _DetailRow(
          Icons.access_time_outlined, 'Hours', 'Mon–Fri 9:00 AM – 4:00 PM'),
      _DetailRow(Icons.phone_outlined, 'Phone', '(503) 555-0127'),
      _DetailRow(Icons.email_outlined, 'Email', 'hello@sarahslearning.com'),
      _DetailRow(
          Icons.language_outlined, 'Website', 'www.sarahslearning.com'),
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
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: Color(0xFFFFCC00)),
                const SizedBox(width: 4),
                Text(
                  '4.9',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF333333),
                  ),
                ),
                Text(
                  ' (24 reviews)',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCC6B2E).withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'A',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFCC6B2E),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amanda Rivera',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF333333),
                          ),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (i) => const Icon(
                              Icons.star,
                              size: 14,
                              color: Color(0xFFFFCC00),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '2 weeks ago',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF999999),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'My daughter absolutely loves the creative arts sessions! Sarah '
                'creates such a warm, encouraging environment. Highly recommend '
                'for any family looking for quality enrichment programs.',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF555555),
                  height: 1.5,
                ),
              ),
            ],
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
