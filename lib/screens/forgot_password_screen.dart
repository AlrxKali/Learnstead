import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../widgets/form_styles.dart';

/// Two-step password reset: request a code by email, then enter the code
/// with a new password. Pops with `true` once the password was changed.
class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _authService = AuthService();
  late final _emailController =
      TextEditingController(text: widget.initialEmail);
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _codeSent = false;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      showErrorSnack(context, 'Please enter your email address.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _authService.requestPasswordReset(email);
      if (!mounted) return;
      setState(() => _codeSent = true);
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    if (code.isEmpty) {
      showErrorSnack(context, 'Enter the code from the email.');
      return;
    }
    if (password.length < 6) {
      showErrorSnack(context, 'Password must be at least 6 characters.');
      return;
    }
    if (password != _confirmController.text) {
      showErrorSnack(context, 'Passwords do not match.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _authService.resetPassword(
        email: _emailController.text.trim(),
        code: code,
        newPassword: password,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF333333),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _codeSent ? 'Check your email' : 'Reset your password',
                style: GoogleFonts.nunito(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _codeSent
                    ? 'If ${_emailController.text.trim()} has an account, we sent it a reset code. Enter it below with your new password.'
                    : "Enter the email you signed up with and we'll send you a reset code.",
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: const Color(0xFF999999),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              if (!_codeSent) ..._buildEmailStep() else ..._buildResetStep(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEmailStep() => [
        fieldLabel('Email'),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          onSubmitted: (_) => _sendCode(),
          style: GoogleFonts.nunito(fontSize: 15),
          decoration: fieldDecoration(
            hint: 'you@example.com',
            prefixIcon: Icons.email_outlined,
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(label: 'Send reset code', busy: _busy, onPressed: _sendCode),
      ];

  List<Widget> _buildResetStep() => [
        fieldLabel('Reset code'),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          style: GoogleFonts.nunito(fontSize: 15, letterSpacing: 2),
          decoration: fieldDecoration(
            hint: '6-digit code',
            prefixIcon: Icons.pin_outlined,
          ),
        ),
        const SizedBox(height: 16),
        fieldLabel('New password'),
        TextField(
          controller: _passwordController,
          obscureText: _obscure,
          style: GoogleFonts.nunito(fontSize: 15),
          decoration: fieldDecoration(
            hint: 'At least 6 characters',
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFFC5D1C9),
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        fieldLabel('Confirm new password'),
        TextField(
          controller: _confirmController,
          obscureText: _obscure,
          onSubmitted: (_) => _reset(),
          style: GoogleFonts.nunito(fontSize: 15),
          decoration: fieldDecoration(
            hint: 'Re-enter your new password',
            prefixIcon: Icons.lock_outline,
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(label: 'Update password', busy: _busy, onPressed: _reset),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy ? null : _sendCode,
          child: Text(
            "Didn't get it? Send again",
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              color: brandGreenLight,
            ),
          ),
        ),
      ];
}
