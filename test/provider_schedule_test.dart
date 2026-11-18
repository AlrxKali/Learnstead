import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:learnstead_ui/screens/provider_dashboard_tab.dart';
import 'package:learnstead_ui/screens/provider_schedule_tab.dart';
import 'package:learnstead_ui/services/auth_service.dart';

// Run with: flutter test --dart-define=API_BASE_URL=http://api.test

Map<String, dynamic> _event(String id, String title, DateTime start) => {
      'id': id,
      'business_id': 'b1',
      'title': title,
      'description': null,
      'event_type': 'session',
      'starts_at': start.toUtc().toIso8601String(),
      'ends_at': start.add(const Duration(hours: 2)).toUtc().toIso8601String(),
      'capacity': 8,
      'status': 'confirmed',
      'created_at': start.toUtc().toIso8601String(),
      'updated_at': start.toUtc().toIso8601String(),
    };

void main() {
  final requests = <http.Request>[];
  late List<Map<String, dynamic>> events;

  final client = MockClient((req) async {
    // google_fonts fetches Nunito at runtime and throws on any failed
    // download. Leave those requests pending so text falls back to the
    // default test font without failing the test.
    if (req.url.host != 'api.test') {
      return Completer<http.Response>().future;
    }
    requests.add(req);
    final path = req.url.path;
    http.Response json(Object body, [int status = 200]) => http.Response(
          jsonEncode(body),
          status,
          headers: {'content-type': 'application/json'},
        );
    if (path == '/businesses/me/events' && req.method == 'GET') {
      return json(events);
    }
    if (path == '/businesses/me/events' && req.method == 'POST') {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      final created = _event(
        'new',
        body['title'] as String,
        DateTime.parse(body['starts_at'] as String).toLocal(),
      );
      events = [...events, created];
      return json(created, 201);
    }
    if (path == '/businesses/me/stats') {
      return json({
        'profile_views': 41,
        'inquiries': 3,
        'saved_count': 7,
        'review_count': 2,
        'avg_rating': 4.5,
      });
    }
    if (path == '/businesses/me') {
      return json({'detail': 'Business not found'}, 404);
    }
    return http.Response('{"detail":"unexpected ${req.method} $path"}', 500);
  });

  setUp(() {
    requests.clear();
    final today = DateTime.now();
    events = [
      _event('e1', 'Creative Arts Workshop',
          DateTime(today.year, today.month, today.day, 10)),
    ];
    Session.current = AuthResult(
      accessToken: 'test-token',
      refreshToken: 'r',
      profile: Profile(
        id: 'u1',
        role: 'provider',
        fullName: 'Pat Provider',
        homeZipCode: null,
        createdAt: DateTime(2026),
      ),
    );
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  }

  testWidgets('schedule lists API events and can add one', (tester) async {
    await http.runWithClient(() async {
      await pump(tester, const ProviderScheduleTab());
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();

      expect(find.text('Creative Arts Workshop'), findsOneWidget);
      expect(find.text('8 spots'), findsOneWidget);
      expect(
        requests.first.headers['Authorization'],
        'Bearer test-token',
      );

      await tester.tap(find.text('Add Event'));
      await tester.pumpAndSettle();
      expect(find.text('New event'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'STEM Exploration');
      await tester.ensureVisible(find.text('Add event'));
      await tester.tap(find.text('Add event'));
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();

      final post = requests.firstWhere((r) => r.method == 'POST');
      final sent = jsonDecode(post.body) as Map<String, dynamic>;
      expect(sent['title'], 'STEM Exploration');
      expect(sent['event_type'], 'session');
      expect(sent['status'], 'confirmed');
      expect(find.text('STEM Exploration'), findsOneWidget);
    }, () => client);
  });

  testWidgets('dashboard shows live stats and upcoming events', (tester) async {
    await http.runWithClient(() async {
      await pump(tester, ProviderDashboardTab(onTabSwitch: (_) {}));
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();

      expect(find.text('41'), findsOneWidget); // profile views
      expect(find.text('7'), findsOneWidget); // saved
      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('Avg Rating (2)'), findsOneWidget);
      expect(find.text('Creative Arts Workshop'), findsOneWidget);
      // No business yet -> setup prompt instead of fake data.
      expect(find.textContaining('Finish setting up'), findsOneWidget);
      expect(find.text('Jessica Thompson'), findsNothing);
    }, () => client);
  });
}
