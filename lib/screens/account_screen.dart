import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../widgets/form_styles.dart';
import 'auth_gate.dart';

/// Account settings for both roles: edit name (and home zip for parents),
/// sign out, delete account. Pops with `true` if the profile was changed.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _authService = AuthService();
  late final Profile? _profile = Session.current?.profile;
  late final _nameController =
      TextEditingController(text: _profile?.fullName ?? '');
  late final _zipController =
      TextEditingController(text: _profile?.homeZipCode ?? '');

  bool _saving = false;
  bool _leaving = false;
  bool _changed = false;

  bool get _isParent => _profile?.role == 'parent';

  @override
  void dispose() {
    _nameController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final zip = _zipController.text.trim();
    if (_isParent) {
      final digits = zip.replaceAll(RegExp(r'\D'), '');
      if (digits.length != 5 && digits.length != 9) {
        showErrorSnack(context, 'Please enter a 5-digit US zip code.');
        return;
      }
    }
    setState(() => _saving = true);
    try {
      await _authService.updateMyProfile(
        fullName: name,
        homeZipCode: _isParent ? zip : null,
      );
      if (!mounted) return;
      _changed = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (_) => false,
    );
  }

  Future<void> _logout() async {
    setState(() => _leaving = true);
    await _authService.logout();
    if (!mounted) return;
    _goToLogin();
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Delete your account?',
          style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        content: Text(
          _isParent
              ? 'This permanently deletes your profile, plans, saved programs, reviews and chats. It cannot be undone.'
              : 'This permanently deletes your profile, your business listing, its schedule and reviews, and your chats. It cannot be undone.',
          style: GoogleFonts.nunito(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete account',
              style: TextStyle(color: errorRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _leaving = true);
    try {
      await _authService.deleteAccount();
      if (!mounted) return;
      _goToLogin();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _leaving = false);
      showErrorSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = Session.email;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          foregroundColor: const Color(0xFF333333),
          title: Text(
            'Account',
            style:
                GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (email != null) ...[
                  fieldLabel('Email'),
                  Text(
                    email,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isParent ? 'Parent account' : 'Provider account',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF999999),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
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
                if (_isParent) ...[
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
                  const SizedBox(height: 6),
                  Text(
                    'Used to show in-person and hybrid programs near you.',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF999999),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Save changes',
                  busy: _saving,
                  onPressed: _leaving ? null : _save,
                ),
                const SizedBox(height: 32),
                const Divider(color: Color(0xFFE0E7E3)),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout, color: Color(0xFF555555)),
                  title: Text(
                    'Sign out',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  enabled: !_leaving,
                  onTap: _logout,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.delete_forever_outlined, color: errorRed),
                  title: Text(
                    'Delete account',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: errorRed,
                    ),
                  ),
                  enabled: !_leaving,
                  onTap: _deleteAccount,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
