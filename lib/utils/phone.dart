/// Format a US phone number for display as (XXX) XXX-XXXX.
///
/// Accepts E.164 (+15035550127), 11 digits starting with 1, or 10 digits.
/// For legacy / non-conforming values, returns the raw input so older rows
/// still render something readable.
String formatPhone(String? raw) {
  if (raw == null) return '';
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';

  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  String? ten;
  if (digits.length == 11 && digits.startsWith('1')) {
    ten = digits.substring(1);
  } else if (digits.length == 10) {
    ten = digits;
  }
  if (ten == null) return trimmed;
  return '(${ten.substring(0, 3)}) ${ten.substring(3, 6)}-${ten.substring(6)}';
}
