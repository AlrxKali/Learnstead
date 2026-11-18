import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/review_service.dart';
import '../utils/datetime_format.dart';

const _star = Color(0xFFE0A030);

/// Five stars, [rating] of them filled. Tappable when [onChanged] is set.
class StarRow extends StatelessWidget {
  final int rating;
  final double size;
  final ValueChanged<int>? onChanged;

  const StarRow({
    super.key,
    required this.rating,
    this.size = 16,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final icon = Icon(
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: i < rating ? _star : const Color(0xFFC5D1C9),
        );
        if (onChanged == null) return icon;
        return InkResponse(
          onTap: () => onChanged!(i + 1),
          radius: size,
          child: Padding(padding: const EdgeInsets.all(4), child: icon),
        );
      }),
    );
  }
}

/// "★ 4.8 (12)" — renders nothing when there are no reviews.
class RatingBadge extends StatelessWidget {
  final double? average;
  final int count;
  final double fontSize;

  const RatingBadge({
    super.key,
    required this.average,
    required this.count,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (average == null || count == 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: fontSize + 3, color: _star),
        const SizedBox(width: 2),
        Text(
          '${average!.toStringAsFixed(1)} ($count)',
          style: GoogleFonts.nunito(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF555555),
          ),
        ),
      ],
    );
  }
}

class ReviewTile extends StatelessWidget {
  final Review review;
  const ReviewTile({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final hasComment = (review.comment ?? '').isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E7E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.isMine ? '${review.displayName} (you)' : review.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF333333),
                  ),
                ),
              ),
              Text(
                formatShortDate(review.createdAt),
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF999999),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          StarRow(rating: review.rating, size: 15),
          if (hasComment) ...[
            const SizedBox(height: 6),
            Text(
              review.comment!,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF555555),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Average of the loaded reviews, or null when empty.
double? averageRating(List<Review> reviews) {
  if (reviews.isEmpty) return null;
  final total = reviews.fold<int>(0, (sum, r) => sum + r.rating);
  return total / reviews.length;
}

/// Dialog for writing or editing a review. Pops with the chosen
/// (rating, comment) or null when dismissed.
Future<({int rating, String comment})?> showReviewDialog(
  BuildContext context, {
  Review? existing,
}) {
  return showDialog<({int rating, String comment})>(
    context: context,
    builder: (_) => _ReviewDialog(existing: existing),
  );
}

class _ReviewDialog extends StatefulWidget {
  final Review? existing;
  const _ReviewDialog({this.existing});

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  late int _rating = widget.existing?.rating ?? 0;
  late final _comment =
      TextEditingController(text: widget.existing?.comment ?? '');

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        widget.existing == null ? 'Write a review' : 'Edit your review',
        style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StarRow(
              rating: _rating,
              size: 32,
              onChanged: (v) => setState(() => _rating = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _comment,
              maxLines: 4,
              maxLength: 2000,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.nunito(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Share your experience (optional)',
                hintStyle: GoogleFonts.nunito(
                    fontSize: 14, color: const Color(0xFFAAAAAA)),
                filled: true,
                fillColor: const Color(0xFFF7F9F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE0E7E3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE0E7E3)),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700, color: const Color(0xFF777777))),
        ),
        TextButton(
          onPressed: _rating == 0
              ? null
              : () => Navigator.pop(
                    context,
                    (rating: _rating, comment: _comment.text.trim()),
                  ),
          child: Text('Save',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}
