import '../services/business_service.dart';

/// Explicit category-name → asset mapping. Anything not listed here gets
/// a deterministic fallback so the same category always shows the same
/// image across renders.
const Map<String, String> _categoryImageMap = {
  'Enrichment Program': 'static/activity cards/Art and Music.png',
  'Co-op': 'static/activity cards/Co-ops.png',
  'Tutoring': 'static/activity cards/Therapies.png',
};

const List<String> _fallbackImages = [
  'static/activity cards/Art and Music.png',
  'static/activity cards/Co-ops.png',
  'static/activity cards/Therapies.png',
];

String imageForCategoryName(String name) {
  final explicit = _categoryImageMap[name];
  if (explicit != null) return explicit;
  return _fallbackImages[name.hashCode.abs() % _fallbackImages.length];
}

String imageForCategory(BusinessCategory c) => imageForCategoryName(c.name);
