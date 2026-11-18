import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../widgets/form_styles.dart';
import 'complete_profile_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'provider_home_screen.dart';

/// The signed-in landing screen for a profile's role.
Widget homeForProfile(Profile profile) => profile.role == 'provider'
    ? const ProviderHomeScreen()
    : const HomeScreen();

/// Root of the app. Decides where the user lands:
///
///  * a persisted session with a profile  → their home screen
///  * a session without a profile (first Google/Apple sign-in)
///                                         → CompleteProfileScreen
///  * no session                           → LoginScreen
///
/// It also stays subscribed to Supabase auth changes while the login or
/// signup screen is showing, which is how an OAuth redirect gets picked up.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authService = AuthService();
  StreamSubscription<sb.AuthState>? _sub;

  bool _resolving = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sub = sb.Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      // Email/password login sets Session.current itself before the
      // Supabase sign-in fires, so this only reacts to OAuth sign-ins.
      if (state.event == sb.AuthChangeEvent.signedIn &&
          Session.current == null &&
          !_resolving) {
        _resolve();
      }
    });
    _resolve();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _resolve() async {
    setState(() {
      _resolving = true;
      _error = null;
    });
    try {
      final profile = await _authService.restoreSession();
      if (!mounted) return;
      if (profile == null) {
        setState(() => _resolving = false);
        return;
      }
      _replaceWith(homeForProfile(profile));
    } on ProfileMissingException {
      if (!mounted) return;
      _replaceWith(const CompleteProfileScreen());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _resolving = false;
        _error = e.message;
      });
    }
  }

  void _replaceWith(Widget screen) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (_) => false,
    );
  }

  Future<void> _signOut() async {
    await _authService.logout();
    if (!mounted) return;
    setState(() {
      _resolving = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_resolving) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined,
                      size: 56, color: Color(0xFFC5D1C9)),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(label: 'Try again', onPressed: _resolve),
                  TextButton(
                    onPressed: _signOut,
                    child: Text(
                      'Sign out',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF777777),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return const LoginScreen();
  }
}
