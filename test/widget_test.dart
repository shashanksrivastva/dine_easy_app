import 'package:flutter_test/flutter_test.dart';

import 'package:dine_easy_app/main.dart';

void main() {
  testWidgets('app loads login screen', (tester) async {
    await tester.pumpWidget(const DineEasyApp());

    expect(find.text('DineEasy'), findsOneWidget);
    expect(find.text('Welcome!'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
