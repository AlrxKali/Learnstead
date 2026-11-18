import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:learnstead_ui/screens/account_screen.dart';
import 'package:learnstead_ui/screens/forgot_password_screen.dart';
import 'package:learnstead_ui/screens/provider_profile_tab.dart';
import 'package:learnstead_ui/services/auth_service.dart';
import 'package:learnstead_ui/services/business_service.dart';
import 'package:learnstead_ui/widgets/business_detail_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

// Run with: flutter test --dart-define=API_BASE_URL=http://api.test

const _business = {
  'id': 'b1',
  'owner_id': 'owner-1',
  'name': 'Maple Microschool',
  'description': 'Small, project-based learning.',
  'phone': '+15035550100',
  'email': 'hello@maple.test',
  'website': 'https://maple.test',
  'address_line1': '1 Main St',
  'address_line2': null,
  'city': 'Portland',
  'state': 'OR',
  'zip_code': '97201',
  'category_id': null,
  'category': null,
  'delivery_mode': 'in_person',
  'min_age': 5,
  'max_age': 11,
  'subcategories': [],
  'avg_rating': 4.5,
  'review_count': 2,
  'created_at': '2026-01-01T00:00:00Z',
  'updated_at': '2026-01-01T00:00:00Z',
};

Map<String, dynamic> _review(String id, String name, int rating, bool mine) => {
      'id': id,
      'business_id': 'b1',
      'parent_id': mine ? 'u1' : 'u2',
      'reviewer_name': name,
      'rating': rating,
      'comment': 'Great for our kids — $name',
      'is_mine': mine,
      'created_at': '2026-10-01T00:00:00Z',
      'updated_at': '2026-10-01T00:00:00Z',
    };

void main() {
  final requests = <http.Request>[];
  late List<Map<String, dynamic>> reviews;

  final client = MockClient((req) async {
    if (req.url.host != 'api.test') {
      // Fonts / Supabase: leave pending (see provider_schedule_test.dart).
      return Completer<http.Response>().future;
    }
    requests.add(req);
    final path = req.url.path;
    http.Response json(Object? body, [int status = 200]) => http.Response(
          body == null ? '' : jsonEncode(body),
          status,
          headers: {'content-type': 'application/json'},
        );
    if (path == '/businesses/me') return json(_business);
    if (path == '/businesses/b1/reviews' && req.method == 'GET') {
      return json(reviews);
    }
    if (path == '/businesses/b1/reviews/mine' && req.method == 'PUT') {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      reviews = [
        {..._review('r-mine', 'Pat Parent', body['rating'] as int, true)},
        ...reviews.where((r) => r['is_mine'] != true),
      ];
      return json(reviews.first);
    }
    if (path == '/businesses/b1/events') return json([]);
    if (path == '/businesses/b1/view') return json(null, 204);
    if (path == '/auth/forgot-password') return json(null, 204);
    if (path == '/auth/reset-password') return json(null, 204);
    if (path == '/auth/me' && req.method == 'PATCH') {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      return json({
        'id': 'u1',
        'role': 'parent',
        'full_name': body['full_name'],
        'home_zip_code': body['home_zip_code'],
        'created_at': '2026-01-01T00:00:00Z',
      });
    }
    return http.Response('{"detail":"unexpected ${req.method} $path"}', 500);
  });

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await sb.Supabase.initialize(url: 'http://sb.test', anonKey: 'anon');
  });

  void signIn(String role) {
    Session.current = AuthResult(
      accessToken: 'test-token',
      refreshToken: 'r',
      profile: Profile(
        id: 'u1',
        role: role,
        fullName: 'Pat Parent',
        homeZipCode: role == 'parent' ? '97201' : null,
        createdAt: DateTime(2026),
      ),
    );
  }

  setUp(() {
    requests.clear();
    reviews = [_review('r2', 'Quinn', 4, false)];
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: child));
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester
          .runAsync(() => Future.delayed(const Duration(milliseconds: 40)));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('listing detail: reviews load, parent can write one',
      (tester) async {
    signIn('parent');
    await http.runWithClient(() async {
      await pump(
        tester,
        Scaffold(
          body: BusinessDetailSheet(
            business: Business.fromJson(_business),
            scrollController: ScrollController(),
          ),
        ),
      );
      await settle(tester);

      expect(find.text('Quinn'), findsOneWidget);
      expect(requests.any((r) => r.url.path == '/businesses/b1/view'), isTrue);

      await tester.ensureVisible(find.text('Write a review'));
      await tester.tap(find.text('Write a review'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.star_outline_rounded).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await settle(tester);

      final put = requests.firstWhere((r) => r.method == 'PUT');
      expect((jsonDecode(put.body) as Map)['rating'], 5);
      expect(find.text('Pat Parent (you)'), findsOneWidget);
      expect(find.text('Edit your review'), findsOneWidget);
    }, () => client);
  });

  testWidgets('providers cannot review', (tester) async {
    signIn('provider');
    await http.runWithClient(() async {
      await pump(
        tester,
        Scaffold(
          body: BusinessDetailSheet(
            business: Business.fromJson(_business),
            scrollController: ScrollController(),
          ),
        ),
      );
      await settle(tester);
      expect(find.text('Quinn'), findsOneWidget);
      expect(find.text('Write a review'), findsNothing);
    }, () => client);
  });

  testWidgets('provider profile shows real reviews', (tester) async {
    signIn('provider');
    await http.runWithClient(() async {
      await pump(tester, const Scaffold(body: ProviderProfileTab()));
      await settle(tester);
      expect(find.text('Maple Microschool'), findsOneWidget);
      expect(find.text('Quinn'), findsOneWidget);
      expect(find.text('No reviews yet.'), findsNothing);
    }, () => client);
  });

  testWidgets('forgot password: request code then reset', (tester) async {
    Session.current = null;
    await http.runWithClient(() async {
      await pump(tester, const ForgotPasswordScreen(initialEmail: 'a@b.test'));
      await tester.tap(find.text('Send reset code'));
      await settle(tester);
      expect(find.text('Check your email'), findsOneWidget);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '123456');
      await tester.enterText(fields.at(1), 'newpass1');
      await tester.enterText(fields.at(2), 'newpass1');
      await tester.tap(find.text('Update password'));
      await settle(tester);

      final reset =
          requests.firstWhere((r) => r.url.path == '/auth/reset-password');
      expect(jsonDecode(reset.body), {
        'email': 'a@b.test',
        'code': '123456',
        'new_password': 'newpass1',
      });
    }, () => client);
  });

  testWidgets('account: parent edits name and zip', (tester) async {
    signIn('parent');
    await http.runWithClient(() async {
      await pump(tester, const AccountScreen());
      await tester.pumpAndSettle();
      expect(find.text('Sign out'), findsOneWidget);
      expect(find.text('Delete account'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'Pat P.');
      await tester.enterText(find.byType(TextField).at(1), '97202');
      await tester.tap(find.text('Save changes'));
      await settle(tester);

      final patch = requests.firstWhere((r) => r.method == 'PATCH');
      expect(jsonDecode(patch.body),
          {'full_name': 'Pat P.', 'home_zip_code': '97202'});
      expect(Session.current!.profile.homeZipCode, '97202');
    }, () => client);
  });
}
