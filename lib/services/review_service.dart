import 'api_client.dart';
import 'auth_service.dart';

class Review {
  final String id;
  final String businessId;
  final String parentId;
  final String? reviewerName;
  final int rating;
  final String? comment;
  final bool isMine;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.businessId,
    required this.parentId,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.isMine,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as String,
        businessId: json['business_id'] as String,
        parentId: json['parent_id'] as String,
        reviewerName: json['reviewer_name'] as String?,
        rating: (json['rating'] as num).toInt(),
        comment: json['comment'] as String?,
        isMine: json['is_mine'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );

  String get displayName {
    final n = reviewerName?.trim() ?? '';
    return n.isEmpty ? 'Learnstead parent' : n;
  }
}

class ReviewService {
  final ApiClient _client = ApiClient();

  String _requireToken() {
    final t = Session.accessToken;
    if (t == null) throw ApiException('You are not signed in.');
    return t;
  }

  Future<List<Review>> listForBusiness(String businessId) async {
    final r = await _client.getJson(
      '/businesses/$businessId/reviews',
      token: _requireToken(),
    );
    return (r as List<dynamic>)
        .map((e) => Review.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Create or replace the signed-in parent's review.
  Future<Review> saveMine(
    String businessId, {
    required int rating,
    String? comment,
  }) async {
    final r = await _client.putJson(
      '/businesses/$businessId/reviews/mine',
      {'rating': rating, 'comment': comment},
      token: _requireToken(),
    );
    return Review.fromJson(r as Map<String, dynamic>);
  }

  Future<void> deleteMine(String businessId) async {
    await _client.deleteJson(
      '/businesses/$businessId/reviews/mine',
      token: _requireToken(),
    );
  }
}
