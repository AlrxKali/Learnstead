import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/business_service.dart';
import '../utils/age.dart';

/// Compact business card used in Discover and Search result lists.
///
/// [imageAsset] is the static image to show as a thumbnail. Pass null to
/// fall back to the initial-letter avatar tile.
class BusinessCard extends StatelessWidget {
  static const Color _brand = Color(0xFF5D7048);
  static const Color _brandLight = Color(0xFF6F9A84);

  final Business business;
  final String? imageAsset;
  final VoidCallback onTap;

  /// If non-null, a heart icon is shown in the top-right and tapping it
  /// invokes [onToggleSave]. [isSaved] controls the fill.
  final bool? isSaved;
  final VoidCallback? onToggleSave;

  const BusinessCard({
    super.key,
    required this.business,
    required this.onTap,
    this.imageAsset,
    this.isSaved,
    this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
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
            _thumbnail(initial),
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
                  const SizedBox(height: 4),
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
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: const Color(0xFF999999),
                              fontWeight: FontWeight.w600,
                            ),
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
            if (onToggleSave != null) _heartButton(),
          ],
        ),
      ),
    );
  }

  Widget _heartButton() {
    final filled = isSaved ?? false;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: InkResponse(
        onTap: onToggleSave,
        radius: 22,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            filled ? Icons.favorite : Icons.favorite_border,
            color: filled ? const Color(0xFFCC6B2E) : const Color(0xFFC5D1C9),
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _thumbnail(String initial) {
    if (imageAsset != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          imageAsset!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: _brandLight.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.nunito(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _brand,
          ),
        ),
      ),
    );
  }

  Widget _metaPill(String text, bool primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: primary
            ? _brandLight.withAlpha(30)
            : const Color(0xFFF0F2F0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: primary ? _brand : const Color(0xFF777777),
        ),
      ),
    );
  }
}
