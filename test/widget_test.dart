import 'package:flutter_test/flutter_test.dart';

import 'package:learnstead_ui/main.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const LearnsteadApp());

    expect(find.text('Welcome to Learnstead'), findsOneWidget);
    expect(find.text('a home base for home schooling'), findsOneWidget);
  });
}
