import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../widgets/form_styles.dart';
import 'auth_gate.dart';
import 'business_form_screen.dart';
import 'home_screen.dart';

/// Shown after a first sign-in with Google/Apple: the auth user exists but
/// we still need their role (and a zip code for parents).
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _authService = AuthService();
  final _nameController = TextEditingController();
  final _zipController = TextEditingController();
  String? _role;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final meta =
        sb.Supabase.instance.client.auth.currentUser?.userMetadata ?? const {};
    _nameController.text =
        (meta['full_name'] ?? meta['name'] ?? '').toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_role == null) {
      showErrorSnack(context, 'Please choose how you will use Learnstead.');
      return;
    }
    final zip = _zipController.text.trim();
    if (_role == 'parent') {
      final digits = zip.replaceAll(RegExp(r'\D'), '');
      if (digits.length != 5 && digits.length != 9) {
        showErrorSnack(context, 'Please enter a 5-digit US zip code.');
        return;
      }
    }
    setState(() => _busy = true);
    try {
      final profile = await _authService.completeProfile(
        role: _role!,
        fullName: _nameController.text.trim(),
        homeZipCode: _role == 'parent' ? zip : null,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => profile.role == 'provider'
              ? const BusinessFormScreen()
              : const HomeScreen(),
        ),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 409) {
        // Profile already exists (e.g. double submit): just route normally.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (_) => false,
        );
        return;
      }
      showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                'One more step',
                style: GoogleFonts.nunito(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tell us a little about you to finish setting up your account.',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: const Color(0xFF999999),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              fieldLabel('I am a…'),
              Row(
                children: [
                  Expanded(
                    child: _roleCard(
                      'parent',
                      Icons.family_restroom_outlined,
                      'Parent',
                      'Finding programs',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _roleCard(
                      'provider',
                      Icons.storefront_outlined,
                      'Provider',
                      'Offering programs',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              fieldLabel('Full name'),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.nunito(fontSize: 15),
                decoration: fieldDecoration(
                  hint: 'Your name',
                  prefixIcon: Icons.person_outline,
                ),
              ),
              if (_role == 'parent') ...[
                const SizedBox(height: 16),
                fieldLabel('Home zip code'),
                TextField(
                  controller: _zipController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.nunito(fontSize: 15),
                  decoration: fieldDecoration(
                    hint: 'e.g. 97201',
                    prefixIcon: Icons.place_outlined,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              PrimaryButton(label: 'Continue', busy: _busy, onPressed: _submit),
              TextButton(
                onPressed: _busy ? null : _cancel,
                child: Text(
                  'Use a different account',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF777777),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard(String role, IconData icon, String title, String subtitle) {
    final selected = _role == role;
    return GestureDetector(
      onTap: () => setState(() => _role = role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? brandGreenLight.withAlpha(25)
              : const Color(0xFFF7F9F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? brandGreen : const Color(0xFFE0E7E3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 28,
                color: selected ? brandGreen : const Color(0xFF999999)),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF333333),
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF999999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
