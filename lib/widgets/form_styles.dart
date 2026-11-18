import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const brandGreen = Color(0xFF5D7048);
const brandGreenLight = Color(0xFF6F9A84);
const errorRed = Color(0xFFB23A48);

/// The filled, rounded text-field style used on the auth screens.
InputDecoration fieldDecoration({
  required String hint,
  IconData? prefixIcon,
  Widget? suffixIcon,
}) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.nunito(fontSize: 15, color: const Color(0xFFAAAAAA)),
    prefixIcon: prefixIcon == null
        ? null
        : Icon(prefixIcon, color: const Color(0xFFC5D1C9), size: 20),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: const Color(0xFFF7F9F8),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: border(const Color(0xFFE0E7E3)),
    enabledBorder: border(const Color(0xFFE0E7E3)),
    focusedBorder: border(brandGreenLight, 1.5),
  );
}

Widget fieldLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF555555),
        ),
      ),
    );

/// Full-width primary action with a built-in busy spinner.
class PrimaryButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback? onPressed;
  final Color color;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.color = brandGreen,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: busy
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: GoogleFonts.nunito(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}

void showErrorSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: errorRed),
  );
}
