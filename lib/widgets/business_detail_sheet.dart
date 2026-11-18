import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/conversation_screen.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/business_service.dart';
import '../services/chat_service.dart';
import '../services/event_service.dart';
import '../services/review_service.dart';
import '../utils/age.dart';
import '../utils/category_image.dart';
import '../utils/datetime_format.dart';
import '../utils/phone.dart';
import 'review_widgets.dart';

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
          // Keyed so the section (and its one-time view count) survives
          // the parent rebuilding this sheet, e.g. when the heart toggles.
          _EngagementSection(key: ValueKey('engagement-${b.id}'), business: b),
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


// ============================================================
//  Upcoming events + reviews (loaded when the sheet opens)
// ============================================================

class _EngagementSection extends StatefulWidget {
  final Business business;
  const _EngagementSection({super.key, required this.business});

  @override
  State<_EngagementSection> createState() => _EngagementSectionState();
}

class _EngagementSectionState extends State<_EngagementSection> {
  static const Color _brand = Color(0xFF5D7048);

  final _reviewService = ReviewService();

  List<BusinessEvent> _events = const [];
  List<Review>? _reviews; // null while loading
  bool _savingReview = false;

  String get _businessId => widget.business.id;

  /// Only parents review, and never their own listing.
  bool get _canReview {
    final profile = Session.current?.profile;
    return profile != null &&
        profile.role == 'parent' &&
        profile.id != widget.business.ownerId;
  }

  Review? get _myReview {
    for (final r in _reviews ?? const <Review>[]) {
      if (r.isMine) return r;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    // Opening the sheet counts as a listing view (deduped server-side).
    BusinessService().recordView(_businessId);
    _loadEvents();
    _loadReviews();
  }

  Future<void> _loadEvents() async {
    try {
      final events =
          await EventService().listUpcomingForBusiness(_businessId, limit: 3);
      if (!mounted) return;
      setState(() => _events = events);
    } on ApiException {
      // Optional section: stay hidden on failure.
    }
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await _reviewService.listForBusiness(_businessId);
      if (!mounted) return;
      setState(() => _reviews = reviews);
    } on ApiException {
      if (!mounted) return;
      setState(() => _reviews ??= const []);
    }
  }

  Future<void> _writeReview() async {
    final result = await showReviewDialog(context, existing: _myReview);
    if (result == null || !mounted) return;
    setState(() => _savingReview = true);
    try {
      await _reviewService.saveMine(
        _businessId,
        rating: result.rating,
        comment: result.comment.isEmpty ? null : result.comment,
      );
      await _loadReviews();
    } on ApiException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _savingReview = false);
    }
  }

  Future<void> _deleteReview() async {
    setState(() => _savingReview = true);
    try {
      await _reviewService.deleteMine(_businessId);
      await _loadReviews();
    } on ApiException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _savingReview = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFFB23A48)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reviews = _reviews;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_events.isNotEmpty) ...[
          const SizedBox(height: 24),
          _heading('Upcoming'),
          const SizedBox(height: 8),
          ..._events.map(_eventRow),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _heading('Reviews')),
            if (reviews != null)
              RatingBadge(
                average: averageRating(reviews),
                count: reviews.length,
                fontSize: 13,
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (reviews == null)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else ...[
          if (reviews.isEmpty)
            Text(
              _canReview
                  ? 'No reviews yet. Be the first to share your experience.'
                  : 'No reviews yet.',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFAAAAAA),
              ),
            ),
          ...reviews.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ReviewTile(review: r),
            ),
          ),
          if (_canReview) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _savingReview ? null : _writeReview,
                  icon: const Icon(Icons.rate_review_outlined, size: 16),
                  label: Text(
                    _myReview == null ? 'Write a review' : 'Edit your review',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _brand,
                    side: const BorderSide(color: Color(0xFFC5D1C9)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                if (_myReview != null)
                  TextButton(
                    onPressed: _savingReview ? null : _deleteReview,
                    child: Text(
                      'Remove',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB23A48),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ],
    );
  }

  Widget _heading(String text) => Text(
        text,
        style: GoogleFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF333333),
        ),
      );

  Widget _eventRow(BusinessEvent e) {
    final details = [
      '${formatShortDate(e.startsAt)} · ${formatTimeRange(e.startsAt, e.endsAt)}',
      if (e.capacity != null) '${e.capacity} spot${e.capacity == 1 ? '' : 's'}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: _brand,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  monthAbbr(e.startsAt),
                  style: GoogleFonts.nunito(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
                Text(
                  '${e.startsAt.day}',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.title,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF333333),
                  ),
                ),
                Text(
                  details,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF999999),
                  ),
                ),
                if ((e.description ?? '').isNotEmpty)
                  Text(
                    e.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF777777),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
