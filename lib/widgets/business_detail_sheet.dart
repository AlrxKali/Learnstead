import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/conversation_screen.dart';
import '../services/business_service.dart';
import '../services/chat_service.dart';
import '../utils/age.dart';
import '../utils/category_image.dart';
import '../utils/phone.dart';

/// Full-detail bottom sheet for a business. Used from Discover, Search,
/// and Saved lists.
///
/// Open with:
///   showModalBottomSheet(
///     isScrollControlled: true,
///     backgroundColor: Colors.transparent,
///     builder: (_) => DraggableScrollableSheet(
///       initialChildSize: 0.7,
///       minChildSize: 0.4,
///       maxChildSize: 0.92,
///       builder: (_, controller) => BusinessDetailSheet(
///         business: b, scrollController: controller,
///         isSaved: saved, onToggleSave: () => ...,
///       ),
///     ),
///   );
class BusinessDetailSheet extends StatelessWidget {
  static const Color _brand = Color(0xFF5D7048);

  final Business business;
  final ScrollController scrollController;
  final bool? isSaved;
  final VoidCallback? onToggleSave;

  const BusinessDetailSheet({
    super.key,
    required this.business,
    required this.scrollController,
    this.isSaved,
    this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    final b = business;
    final hasHeart = onToggleSave != null;
    final filled = isSaved ?? false;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView(
        controller: scrollController,
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
          if (b.category != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imageForCategory(b.category!),
                    width: double.infinity,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),
                if (hasHeart)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: onToggleSave,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(220),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          filled ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: filled
                              ? const Color(0xFFCC6B2E)
                              : const Color(0xFF555555),
                        ),
                      ),
                    ),
                  ),
              ],
            )
          else if (hasHeart)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: onToggleSave,
                icon: Icon(
                  filled ? Icons.favorite : Icons.favorite_border,
                  color: filled
                      ? const Color(0xFFCC6B2E)
                      : const Color(0xFF555555),
                ),
              ),
            ),
          const SizedBox(height: 14),
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
              if (b.category != null) _pill(b.category!.name, primary: true),
              _pill(b.deliveryMode.label),
              if (formatAgeRange(b.minAge, b.maxAge) != null)
                _pill(formatAgeRange(b.minAge, b.maxAge)!),
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
                            color: _brand,
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
          const SizedBox(height: 20),
          _MessageButton(business: b),
        ],
      ),
    );
  }

  Widget _pill(String text, {bool primary = false}) {
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
          color: primary ? _brand : const Color(0xFF777777),
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

// ============================================================
//  Message-the-provider button
// ============================================================

class _MessageButton extends StatefulWidget {
  final Business business;
  const _MessageButton({required this.business});

  @override
  State<_MessageButton> createState() => _MessageButtonState();
}

class _MessageButtonState extends State<_MessageButton> {
  static const Color _brand = Color(0xFF5D7048);

  final _chat = ChatService();
  bool _busy = false;

  bool get _viewerOwnsThis =>
      _chat.currentUserId != null &&
      _chat.currentUserId == widget.business.ownerId;

  Future<void> _open() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final conv = await _chat.getOrCreateForBusiness(widget.business.id);
      if (!mounted) return;
      Navigator.of(context).pop(); // close the detail sheet first
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConversationScreen(conversation: conv),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Couldn't open chat: $e"),
          backgroundColor: const Color(0xFFB23A48),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Providers viewing their own business don't get a "message yourself"
    // button.
    if (_viewerOwnsThis) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: _busy ? null : _open,
        icon: _busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.chat_bubble_outline, size: 18),
        label: Text(
          'Message provider',
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _brand,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
