/// Render an age range as a human-readable string.
///
/// Examples:
///   (4, 12)     -> "Ages 4 – 12"
///   (4, null)   -> "Ages 4+"
///   (null, 12)  -> "Up to age 12"
///   (null, null)-> null  (caller should hide the row)
String? formatAgeRange(int? minAge, int? maxAge) {
  if (minAge == null && maxAge == null) return null;
  if (minAge != null && maxAge != null) return 'Ages $minAge – $maxAge';
  if (minAge != null) return 'Ages $minAge+';
  return 'Up to age $maxAge';
}
